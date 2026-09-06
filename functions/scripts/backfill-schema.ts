import {getFirestore} from "firebase-admin/firestore";
import type {DocumentSnapshot, WriteBatch} from "firebase-admin/firestore";
import {getDatabase} from "firebase-admin/database";
import {deleteApp} from "firebase-admin/app";

import {
  planFirestoreBackfill,
  planRtdbMenuMigration,
  requireApplyConfirmation,
  type FirestoreBackfill,
  type StoredRecord,
} from "./schema-plan";
import {
  firebaseAdminApp,
  parseArguments,
  printJson,
  requiredString,
} from "./firebase-script-utils";

const TOP_LEVEL_COLLECTIONS = [
  "users", "clubs", "announcements", "board", "student-events",
  "lost_found_items", "campus_photos",
];
const WRITE_BATCH_LIMIT = 400;

async function main(): Promise<void> {
  const args = parseArguments(process.argv.slice(2));
  const project = requiredString(args, "project");
  const apply = requireApplyConfirmation({
    project,
    apply: args.apply === true,
    confirmProject: typeof args["confirm-project"] === "string" ? args["confirm-project"] : undefined,
  });
  const app = firebaseAdminApp(project);
  try {
    const firestore = getFirestore(app);
    const database = getDatabase(app);

    const recordGroups = await Promise.all([
      ...TOP_LEVEL_COLLECTIONS.map((name) => firestore.collection(name).get()),
      firestore.collectionGroup("club-events").get(),
      firestore.collectionGroup("comments").get(),
    ]);
    const records: StoredRecord[] = recordGroups.flatMap((snapshot) =>
      snapshot.docs.map(documentRecord));
    const firestoreChanges = planFirestoreBackfill(records);
    const menuSnapshot = await database.ref("cafeteria_menu").get();
    const menu = menuSnapshot.val();
    const rtdbChanges = planRtdbMenuMigration(
      menu !== null && typeof menu === "object" ? menu as Record<string, unknown> : {},
    );

    const byCollection = firestoreChanges.reduce<Record<string, number>>((counts, change) => {
      const root = change.path.split("/")[0];
      counts[root] = (counts[root] ?? 0) + 1;
      return counts;
    }, {});

    printJson({
      project,
      mode: apply ? "apply" : "dry-run",
      firestore: {
        changeCount: firestoreChanges.length,
        byCollection,
        samplePaths: firestoreChanges.slice(0, 20).map(({path}) => path),
      },
      rtdb: {
        changeCount: rtdbChanges.length,
        samplePaths: rtdbChanges.slice(0, 20).map(({path}) => path),
      },
    });

    if (!apply) return;
    await applyFirestoreChanges(firestoreChanges, firestore);
    if (rtdbChanges.length > 0) {
      await database.ref().update(Object.fromEntries(rtdbChanges.map(({path, value}) => [path, value])));
    }
    process.stdout.write("Backfill tamamlandı.\n");
  } finally {
    await deleteApp(app);
  }
}

function documentRecord(snapshot: DocumentSnapshot): StoredRecord {
  return {path: snapshot.ref.path, data: snapshot.data() ?? {}};
}

async function applyFirestoreChanges(
  changes: FirestoreBackfill[],
  firestore: ReturnType<typeof getFirestore>,
): Promise<void> {
  let batch: WriteBatch = firestore.batch();
  let pending = 0;
  for (const change of changes) {
    batch.update(firestore.doc(change.path), change.patch);
    pending += 1;
    if (pending === WRITE_BATCH_LIMIT) {
      await batch.commit();
      batch = firestore.batch();
      pending = 0;
    }
  }
  if (pending > 0) await batch.commit();
}

void main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
