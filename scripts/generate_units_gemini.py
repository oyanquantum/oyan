#!/usr/bin/env python3
"""
Generate Unit 2 & 3 lesson content via Gemini API.
Get API key from https://aistudio.google.com/app/apikey

Run:
  GEMINI_API_KEY=yourkey python3 scripts/generate_units_gemini.py
  # or
  python3 scripts/generate_units_gemini.py --key=yourkey

Output: scripts/generated/cloud5.json ... cloud11.json
Then run: python3 scripts/apply_generated_to_swift.py
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.error

def get_api_key():
    key = os.environ.get("GEMINI_API_KEY")
    if key:
        return key
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", help="Gemini API key")
    args, _ = parser.parse_known_args()
    return args.key

API_KEY = get_api_key()
if not API_KEY:
    print("ERROR: Set GEMINI_API_KEY or pass --key=YOUR_KEY. Get key from https://aistudio.google.com/app/apikey")
    sys.exit(1)

API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={API_KEY}"

UNIT1_REF = '''
Unit 1 format (FOLLOW EXACTLY):
- explanation_slides: 2-3 short paragraphs
- examples: 0-4 items, format "Kazakh — English"
- quiz: mix of multiple_choice, listening (audio_text for Kazakh to play), match (Connect by sound with syllables)
- Use points: 0 for intro/listening "Do you hear?", 1 for standard MC, 2 for connect-by-sound
- For listening: question like "Сәлем  -  [Sälem]", options: ["Do you hear? ..."], correct_index: 0, points: 0, question_type: "listening", audio_text: "Сәлем"
- Every multiple-choice, translate, and fill-in question MUST have at least 3 options (preferably 4). Never use 2 options.
'''

SUMMARIES = {
    5: ("Unit 2, Lesson 1: Greeting and farewell (Сәлем, сәлеметсіз бе. Сау бол, сау болыңыз).",
        "Unit 1: synharmonism, sounds, first law. бас, доп, қыз, кет, көз, сәт."),
    6: ("Unit 2, Lesson 2: First vocabulary (мұғалім, сыныптасы). Usage: teacher → Сәлеметсіз бе, classmate → Сәлем.",
        "Unit 1 + Unit 2 Lesson 1 (greetings, farewells)."),
    7: ("Unit 2 Test: Greeting, farewell, vocabulary (мұғалім, сыныптасы), when Сәлем vs Сәлеметсіз бе.",
        "Unit 1 + Unit 2 Lessons 1-2."),
    8: ("Unit 3, Lesson 1: Me and you (мен, сен) + vocabulary (оқушы). Personal endings coming next.",
        "Unit 1 + Unit 2."),
    9: ("Unit 3, Lesson 2: Personal endings (мен: -мың/-мін; сен: -сың/-сің). Examples: Мен мұғаліммін, Сен оқушысың.",
        "Unit 1 + Unit 2 + Unit 3 Lesson 1."),
    10: ("Unit 3, Lesson 3: Usage (Мен мұғаліммін, сен оқушысың). Put it together.",
        "Unit 1 + Unit 2 + Unit 3 Lessons 1-2."),
    11: ("Unit 3 Test: мен/сен, оқушы, personal endings, sentences Мен мұғаліммін, Сен оқушысың.",
        "All prior units."),
}


def call_gemini(prompt: str) -> str:
    req = urllib.request.Request(
        API_URL,
        data=json.dumps({
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"maxOutputTokens": 4096, "temperature": 0.4, "responseMimeType": "application/json"},
        }).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=90) as r:
        data = json.load(r)
    text = data.get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
    if not text:
        raise ValueError("Empty Gemini response")
    return text.strip()


def extract_json(text: str) -> dict:
    start = text.find("{")
    end = text.rfind("}") + 1
    if start < 0 or end <= start:
        raise ValueError("No JSON in response")
    return json.loads(text[start:end])


def main():
    os.makedirs("scripts/generated", exist_ok=True)
    for cloud, (summary, prior) in SUMMARIES.items():
        prompt = f"""You are a Kazakh language lesson generator for OYAN app. Generate lesson content in JSON.

{UNIT1_REF}

Prior lessons: {prior}

Current lesson summary: {summary}

Output ONLY valid JSON (no markdown):
{{
  "title": "Short title",
  "explanation_slides": ["para1", "para2"],
  "examples": ["Kazakh — English", ...],
  "quiz": [
    {{"question": "...", "options": ["A","B","C","D"], "correct_index": 0, "points": 1, "question_type": "multiple_choice", "audio_text": null}},
    ... for listening: {{"question": "X  -  [X]", "options": ["Do you hear? ..."], "correct_index": 0, "points": 0, "question_type": "listening", "audio_text": "X"}}
  ]
}}

Use correct_index 0-based. All Kazakh must be grammatically correct. Output ONLY the JSON object."""

        print(f"Calling Gemini for cloud {cloud}...")
        try:
            raw = call_gemini(prompt)
            obj = extract_json(raw)
            obj["quiz"] = [
                {**q, "correct_index": q.get("correct_index", q.get("correctIndex", 0))}
                for q in obj.get("quiz", [])
            ]
            with open(f"scripts/generated/cloud{cloud}.json", "w", encoding="utf-8") as f:
                json.dump(obj, f, ensure_ascii=False, indent=2)
            print(f"  Saved cloud{cloud}.json")
        except Exception as e:
            print(f"  ERROR cloud {cloud}: {e}")
    print("Done. Check scripts/generated/")


if __name__ == "__main__":
    main()
