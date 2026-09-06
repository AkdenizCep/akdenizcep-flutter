import {getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getDatabase} from "firebase-admin/database";
import {deleteApp, getApps} from "firebase-admin/app";

import {executeAdminBootstrap} from "./schema-plan";
import {
  firebaseAdminApp,
  parseArguments,
  printJson,
  requiredString,
} from "./firebase-script-utils";

export type BootstrapSummary = {
  project: string;
  requested: number;
  added: number;
  unchanged: number;
};

export async function bootstrapAdmins(project: string, uids: string[]): Promise<BootstrapSummary> {
  if (uids.length === 0) throw new Error("En az bir UID verilmelidir.");

  const app = firebaseAdminApp(project);
  const auth = getAuth(app);
  const firestore = getFirestore(app);
  const database = getDatabase(app);
  let adminCountBefore = 0;

  const added = await executeAdminBootstrap(uids, {
    loadAuthEmails: async (requested) => {
      const users = await Promise.all(requested.map((uid) => auth.getUser(uid)));
      return new Map(users.flatMap((user) => user.email ? [[user.uid, user.email]] : []));
    },
    loadUserEmails: async (requested) => {
      const snapshots = await Promise.all(requested.map((uid) => firestore.doc(`users/${uid}`).get()));
      return new Map(snapshots.flatMap((snapshot) => {
        const email = snapshot.get("email");
        return typeof email === "string" ? [[snapshot.id, email]] : [];
      }));
    },
    loadExistingAdmins: async () => {
      const snapshot = await firestore.collection("admins").get();
      adminCountBefore = snapshot.size;
      return new Set(snapshot.docs.map((document) => document.id));
    },
    applyFirestore: async (entries) => {
      const batch = firestore.batch();
      for (const entry of entries) {
        batch.create(firestore.doc(`admins/${entry.uid}`), {
          uid: entry.uid,
          email: entry.email,
          createdAt: FieldValue.serverTimestamp(),
          createdBy: "bootstrap-script",
        });
      }
      batch.set(firestore.doc("admin_config/current"), {
        adminCount: adminCountBefore + entries.length,
        revision: FieldValue.increment(1),
        lastChangedUid: entries.at(-1)?.uid ?? null,
        lastChangeType: "bootstrap",
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: "bootstrap-script",
      }, {merge: true});
      await batch.commit();
    },
    applyRtdb: async (entries) => {
      await database.ref("admin_uids").update(Object.fromEntries(entries.map(({uid}) => [uid, true])));
    },
    rollbackFirestore: async (entries) => {
      const batch = firestore.batch();
      entries.forEach(({uid}) => batch.delete(firestore.doc(`admins/${uid}`)));
      batch.set(firestore.doc("admin_config/current"), {
        adminCount: adminCountBefore,
        revision: FieldValue.increment(1),
        lastChangedUid: entries.at(-1)?.uid ?? null,
        lastChangeType: "bootstrap-rollback",
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: "bootstrap-script",
      }, {merge: true});
      await batch.commit();
    },
  });

  return {project, requested: uids.length, added, unchanged: uids.length - added};
}

async function main(): Promise<void> {
  const args = parseArguments(process.argv.slice(2));
  const project = requiredString(args, "project");
  const uids = requiredString(args, "uids").split(",").map((uid) => uid.trim()).filter(Boolean);
  try {
    printJson(await bootstrapAdmins(project, uids));
  } finally {
    const app = getApps().find((candidate) => candidate.name === project);
    if (app) await deleteApp(app);
  }
}

if (require.main === module) {
  void main().catch((error: unknown) => {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  });
}
