# Repository Guidelines

## Project Structure & Module Organization
Core app code lives in `lib/`, organized by layer:
- `lib/models/` data types (`FillRecord`, `FuelType`, `Vehicle`)
- `lib/providers/` state + analytics logic
- `lib/services/` persistence/import services
- `lib/screens/` page-level UI
- `lib/widgets/` reusable components
- `lib/theme/` theme setup

Tests live in `test/` and mirror runtime modules (for example, `test/providers/records_provider_test.dart`). Shared assets are in `assets/`. Utility scripts are in `tools/` (notably `tools/generate_app_store_assets.py`). Platform folders (`android/`, `ios/`, `macos/`, `web/`) should only be edited for platform-specific changes.

## Build, Test, and Development Commands
Run from repository root:
- `flutter pub get`: install/update Dart and Flutter dependencies.
- `flutter run`: run the app on a simulator/device.
- `flutter test`: execute all unit tests under `test/`.
- `flutter analyze`: run static analysis with repo lint rules.
- `dart format lib test`: format Dart sources before committing.
- `python3 tools/generate_app_store_assets.py`: regenerate App Store asset pack in `output/app_store/`.

## Coding Style & Naming Conventions
Follow `analysis_options.yaml` (`flutter_lints` + const-preference rules). Use 2-space indentation and trailing commas in widget trees for stable formatting. File names use `snake_case.dart`; classes/enums use `PascalCase`; variables/methods use `camelCase`. Keep business logic in `providers/` and `services/`; keep screens focused on composition and presentation.

## Testing Guidelines
Use `flutter_test` and `mocktail`. Name files `*_test.dart` and group tests by domain (`models`, `providers`, `services`, `utils`). Add or update tests for new calculations, serialization paths, and import/storage edge cases. Before opening a PR, run `flutter test` and `flutter analyze`.

## Commit & Pull Request Guidelines
Current history favors short, imperative, capitalized commit subjects (for example: `Add multi-vehicle management feature`, `Fix fuel type edit error`). Keep commits scoped to a single concern and include related tests.

PRs should include:
- a clear summary and user-visible impact
- linked issue/reference when applicable
- screenshots for UI changes
- validation notes for `flutter test` and `flutter analyze`
