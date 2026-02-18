# OYAN AI

OYAN AI is an iOS application designed to help English speakers learn the Kazakh language through interactive lessons and AI-powered assistance.

## Mission

Our mission is to make Kazakh accessible to foreigners and modernize the way the language is taught using AI and adaptive learning technologies.

---

## Features

- Structured learning units
- AI-powered chat assistant
- Kazakh audio generation
- User progress tracking
- Cloud-based backend (Supabase)

---

## Tech Stack

- SwiftUI (iOS)
- Supabase (Database & Edge Functions)
- Microsoft Azure
- Gemini API
- KazLLM
- Custom backend functions

---

## Project Structure

- `OYAN App/` – iOS application source code
- `supabase/` – Edge functions and database scripts
- `scripts/` – Content generation scripts
- `API_ARCHITECTURE.md` – System design overview

---

## How to Run

1. Clone the repository
2. Open `OYAN App.xcodeproj` in Xcode
3. Select a simulator
4. Press Run

> The app connects to Supabase and AI APIs automatically.
> Before executing the code, in the main settings of the file you have to select a team (your Apple ID), in order to proceed.
> Also, if the Status in the main settings shows a failure, simply change the identifier Bundle Identifier title to a different one

---

## Note

API keys and production credentials are managed securely and are not exposed publicly.
