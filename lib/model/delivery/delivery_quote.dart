import 'package:sanga_ride/model/delivery/delivery_failure.dart';
import 'package:sanga_ride/model/trip/server_time.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class QuoteTier {
  const QuoteTier({required this.id, required this.fare, required this.etaMinutes, required this.isRecommended});

  factory QuoteTier.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    final etas = reader.raw['etaMinutes'];
    return QuoteTier(
      id: reader.str('id'),
      fare: reader.integer('fare'),
      etaMinutes: [
        if (etas is List)
          for (final minutes in etas)
            if (minutes is num) minutes.round(),
      ],
      isRecommended: reader.boolOr('recommended', false),
    );
  }

  final String id;
  final int fare;
  final List<int> etaMinutes;
  final bool isRecommended;
}

class DeliveryQuote {
  const DeliveryQuote({
    required this.quoteId,
    required this.expiresAt,
    required this.tiers,
    required this.recommendedTier,
  });

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
