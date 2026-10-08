import 'package:sanga_ride/model/delivery/delivery_failure.dart';
import 'package:sanga_ride/model/trip/server_time.dart';

class QuoteTier {
  const QuoteTier({required this.id, required this.fare, required this.etaMinutes, required this.isRecommended});

  factory QuoteTier.fromJson(Map<String, dynamic> json) => QuoteTier(
    id: json['id'] as String,
    fare: (json['fare'] as num).toInt(),
    etaMinutes: [for (final minutes in json['etaMinutes'] as List) (minutes as num).toInt()],
    isRecommended: json['recommended'] as bool? ?? false,
  );

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
    final serverTime = DateTime.parse(json['serverTime'] as String);
    return DeliveryQuote(
      quoteId: json['quoteId'] as String,
      expiresAt: deadlineAfter(serverTime, json['expiresAt'] as String),
      tiers: [for (final tier in json['tiers'] as List) QuoteTier.fromJson(Map<String, dynamic>.from(tier as Map))],
      recommendedTier: json['recommendedTier'] as String?,
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
