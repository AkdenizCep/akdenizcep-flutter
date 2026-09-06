import {after, before, beforeEach, test} from "node:test";
import {
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {get, ref, remove, set, update} from "firebase/database";

import {createRulesTestEnv} from "./rules-test-env";

const rulesEnabled = process.env.FIREBASE_DATABASE_EMULATOR_HOST !== undefined;
let env: RulesTestEnvironment;

before(async () => {
  if (rulesEnabled) {
    env = await createRulesTestEnv("database-admin", {database: true});
  }
});
beforeEach(async () => {
  if (!rulesEnabled) return;
  await env.clearDatabase();
  await env.withSecurityRulesDisabled(async (context) => {
    await set(ref(context.database()), {
      admin_uids: {admin: true, second: true},
      cafeteria_menu: {"2026-09-06": ["Çorba", "Pilav"]},
      ring_stops: {durak_1: {name: "Durak", lat: 36.8, lng: 30.6}},
      ring_schedule: {
        au_102_gidis: {
          weekday: ["08:00"], weekend: ["09:00"], stops: ["durak_1"],
        },
      },
    });
  });
});
after(async () => {
  if (rulesEnabled) await env.cleanup();
});

function database(uid: string, email = `${uid}@ogr.akdeniz.edu.tr`) {
  return env.authenticatedContext(uid, {email}).database();
}

test("Akdeniz öğrencisi menü, ring ve durak verisini okuyabilir", {skip: !rulesEnabled}, async () => {
  const student = database("student");
  await assertSucceeds(get(ref(student, "cafeteria_menu/2026-09-06")));
  await assertSucceeds(get(ref(student, "ring_schedule/au_102_gidis")));
  await assertSucceeds(get(ref(student, "ring_stops/durak_1")));
});

test("admin olmayan öğrenci menü veya sefer yazamaz", {skip: !rulesEnabled}, async () => {
  const student = database("student");
  await assertFails(set(ref(student, "cafeteria_menu/2026-09-07"), ["Çorba"]));
  await assertFails(set(ref(student, "ring_schedule/au_102_gidis/weekday"), ["08:30"]));
});

test("admin menü ile hafta içi ve hafta sonu saatlerini düzenleyebilir", {skip: !rulesEnabled}, async () => {
  const admin = database("admin");
  await assertSucceeds(set(ref(admin, "cafeteria_menu/2026-09-07"), ["Çorba", "Pilav"]));
  await assertSucceeds(update(ref(admin, "ring_schedule/au_102_gidis"), {
    weekday: ["08:30", "09:00"], weekend: [],
  }));
});

test("admin durak sırasını değiştiremez veya yeni hat oluşturamaz", {skip: !rulesEnabled}, async () => {
  const admin = database("admin");
  await assertFails(set(ref(admin, "ring_schedule/au_102_gidis/stops"), ["durak_2"]));
  await assertFails(set(ref(admin, "ring_schedule/yeni_hat"), {
    weekday: ["08:00"], weekend: [], stops: ["durak_1"],
  }));
});

test("bozuk tarih, boş yemek ve bozuk saat reddedilir", {skip: !rulesEnabled}, async () => {
  const admin = database("admin");
  await assertFails(set(ref(admin, "cafeteria_menu/06-09-2026"), ["Çorba"]));
  await assertFails(set(ref(admin, "cafeteria_menu/2026-09-07"), [""]));
  await assertFails(set(ref(admin, "ring_schedule/au_102_gidis/weekday"), ["25:10"]));
});

test("son RTDB yöneticisi silinemez", {skip: !rulesEnabled}, async () => {
  const admin = database("admin");
  await assertSucceeds(remove(ref(admin, "admin_uids/second")));
  await assertFails(remove(ref(admin, "admin_uids/admin")));
});

test("yönetici aynasına yalnız true ve öğrenci tokenıyla erişilebilir", {skip: !rulesEnabled}, async () => {
  const admin = database("admin");
  await assertFails(set(ref(admin, "admin_uids/student"), false));
  await assertFails(get(ref(database("admin", "user@example.com"), "cafeteria_menu")));
});
