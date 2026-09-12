import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { compactVerify, decodeProtectedHeader, importX509 } from "npm:jose@5.10.0";

Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response("Method Not Allowed", { status: 405 });
  const signedPayload = (await request.json()).signedPayload;
  if (typeof signedPayload !== "string") return new Response("Invalid payload", { status: 400 });
  const verified = await verifyAppleSignedPayload(signedPayload);
  if (!verified) return new Response("Invalid signature", { status: 401 });
  const payload = decodePayload(signedPayload);
  const transaction = payload?.data?.signedTransactionInfo ? decodePayload(payload.data.signedTransactionInfo) : null;
  const userId = transaction?.appAccountToken;
  if (!userId) return new Response("Missing appAccountToken", { status: 400 });
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const active = !["EXPIRED", "REVOKED", "REFUND"].includes(payload.notificationType);
  const { error } = await admin.from("entitlements").upsert({ user_id: userId, product_id: transaction.productId, original_transaction_id: transaction.originalTransactionId, tier: active ? "premium" : "free", expires_at: transaction.expiresDate ? new Date(Number(transaction.expiresDate)).toISOString() : null, environment: transaction.environment, updated_at: new Date().toISOString() });
  return error ? new Response("Database error", { status: 500 }) : new Response("ok");
});

async function verifyAppleSignedPayload(jws: string) {
  try {
    const header = decodeProtectedHeader(jws);
    const certificates = (header.x5c as string[] | undefined) ?? [];
    const rootCertificate = Deno.env.get("APPLE_ROOT_CERTIFICATE_PEM");
    if (header.alg !== "ES256" || certificates.length < 2 || !rootCertificate) return false;
    const leafPem = toPem(certificates[0]);
    const presentedRootPem = toPem(certificates[certificates.length - 1]);
    if (normalizePem(presentedRootPem) !== normalizePem(rootCertificate)) return false;
    const key = await importX509(leafPem, "ES256");
    await compactVerify(jws, key);
    return true;
  } catch {
    return false;
  }
}
function toPem(value: string) { return `-----BEGIN CERTIFICATE-----\n${value.match(/.{1,64}/g)?.join("\n")}\n-----END CERTIFICATE-----`; }
function normalizePem(value: string) { return value.replace(/\s/g, ""); }
function decodePayload(jws: string) { try { return JSON.parse(atob(jws.split(".")[1].replace(/-/g, "+").replace(/_/g, "/"))); } catch { return null; } }
