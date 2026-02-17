#!/bin/bash
# Calls gemini-generator Edge Function (Gemini) to generate Unit 2 & 3 lesson content.
# Output: scripts/generated/cloud5.json ... cloud11.json
#
# If you hit 429 quota: wait for reset (or try tomorrow) or switch gemini-generator
# to gemini-1.5-flash in the Edge Function code. Then run:
#   python3 scripts/apply_generated_to_swift.py
# to update CourseStructure.swift.

set -e
API_URL="https://porfjjvcnixghoxnbbdt.supabase.co/functions/v1/gemini-generator"
AUTH="Bearer sb_publishable_W3c5_zb0g3uFl1IejkBKKQ_f3wJMOhf"
OUT_DIR="$(cd "$(dirname "$0")" && pwd)/generated"
mkdir -p "$OUT_DIR"

UNIT1_REF='Output ONLY valid JSON. Use this exact structure:
{
  "title": "Short title",
  "explanation_slides": ["slide1", "slide2", ...],
  "examples": ["Kazakh — English", ...],
  "quiz": [...]
}
TARGET AUDIENCE: Lessons are for complete beginners who do NOT know Kazakh — they cannot read, write, speak, or listen to it. All explanations MUST be in English. Do not assume any prior knowledge of the Kazakh script, sounds, or grammar.

FORMATTING RULES (critical - match Unit 1 style):
1) HIGHLIGHTS: Wrap important terms and key phrases in **double asterisks**. Example: "Use **Сәлем** for informal greeting." The app will show **text** in orange. Highlight 2-4 key terms per slide (Kazakh words, main concepts).
2) PARAGRAPHS: Split each explanation_slides item into 2-4 SHORT mini-paragraphs. Use \\n\\n between them. NEVER write one long block of sentences. Example: "First sentence or two.\\n\\nSecond mini-paragraph here.\\n\\nThird short chunk." Like Unit 1: each slide feels broken into digestible pieces.
3) Keep each slide 2-4 sentences total, split across mini-paragraphs.
correct_index 0-based. For listening: question_type "listening", audio_text with Kazakh. For connect-by-sound: question "Connect by sound: [phrase]" (include the Kazakh phrase), points 2.
CRITICAL: Every quiz item MUST have a clear "question" field. NEVER use "?" or leave question empty.
MULTIPLE CHOICE: Every multiple-choice, translate, and fill-in question MUST have at least 3 answer options (preferably 4). Never use 2 options or placeholder "—".
FILL-IN: Put blank AFTER the word (e.g. "Мен дәрігер____"). For "X ... (Y)" use "X Y____" with endings as options.
NO DUPLICATES: Never use both "Сәлем" and "Сәлем!" or мұғаліммін twice. All options must be distinct.
MATCH: Include pairs {kazakh, english}. Never use Yes/No for matching questions.
connect_by_sound: ONLY for Unit 1 (clouds 1-4) with options like ["Жү","Мы","сық","рек"]. For Unit 2 & 3, use multiple_choice instead (e.g. "What does X mean?").'

call_gemini() {
  local prompt="$1"
  local outfile="$2"
  local payload
  payload=$(jq -n --arg p "$prompt" '{prompt: $p, maxOutputTokens: 4096, temperature: 0.4}')
  local resp
  local retries=5
  while [ $retries -gt 0 ]; do
    resp=$(curl -s -X POST "$API_URL" -H "Content-Type: application/json" -H "Authorization: $AUTH" -d "$payload")
    if echo "$resp" | jq -e '.error.code == 429' >/dev/null 2>&1; then
      echo "  Quota exceeded. Waiting 60s before retry..." >&2
      sleep 60
      retries=$((retries - 1))
    else
      break
    fi
  done
  if echo "$resp" | jq -e '.error' >/dev/null 2>&1; then
    echo "ERROR: $resp" >&2
    return 1
  fi
  local text
  text=$(echo "$resp" | jq -r '.candidates[0].content.parts[0].text // .candidates[0].output // empty')
  if [ -z "$text" ]; then
    text=$(echo "$resp" | jq -r '.text // empty')
  fi
  if [ -z "$text" ]; then
    echo "No text in response" >&2
    echo "$resp" >&2
    return 1
  fi
  echo "$text" | python3 -c "
import sys, re, json
t = sys.stdin.read()
t = re.sub(r'^\s*\`\`\`(?:json)?\s*', '', t)
t = re.sub(r'\s*\`\`\`\s*$', '', t)
start = t.find('{')
end = t.rfind('}') + 1
if start >= 0 and end > start:
    j = json.loads(t[start:end])
    print(json.dumps(j, indent=2, ensure_ascii=False))
" > "$outfile" 2>/dev/null || echo "$text" > "$outfile"
}

