#!/bin/bash
# Calls the generate-course-content Edge Function (Gemini + KazLLM) for Unit 2 & 3 lessons.
# Outputs JSON to scripts/generated/ for each cloud. Run from project root.

set -e
API_URL="https://porfjjvcnixghoxnbbdt.supabase.co/functions/v1/generate-course-content"
AUTH="Bearer sb_publishable_W3c5_zb0g3uFl1IejkBKKQ_f3wJMOhf"
OUT_DIR="$(dirname "$0")/generated"
mkdir -p "$OUT_DIR"

# Unit 1 summaries (for prior context)
U1_L1="Unit 1, Lesson 1: Tell about the Kazakh language. Synharmonism is the basis. Comparing language to music."
U1_L2="Unit 1, Lesson 2: Sounds."
U1_L3="Unit 1, Lesson 3: First law of synharmonism (a soft vowel creates a soft syllable, a hard vowel creates a hard syllable). Pronouncing бас, доп, қыз, кет, көз, сәт."
U1_TEST="Unit 1 Test: Kazakh language introduction, synharmonism basis, sounds, first law of synharmonism, pronouncing бас, доп, қыз, кет, көз, сәт."

# Cloud 5 - Unit 2 Lesson 1
PRIOR_5="Lesson 1: $U1_L1
Lesson 2: $U1_L2
Lesson 3: $U1_L3
Lesson 4: $U1_TEST"
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH" \
  -d "{\"unit_summary\": \"Unit 2, Lesson 1: Greeting and farewell (Сәлем, сәлеметсіз бе. Сау бол, сау болыңыз).\", \"prior_lessons_summary\": $(echo "$PRIOR_5" | jq -Rs .), \"cloud_index\": 5}" \
  > "$OUT_DIR/cloud5.json"
echo "Cloud 5 done"

# Cloud 6
PRIOR_6="$PRIOR_5
Lesson 5: Unit 2, Lesson 1: Greeting and farewell (Сәлем, сәлеметсіз бе. Сау бол, сау болыңыз)."
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH" \
  -d "{\"unit_summary\": \"Unit 2, Lesson 2: First vocabulary (purpose related, e.g. education: мұғалім, сыныптасы). First usage of greeting and farewell (мұғалім - сәлеметсіз бе, сыныптасы - сәлем).\", \"prior_lessons_summary\": $(echo "$PRIOR_6" | jq -Rs .), \"cloud_index\": 6}" \
  > "$OUT_DIR/cloud6.json"
echo "Cloud 6 done"

# Cloud 7 - Unit 2 Test
PRIOR_7="$PRIOR_6
Lesson 6: Unit 2, Lesson 2: First vocabulary (мұғалім, сыныптасы)."
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH" \
  -d "{\"unit_summary\": \"Unit 2 Test: Greeting and farewell, first vocabulary (мұғалім, сыныптасы), usage of greetings.\", \"prior_lessons_summary\": $(echo "$PRIOR_7" | jq -Rs .), \"cloud_index\": 7}" \
  > "$OUT_DIR/cloud7.json"
echo "Cloud 7 done"

# Cloud 8
PRIOR_8="$PRIOR_7
Lesson 7: Unit 2 Test"
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH" \
  -d "{\"unit_summary\": \"Unit 3, Lesson 1: Me and you (мен, сен) + Second vocabulary (e.g. оқушы).\", \"prior_lessons_summary\": $(echo "$PRIOR_8" | jq -Rs .), \"cloud_index\": 8}" \
  > "$OUT_DIR/cloud8.json"
echo "Cloud 8 done"

# Cloud 9
PRIOR_9="$PRIOR_8
Lesson 8: Unit 3, Lesson 1: Me and you (мен, сен), оқушы"
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH" \
  -d "{\"unit_summary\": \"Unit 3, Lesson 2: Personal endings (мен: мың, мін, бын, бін, пын, пін. Сен: сың, сің). Personal endings are added to names, professions, verbs, nouns, numerals, adjectives.\", \"prior_lessons_summary\": $(echo "$PRIOR_9" | jq -Rs .), \"cloud_index\": 9}" \
  > "$OUT_DIR/cloud9.json"
echo "Cloud 9 done"

# Cloud 10
PRIOR_10="$PRIOR_9
Lesson 9: Unit 3, Lesson 2: Personal endings"
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH" \
  -d "{\"unit_summary\": \"Unit 3, Lesson 3: Usage (Мен мұғаліммін, сен оқушысың).\", \"prior_lessons_summary\": $(echo "$PRIOR_10" | jq -Rs .), \"cloud_index\": 10}" \
  > "$OUT_DIR/cloud10.json"
echo "Cloud 10 done"

# Cloud 11 - Unit 3 Test
PRIOR_11="$PRIOR_10
Lesson 10: Unit 3, Lesson 3: Usage"
curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: $AUTH" \
  -d "{\"unit_summary\": \"Unit 3 Test: Me and you (мен, сен), vocabulary (оқушы), personal endings, usage (Мен мұғаліммін, сен оқушысың).\", \"prior_lessons_summary\": $(echo "$PRIOR_11" | jq -Rs .), \"cloud_index\": 11}" \
  > "$OUT_DIR/cloud11.json"
echo "Cloud 11 done"

echo "All done. Check $OUT_DIR/"
