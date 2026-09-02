export const MAX_PROFILE_PHOTO_BYTES = 1024 * 1024;

export type ProfilePhotoIdentity = {
  uid: string;
  email: string;
};

export type ProfilePhotoDependencies = {
  upload(bytes: Buffer, publicId: string): Promise<{secureUrl: string}>;
  destroy(publicId: string): Promise<string>;
  writePhotoUrl(uid: string, photoUrl: string | null): Promise<void>;
};

export class ProfilePhotoError extends Error {
  constructor(
    readonly code:
      | "unauthenticated"
      | "permission-denied"
      | "invalid-argument"
      | "resource-exhausted",
    message: string,
  ) {
    super(message);
  }
}

type SetProfilePhotoInput = {
  identity: ProfilePhotoIdentity | null;
  imageBase64: unknown;
  deps: ProfilePhotoDependencies;
};

type RemoveProfilePhotoInput = {
  identity: ProfilePhotoIdentity | null;
  deps: ProfilePhotoDependencies;
};

export async function setProfilePhoto({
  identity,
  imageBase64,
  deps,
}: SetProfilePhotoInput): Promise<{photoUrl: string}> {
  const student = requireStudent(identity);
  const bytes = decodeJpeg(imageBase64);
  const publicId = profilePhotoPublicId(student.uid);
  const uploaded = await deps.upload(bytes, publicId);
  await deps.writePhotoUrl(student.uid, uploaded.secureUrl);
  return {photoUrl: uploaded.secureUrl};
}

export async function removeProfilePhoto({
  identity,
  deps,
}: RemoveProfilePhotoInput): Promise<{removed: true}> {
  const student = requireStudent(identity);
  const result = await deps.destroy(profilePhotoPublicId(student.uid));
  if (result !== "ok" && result !== "not found") {
    throw new Error(`Cloudinary silme işlemi başarısız: ${result}`);
  }
  await deps.writePhotoUrl(student.uid, null);
  return {removed: true};
}

export function profilePhotoPublicId(uid: string): string {
  return `profile-photos/${uid}/avatar`;
}

function requireStudent(
  identity: ProfilePhotoIdentity | null,
): ProfilePhotoIdentity {
  if (!identity?.uid || !identity.email) {
    throw new ProfilePhotoError(
      "unauthenticated",
      "Profil fotoğrafı için oturum açmalısın.",
    );
  }
  if (!identity.email.toLowerCase().endsWith("@ogr.akdeniz.edu.tr")) {
    throw new ProfilePhotoError(
      "permission-denied",
      "Yalnızca Akdeniz Üniversitesi öğrenci hesapları fotoğraf yükleyebilir.",
    );
  }
  return identity;
}

function decodeJpeg(imageBase64: unknown): Buffer {
  if (
    typeof imageBase64 !== "string" ||
    imageBase64.length === 0 ||
    imageBase64.length % 4 !== 0 ||
    !/^[A-Za-z0-9+/]+={0,2}$/.test(imageBase64)
  ) {
    throw new ProfilePhotoError(
      "invalid-argument",
      "Fotoğraf verisi geçerli değil.",
    );
  }

  const bytes = Buffer.from(imageBase64, "base64");
  if (bytes.length > MAX_PROFILE_PHOTO_BYTES) {
    throw new ProfilePhotoError(
      "resource-exhausted",
      "Profil fotoğrafı 1 MB sınırını aşıyor.",
    );
  }
  if (
    bytes.length < 3 ||
    bytes[0] !== 0xff ||
    bytes[1] !== 0xd8 ||
    bytes[2] !== 0xff
  ) {
    throw new ProfilePhotoError(
      "invalid-argument",
      "Yalnızca JPEG profil fotoğrafı kabul edilir.",
    );
  }
  return bytes;
}
