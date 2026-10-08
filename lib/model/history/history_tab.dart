import 'package:sanga_ride/model/history/history_item.dart';

enum HistoryTab {
  completed('Completed', HistoryStatus.completed),
  cancelled('Cancelled', HistoryStatus.cancelled),
  scheduled('Scheduled', null);

  const HistoryTab(this.label, this.status);

  final String label;
  final HistoryStatus? status;
}
