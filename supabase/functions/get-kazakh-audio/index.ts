// Supabase Edge Function: get-kazakh-audio
//
// Kazakh text-to-speech via Microsoft Azure Speech Services.
// Expects: AZURE_REGION (e.g. eastus, westeurope), AZURE_SPEECH_KEY
// Deploy: supabase functions deploy get-kazakh-audio --project-ref porfjjvcnixghoxnbbdt
//
// Set secrets:
//   supabase secrets set AZURE_REGION=eastus AZURE_SPEECH_KEY=your_key

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const KAZAKH_VOICE = "kk-KZ-AigulNeural";
const OUTPUT_FORMAT = "audio-16khz-128kbitrate-mono-mp3";

function escapeSsml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders(), status: 204 });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Use POST with { text: string }" }),
      { status: 405, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  }

  const region = Deno.env.get("AZURE_REGION");
  const key = Deno.env.get("AZURE_SPEECH_KEY");

  if (!region || !key) {
    return new Response(
      JSON.stringify({
        error: "Azure Speech not configured. Set AZURE_REGION and AZURE_SPEECH_KEY secrets.",
      }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  }

  let body: { text?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON. Send { text: string }" }),
      { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  }

  const text = typeof body?.text === "string" ? body.text.trim() : "";
  if (!text) {
    return new Response(
      JSON.stringify({ error: "Missing or empty text" }),
      { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  }

  const ssml = `<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='kk-KZ'><voice name='${KAZAKH_VOICE}'>${escapeSsml(text)}</voice></speak>`;

  const ttsUrl = `https://${region}.tts.speech.microsoft.com/cognitiveservices/v1`;

  const ttsRes = await fetch(ttsUrl, {
    method: "POST",
    headers: {
      "Ocp-Apim-Subscription-Key": key,
      "Content-Type": "application/ssml+xml",
      "X-Microsoft-OutputFormat": OUTPUT_FORMAT,
      "User-Agent": "OYAN-App/1.0",
    },
    body: ssml,
  });

  if (!ttsRes.ok) {
    const errText = await ttsRes.text();
    console.error("Azure TTS error:", ttsRes.status, errText);
    return new Response(
      JSON.stringify({
        error: `Azure TTS failed: ${ttsRes.status}`,
        detail: errText.slice(0, 200),
      }),
      {
        status: 502,
        headers: { "Content-Type": "application/json", ...corsHeaders() },
      }
    );
  }

  const audioBytes = await ttsRes.arrayBuffer();
  return new Response(audioBytes, {
    status: 200,
    headers: {
      "Content-Type": "audio/mpeg",
      "Cache-Control": "public, max-age=86400",
      ...corsHeaders(),
    },
  });
});
