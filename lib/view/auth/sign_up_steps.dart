import 'package:sanga_ride_ui/sanga_ride_ui.dart';

enum RiderSignUpStep {
  details,
  aboutYou,
  selfie,
  home;

  SangaFormStep get formStep => SangaFormStep(index + 1, values.length);
}
