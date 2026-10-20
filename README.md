# Sanga Ride

The Sanga Ride rider app. Built on the sanga_mobile architecture (GetX controllers, go_router, Dio `ApiService`).

## Setup

The shared packages live in [sanga-ride-building-blocks](https://github.com/Techproguy/sanga-ride-building-blocks). Clone it next to this repo (`../sanga-ride-building-blocks`), then `flutter pub get`.

## Environments

| Env | Flavor | Talks to | Config file |
|---|---|---|---|
| `demo` | `dev` | In-app mock data, no server | `dart_defines/demo.json` |
| `dev` | `dev` | The dev server | `dart_defines/dev.json` |
| `prod` | `prod` | The production server | `dart_defines/prod.json` |

The `dev` flavor installs as **Sanga Ride Dev** (`com.sangatechnologies.ride.dev`), so it sits next to the real app on one phone. The `prod` flavor is **Sanga Ride** (`com.sangatechnologies.ride`).

Each config file sets `APP_ENV`. The app checks it at startup: `demo` and `dev` must run on the `dev` flavor and `prod` on the `prod` flavor, `prod` must use an HTTPS `BASE_URL`, and a live env refuses to start on a placeholder URL or Maps key.

Config files are gitignored. Copy each example and fill it in:

```sh
cp dart_defines/demo.example.json dart_defines/demo.json
cp dart_defines/dev.example.json dart_defines/dev.json
cp dart_defines/prod.example.json dart_defines/prod.json   # add the production URL here
cp android/secrets.properties.example android/secrets.properties
cp ios/Flutter/Secrets.example.xcconfig ios/Flutter/Secrets.xcconfig
```

## Run

```sh
make run env=dev     # or env=demo, env=prod
```

In VS Code, pick **Dev**, **Demo**, **Prod** or **Prod (release)** from the Run menu. Without make:

```sh
flutter run --flavor dev --dart-define-from-file=dart_defines/dev.json
```

## Build

```sh
make apk env=prod         # Android APK
make appbundle env=prod   # Android App Bundle for Play
make ipa env=prod         # iOS archive for TestFlight
```

Swap `env=prod` for `env=dev` to build the dev app.

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

## Mock data

Until the backend exists, API calls are answered in-app from plain fixtures in `lib/core/api/mock/`. The sign-in code is `123456`.

- `mock_endpoints.dart`: the paths
- `mock_data.dart`: the fixtures
- `mock_routes.dart`: which fixture each path returns
- `mock_server.dart`: the interceptor that serves them

A flow that needs data adds its path, fixture and route here, and nothing else.

To remove the mocks, delete the `mock/` folder, drop the `MockServerInterceptor()` line in `api.dart`, and swap `MockEndpoints` for the real endpoints class.
