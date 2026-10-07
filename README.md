# Sanga Ride

The Sanga Ride rider app. Built on the sanga_mobile architecture (GetX controllers, go_router, Dio `ApiService`).

## Setup

Maps keys live in three gitignored files. Copy each example and fill in the keys:

```sh
cp dart_defines/ride.example.json dart_defines/ride.json
cp android/secrets.properties.example android/secrets.properties
cp ios/Flutter/Secrets.example.xcconfig ios/Flutter/Secrets.xcconfig
```

## Run

```sh
flutter run --dart-define-from-file=dart_defines/ride.json
```

## Mock data

Until the backend exists, API calls are answered in-app from plain fixtures in `lib/core/api/mock/`. The sign-in code is `123456`.

- `mock_endpoints.dart`: the paths
- `mock_data.dart`: the fixtures
- `mock_routes.dart`: which fixture each path returns
- `mock_server.dart`: the interceptor that serves them

A flow that needs data adds its path, fixture and route here, and nothing else.

To remove the mocks, delete the `mock/` folder, drop the `MockServerInterceptor()` line in `api.dart`, and swap `MockEndpoints` for the real endpoints class.
