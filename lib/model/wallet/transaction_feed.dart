import 'package:sanga_ride/model/wallet/wallet_transaction.dart';

class TransactionPage {
  const TransactionPage({required this.entries, required this.page, required this.hasMore});

  factory TransactionPage.fromJson(Map<String, dynamic> json) => TransactionPage(
    entries: [
      for (final entry in json['transactions'] as List)
        WalletTransaction.fromJson(Map<String, dynamic>.from(entry as Map)),
    ],
    page: (json['page'] as num).toInt(),
    hasMore: json['hasMore'] as bool,
  );

  final List<WalletTransaction> entries;
  final int page;
  final bool hasMore;
}

enum TransactionMore { idle, loading, failed }

sealed class TransactionFeed {
  const TransactionFeed();
}

final class TransactionsLoading extends TransactionFeed {
  const TransactionsLoading();
}

final class TransactionsFailed extends TransactionFeed {
  const TransactionsFailed();
}

final class TransactionsLoaded extends TransactionFeed {
  const TransactionsLoaded(this.entries, {required this.page, required this.hasMore, this.more = TransactionMore.idle});

  final List<WalletTransaction> entries;
  final int page;
  final bool hasMore;
  final TransactionMore more;

  TransactionsLoaded withMore(TransactionMore next) =>
      TransactionsLoaded(entries, page: page, hasMore: hasMore, more: next);
}

enum TransactionFailure {
  notFound('We can’t find that transaction', 'It may have been removed. Head back to your history.', canRetry: false),
  connection('We couldn’t reach the server', 'Check your connection and give it another go.');

  const TransactionFailure(this.title, this.message, {this.canRetry = true});

  final String title;
  final String message;
  final bool canRetry;

  static TransactionFailure fromCode(String? code) => switch (code) {
    'transaction_not_found' => notFound,
    _ => connection,
  };
}

sealed class TransactionDetailState {
  const TransactionDetailState();
}

final class TransactionDetailLoading extends TransactionDetailState {
  const TransactionDetailLoading();
}

final class TransactionDetailFailed extends TransactionDetailState {
  const TransactionDetailFailed(this.failure);

  final TransactionFailure failure;
}

final class TransactionDetailLoaded extends TransactionDetailState {
  const TransactionDetailLoaded(this.transaction);

  final WalletTransaction transaction;
}
