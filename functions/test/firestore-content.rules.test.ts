import {after, before, beforeEach, test} from "node:test";
import {
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  addDoc,
  collection,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from "firebase/firestore";

import {createRulesTestEnv} from "./rules-test-env";

const rulesEnabled = process.env.FIRESTORE_EMULATOR_HOST !== undefined;
let env: RulesTestEnvironment;

before(async () => {
  if (rulesEnabled) {
    env = await createRulesTestEnv("firestore-content", {firestore: true});
  }
});
beforeEach(async () => {
  if (rulesEnabled) await env.clearFirestore();
});
after(async () => {
  if (rulesEnabled) await env.cleanup();
});

function db(uid: string) {
  return env.authenticatedContext(uid, {
    email: `${uid}@ogr.akdeniz.edu.tr`,
  }).firestore();
}

async function seed(restriction: "none" | "indefinite" | "expired") {
  await env.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "users/admin"), {
      name: "Admin", email: "admin@ogr.akdeniz.edu.tr", studentId: "1",
      postingRestricted: false, postingRestrictedUntil: null,
    });
    await setDoc(doc(adminDb, "users/student"), {
      name: "Student", email: "student@ogr.akdeniz.edu.tr", studentId: "2",
      postingRestricted: restriction !== "none",
      postingRestrictedUntil: restriction === "expired" ? new Date("2020-01-01T00:00:00Z") : null,
    });
    await setDoc(doc(adminDb, "admins/admin"), {
      uid: "admin", email: "admin@ogr.akdeniz.edu.tr",
      createdAt: new Date("2026-09-01T00:00:00Z"), createdBy: "bootstrap",
    });
    await setDoc(doc(adminDb, "board/item"), {
      authorUid: "student", title: "Başlık", content: "Metin", category: "genel",
      moderationStatus: "visible", moderatedAt: null, moderatedBy: null,
      createdAt: new Date("2026-09-01T00:00:00Z"),
    });
    await setDoc(doc(adminDb, "student-events/event"), {
      authorUid: "admin", title: "Etkinlik", attendeeIds: [], attendeeCount: 0,
      moderationStatus: "visible", moderatedAt: null, moderatedBy: null,
      createdAt: new Date("2026-09-01T00:00:00Z"),
    });
  });
}

function boardPayload() {
  return {
    authorUid: "student",
    title: "Yeni ilan",
    content: "Metin",
    category: "genel",
    moderationStatus: "visible",
    moderatedAt: null,
    moderatedBy: null,
    createdAt: serverTimestamp(),
  };
}

test("süresiz kısıtlı öğrenci yeni paylaşım ve yorum oluşturamaz", {skip: !rulesEnabled}, async () => {
  await seed("indefinite");
  const student = db("student");
  await assertFails(addDoc(collection(student, "board"), boardPayload()));
  await assertFails(addDoc(collection(student, "student-events/event/comments"), {
    authorUid: "student", authorName: "Student", text: "Yorum",
    moderationStatus: "visible", moderatedAt: null, moderatedBy: null,
    createdAt: serverTimestamp(),
  }));
});

test("süresi geçmiş kısıtlama yeni paylaşıma engel olmaz", {skip: !rulesEnabled}, async () => {
  await seed("expired");
  await assertSucceeds(addDoc(collection(db("student"), "board"), boardPayload()));
});

test("kısıtlama beğeni ve etkinliğe katılım alanlarını engellemez", {skip: !rulesEnabled}, async () => {
  await seed("indefinite");
  await env.withSecurityRulesDisabled(async (context) => {
    const root = context.firestore();
    await setDoc(doc(root, "campus_photos/photo"), {
      authorUid: "admin", authorName: "Admin", imageUrl: "https://example.com/a.jpg",
      caption: "", likedBy: [], moderationStatus: "visible",
      moderatedAt: null, moderatedBy: null, createdAt: new Date(),
    });
  });
  const student = db("student");
  await assertSucceeds(updateDoc(doc(student, "campus_photos/photo"), {likedBy: ["student"]}));
  await assertSucceeds(updateDoc(doc(student, "student-events/event"), {
    attendeeIds: ["student"], attendeeCount: 1,
  }));
});

test("öğrenci moderasyon alanını değiştiremez, yönetici metni değiştirmeden gizleyebilir", {skip: !rulesEnabled}, async () => {
  await seed("none");
  await assertFails(updateDoc(doc(db("student"), "board/item"), {
    moderationStatus: "hidden", moderatedAt: serverTimestamp(), moderatedBy: "student",
  }));
  await assertSucceeds(updateDoc(doc(db("admin"), "board/item"), {
    moderationStatus: "hidden", moderatedAt: serverTimestamp(), moderatedBy: "admin",
  }));
  await assertFails(updateDoc(doc(db("admin"), "board/item"), {content: "değişti"}));
});

test("gizli içeriği öğrenci okuyamaz, yönetici okuyabilir", {skip: !rulesEnabled}, async () => {
  await seed("none");
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), "board/item"), {moderationStatus: "hidden"});
  });
  await assertFails(getDoc(doc(db("student"), "board/item")));
  await assertSucceeds(getDoc(doc(db("admin"), "board/item")));
});
