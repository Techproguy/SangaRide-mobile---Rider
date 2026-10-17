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

## Mock data

Until the backend exists, API calls are answered in-app from plain fixtures in `lib/core/api/mock/`. The sign-in code is `123456`.

- `mock_endpoints.dart`: the paths
- `mock_data.dart`: the fixtures
- `mock_routes.dart`: which fixture each path returns
- `mock_server.dart`: the interceptor that serves them

A flow that needs data adds its path, fixture and route here, and nothing else.

To remove the mocks, delete the `mock/` folder, drop the `MockServerInterceptor()` line in `api.dart`, and swap `MockEndpoints` for the real endpoints class.
