import 'package:sanga_ride/model/trip/wrapup/card_details.dart';

abstract interface class CardTokenizer {
  Future<String> tokenize(CardDetails details);
}

class UnboundCardTokenizer implements CardTokenizer {
  @override
  Future<String> tokenize(CardDetails details) => Future.error(StateError('No live card tokenizer is bound yet.'));
}
