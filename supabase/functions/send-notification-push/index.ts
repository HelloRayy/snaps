import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Embedded default service account for robust server-side execution fallback
const DEFAULT_FIREBASE_SERVICE_ACCOUNT = {
  type: "service_account",
  project_id: "snaps-6767",
  private_key_id: "518bd678d3699f5b96ae51aad304dbd7099d8baa",
  private_key: "-----BEGIN PRIVATE KEY-----\nMIIEugIBADANBgkqhkiG9w0BAQEFAASCBKQwggSgAgEAAoIBAQC1M6qOg/k0R5+Y\nCAY+JiMYcAFwL4t5+9yaIdXDRZ0//dXNS0kR2FDuARYZ8ti++An01PWqOc40orYD\nebWSpPUjjLn/exwMTbC44tslLw86hzTBlPmzrh44Us0zIbziL0q8hQy2XKdek66o\nuOgZtFpydO9jF/U7hsGNopTvEKzapc0rKjbFDDz45zg2k3SYQX+3vrO86bcYFQZw\nqWvRHLrluePX0WCeVKFEQAZe5BkBpd8vhY2K43zGOpPBuFDf6ihCjT2duZLSD6BU\n3ZNndflb3lAn7ZbxMUX2g88m4eWGiQPnmIdzqpgOyvNuLoUN3x8TWRo4s5xncnvt\nZCv/6k6ZAgMBAAECgf8cp1N6UUjSdwEBIGhKBxAhGt5D7Pel6WBGyHeAiYYrJg9/\n9PV5DzdPRwpp9Jz/cULYpsIf/9ZgYP8VBHe/tChrBGzAmalspBNJcnGZmNLmhU0y\nYbNRn6lVbHlrBaYvnkG3zfbm8ckFsDlgopOjoYF1ISQVMJSt0IFmX7htcN7AD7zz\n0oEO5WIjPeSGRG/G8vjMzaVEwJFoREIYnWb/VlH+qsoe/4v2ZCvBETcOS7rcjwQH\nM4QYmVlDD0ciD9lotsntfY2QZVxuE5dXz7K4XrXBvKLAZyTbNVrg1Mp3LibTGG2g\nNpCELnOu0B/1o8ziYKtHsMyziy0DosoAN/qnQxECgYEA2wgrMBgnboAnCE8gIFRB\n9AEvwFrtfYPvtw3K07OC1PjTzaFRh/BXRiWbR8h2+PFT9oeLaL2DwntWcF6g4LCe\nE9jI0b8PnwbJO875qdzcIZFJMrj2+eNxYGcoZPh8PD7yLvDC5fNZ890pEaPq/Ly9\na7p+dyghixPtvO5v609I0tECgYEA08jzyE5xUMynJuFbaMMyQU0nSo7I+XH1g0u7\ne/cMFqReImSPRaywEAImAwgvd9PGNOVkIHAMZl2J4rRk50ctBEWsJt34dPOINO0K\n1kIC9yxfXWwCOkytvCIcWYLvI8Whp6Mqs5YFonRjv1GRRnE0yUYXrVi0RSGqzbb4\n5Xc1YUkCgYA3yjPd8zkP/1px1l2zfmKyOR8lmsOFRfboJH42QDIh9yNT7DQtMP25\n41hTB2+uZyHg2JOc4TDPd8UDqEbIFJSfL4evTUA4XG0ja8vSBWyYrD39ynk2G0XE\nrWHvng9e9RWQ+UhbdAnEgN+2G49+QsDo0L7nsPQiTbgveHhPcol1EQKBgHRgj725\nhUE+RHf0DFQEN2B08ithTQTt31jXy92yAt2KUwQZODW0UEdrttGhtNvm7prwltXQ\nXK//pJ6EPJJupUkctB3jif1SOb3DqFnWimSi6ICgspSwwCOKpwN1FM4Wct94pSVs\nQgpkZM+kFe2clcIolyg1f1IhzwceDaWinR2pAoGADXTlKuMKXU9yrKISpw8EWoFT\npyizQMdmvKlK5vYP2Oc583UHFIa+WRa7lqy1+wJTLAKwqKpo96IdkFmJre9oDgLu\nTiRi6ZppHBEjBHeYylncKE2Fk9eyqOMosD3kEjdANebZkm+vHr/owEOvxzaMQYQj\neIy/mWXR2uni7xnSjww=\n-----END PRIVATE KEY-----\n",
  client_email: "firebase-adminsdk-fbsvc@snaps-6767.iam.gserviceaccount.com",
  client_id: "116201590481910776853",
  auth_uri: "https://accounts.google.com/o/oauth2/auth",
  token_uri: "https://oauth2.googleapis.com/token",
  auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
  client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40snaps-6767.iam.gserviceaccount.com",
  universe_domain: "googleapis.com",
};

