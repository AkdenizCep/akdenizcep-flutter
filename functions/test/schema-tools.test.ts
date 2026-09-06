import assert from "node:assert/strict";
import test from "node:test";

import {
  planAdminBootstrap,
  planFirestoreBackfill,
  planRtdbMenuMigration,
  requireApplyConfirmation,
  executeAdminBootstrap,
} from "../scripts/schema-plan";

test("backfill yalnız eksik entegrasyon alanlarını ekler", () => {
  const changes = planFirestoreBackfill([
    {path: "users/u1", data: {email: "u1@ogr.akdeniz.edu.tr"}},
    {path: "clubs/c1", data: {active: false, followerCount: 12}},
    {path: "board/b1", data: {title: "İlan", likedBy: ["u2"]}},
    {path: "announcements/a1", data: {title: "Duyuru", createdAt: "stamp"}},
  ]);

  assert.deepEqual(changes, [
    {path: "users/u1", patch: {postingRestricted: false, postingRestrictedUntil: null}},
    {path: "board/b1", patch: {moderationStatus: "visible", moderatedAt: null, moderatedBy: null}},
    {path: "announcements/a1", patch: {status: "published", publishedAt: "stamp", updatedAt: "stamp"}},
  ]);
});

test("ikinci backfill çalışması değişiklik üretmez", () => {
  const changes = planFirestoreBackfill([
    {path: "users/u1", data: {postingRestricted: false, postingRestrictedUntil: null}},
    {path: "clubs/c1", data: {active: true}},
    {path: "campus_photos/p1", data: {moderationStatus: "visible", moderatedAt: null, moderatedBy: null}},
    {path: "announcements/a1", data: {status: "published", publishedAt: "stamp", updatedAt: "stamp"}},
  ]);
  assert.deepEqual(changes, []);
});

test("legacy menüden yalnız öncelikli ilk öğünü düz diziye taşır", () => {
  assert.deepEqual(planRtdbMenuMigration({
    "2026-09-06": {lunch: ["Çorba"], dinner: ["Pilav"]},
    "2026-09-07": ["Makarna"],
    "2026-09-08": {breakfast: ["Peynir"], lunch: ["Nohut"]},
  }), [
    {path: "cafeteria_menu/2026-09-06", value: ["Çorba"]},
    {path: "cafeteria_menu/2026-09-08", value: ["Peynir"]},
  ]);
});

test("bootstrap yalnız doğrulanmış öğrenci hesaplarından eksik adminleri planlar", () => {
  const plan = planAdminBootstrap(
    ["a", "b"],
    new Map([
      ["a", "a@ogr.akdeniz.edu.tr"],
      ["b", "b@ogr.akdeniz.edu.tr"],
    ]),
    new Map([
      ["a", "a@ogr.akdeniz.edu.tr"],
      ["b", "b@ogr.akdeniz.edu.tr"],
    ]),
    new Set(["a"]),
  );
  assert.deepEqual(plan, [
    {uid: "b", email: "b@ogr.akdeniz.edu.tr"},
  ]);
});

test("bootstrap dış-domain veya users belgesi olmayan hesabı reddeder", () => {
  assert.throws(() => planAdminBootstrap(
    ["outsider"],
    new Map([["outsider", "user@example.com"]]),
    new Map(),
    new Set(),
  ), /öğrenci hesabı değil/);
});

test("apply yalnız proje kimliği iki kez eşleştiğinde açılır", () => {
  assert.equal(requireApplyConfirmation({
    project: "akdeniz-cep-36d3f",
    apply: true,
    confirmProject: "akdeniz-cep-36d3f",
  }), true);
  assert.throws(() => requireApplyConfirmation({
    project: "akdeniz-cep-36d3f",
    apply: true,
    confirmProject: "başka-proje",
  }), /proje doğrulaması/);
  assert.equal(requireApplyConfirmation({
    project: "akdeniz-cep-36d3f",
    apply: false,
  }), false);
});

test("bootstrap ikinci çalışmada yeni yazma üretmez", async () => {
  const existing = new Set<string>();
  let firestoreWrites = 0;
  let rtdbWrites = 0;
  const deps = {
    loadAuthEmails: async () => new Map([["a", "a@ogr.akdeniz.edu.tr"]]),
    loadUserEmails: async () => new Map([["a", "a@ogr.akdeniz.edu.tr"]]),
    loadExistingAdmins: async () => new Set(existing),
    applyFirestore: async (entries: {uid: string}[]) => {
      firestoreWrites += entries.length;
      entries.forEach((entry) => existing.add(entry.uid));
    },
    applyRtdb: async (entries: {uid: string}[]) => {
      rtdbWrites += entries.length;
    },
    rollbackFirestore: async () => undefined,
  };

  assert.equal(await executeAdminBootstrap(["a"], deps), 1);
  assert.equal(await executeAdminBootstrap(["a"], deps), 0);
  assert.equal(firestoreWrites, 1);
  assert.equal(rtdbWrites, 1);
});

test("RTDB aynası başarısızsa Firestore bootstrap geri alınır", async () => {
  let rolledBack: string[] = [];
  const deps = {
    loadAuthEmails: async () => new Map([["a", "a@ogr.akdeniz.edu.tr"]]),
    loadUserEmails: async () => new Map([["a", "a@ogr.akdeniz.edu.tr"]]),
    loadExistingAdmins: async () => new Set<string>(),
    applyFirestore: async () => undefined,
    applyRtdb: async () => { throw new Error("RTDB kapalı"); },
    rollbackFirestore: async (entries: {uid: string}[]) => {
      rolledBack = entries.map((entry) => entry.uid);
    },
  };

  await assert.rejects(executeAdminBootstrap(["a"], deps), /RTDB kapalı/);
  assert.deepEqual(rolledBack, ["a"]);
});
