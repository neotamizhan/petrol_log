# Vehicle Logbook

Vehicle Logbook is a Flutter app for tracking vehicle maintenance, service reminders, fuel activity, mileage, and cost history.
It is designed around a vehicle-first workflow: pick a vehicle, log what happened, and review the full service and fuel timeline in one place.

## Product Overview

Vehicle Logbook helps answer practical ownership questions:

- What service, repair, or inspection was done last?
- What maintenance is overdue or coming up?
- How much am I spending on service and fuel?
- How efficient is my vehicle over time?
- When will I likely need to refuel next?

The app stores records locally, calculates analytics automatically, and keeps maintenance status visible on the home dashboard.

## Core Features

- Vehicle logbook dashboard
- Shows selected vehicle, odometer, open maintenance items, total entries, next service signals, fuel forecast, and recent activity.

- Service and maintenance logging
- Log oil changes, brakes, tires, battery work, insurance, inspections, repairs, and other ownership events.
- Set next due odometer/date and track `on_track`, `due_soon`, and `overdue` service states.

- Fuel logging
- Add date/time, odometer, fuel type, total cost, and notes for every fuel purchase.
- Automatically estimates fuel volume from configured price per liter.

- Combined activity timeline
- Shows service entries and fuel logs together so the vehicle history reads chronologically.

- Refuel forecast
- Forecasts likely next refill date, expected cycle length, projected odometer, and expected spend.
- Includes confidence and urgency states (`on_track`, `soon`, `overdue`).

- Statistics dashboard
- Total fills, fuel volume, distance, duration, best/worst efficiency, average fill cost, and monthly spending trends.

- Data import
- CSV import flow to migrate historical fuel records.
- Supports common date formats (for example: `yyyy-MM-dd`, `dd/MM/yyyy`, `MM/dd/yyyy`).

- Personalization
- Fuel price, fuel types, currency, vehicles, and theme mode (`Light`, `Dark`, `System`).

## Tech Stack

- Flutter (Material 3)
- Provider (state management)
- SharedPreferences (local persistence)
- intl (formatting)
- csv + file_picker (CSV import)

## Project Structure

- `lib/models/` data models (`FillRecord`, `MaintenanceRecord`, `Vehicle`)
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

## Product Website

The public product website is a static GitHub Pages site under `docs/`.
It includes the landing page plus app store review pages:

- `docs/index.html`
- `docs/privacy.html`
- `docs/support.html`
- `docs/terms.html`
- `docs/data-control.html`

To host it on GitHub Pages, configure the repository Pages source to serve the `docs/` folder from the default branch.

## Current Status

- Product workflow is centered on vehicle maintenance logging, with fuel logging as one activity type.
- Unit tests are available for model, provider, utility, and import logic.
- iOS release validation succeeds, pending non-placeholder bundle identifier configuration.
