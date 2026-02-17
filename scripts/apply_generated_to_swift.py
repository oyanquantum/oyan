#!/usr/bin/env python3
"""
Read scripts/generated/cloud5.json ... cloud11.json (from generate_units_gemini.py)
and update OYAN App/OYAN App/CourseStructure.swift bundled content for Unit 2 & 3.
"""

import json
import os
import re
from typing import Optional

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
GEN_DIR = os.path.join(SCRIPT_DIR, "generated")
COURSE_FILE = os.path.join(SCRIPT_DIR, "..", "OYAN App", "OYAN App", "CourseStructure.swift")

# Valid syllable sets for Connect by sound (Unit 1 only) - app only supports these
_VALID_CONNECT_SYLLABLES = [{"Жү", "Мы", "сық", "рек"}, {"Мы", "Тү", "йе", "сық"}, {"Ал", "Сә", "мұрт", "біз"}]


# Fallback when connect_by_sound has question "Connect by sound: X" but no pairs
_CONNECT_MEANINGS = {
    "Сау бол": "Goodbye! (informal)",
    "Сау болыңыз": "Goodbye! (formal)",
    "Сәлем": "Hi!",
    "Сәлеметсіз бе": "Hello! (formal)",
    "Мен": "I",
    "Сен": "You (informal)",
    "Оқушы": "Student",
    "Мұғалім": "Teacher",
}


def _normalize_for_dedup(s: str) -> str:
    """Normalize option for deduplication: strip trailing punctuation, case-fold."""
    if not s:
        return ""
    t = str(s).strip().rstrip("!?.,;:")
    return t


def _deduplicate_options(opts: list, correct_index: int):
    """Remove duplicate/near-duplicate options. Returns (deduped_opts, new_correct_index)."""
    if not opts:
        return opts, correct_index
    seen = {}
    out = []
    for i, o in enumerate(opts):
        key = _normalize_for_dedup(o)
        if key and key not in seen:
            seen[key] = len(out)
            out.append(o)
    if not out:
        return opts, correct_index
    # Remap correct_index if we removed the correct option's duplicate
    correct_val = opts[correct_index] if 0 <= correct_index < len(opts) else opts[0]
    new_idx = next((i for i, x in enumerate(out) if _normalize_for_dedup(x) == _normalize_for_dedup(correct_val)), 0)
    return out, new_idx


def _convert_matching_to_mcq(q: dict) -> Optional[dict]:
    """Convert matching question with pairs to MCQ. Never use Yes/No for matching."""
    pairs = q.get("pairs", [])
    if not pairs:
        return None
    first = pairs[0]
    kazakh = first.get("kazakh", "").strip()
    english = first.get("english", "").strip()
    if not kazakh or not english:
        return None
    others = [p.get("english", "") for p in pairs[1:] if p.get("english")]
    distractors = ["Student", "Teacher", "Hello", "Goodbye", "I", "You", "Classmate", "Hi"]
    for o in others:
        if o and o != english and o not in distractors:
            distractors.insert(0, o)
    opts = [english]
    for d in distractors:
        if d != english and d not in opts and len(opts) < 4:
            opts.append(d)
    return {
        "question": f"What does {kazakh} mean?",
        "options": opts[:4],
        "correct_index": 0,
        "points": q.get("points", 2),
        "question_type": "multiple_choice",
    }


