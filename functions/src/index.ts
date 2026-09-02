import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {v2 as cloudinary} from "cloudinary";

import {
  ProfilePhotoDependencies,
  ProfilePhotoError,
  ProfilePhotoIdentity,
  removeProfilePhoto as removeProfilePhotoCore,
  setProfilePhoto as setProfilePhotoCore,
} from "./profile-photo";

initializeApp();

const cloudName = defineSecret("CLOUDINARY_CLOUD_NAME");
const apiKey = defineSecret("CLOUDINARY_API_KEY");
const apiSecret = defineSecret("CLOUDINARY_API_SECRET");
const callableOptions = {
  region: "europe-west1",
  secrets: [cloudName, apiKey, apiSecret],
};

export const setProfilePhoto = onCall(callableOptions, async (request) => {
  try {
    return await setProfilePhotoCore({
      identity: identityFrom(request.auth),
      imageBase64: request.data?.imageBase64,
      deps: dependencies(),
    });
  } catch (error) {
    throw callableError(error);
  }
});

export const removeProfilePhoto = onCall(callableOptions, async (request) => {
  try {
    return await removeProfilePhotoCore({
      identity: identityFrom(request.auth),
      deps: dependencies(),
    });
  } catch (error) {
    throw callableError(error);
  }
});

function identityFrom(
  auth: {uid: string; token: Record<string, unknown>} | undefined,
): ProfilePhotoIdentity | null {
  const email = auth?.token.email;
  if (!auth || typeof email !== "string") return null;
  return {uid: auth.uid, email};
}

function dependencies(): ProfilePhotoDependencies {
  cloudinary.config({
    cloud_name: cloudName.value(),
    api_key: apiKey.value(),
    api_secret: apiSecret.value(),
    secure: true,
  });

  return {
    upload: (bytes, publicId) =>
      new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          {
            public_id: publicId,
            overwrite: true,
            invalidate: true,
            resource_type: "image",
            format: "jpg",
            transformation: [
              {
                width: 512,
                height: 512,
                crop: "limit",
                quality: "auto:good",
                flags: "strip_profile",
              },
            ],
          },
          (error, result) => {
            if (error || !result?.secure_url) {
              reject(error ?? new Error("Cloudinary URL döndürmedi."));
              return;
            }
            resolve({secureUrl: result.secure_url});
          },
        );
        stream.end(bytes);
      }),
    destroy: async (publicId) => {
      const result = await cloudinary.uploader.destroy(publicId, {
        resource_type: "image",
        invalidate: true,
      });
      return String(result.result);
    },
    writePhotoUrl: async (uid, photoUrl) => {
      await getFirestore()
        .collection("users")
        .doc(uid)
        .update({photoUrl: photoUrl ?? FieldValue.delete()});
    },
  };
}

function callableError(error: unknown): HttpsError {
  if (error instanceof ProfilePhotoError) {
    return new HttpsError(error.code, error.message);
  }
  logger.error("Profil fotoğrafı işlemi başarısız.", error);
  return new HttpsError(
    "internal",
    "Profil fotoğrafı işlemi tamamlanamadı.",
  );
}
