import {applicationDefault, cert, getApps, initializeApp} from "firebase-admin/app";
import type {App} from "firebase-admin/app";
import {readFileSync} from "node:fs";

export type CliArguments = Record<string, string | boolean>;

export function parseArguments(args: string[]): CliArguments {
  const parsed: CliArguments = {};
  for (let index = 0; index < args.length; index += 1) {
    const token = args[index];
    if (!token.startsWith("--")) throw new Error(`Beklenmeyen argüman: ${token}`);
    const key = token.slice(2);
    const next = args[index + 1];
    if (!next || next.startsWith("--")) {
      parsed[key] = true;
    } else {
      parsed[key] = next;
      index += 1;
    }
  }
  return parsed;
}

export function requiredString(args: CliArguments, key: string): string {
  const value = args[key];
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`--${key} zorunludur.`);
  }
  return value.trim();
}

export function firebaseAdminApp(projectId: string): App {
  const existing = getApps().find((app) => app.name === projectId);
  if (existing) return existing;

  const emulatorMode = Boolean(
    process.env.FIRESTORE_EMULATOR_HOST ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST ||
    process.env.FIREBASE_DATABASE_EMULATOR_HOST,
  );
  const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const credential = emulatorMode ? applicationDefault() : serviceAccountPath ?
    cert(JSON.parse(readFileSync(serviceAccountPath, "utf8"))) :
    applicationDefault();

  return initializeApp({
    projectId,
    databaseURL: `https://${projectId}-default-rtdb.europe-west1.firebasedatabase.app`,
    credential,
  }, projectId);
}

export function printJson(value: unknown): void {
  process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
}