def _fix_fill_in_blank_question(q: dict) -> None:
    """Fix fill-in-the-blank format: X ... (Y) → X Y____ with endings as options."""
    raw = q.get("question", "")
    correct = q.get("correct_answer")
    opts = q.get("options", q.get("answers", []))
    # Pattern: "Мен ... (мұғалім)" with options like мұғаліммін, мұғалімсің → "Мен мұғалім____." + endings
    m = re.search(r"^(.+?)\s+\.\.\.\s+\(([^)]+)\)\s*$", raw)
    if m and opts and (isinstance(correct, str) or correct is None):
        prefix, word = m.group(1).strip(), m.group(2).strip()
        new_q = f"Complete the sentence: {prefix} {word}____."
        q["question"] = new_q
        # Extract endings: мұғаліммін → мін, мұғалімсің → сің
        endings = []
        for o in opts:
            if isinstance(o, str) and word and o.startswith(word):
                endings.append(o[len(word):].strip())
            else:
                endings.append(o)
        if len(endings) >= 2 and all(isinstance(e, str) and len(e) <= 6 for e in endings):
            q["options"] = endings
            ci = q.get("correct_index", q.get("correctIndex", 0))
            if 0 <= ci < len(opts) and opts[ci].startswith(word):
                q["correct_index"] = endings.index(opts[ci][len(word):].strip()) if opts[ci][len(word):].strip() in endings else 0


def _convert_connect_to_mcq(q):
    """Convert connect_by_sound with pairs (no valid syllables) to multiple choice."""
    pairs = q.get("pairs", [])
    if pairs:
        first = pairs[0]
        kazakh, english = first.get("kazakh", ""), first.get("english", "")
    else:
        raw_q = q.get("question", "")
        m = re.search(r"Connect by sound:\s*(.+)", raw_q)
        kazakh = (m.group(1).strip() if m else "").strip()
        english = _CONNECT_MEANINGS.get(kazakh, "")
    if not kazakh or not english:
        return None
    others = [p.get("english", "") for p in pairs[1:] if p.get("english")]
    distractors = ["Student", "Teacher", "Hello", "Goodbye"]
    for o in others:
        if o and o != english and o not in distractors:
            distractors.insert(0, o)
    opts = [english]
    for d in distractors:
        if d != english and d not in opts and len(opts) < 4:
            opts.append(d)
    while len(opts) < 2:
        opts.append("—")
    return {
        "question": f"What does {kazakh} mean?",
        "options": opts[:4],
        "correct_index": 0,
        "points": q.get("points", 2),
        "question_type": "multiple_choice",
    }


def escape_swift(s):
    return str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def _looks_kazakh(s: str) -> bool:
    kazakh_letters = "әіңғүұқөһАӘБВГДЕЖЗИЙКЛМНОӨПРСТУҰҚФХҺЦЧШЩЫЭЮЯ"
    return any(c in kazakh_letters for c in (s or ""))


def _collect_distractors(all_quiz: list, examples: list, want_kazakh: bool, exclude: str) -> list:
    """Gather candidate distractors from quiz and examples. want_kazakh=True for translate_to_kazakh."""
    candidates = []
    exclude_lower = (exclude or "").lower().strip()
    for item in all_quiz:
        ca = item.get("correct_answer")
        if isinstance(ca, str) and ca.strip().lower() != exclude_lower:
            if want_kazakh and _looks_kazakh(ca):
                candidates.append(ca.strip())
            elif not want_kazakh and not _looks_kazakh(ca):
                candidates.append(ca.strip())
        opts = item.get("options", item.get("answers", []))
        for o in (opts or []):
            if isinstance(o, str) and o.strip() and o.strip() != "—":
                if want_kazakh and _looks_kazakh(o) and o.strip().lower() != exclude_lower:
                    candidates.append(o.strip())
                elif not want_kazakh and not _looks_kazakh(o) and o.strip().lower() != exclude_lower:
                    candidates.append(o.strip())
    for ex in (examples or []):
        if "—" in ex or " - " in ex:
            parts = re.split(r"\s*[—\-]\s*", ex, 1)
            if len(parts) == 2:
                k, e = parts[0].strip(), parts[1].strip()
                if want_kazakh and k and k.lower() != exclude_lower:
                    candidates.append(k)
                elif not want_kazakh and e and e.lower() != exclude_lower:
                    candidates.append(e)
    seen = set()
    out = []
    for c in candidates:
        key = c.lower()
        if key not in seen and c not in out:
            seen.add(key)
            out.append(c)
            if len(out) >= 4:
                break
    return out


