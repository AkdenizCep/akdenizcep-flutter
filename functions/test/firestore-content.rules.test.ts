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
    await setDoc(doc(adminDb, "clubs/club"), {
      name: "Kulüp", adminUid: "admin", adminUids: [], active: true,
    });
    await setDoc(doc(adminDb, "clubs/club/club-events/event"), {
      title: "Etkinlik", attendeeIds: [], attendeeCount: 0,
      moderationStatus: "visible", moderatedAt: null, moderatedBy: null,
      createdAt: new Date("2026-09-01T00:00:00Z"),
    });
  });
}

function commentPayload() {
  return {
    authorUid: "student", authorName: "Student", text: "Yorum",
    moderationStatus: "visible", moderatedAt: null, moderatedBy: null,
    createdAt: serverTimestamp(),
  };
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
  await assertFails(addDoc(
    collection(student, "clubs/club/club-events/event/comments"), commentPayload(),
  ));
});

test("kısıtsız öğrenci topluluk etkinliğine yorum yazabilir", {skip: !rulesEnabled}, async () => {
  await seed("none");
  await assertSucceeds(addDoc(
    collection(db("student"), "clubs/club/club-events/event/comments"), commentPayload(),
  ));
});

test("süresi geçmiş kısıtlama yeni paylaşıma engel olmaz", {skip: !rulesEnabled}, async () => {
  await seed("expired");
  await assertSucceeds(addDoc(collection(db("student"), "board"), boardPayload()));
});

test("kısıtlama alanları henüz taşınmamış öğrenci görünür içerik oluşturabilir", {skip: !rulesEnabled}, async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users/student"), {
      name: "Student", email: "student@ogr.akdeniz.edu.tr", studentId: "2",
    });
  });
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
  await assertSucceeds(updateDoc(doc(student, "clubs/club/club-events/event"), {
    attendeeIds: ["student"], attendeeCount: 1,
  }));
});

test("kaldırılan student-events koleksiyonuna kimse okuma ya da yazma yapamaz", {skip: !rulesEnabled}, async () => {
  await seed("none");
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "student-events/legacy"), {
      authorUid: "student", title: "Eski etkinlik", attendeeIds: [], attendeeCount: 0,
      moderationStatus: "visible", moderatedAt: null, moderatedBy: null,
      createdAt: new Date("2026-09-01T00:00:00Z"),
    });
  });
  const newEvent = {
    authorUid: "student", title: "Yeni etkinlik", attendeeIds: [], attendeeCount: 0,
    moderationStatus: "visible", moderatedAt: null, moderatedBy: null,
    createdAt: serverTimestamp(),
  };
  for (const uid of ["student", "admin"]) {
    await assertFails(getDoc(doc(db(uid), "student-events/legacy")));
    await assertFails(addDoc(collection(db(uid), "student-events"), newEvent));
    await assertFails(updateDoc(doc(db(uid), "student-events/legacy"), {title: "Değişti"}));
  }
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
