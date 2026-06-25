## Summary

The Flutter build warns that `mobile_scanner` applies the Kotlin Gradle Plugin (KGP), which will be unsupported in future Flutter/AGP versions.

## Status

- `mobile_scanner` in this project is pinned to `^7.2.0` (no newer compatible versions available via `pub`).
- `android/gradle.properties` already contains the compatibility flags added by Flutter:
    - `android.newDsl=false`
    - `android.builtInKotlin=false`

## Recommendation

1. Prefer upgrading the plugin to a version migrated to Built-in Kotlin (if/when released).
2. If no migrated release exists, open an issue for the plugin maintainer using the template below and link to the Flutter migration guide.
3. Keep `android.builtInKotlin=false` and `android.newDsl=false` in `android/gradle.properties` until the plugin is migrated.

## How to reproduce

Run the app and observe the warning produced by `flutter run`:

```bash
flutter run
```

## Issue template to file against the plugin repository

Title: Migrate Plugin to Built-in Kotlin (`mobile_scanner`)

Body:

```
I am using `mobile_scanner` (version: 7.2.0) in my Flutter app.

When running `flutter run`, I see this warning:

"WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): mobile_scanner
Future versions of Flutter will fail to build if your plugin applies KGP."

Please migrate `mobile_scanner` to use Built-in Kotlin (do not apply the `kotlin-gradle-plugin`). The Flutter migration guide is here:
https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors

This app currently keeps the following flags in `android/gradle.properties` to remain compatible:
```

android.newDsl=false
android.builtInKotlin=false

```

Could you confirm whether a migrated release is planned or provide guidance to users?
Thanks!
```

## Useful links

- Flutter migration guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/
- Example issue for reference: https://github.com/flutter/flutter/issues/181383

## Local notes

- If you want, I can open the issue for you (needs plugin repo link / permission).
- Alternatively, we can monitor `mobile_scanner` releases and upgrade when a migrated version appears.
