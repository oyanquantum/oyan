// Supabase Edge Function: generate-course-content
//
// API Assignment (see API_ARCHITECTURE.md):
// - GEMINI: Generate lessons and questions with prior-context awareness
// - KazLLM: Correct Kazakh grammar in the output
//
// Flow: Gemini generates (Unit 1 format) → KazLLM corrects Kazakh text → return JSON
//
// Secrets: GEMINI_KEY (or GEMINI_API_KEY), HUGGINGFACE_ACCESS_TOKEN
// Deploy: supabase functions deploy generate-course-content --project-ref porfjjvcnixghoxnbbdt

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const HF_API = "https://api-inference.huggingface.co/models";
// Use HF_KAZLLM_MODEL env for KazLLM (e.g. issai/LLama-3.1-KazLLM-1.0-70B-AWQ4) or a model that handles Kazakh
const DEFAULT_KAZLLM = "mistralai/Mistral-7B-Instruct-v0.2";
const GEMINI_API = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

interface RequestBody {
  unit_summary?: string;
  prior_lessons_summary?: string;
  cloud_index?: number;
}

interface QuizItem {
  question: string;
  options: string[];
  correct_index: number;
  points?: number;
  question_type?: "multiple_choice" | "listening" | "match";
  audio_text?: string;
}

interface GeneratedLessonContent {
  title: string;
  explanation_slides: string[];
  examples: string[];
  quiz: QuizItem[];
}

const UNIT1_FORMAT_SPEC = `
TARGET AUDIENCE: Lessons are for complete beginners who do NOT know Kazakh — they cannot read, write, speak, or listen to it. All explanations MUST be in the user's chosen language (e.g. English if they chose English). Do not assume any prior knowledge of the Kazakh script, sounds, or grammar.

Output ONLY valid JSON with this exact structure (no markdown, no extra text):
{
  "title": "Short lesson title",
  "explanation_slides": ["Paragraph 1.", "Paragraph 2."],
  "examples": ["Example 1", "Example 2"],
  "quiz": [
    {
      "question": "Question text?",
      "options": ["A", "B", "C", "D"],
      "correct_index": 0,
      "points": 1,
      "question_type": "multiple_choice",
      "audio_text": null
    }
  ]
}

Question types:
- multiple_choice: Standard 4-option MCQ. Set audio_text to null.
- listening: User hears Kazakh, then chooses. Put the spoken Kazakh in audio_text.
- match: Match items. question = "Connect by sound" or "Соедини по звуку".

FORMATTING (critical - match Unit 1):
1) HIGHLIGHTS: Wrap key terms in **double asterisks**. Example: "Use **Сәлем** for informal." The app shows **text** in orange. Highlight 2-4 key terms per slide.
2) PARAGRAPHS: Split each explanation_slide into 2-4 SHORT mini-paragraphs using \\n\\n. NEVER one long block. Example: "First idea.\\n\\nSecond point.\\n\\nThird chunk." Like Unit 1: digestible pieces.
3) Keep each slide 2-4 sentences total, split across mini-paragraphs.
`;

function buildGeminiPrompt(unitSummary: string, priorSummary: string): string {
  return `You are a Kazakh language lesson generator for the OYAN app. Generate a lesson that matches the Unit 1 design format exactly.

${priorSummary ? `PRIOR LESSONS (user has already studied):\n${priorSummary}\n\n` : ""}
CURRENT LESSON SUMMARY:
${unitSummary}

${UNIT1_FORMAT_SPEC}

Rules:
- explanation_slides: 1–3 slides, each with 2–4 mini-paragraphs (use \\n\\n). Use ** around key terms for highlighting.
- examples: 0–4 examples. Use Kazakh with translation in parentheses where helpful.
- quiz: 2–8 questions. Mix multiple_choice, listening (when audio helps), and match (e.g. connect by sound for vowels).
- All Kazakh text must be grammatically correct.
- correct_index is 0-based.
- CRITICAL: Every quiz item MUST have a clear "question" field. NEVER use "?" or leave question empty. Examples: "Translate to Kazakh: I", "What does Сен mean?", "Connect by sound: Сау бол".
- Every multiple-choice, translate, and fill-in question MUST have at least 3 answer options (preferably 4). Never use 2 options or placeholders.
- Output ONLY the JSON object, nothing else.`;
}