let cachedAccessToken: string | null = null;
let tokenExpiresAt = 0;

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64Lines = pem.replace(/-----[^\n]+-----/g, "").replace(/\s+/g, "");
  const binaryString = atob(b64Lines);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

function toBase64Url(obj: unknown): string {
  const str = JSON.stringify(obj);
  const bytes = new TextEncoder().encode(str);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

async function getGoogleFcmAccessToken(serviceAccount: Record<string, any>): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && now < tokenExpiresAt - 60) {
    return cachedAccessToken;
  }

  const binaryDer = pemToArrayBuffer(serviceAccount.private_key);
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const signingInput = `${toBase64Url(header)}.${toBase64Url(claimSet)}`;
  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );

  const sigBytes = new Uint8Array(signatureBuffer);
  let sigBinary = "";
  for (let i = 0; i < sigBytes.length; i++) {
    sigBinary += String.fromCharCode(sigBytes[i]);
  }
  const signature = btoa(sigBinary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const jwt = `${signingInput}.${signature}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenRes.ok) {
    throw new Error(`Failed to fetch Google OAuth token: ${await tokenRes.text()}`);
  }

  const tokenJson = await tokenRes.json();
  cachedAccessToken = tokenJson.access_token;
  tokenExpiresAt = now + (tokenJson.expires_in || 3600);
  return cachedAccessToken!;
}

Deno.serve(async (req: Request) => {
  try {
    const body = await req.json();
    const record = body.record ?? body;

    if (!record || !record.user_id) {
      return new Response(JSON.stringify({ error: "Missing notification record" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const recipientId: string = record.user_id;
    const title: string = record.title || "Snaps";
    const message: string = record.message || "Ada aktivitas baru";
    const actionType: string = record.action_type || "";
    const actionUrl: string = record.action_url || "";
    const postId: string = record.post_id ? String(record.post_id) : actionUrl;
    const notifType: string = record.type || "comment";

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: tokensData, error: tokenError } = await supabase
      .from("user_fcm_tokens")
      .select("fcm_token")
      .eq("user_id", recipientId);

    if (tokenError || !tokensData || tokensData.length === 0) {
      return new Response(JSON.stringify({ message: "No FCM tokens registered for recipient" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const rawServiceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    let serviceAccount: any;
    if (rawServiceAccount && rawServiceAccount.trim().startsWith("{")) {
      try {
        serviceAccount = JSON.parse(rawServiceAccount);
      } catch (_) {
        serviceAccount = DEFAULT_FIREBASE_SERVICE_ACCOUNT;
      }
    } else {
      serviceAccount = DEFAULT_FIREBASE_SERVICE_ACCOUNT;
    }

    const accessToken = await getGoogleFcmAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id || "snaps-6767";
    const endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const deadTokens: string[] = [];
    let sentCount = 0;

    await Promise.all(
      tokensData.map(async ({ fcm_token }) => {
        try {
          const fcmMessage = {
            message: {
              token: fcm_token,
              notification: {
                title,
                body: message,
              },
              data: {
                type: notifType,
                notification_id: String(record.id || ""),
                action_type: actionType,
                action_url: actionUrl,
                post_id: postId,
                sound: "snaps_default",
                channel_id: "snaps_general_v1",
              },
              android: {
                priority: "high",
                notification: {
                  channel_id: "snaps_general_v1",
                  sound: "snaps_default",
                  click_action: "FLUTTER_NOTIFICATION_CLICK",
                  tag: postId ? `post_${postId}` : `notif_${record.id || Date.now()}`,
                },
              },
            },
          };

          const res = await fetch(endpoint, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify(fcmMessage),
          });

          if (res.ok) {
            sentCount++;
          } else {
            const errText = await res.text();
            if (errText.includes("UNREGISTERED") || errText.includes("NOT_FOUND")) {
              deadTokens.push(fcm_token);
            }
          }
        } catch (err) {
          console.error("[send-notification-push] Error sending:", err);
        }
      }),
    );

    if (deadTokens.length > 0) {
      await supabase.from("user_fcm_tokens").delete().in("fcm_token", deadTokens);
    }

    return new Response(JSON.stringify({ success: true, sentCount }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err?.message || "Internal error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