def _ensure_min_options(q: dict, all_quiz: list, examples: list) -> None:
    """Mutate q to have at least 3 options. Uses correct_answer and distractors from lesson."""
    opts = q.get("options", q.get("answers"))
    if opts and len(opts) >= 3:
        return
    correct = q.get("correct_answer")
    if not isinstance(correct, str):
        return
    correct = correct.strip()
    qtype = q.get("question_type", "")
    if qtype.startswith("translate_to_kazakh"):
        distractors = _collect_distractors(all_quiz, examples, want_kazakh=True, exclude=correct)
    elif qtype.startswith("translate_to_english"):
        distractors = _collect_distractors(all_quiz, examples, want_kazakh=False, exclude=correct)
    elif qtype == "fill_in_the_blank":
        distractors = _collect_distractors(all_quiz, examples, want_kazakh=True, exclude=correct)
    else:
        return
    fallback_kz = ["Мен", "Сен", "Ол", "Оқушы", "Мұғалім", "Сәлем", "Сау бол"]
    fallback_en = ["I", "You", "He/She", "Student", "Teacher", "Hello", "Goodbye"]
    fallback = fallback_kz if "kazakh" in qtype or qtype == "fill_in_the_blank" else fallback_en
    for f in fallback:
        if f != correct and f not in distractors:
            distractors.append(f)
        if len(distractors) >= 3:
            break
    new_opts = [correct]
    for d in distractors:
        if d != correct and d not in new_opts:
            new_opts.append(d)
        if len(new_opts) >= 4:
            break
    if len(new_opts) >= 3:
        q["options"] = new_opts
        q["correct_index"] = 0


def quiz_item_to_swift(q, indent="                    "):
    raw_q = q.get("question")
    if not raw_q or raw_q.strip() == "?":
        text = q.get("text", "")
        qtype = q.get("question_type", "")
        if qtype == "translate_to_kazakh" and text:
            raw_q = f"Translate to Kazakh: {text}"
        elif qtype == "translate_to_english" and text:
            raw_q = f"What does {text} mean?"
        elif qtype == "fill_in_the_blank" and text:
            raw_q = f"Fill in the blank: {text}"
        elif qtype in ("connect_by_sound", "connect-by-sound"):
            pairs = q.get("pairs", [])
            if pairs:
                first = pairs[0]
                k, e = first.get("kazakh", ""), first.get("english", "")
                raw_q = f"Connect by sound: {k}" if k else "Connect by sound"
            else:
                raw_q = "Connect by sound"
        else:
            raw_q = raw_q or "Choose the correct answer"
    question = escape_swift(raw_q)
    opts = q.get("options", q.get("answers"))
    if opts is None or len(opts) < 3:
        qtype_check = q.get("question_type", "")
        correct = q.get("correct_answer")
        if qtype_check.startswith("translate") and isinstance(correct, str):
            opts = opts or [correct]
        elif qtype_check == "fill_in_the_blank" and isinstance(correct, str):
            opts = opts or [correct]
        else:
            opts = opts or ["Yes", "No"]
    # Ensure at least 3 options (no "—" placeholders)
    opts = [o for o in opts if o and str(o).strip() != "—"]
    if len(opts) < 3 and q.get("correct_answer"):
        c = q.get("correct_answer")
        if c and c not in opts:
            opts = [c] + [o for o in opts if o != c]
    correct_index = q.get("correct_index", q.get("correctIndex", 0))
    opts, correct_index = _deduplicate_options(opts, correct_index)
    options = [escape_swift(o) for o in (opts if len(opts) >= 2 else opts + ["Yes", "No"][: 3 - len(opts)])]
    points = q.get("points")
    qtype = q.get("question_type")
    audio = q.get("audio_text")
    opts_str = ", ".join(f'"{o}"' for o in options)
    args = [f'question: "{question}"', f"options: [{opts_str}]", f"correctIndex: {correct_index}"]
    if points is not None:
        args.append(f"points: {points}")
    if qtype:
        args.append(f'type: "{qtype}"')
    if audio:
        args.append(f'audioText: "{escape_swift(audio)}"')
    return f'GeneratedQuizItem({", ".join(args)})'


