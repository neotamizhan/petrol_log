# Petrol Log

Petrol Log is a polished Flutter app for tracking fuel fills, cost trends, and mileage performance.
It is designed for drivers who want fast daily logging and clear long-term insights.

## Product Overview

Petrol Log helps you answer three practical questions:

- How much am I spending on fuel?
- How efficient is my vehicle over time?
- When will I likely need to refuel next?

The app stores your records locally, calculates analytics automatically, and presents everything in a clean dashboard-first interface.

## Core Features

- Quick fuel entry
- Add date/time, odometer, total cost, and notes for every fill.

- Live volume calculation
- Automatically estimates fuel volume from your configured price per liter.

- Smart history cards
- Shows efficiency, distance since previous fill, interval days, and cost per record.

- Refuel Radar (predictive)
- Forecasts likely next refill date, expected cycle length, projected odometer, and expected spend.
- Includes confidence and urgency states (`on_track`, `soon`, `overdue`).

- Statistics dashboard
- Total fills, fuel volume, distance, duration, best/worst efficiency, average fill cost, and monthly spending trends.

- Data import
- CSV import flow to migrate historical records.
- Supports common date formats (for example: `yyyy-MM-dd`, `dd/MM/yyyy`, `MM/dd/yyyy`).

- Personalization
- Fuel price, currency, and theme mode (`Light`, `Dark`, `System`).

## Tech Stack

- Flutter (Material 3)
- Provider (state management)
- SharedPreferences (local persistence)
- intl (formatting)
- csv + file_picker (CSV import)

## Project Structure

- `lib/models/` data models (`FillRecord`)
- `lib/providers/` app state and analytics logic (`RecordsProvider`)
- `lib/screens/` user-facing flows (home, add/edit, stats, settings)
- `lib/services/` storage and import services
- `lib/widgets/` reusable UI components
- `test/` model/service/provider unit tests

## Getting Started

### Prerequisites

- Flutter SDK (stable)
- Xcode (for iOS builds)
- Android Studio / Android SDK (for Android builds)

### Install

```bash
flutter pub get
```

### Run

```bash
flutter run
```

## Quality Checks

Run unit tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

## Release Builds

Android APK:

```bash
flutter build apk --release
```

iOS archive (unsigned):

```bash
flutter build ipa --release --no-codesign
```

## App Store Asset Pack

This repository includes generated App Store assets and a reproducible generator script:

- Generator: `tools/generate_app_store_assets.py`
- Output pack: `output/app_store/`
- Includes:
  - Launcher icons (iOS/Android/Web)
  - iOS launch images
  - App Store screenshot sets (`iphone_6.7`, `iphone_6.5`, `ipad_13`)
  - Listing metadata drafts (`app_store_listing.md`, `screenshot_captions.md`)

Regenerate assets:

```bash
python3 tools/generate_app_store_assets.py
```

## Current Status

- Product features implemented for daily fuel tracking, analytics, and prediction.
- Unit tests are available for model, provider, and import logic.
- iOS release validation succeeds, pending non-placeholder bundle identifier configuration.
