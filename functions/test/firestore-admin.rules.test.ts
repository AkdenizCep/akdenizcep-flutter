import assert from "node:assert/strict";
import {after, before, beforeEach, test} from "node:test";
import {
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  deleteDoc,
  doc,
  getDoc,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
} from "firebase/firestore";

import {createRulesTestEnv} from "./rules-test-env";

const rulesEnabled = process.env.FIRESTORE_EMULATOR_HOST !== undefined;
let env: RulesTestEnvironment;

before(async () => {
  if (rulesEnabled) {
    env = await createRulesTestEnv("firestore-admin", {firestore: true});
  }
});
beforeEach(async () => {
  if (rulesEnabled) await env.clearFirestore();
});
after(async () => {
  if (rulesEnabled) await env.cleanup();
});

async function seedAdminState(adminUids: string[]) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const uid of [...adminUids, "student", "outsider"]) {
      const email = uid === "outsider" ? "user@example.com" : `${uid}@ogr.akdeniz.edu.tr`;
      await setDoc(doc(db, `users/${uid}`), {
        name: uid,
        email,
        studentId: uid,
        followedClubs: [],
        ratedMealIds: [],
        savedEventIds: [],
        postingRestricted: false,
        postingRestrictedUntil: null,
        createdAt: new Date("2026-09-01T00:00:00Z"),
      });
    }
    for (const uid of adminUids) {
      await setDoc(doc(db, `admins/${uid}`), {
        uid,
        email: `${uid}@ogr.akdeniz.edu.tr`,
        createdAt: new Date("2026-09-01T00:00:00Z"),
        createdBy: "bootstrap",
      });
    }
    await setDoc(doc(db, "admin_config/current"), {
      adminCount: adminUids.length,
      revision: 1,
      lastChangedUid: adminUids.at(-1) ?? "bootstrap",
      lastChangeType: "bootstrap",
      updatedAt: new Date("2026-09-01T00:00:00Z"),
      updatedBy: "bootstrap",
    });
  });
}

function studentDb(uid: string, email = `${uid}@ogr.akdeniz.edu.tr`) {
  return env.authenticatedContext(uid, {email}).firestore();
}

test("kullanıcı yalnız kendi admin kaydını okuyarak panel erişimini doğrulayabilir", {skip: !rulesEnabled}, async () => {
  await seedAdminState(["admin-a"]);
  await assertSucceeds(getDoc(doc(studentDb("admin-a"), "admins/admin-a")));
  await assertFails(getDoc(doc(studentDb("student"), "admins/admin-a")));
});

test("son yönetici transaction ile dahi kaldırılamaz", {skip: !rulesEnabled}, async () => {
  await seedAdminState(["admin-a"]);
  const db = studentDb("admin-a");
  await assertFails(runTransaction(db, async (tx) => {
    tx.delete(doc(db, "admins/admin-a"));
    tx.update(doc(db, "admin_config/current"), {
      adminCount: 0,
      revision: 2,
      lastChangedUid: "admin-a",
      lastChangeType: "remove",
      updatedAt: serverTimestamp(),
      updatedBy: "admin-a",
    });
  }));
});

test("iki yöneticiden biri eşleşen config transactionı ile kaldırılabilir", {skip: !rulesEnabled}, async () => {
  await seedAdminState(["admin-a", "admin-b"]);
  const db = studentDb("admin-a");
  await assertSucceeds(runTransaction(db, async (tx) => {
    tx.delete(doc(db, "admins/admin-b"));
    tx.update(doc(db, "admin_config/current"), {
      adminCount: 1,
      revision: 2,
      lastChangedUid: "admin-b",
      lastChangeType: "remove",
      updatedAt: serverTimestamp(),
      updatedBy: "admin-a",
    });
  }));
});

test("rol belgesi config transactionı olmadan değiştirilemez", {skip: !rulesEnabled}, async () => {
  await seedAdminState(["admin-a", "admin-b"]);
  const db = studentDb("admin-a");
  await assertFails(deleteDoc(doc(db, "admins/admin-b")));
  await assertFails(setDoc(doc(db, "admins/student"), {
    uid: "student",
    email: "student@ogr.akdeniz.edu.tr",
    createdAt: serverTimestamp(),
    createdBy: "admin-a",
  }));
});

test("öğrenci domaini dışındaki hesap yönetici yapılamaz", {skip: !rulesEnabled}, async () => {
  await seedAdminState(["admin-a"]);
  const db = studentDb("admin-a");
  await assertFails(runTransaction(db, async (tx) => {
    tx.set(doc(db, "admins/outsider"), {
      uid: "outsider",
      email: "user@example.com",
      createdAt: serverTimestamp(),
      createdBy: "admin-a",
    });
    tx.update(doc(db, "admin_config/current"), {
      adminCount: 2,
      revision: 2,
      lastChangedUid: "outsider",
      lastChangeType: "add",
      updatedAt: serverTimestamp(),
      updatedBy: "admin-a",
    });
  }));
});

test("yönetici kullanıcı kısıtlamasını metin alanlarına dokunmadan değiştirebilir", {skip: !rulesEnabled}, async () => {
  await seedAdminState(["admin-a"]);
  const db = studentDb("admin-a");
  const target = doc(db, "users/student");
  await assertSucceeds(runTransaction(db, async (tx) => {
    const snapshot = await tx.get(target);
    assert.equal(snapshot.exists(), true);
    tx.update(target, {
      postingRestricted: true,
      postingRestrictedUntil: null,
      restrictionUpdatedAt: serverTimestamp(),
      restrictionUpdatedBy: "admin-a",
    });
  }));
});

test("yönetici profil alanını kısıtlama metadatası olmadan temizleyebilir", {skip: !rulesEnabled}, async () => {
  await seedAdminState(["admin-a"]);
  await assertSucceeds(updateDoc(doc(studentDb("admin-a"), "users/student"), {
    photoUrl: "",
    bio: "",
  }));
});

test("yönetici kısıtlama değişikliğinde denetim metadatasını yazmak zorundadır", {skip: !rulesEnabled}, async () => {
  await seedAdminState(["admin-a"]);
  await assertFails(updateDoc(doc(studentDb("admin-a"), "users/student"), {
    postingRestricted: true,
  }));
});