async function callGemini(prompt: string, apiKey: string): Promise<string> {
  const res = await fetch(`${GEMINI_API}?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: {
        maxOutputTokens: 4096,
        temperature: 0.4,
        responseMimeType: "application/json",
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
  if (!text || !/[а-яәғқңөұүһі]/i.test(text)) return text; // No Kazakh, skip
  const url = `${HF_API}/${model}`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      inputs: `Correct the following Kazakh text for grammar. Return ONLY the corrected text, nothing else.\n\n${text}`,
      parameters: { max_new_tokens: 256, temperature: 0.1, return_full_text: false },
    }),
  });
  if (!res.ok) return text;
  const data = (await res.json()) as { generated_text?: string; error?: string } | Array<{ generated_text?: string }>;
  const raw = Array.isArray(data) ? (data[0]?.generated_text ?? "") : (data?.generated_text ?? "");
  const corrected = (raw || text).trim();
  return corrected.length > 0 ? corrected : text;
}

function extractKazakhSegments(obj: unknown): string[] {
  const out: string[] = [];
  const add = (s: unknown) => {
    if (typeof s === "string" && /[а-яәғқңөұүһі]/i.test(s)) out.push(s);
  };
  const walk = (x: unknown) => {
    if (typeof x === "string") add(x);
    else if (Array.isArray(x)) x.forEach(walk);
    else if (x && typeof x === "object") Object.values(x).forEach(walk);
  };
  walk(obj);
  return [...new Set(out)];
}

function extractJSON(text: string): string | null {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) return null;
  return text.slice(start, end + 1);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders(), status: 204 });
  }

  try {
    const geminiKey = Deno.env.get("GEMINI_KEY") ?? Deno.env.get("GEMINI_API_KEY");
    const hfToken = Deno.env.get("HUGGINGFACE_ACCESS_TOKEN");

    if (!geminiKey) {
      return jsonResponse(
        { error: "GEMINI_KEY or GEMINI_API_KEY not set in Edge Function secrets" },
        500
      );
    }

    const body = (await req.json()) as RequestBody;
    const unitSummary = (body?.unit_summary ?? "").trim();
    const priorSummary = (body?.prior_lessons_summary ?? "").trim();
    const cloudIndex = body?.cloud_index ?? 0;

    if (!unitSummary) {
      return jsonResponse({ error: "unit_summary is required" }, 400);
    }

    const prompt = buildGeminiPrompt(unitSummary, priorSummary);
    const rawJson = await callGemini(prompt, geminiKey);
    const jsonStr = extractJSON(rawJson);
    if (!jsonStr) {
      return jsonResponse(
        { error: "Could not parse Gemini response as JSON", raw: rawJson.slice(0, 300) },
        502
      );
    }

    const content = JSON.parse(jsonStr) as GeneratedLessonContent;

    if (!content.title) content.title = unitSummary.slice(0, 80);
    if (!Array.isArray(content.explanation_slides)) content.explanation_slides = [unitSummary];
    if (!Array.isArray(content.examples)) content.examples = [];
    if (!Array.isArray(content.quiz)) content.quiz = [];

    content.quiz = content.quiz.map((q) => ({
      question: q.question || "?",
      options: Array.isArray(q.options) && q.options.length >= 2 ? q.options : ["Yes", "No"],
      correct_index: typeof q.correct_index === "number" ? Math.max(0, Math.min(q.correct_index, (q.options?.length ?? 2) - 1)) : 0,
      points: q.points ?? 1,
      question_type: q.question_type ?? "multiple_choice",
      audio_text: q.audio_text ?? null,
    }));

    if (hfToken) {
      const kazllmModel = Deno.env.get("HF_KAZLLM_MODEL") ?? DEFAULT_KAZLLM;
      const segments = extractKazakhSegments(content);
      const correctedMap = new Map<string, string>();
      for (const seg of segments.slice(0, 20)) {
        try {
          const corrected = await correctKazakhWithKazLLM(seg, hfToken, kazllmModel);
          if (corrected !== seg) correctedMap.set(seg, corrected);
        } catch {
          // Keep original on KazLLM failure
        }
      }
      const replace = (s: string) => (correctedMap.get(s) ?? s);
      content.title = replace(content.title);
      content.explanation_slides = content.explanation_slides.map(replace);
      content.examples = content.examples.map(replace);
      content.quiz = content.quiz.map((q) => ({
        ...q,
        question: replace(q.question),
        options: q.options.map(replace),
        audio_text: q.audio_text ? replace(q.audio_text) : null,
      }));
    }

    return jsonResponse(content, 200);
  } catch (e) {
    console.error(e);
    return jsonResponse(
      { error: e instanceof Error ? e.message : "Unknown error" },
      500
    );
  }
});

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(),
    },
  });
}

function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}
