// Supabase Edge Function: chat-assistant
//
// Kazakh-only chat tutor: Gemini + KazLLM.
// Responds ONLY in Kazakh. Adapts to user's level. Off-topic → immediately back to Kazakh.
// Only exception: grammar/Kazakh help may use user's language for explanations.
//
// Secrets: GEMINI_KEY (or GEMINI_API_KEY), HUGGINGFACE_ACCESS_TOKEN (optional, for KazLLM)
// Deploy: supabase functions deploy chat-assistant --project-ref porfjjvcnixghoxnbbdt

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_API =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";
const HF_API = "https://api-inference.huggingface.co/models";
const DEFAULT_KAZLLM = "mistralai/Mistral-7B-Instruct-v0.2";

interface ChatMessage {
  role: "user" | "assistant";
  text: string;
}

interface RequestBody {
  messages: ChatMessage[];
  prior_lessons_summary?: string;
  user_language?: string; // "en" | "ru" — for grammar-help exceptions only
}

function buildSystemPrompt(priorSummary?: string, userLang?: string): string {
  const explainLang = userLang === "ru" ? "Russian" : "English";
  const levelBlock = priorSummary
    ? `The user has completed these lessons:\n${priorSummary}\n\nUse vocabulary and grammar appropriate for their level.`
    : "Assume the user is a beginner. Use simple Kazakh: short sentences, basic vocabulary.";

  return `You are a Kazakh language tutor in the OYAN app. STRICT RULES:

1. NORMAL CHAT: When replying in Kazakh (conversation, practice, small talk), use MAX 50 WORDS per message. Be concise.
2. ADAPT TO USER LEVEL. ${levelBlock}
3. OFF-TOPIC: If the user goes off topic (weather, sports, etc.), reply briefly in Kazakh (max 50 words) and steer back to learning.
4. EXPLANATION: When the user asks for help understanding Kazakh (e.g. "explain synharmonism", "what does X mean?", "how does grammar work?"), give your FULL explanation in ${explainLang}. If the user asks their question in Russian, respond entirely in Russian. If they ask in English, respond in English. Keep explanations clear and concise. Include Kazakh examples where helpful. After explaining, you may add a short Kazakh phrase to practice.
5. Be encouraging and patient.`;
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };
}

async function callGemini(
  contents: { role: string; parts: { text: string }[] }[],
  systemPrompt: string,
  apiKey: string
): Promise<string> {
  const res = await fetch(`${GEMINI_API}?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: systemPrompt }] },
      contents,
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 1024,
      },
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Gemini API error ${res.status}: ${err.slice(0, 300)}`);
  }
  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new Error("Gemini returned empty or unexpected response");
  }
  return text.trim();
}

async function correctKazakhWithKazLLM(
  text: string,
  token: string,
  model: string
): Promise<string> {
  if (!text || !/[а-яәғқңөұүһі]/i.test(text)) return text;
  const url = `${HF_API}/${model}`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      inputs: `Correct the following Kazakh text for grammar. Return ONLY the corrected text, nothing else.\n\n${text}`,
      parameters: {
        max_new_tokens: 512,
        temperature: 0.1,
        return_full_text: false,
      },
    }),
  });
  if (!res.ok) return text;
  const data = (await res.json()) as
    | { generated_text?: string }
    | Array<{ generated_text?: string }>;
  const raw = Array.isArray(data) ? (data[0]?.generated_text ?? "") : (data?.generated_text ?? "");
  const corrected = (raw || text).trim();
  return corrected.length > 0 ? corrected : text;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders(), status: 204 });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Use POST" }),
      { status: 405, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  }

  const geminiKey = Deno.env.get("GEMINI_KEY") ?? Deno.env.get("GEMINI_API_KEY");
  if (!geminiKey) {
    return new Response(
      JSON.stringify({ error: "GEMINI_KEY not set" }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  }

  let body: RequestBody;
  try {
    body = (await req.json()) as RequestBody;
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON" }),
      { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  }

  const messages = body?.messages ?? [];
  if (!Array.isArray(messages) || messages.length === 0) {
    return new Response(
      JSON.stringify({ error: "messages array is required" }),
      { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  }

  const priorSummary = (body?.prior_lessons_summary ?? "").trim() || undefined;
  const userLang = body?.user_language === "ru" ? "ru" : body?.user_language === "en" ? "en" : "en";
  const systemPrompt = buildSystemPrompt(priorSummary, userLang);

  const contents = messages.map((m) => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.text }],
  }));

  try {
    let response = await callGemini(contents, systemPrompt, geminiKey);

    const hfToken = Deno.env.get("HUGGINGFACE_ACCESS_TOKEN");
    if (hfToken && /[а-яәғқңөұүһі]/i.test(response)) {
      const model = Deno.env.get("HF_KAZLLM_MODEL") ?? DEFAULT_KAZLLM;
      try {
        response = await correctKazakhWithKazLLM(response, hfToken, model);
      } catch {
        // Keep original on KazLLM failure
      }
    }

    return new Response(
      JSON.stringify({ text: response }),
      { status: 200, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  } catch (e) {
    console.error("chat-assistant error:", e);
    return new Response(
      JSON.stringify({ error: e instanceof Error ? e.message : "Unknown error" }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders() } }
    );
  }
});
