import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class ExtendQuote {
  const ExtendQuote({required this.minutes, required this.added, this.id});

  factory ExtendQuote.fromJson(int minutes, Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return ExtendQuote(
      minutes: minutes,
      added:
          reader.moneyOrNull('addedFare') ??
          reader.moneyOrNull('amount') ??
          reader.moneyOrNull('price') ??
          reader.money('fare'),
      id: reader.strOrNull('quoteId'),
    );
  }

  final int minutes;
  final Money added;
  final String? id;
}

abstract final class ExtendOptions {
  static const List<int> presetMinutes = [60, 120, 180];
  static const int customStepMinutes = 30;
  static const int customMinMinutes = 210;
  static const int customMaxMinutes = 720;
  static const int customStartMinutes = 240;

  static String label(int minutes) {
    final hours = minutes ~/ Duration.minutesPerHour;
    final rest = minutes % Duration.minutesPerHour;
    final hoursLabel = hours == 1 ? '1 hour' : '$hours hours';
    if (hours == 0) return '$rest mins';
    return rest == 0 ? hoursLabel : '$hoursLabel $rest mins';
  }

  static String presetLabel(int minutes) => '+ ${label(minutes)}';
}
