// supabase/functions/gemini-proxy/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Use POST", { status: 405 });
  }

  const key = Deno.env.get("GEMINI_KEY") ?? Deno.env.get("GEMINI_API_KEY");
  if (!key) return new Response("Missing GEMINI_KEY", { status: 500 });

  const body = await req.json().catch(() => null);
  if (!body?.prompt) {
    return new Response(JSON.stringify({ error: "Missing prompt" }), {
      status: 400,
      headers: { "content-type": "application/json" },
    });
  }

  const geminiPayload = {
    contents: [
      {
        role: "user",
        parts: [{ text: String(body.prompt) }],
      },
    ],
    generationConfig: {
      temperature: body.temperature ?? 0.6,
      maxOutputTokens: body.maxOutputTokens ?? 512,
    },
  };

  const resp = await fetch(GEMINI_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-goog-api-key": key,
    },
    body: JSON.stringify(geminiPayload),
  });

  const text = await resp.text();
  return new Response(text, {
    status: resp.status,
    headers: { "content-type": "application/json" },
  });
});
