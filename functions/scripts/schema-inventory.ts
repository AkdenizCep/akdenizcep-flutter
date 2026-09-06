import {getFirestore} from "firebase-admin/firestore";
import {getDatabase} from "firebase-admin/database";
import {deleteApp} from "firebase-admin/app";

import {
  firebaseAdminApp,
  parseArguments,
  printJson,
  requiredString,
} from "./firebase-script-utils";

const TOP_LEVEL_COLLECTIONS = [
  "users", "clubs", "announcements", "board", "student-events",
  "lost_found_items", "campus_photos", "feedback", "cafeteria_ratings",
];

async function main(): Promise<void> {
  const args = parseArguments(process.argv.slice(2));
  const project = requiredString(args, "project");
  const app = firebaseAdminApp(project);
  try {
    const firestore = getFirestore(app);
    const database = getDatabase(app);

    const collections = Object.fromEntries(await Promise.all(TOP_LEVEL_COLLECTIONS.map(async (name) => {
      const snapshot = await firestore.collection(name).count().get();
      return [name, snapshot.data().count];
    })));
    const [clubEvents, comments, adminUids, menu] = await Promise.all([
      firestore.collectionGroup("club-events").count().get(),
      firestore.collectionGroup("comments").count().get(),
      database.ref("admin_uids").get(),
      database.ref("cafeteria_menu").get(),
    ]);
    const menuValue = menu.val() as Record<string, unknown> | null;

    printJson({
      project,
      mode: "read-only",
      firestore: {
        collections,
        collectionGroups: {"club-events": clubEvents.data().count, comments: comments.data().count},
      },
      rtdb: {
        adminUidCount: adminUids.numChildren(),
        menuDateCount: menu.numChildren(),
        legacyMenuDateCount: Object.values(menuValue ?? {}).filter((value) =>
          value !== null && typeof value === "object" && !Array.isArray(value)).length,
      },
    });
  } finally {
    await deleteApp(app);
  }
}

void main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
