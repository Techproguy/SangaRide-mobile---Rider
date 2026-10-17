env ?= dev
flavor_dev := dev
flavor_prod := prod
flavor = $(flavor_$(env))
defines = dart_defines/$(env).json
args = --flavor $(flavor) --dart-define-from-file=$(defines)

.PHONY: check run apk appbundle ipa

check:
	@test -n "$(flavor)" || (echo "env must be dev or prod (the mock server is retired)" && exit 1)
	@test -f $(defines) || (echo "$(defines) is missing. Copy dart_defines/$(env).example.json and fill it in." && exit 1)

run: check
	flutter run $(args)

apk: check
	flutter build apk --release $(args)

appbundle: check
	flutter build appbundle --release $(args)

ipa: check
	flutter build ipa --release $(args)
