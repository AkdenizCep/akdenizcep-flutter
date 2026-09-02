import assert from "node:assert/strict";
import test from "node:test";

import {
  MAX_PROFILE_PHOTO_BYTES,
  ProfilePhotoError,
  ProfilePhotoDependencies,
  removeProfilePhoto,
  setProfilePhoto,
} from "../src/profile-photo";

const student = {
  uid: "student-1",
  email: "student@ogr.akdeniz.edu.tr",
};

function jpeg(size = 32): Buffer {
  const result = Buffer.alloc(size);
  result.set([0xff, 0xd8, 0xff]);
  return result;
}

function dependencies(): ProfilePhotoDependencies & {
  uploaded?: {bytes: Buffer; publicId: string};
  written?: {uid: string; photoUrl: string | null};
} {
  const deps: ProfilePhotoDependencies & {
    uploaded?: {bytes: Buffer; publicId: string};
    written?: {uid: string; photoUrl: string | null};
  } = {
    async upload(bytes, publicId) {
      deps.uploaded = {bytes, publicId};
      return {secureUrl: "https://cdn.example/avatar.jpg"};
    },
    async destroy() {
      return "ok";
    },
    async writePhotoUrl(uid, photoUrl) {
      deps.written = {uid, photoUrl};
    },
  };
  return deps;
}

test("kimliksiz profil fotoğrafı çağrısını reddeder", async () => {
  await assert.rejects(
    setProfilePhoto({identity: null, imageBase64: jpeg().toString("base64"), deps: dependencies()}),
    (error: ProfilePhotoError) => error.code === "unauthenticated",
  );
});

test("Akdeniz öğrenci alanı dışındaki hesabı reddeder", async () => {
  await assert.rejects(
    setProfilePhoto({
      identity: {uid: "other", email: "other@example.com"},
      imageBase64: jpeg().toString("base64"),
      deps: dependencies(),
    }),
    (error: ProfilePhotoError) => error.code === "permission-denied",
  );
});

test("JPEG olmayan veriyi reddeder", async () => {
  await assert.rejects(
    setProfilePhoto({
      identity: student,
      imageBase64: Buffer.from("not-a-jpeg").toString("base64"),
      deps: dependencies(),
    }),
    (error: ProfilePhotoError) => error.code === "invalid-argument",
  );
});

test("bir megabayttan büyük görseli reddeder", async () => {
  await assert.rejects(
    setProfilePhoto({
      identity: student,
      imageBase64: jpeg(MAX_PROFILE_PHOTO_BYTES + 1).toString("base64"),
      deps: dependencies(),
    }),
    (error: ProfilePhotoError) => error.code === "resource-exhausted",
  );
});

test("görseli kullanıcıya ait sabit kimlikle yükleyip URL'yi yazar", async () => {
  const deps = dependencies();
  const bytes = jpeg();

  const result = await setProfilePhoto({
    identity: student,
    imageBase64: bytes.toString("base64"),
    deps,
  });

  assert.deepEqual(deps.uploaded, {
    bytes,
    publicId: "profile-photos/student-1/avatar",
  });
  assert.deepEqual(deps.written, {
    uid: "student-1",
    photoUrl: "https://cdn.example/avatar.jpg",
  });
  assert.deepEqual(result, {photoUrl: "https://cdn.example/avatar.jpg"});
});

test("Cloudinary yüklemesi başarısızsa eski URL'yi değiştirmez", async () => {
  const deps = dependencies();
  deps.upload = async () => {
    throw new Error("cloudinary unavailable");
  };

  await assert.rejects(
    setProfilePhoto({
      identity: student,
      imageBase64: jpeg().toString("base64"),
      deps,
    }),
  );
  assert.equal(deps.written, undefined);
});

test("Cloudinary dosyası bulunmasa da profil URL'sini temizler", async () => {
  const deps = dependencies();
  deps.destroy = async () => "not found";

  const result = await removeProfilePhoto({identity: student, deps});

  assert.deepEqual(deps.written, {uid: "student-1", photoUrl: null});
  assert.deepEqual(result, {removed: true});
});