# Cloud 5
echo "Generating cloud 5..."
call_gemini "You are a Kazakh lesson generator for OYAN. $UNIT1_REF

Prior: Unit 1 (synharmonism, sounds, first law, бас доп қыз кет көз сәт).

Generate lesson for: Unit 2, Lesson 1: Greeting and farewell (Сәлем, сәлеметсіз бе. Сау бол, сау болыңыз).

Include 1 listening intro question for Сәлем. 8-10 quiz items total. Output ONLY the JSON object." "$OUT_DIR/cloud5.json"
sleep 3

# Cloud 6
echo "Generating cloud 6..."
call_gemini "You are a Kazakh lesson generator for OYAN. $UNIT1_REF

Prior: Unit 1 + Unit 2 Lesson 1 (greetings, farewells).

Generate lesson for: Unit 2, Lesson 2: First vocabulary (мұғалім, сыныптасы). Usage: teacher → Сәлеметсіз бе, classmate → Сәлем.

Include 1 listening intro for мұғалім. 8-10 quiz items. Output ONLY the JSON object." "$OUT_DIR/cloud6.json"
sleep 3

# Cloud 7
echo "Generating cloud 7..."
call_gemini "You are a Kazakh lesson generator for OYAN. $UNIT1_REF

Prior: Unit 1 + Unit 2 Lessons 1-2.

Generate Unit 2 Test: Greeting, farewell, vocabulary (мұғалім, сыныптасы), when Сәлем vs Сәлеметсіз бе.

10-12 quiz items. Output ONLY the JSON object." "$OUT_DIR/cloud7.json"
sleep 3

# Cloud 8
echo "Generating cloud 8..."
call_gemini "You are a Kazakh lesson generator for OYAN. $UNIT1_REF

Prior: Unit 1 + Unit 2.

Generate lesson for: Unit 3, Lesson 1: Me and you (мен, сен) + vocabulary (оқушы). Personal endings coming next.

Include 1 listening intro for оқушы. 8-10 quiz items. Output ONLY the JSON object." "$OUT_DIR/cloud8.json"
sleep 3

# Cloud 9
echo "Generating cloud 9..."
call_gemini "You are a Kazakh lesson generator for OYAN. $UNIT1_REF

Prior: Unit 1 + Unit 2 + Unit 3 Lesson 1.

Generate lesson for: Unit 3, Lesson 2: Personal endings (мен: -мың/-мін; сен: -сың/-сің). Examples: Мен мұғаліммін, Сен оқушысың.

Include 1 listening intro for Мен мұғаліммін. 8-10 quiz items. Output ONLY the JSON object." "$OUT_DIR/cloud9.json"
sleep 3

# Cloud 10
echo "Generating cloud 10..."
call_gemini "You are a Kazakh lesson generator for OYAN. $UNIT1_REF

Prior: Unit 1 + Unit 2 + Unit 3 Lessons 1-2.

Generate lesson for: Unit 3, Lesson 3: Usage (Мен мұғаліммін, сен оқушысың). Put it together.

Include 1 listening intro for Сен оқушысың. 8-10 quiz items. Output ONLY the JSON object." "$OUT_DIR/cloud10.json"
sleep 3

# Cloud 11
echo "Generating cloud 11..."
call_gemini "You are a Kazakh lesson generator for OYAN. $UNIT1_REF

Prior: All units.

Generate Unit 3 Test: мен/сен, оқушы, personal endings, sentences Мен мұғаліммін, Сен оқушысың.

10-12 quiz items. Output ONLY the JSON object." "$OUT_DIR/cloud11.json"

echo "Done. Generated files in $OUT_DIR/"
echo "Run: python3 scripts/apply_generated_to_swift.py  # to update CourseStructure.swift"
