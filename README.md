# Polarity iOS

Polarity is an open source iOS app for daily reflection through contrasting word pairs.

## Inspiration

Polarity is inspired by ideas in *Power vs. Force* by David R. Hawkins.

The app is built as a practical daily exercise:
- notice two opposing states
- reflect on what each means in your life
- journal one intentional step toward the higher expression

This project is inspired by that body of work and is not affiliated with or endorsed by David R. Hawkins or his publishers.

## How the Daily Practice Works

1. Every user gets the same two contrasting words each day.
2. You can tap each word to view its definition.
3. You journal on the contrast and what direction you want to move toward.
4. Entries are stored on-device, with optional private iCloud sync.

## Why Daily Journaling Matters

The practice is intentionally simple:
- naming a polarity increases awareness
- writing creates clarity and accountability
- repeating daily helps turn insight into behavior

## Open Source and Privacy

- This repo is public so anyone can inspect and audit the iOS code.
- No model API keys are stored in the app.
- Journal content remains local by default.
- If enabled, iCloud sync uses the user's private iCloud container.

## Project Structure

- `ios/Polarity/PolarityApp`: Xcode project
- `ios/Polarity/Sources`: mirrored Swift source folder

## Run Locally

1. Open `ios/Polarity/PolarityApp/PolarityApp.xcodeproj` in Xcode.
2. Choose an iPhone simulator.
3. Press Run.

## Backend

Backend services live in a separate private repository: `polarity_backend`.
That backend generates and serves daily words to the app.
