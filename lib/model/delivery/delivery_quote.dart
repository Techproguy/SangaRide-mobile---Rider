import 'package:sanga_ride/core/format/money_json.dart';
import 'package:sanga_ride/model/delivery/delivery_failure.dart';
import 'package:sanga_ride/model/trip/server_time.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class QuoteTier {
  const QuoteTier({
    required this.id,
    required this.fare,
    required this.etaMinutes,
    required this.isRecommended,
    this.quoteId,
    this.expiresAt,
  });

  factory QuoteTier.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final etas = reader.raw['etaMinutes'];
    return QuoteTier(
      id: reader.str('id'),
      fare: reader.money('fare'),
      etaMinutes: [
        if (etas is List)
          for (final minutes in etas)
            if (minutes is num) minutes.round(),
      ],
      isRecommended: reader.boolOr('recommended', false),
    );
  }

  factory QuoteTier.fromEstimate(String tierId, Map<String, dynamic> json, {required List<int> fallbackEta}) {
    final reader = JsonReader.of(json);
    final quote = reader.objectOrNull('quote') ?? reader;
    final fare = _firstMoney(quote, const ['fare', 'price', 'total', 'amount', 'estimatedFare', 'tierPrice']);
    if (fare == null) throw JsonFormatError('Expected a fare in the delivery estimate', json);
    final etaMin = quote.intOrNull('etaMinMinutes');
    final etaMax = quote.intOrNull('etaMaxMinutes');
    final expiresAt = quote.strOrNull('expiresAt');
    return QuoteTier(
      id: tierId,
      quoteId: quote.strOrNull('quoteId') ?? quote.strOrNull('id'),
      fare: fare,
      etaMinutes: etaMin == null ? fallbackEta : [etaMin, ?etaMax],
      isRecommended: false,
      expiresAt: expiresAt == null ? null : deviceDeadlineOf(expiresAt),
    );
  }

  static Money? _firstMoney(JsonReader reader, List<String> keys) {
    for (final key in keys) {
      final value = reader.raw[key];
      final money = value is Map ? Money.tryParse(value['amount'] ?? value) : Money.tryParse(value);
      if (money != null) return money;
    }
    return null;
  }

  final String id;
  final String? quoteId;
  final Money fare;
  final List<int> etaMinutes;
  final bool isRecommended;
  final DateTime? expiresAt;
}

class DeliveryQuote {
  const DeliveryQuote({
    required this.quoteId,
    required this.expiresAt,
    required this.tiers,
    required this.recommendedTier,
  });

  factory DeliveryQuote.ofTiers(List<QuoteTier> tiers, {String? recommendedTier}) {
    final deadlines = [for (final tier in tiers) ?tier.expiresAt];
    return DeliveryQuote(
      quoteId: tiers.firstOrNull?.quoteId ?? '',
      expiresAt: deadlines.isEmpty
          ? DateTime.now().add(_defaultLifetime)
          : deadlines.reduce((a, b) => a.isBefore(b) ? a : b),
      tiers: tiers,
      recommendedTier: recommendedTier,
    );
  }

  static const Duration _defaultLifetime = Duration(minutes: 10);

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return DeliveryQuote(
      quoteId: reader.str('quoteId'),
      expiresAt: deviceDeadlineOf(reader.str('expiresAt')),
      tiers: reader.listOf('tiers', (tier) => QuoteTier.fromJson(tier.raw)),
      recommendedTier: reader.strOrNull('recommendedTier'),
    );
  }

  final String quoteId;
  final DateTime expiresAt;
  final List<QuoteTier> tiers;
  final String? recommendedTier;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());

  QuoteTier? tierOf(String? id) => tiers.where((tier) => tier.id == id).firstOrNull;

  QuoteTier? get preselected => tierOf(recommendedTier) ?? tiers.firstOrNull;
}

sealed class DeliveryQuoteState {
  const DeliveryQuoteState();
}

final class QuoteIdle extends DeliveryQuoteState {
  const QuoteIdle();
}

final class QuoteLoading extends DeliveryQuoteState {
  const QuoteLoading();
}

final class QuoteReady extends DeliveryQuoteState {
  const QuoteReady(this.quote, {required this.signature});

  final DeliveryQuote quote;
  final String signature;
}

final class QuoteFailed extends DeliveryQuoteState {
  const QuoteFailed(this.failure);

  final DeliveryFailure failure;
}
