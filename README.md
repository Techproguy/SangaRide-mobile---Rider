# Sanga Ride

The Sanga Ride rider app. Built on the sanga_mobile architecture (GetX controllers, go_router, Dio `ApiService`).

## Setup

The shared packages live in [sanga-ride-building-blocks](https://github.com/Techproguy/sanga-ride-building-blocks). Clone it next to this repo (`../sanga-ride-building-blocks`), then `flutter pub get`.

## Configuration

There is one configuration: the live server (`https://api-staging.sangaride.com`). The host, Maps key and Google client ids are plain constants in the app, so no flags, flavors or config files are needed.

## Run and build

```sh
flutter run
flutter build apk --release        # needs the release keystore env vars
flutter build appbundle --release
flutter build ipa --release
```

A release Android build stops with an error unless `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS` and `CM_KEY_PASSWORD` point at the upload keystore.

## Tester builds (Codemagic)

Codemagic builds both stores from `codemagic.yaml` whenever a tag that starts with `v` is pushed. Set the version in `pubspec.yaml` first (Codemagic picks the build number), then:

```sh
git tag v1.0.1
git push origin v1.0.1
```

| Workflow | Builds | Testers join with |
|---|---|---|
| `testflight` | iOS IPA, sent to the TestFlight group "Sanga Ride External". Apple reviews each build before testers get it, usually within a day | https://testflight.apple.com/join/tWuXrm5X |
| `play-open-testing` | Android App Bundle, uploaded to Play open testing as a draft | https://play.google.com/apps/testing/com.sangatechnologies.ride |

Either workflow can also be started by hand in Codemagic (the app, then Start new build). Build numbers go one above the latest in TestFlight or Play.

Play holds each build as a draft: in Play Console open Test and release, Open testing, then review the draft and send it to Google. After the first open testing release is approved, set `submit_as_draft: false` in `codemagic.yaml` so later builds go out on their own.

Anyone with the links can join: the TestFlight link takes up to 10,000 testers and Play open testing has no list. To invite someone by email instead, add them to "Sanga Ride External" in App Store Connect, TestFlight.

Secrets live in the Codemagic variable group `sanga_ride_rider`. Set or refresh them with `python3 ../sanga-ride-building-blocks/tool/codemagic_setup.py`; every variable is explained in [CODEMAGIC.md](https://github.com/Techproguy/sanga-ride-building-blocks/blob/main/docs/ci/CODEMAGIC.md).
