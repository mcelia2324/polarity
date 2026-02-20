# Polarity iOS (SwiftUI)

This folder contains the iOS app source and Xcode project for Polarity.

## Inspiration

The product is inspired by the polarity framework discussed in *Power vs. Force* by David R. Hawkins:
- hold two contrasting states side by side
- reflect on lived meaning
- choose a higher alignment through daily action

## Daily Experience

1. The app fetches one shared daily word pair for all users.
2. Users can tap each word to see definitions.
3. Users journal reflections and intention for the day.
4. Journal data is local-first, with optional private iCloud sync.

## Open in Xcode

1. Open `ios/Polarity/PolarityApp/PolarityApp.xcodeproj`.
2. Select simulator or device.
3. Build and run.

## Required Capabilities (if enabled)

- Push Notifications
- Background Modes -> Remote notifications
- iCloud (for optional sync)

## Backend Base URL

Set the base URL from in-app Settings.
For device testing against local backend, use your machine IP (example: `http://192.168.1.20:8069`).
