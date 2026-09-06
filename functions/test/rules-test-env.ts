import {readFileSync} from "node:fs";
import {resolve} from "node:path";
import {
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";

const repositoryRoot = resolve(__dirname, "../../..");

export async function createRulesTestEnv(
  suiteName: string,
  services: {firestore?: boolean; database?: boolean} = {
    firestore: true,
    database: true,
  },
): Promise<RulesTestEnvironment> {
  return initializeTestEnvironment({
    projectId: `demo-akdeniz-cep-${suiteName}`,
    ...(services.firestore ? {
      firestore: {
        host: "127.0.0.1",
        port: 8080,
        rules: readFileSync(
          resolve(repositoryRoot, "firestore.rules"),
          "utf8",
        ),
      },
    } : {}),
    ...(services.database ? {
      database: {
        host: "127.0.0.1",
        port: 9000,
        rules: readFileSync(
          resolve(repositoryRoot, "database.rules.json"),
          "utf8",
        ),
      },
    } : {}),
  });
}