def content_to_swift_case(cloud: int, data: dict, lang: str) -> str:
    title = escape_swift(data.get("title", "Lesson"))
    slides = data.get("explanation_slides", [])
    examples = data.get("examples", [])
    quiz_raw = data.get("quiz", [])
    quiz = []
    for q in list(quiz_raw):
        qtype = q.get("question_type", "")
        if qtype in ("connect_by_sound", "connect-by-sound"):
            opts = q.get("options", q.get("answers", []))
            opt_set = set(str(o) for o in opts) if opts else set()
            if opt_set not in _VALID_CONNECT_SYLLABLES:
                converted = _convert_connect_to_mcq(q)
                if converted:
                    quiz.append(converted)
                    continue
                # Skip broken connect_by_sound (no pairs, no phrase to extract)
                continue
        if qtype == "matching":
            converted = _convert_matching_to_mcq(q)
            if converted:
                quiz.append(converted)
                continue
            # Skip broken matching (no pairs)
            continue
        if qtype in ("fill_in_the_blank", "multiple_choice"):
            _fix_fill_in_blank_question(q)
        if qtype == "true_false":
            correct_val = q.get("correct_answer")
            if correct_val is False:
                q["correct_index"] = 1  # No
                q["options"] = ["Yes", "No"]
            else:
                q["correct_index"] = 0  # Yes
                q["options"] = ["Yes", "No"]
        _ensure_min_options(q, quiz_raw, examples)
        quiz.append(q)
    slides_str = ",\n                ".join(f'"{escape_swift(s)}"' for s in slides)
    ex_str = ", ".join(f'"{escape_swift(e)}"' for e in examples)
    quiz_lines = [quiz_item_to_swift(q) for q in quiz]
    quiz_str = ",\n                    ".join(quiz_lines)
    return f"""
        case {cloud}:
            return GeneratedLessonContent(
                title: "{title}",
                explanationSlides: [
                    {slides_str}
                ],
                examples: [{ex_str}],
                quiz: [
                    {quiz_str}
                ]
            )"""


def main():
    if not os.path.isdir(GEN_DIR):
        print(f"ERROR: {GEN_DIR} not found. Run generate_units_gemini.py first.")
        return 1

    with open(COURSE_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    for cloud in range(5, 12):
        path = os.path.join(GEN_DIR, f"cloud{cloud}.json")
        if not os.path.exists(path):
            print(f"WARN: {path} not found, skipping")
            continue
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        for slide in data.get("explanation_slides", []):
            if isinstance(slide, str) and "\\n" in slide:
                data["explanation_slides"] = [s.replace("\\n", "\n") if isinstance(s, str) else s for s in data["explanation_slides"]]
                break
        for q in data.get("quiz", []):
            if "answers" in q and "options" not in q:
                q["options"] = q.pop("answers")
        new_block = content_to_swift_case(cloud, data, "en")
        case_start = re.search(rf"\n        case {cloud}:\s*\n", content)
        if not case_start:
            print(f"WARN: Could not find case {cloud} in Swift file")
            continue
        start = case_start.end()
        next_case = re.search(r"\n        (?:case \d+|default):", content[start:])
        end = start + next_case.start() if next_case else len(content)
        content = content[:case_start.start()] + new_block + content[end:]
        print(f"Updated case {cloud}")

    with open(COURSE_FILE, "w", encoding="utf-8") as f:
        f.write(content)
    print("Done. CourseStructure.swift updated.")
    return 0


if __name__ == "__main__":
    exit(main())
