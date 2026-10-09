import 'package:sanga_ride/model/account/load_problem.dart';
import 'package:sanga_ride/model/wallet/wallet_transaction.dart';
import 'package:sanga_ride_core/sanga_ride_core.dart';

class TransactionPage {
  const TransactionPage({required this.entries, required this.page, required this.hasMore});

  factory TransactionPage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return TransactionPage(
      entries: reader.listOf('transactions', (item) => WalletTransaction.fromJson(item.raw)),
      page: reader.intOr('page', 1),
      hasMore: reader.boolOr('hasMore', false),
    );
  }

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
  const TransactionsFailed(this.problem);

  final LoadProblem problem;
}

final class TransactionsLoaded extends TransactionFeed {
  const TransactionsLoaded(
    this.entries, {
    required this.page,
    required this.hasMore,
    this.more = TransactionMore.idle,
    this.isStale = false,
  });

  final List<WalletTransaction> entries;
  final int page;
  final bool hasMore;
  final TransactionMore more;
  final bool isStale;

  TransactionsLoaded withMore(TransactionMore next) =>
      TransactionsLoaded(entries, page: page, hasMore: hasMore, more: next, isStale: isStale);

  TransactionsLoaded markStale() =>
      TransactionsLoaded(entries, page: page, hasMore: hasMore, more: more, isStale: true);
}

enum TransactionFailure {
  notFound('We can’t find that transaction', 'It may have been removed. Head back to your history.', canRetry: false),
  connection('We couldn’t reach the server', 'Check your connection and give it another go.'),
  unknown('Something went wrong on our side', 'Try again in a moment.');

  const TransactionFailure(this.title, this.message, {this.canRetry = true});

  final String title;
  final String message;
  final bool canRetry;

  static TransactionFailure of(Object error) => switch (ProblemKind.of(error)) {
    ProblemRejected(code: 'transaction_not_found') => notFound,
    ProblemOffline() => connection,
    _ => unknown,
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
