import assert from "node:assert/strict";
import test from "node:test";
import {after} from "node:test";
import {deleteApp, getApps} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {getDatabase} from "firebase-admin/database";

import {bootstrapAdmins} from "../scripts/bootstrap-admins";
import {firebaseAdminApp} from "../scripts/firebase-script-utils";

const emulatorMode = Boolean(
  process.env.FIRESTORE_EMULATOR_HOST &&
  process.env.FIREBASE_AUTH_EMULATOR_HOST &&
  process.env.FIREBASE_DATABASE_EMULATOR_HOST,
);
const project = "demo-akdeniz-cep";
const initialAdmins = [
  "LmSCYHp3JgQ69V9lv8sqiilvScL2",
  "Q0wpzZygz6Wv3RjSAThQLbO6FW72",
  "ryDghUu82ifAYyRyTzZj3NyMaNi1",
];

after(async () => {
  await Promise.all(getApps().map((app) => deleteApp(app)));
});

test("üç başlangıç yöneticisi emulator üzerinde idempotent bootstrap edilir", {skip: !emulatorMode}, async () => {
  const app = firebaseAdminApp(project);
  const auth = getAuth(app);
  const firestore = getFirestore(app);
  const database = getDatabase(app);

  for (const [index, uid] of initialAdmins.entries()) {
    const email = `admin${index + 1}@ogr.akdeniz.edu.tr`;
    await auth.createUser({uid, email});
    await firestore.doc(`users/${uid}`).set({uid, email});
  }

  const first = await bootstrapAdmins(project, initialAdmins);
  const second = await bootstrapAdmins(project, initialAdmins);
  assert.deepEqual(first, {project, requested: 3, added: 3, unchanged: 0});
  assert.deepEqual(second, {project, requested: 3, added: 0, unchanged: 3});

  const [admins, config, mirror] = await Promise.all([
    firestore.collection("admins").get(),
    firestore.doc("admin_config/current").get(),
    database.ref("admin_uids").get(),
  ]);
  assert.equal(admins.size, 3);
  assert.equal(config.get("adminCount"), 3);
  assert.deepEqual(mirror.val(), Object.fromEntries(initialAdmins.map((uid) => [uid, true])));
});
