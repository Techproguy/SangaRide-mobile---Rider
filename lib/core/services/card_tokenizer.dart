import 'package:sanga_ride/model/trip/wrapup/card_details.dart';

abstract interface class CardTokenizer {
  Future<String> tokenize(CardDetails details);
}
