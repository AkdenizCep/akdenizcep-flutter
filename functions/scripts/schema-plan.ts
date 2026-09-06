export type StoredRecord = {
  path: string;
  data: Record<string, unknown>;
};

export type FirestoreBackfill = {
  path: string;
  patch: Record<string, unknown>;
};

export type RtdbMenuMigration = {
  path: string;
  value: string[];
};

export type AdminBootstrapEntry = {
  uid: string;
  email: string;
};

export type AdminBootstrapDependencies = {
  loadAuthEmails(uids: string[]): Promise<Map<string, string>>;
  loadUserEmails(uids: string[]): Promise<Map<string, string>>;
  loadExistingAdmins(): Promise<Set<string>>;
  applyFirestore(entries: AdminBootstrapEntry[]): Promise<void>;
  applyRtdb(entries: AdminBootstrapEntry[]): Promise<void>;
  rollbackFirestore(entries: AdminBootstrapEntry[]): Promise<void>;
};

type ApplyOptions = {
  project: string;
  apply: boolean;
  confirmProject?: string;
};

const STUDENT_DOMAIN = "@ogr.akdeniz.edu.tr";

function has(data: Record<string, unknown>, field: string): boolean {
  return Object.prototype.hasOwnProperty.call(data, field);
}

function isModeratedPath(path: string): boolean {
  const parts = path.split("/");

  if (parts.length === 2) {
    return ["board", "student-events", "lost_found_items", "campus_photos"].includes(parts[0]);
  }

  if (parts.length === 4 && parts[2] === "comments") {
    return ["student-events", "campus_photos"].includes(parts[0]);
  }

  if (parts.length === 4 && parts[0] === "clubs" && parts[2] === "club-events") {
    return true;
  }

  return parts.length === 6 &&
    parts[0] === "clubs" &&
    parts[2] === "club-events" &&
    parts[4] === "comments";
}

export function planFirestoreBackfill(records: StoredRecord[]): FirestoreBackfill[] {
  return records.flatMap(({path, data}) => {
    const patch: Record<string, unknown> = {};

    if (path.startsWith("users/") && path.split("/").length === 2) {
      if (!has(data, "postingRestricted")) patch.postingRestricted = false;
      if (!has(data, "postingRestrictedUntil")) patch.postingRestrictedUntil = null;
    } else if (path.startsWith("clubs/") && path.split("/").length === 2) {
      if (!has(data, "active")) patch.active = true;
    } else if (isModeratedPath(path)) {
      if (!has(data, "moderationStatus")) patch.moderationStatus = "visible";
      if (!has(data, "moderatedAt")) patch.moderatedAt = null;
      if (!has(data, "moderatedBy")) patch.moderatedBy = null;
    } else if (path.startsWith("announcements/") && path.split("/").length === 2) {
      const createdAt = has(data, "createdAt") ? data.createdAt : null;
      if (!has(data, "status")) patch.status = "published";
      if (!has(data, "publishedAt")) patch.publishedAt = createdAt;
      if (!has(data, "updatedAt")) patch.updatedAt = createdAt;
    }

    return Object.keys(patch).length > 0 ? [{path, patch}] : [];
  });
}

export function planRtdbMenuMigration(
  menu: Record<string, unknown>,
): RtdbMenuMigration[] {
  return Object.entries(menu).flatMap(([date, value]) => {
    if (Array.isArray(value) || typeof value !== "object" || value === null) return [];

    const legacy = value as Record<string, unknown>;
    const selected = [legacy.breakfast, legacy.lunch, legacy.dinner]
      .find((meal): meal is string[] => Array.isArray(meal) && meal.every((item) => typeof item === "string"));

    return selected ? [{path: `cafeteria_menu/${date}`, value: selected}] : [];
  });
}

export function planAdminBootstrap(
  requestedUids: string[],
  authEmails: Map<string, string>,
  userEmails: Map<string, string>,
  existingAdmins: Set<string>,
): AdminBootstrapEntry[] {
  return [...new Set(requestedUids.map((uid) => uid.trim()).filter(Boolean))].flatMap((uid) => {
    const authEmail = authEmails.get(uid)?.trim().toLowerCase();
    if (!authEmail?.endsWith(STUDENT_DOMAIN)) {
      throw new Error(`${uid} öğrenci hesabı değil.`);
    }

    const userEmail = userEmails.get(uid)?.trim().toLowerCase();
    if (!userEmail || userEmail !== authEmail) {
      throw new Error(`${uid} için users belgesi eksik veya e-posta eşleşmiyor.`);
    }

    return existingAdmins.has(uid) ? [] : [{uid, email: authEmail}];
  });
}

export async function executeAdminBootstrap(
  requestedUids: string[],
  dependencies: AdminBootstrapDependencies,
): Promise<number> {
  const [authEmails, userEmails, existingAdmins] = await Promise.all([
    dependencies.loadAuthEmails(requestedUids),
    dependencies.loadUserEmails(requestedUids),
    dependencies.loadExistingAdmins(),
  ]);
  const entries = planAdminBootstrap(requestedUids, authEmails, userEmails, existingAdmins);
  if (entries.length === 0) return 0;

  await dependencies.applyFirestore(entries);
  try {
    await dependencies.applyRtdb(entries);
  } catch (error) {
    await dependencies.rollbackFirestore(entries);
    throw error;
  }

  return entries.length;
}

export function requireApplyConfirmation(options: ApplyOptions): boolean {
  if (!options.apply) return false;
  if (options.confirmProject !== options.project) {
    throw new Error("Apply için proje doğrulaması eşleşmiyor.");
  }
  return true;
}
