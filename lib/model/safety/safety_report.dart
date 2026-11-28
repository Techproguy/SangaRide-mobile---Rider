import 'package:sanga_ride_core/sanga_ride_core.dart';

// TODO(#270): drop the built-in report categories and detail lengths when GET /safety/report-categories returns categories[], minDetails and maxDetails
enum ReportCategory {
  driving('driving', 'Unsafe driving'),
  harassment('harassment', 'Harassment'),
  vehicle('vehicle', 'Vehicle'),
  route('route', 'Wrong route'),
  other('other', 'Something else');

  const ReportCategory(this.code, this.label);

  final String code;
  final String label;
}

abstract final class SafetyReportRules {
  static const int minDetailsLength = 10;
  static const int maxDetailsLength = 500;

  static bool isReady(ReportCategory? category, String details) =>
      category != null && details.trim().length >= minDetailsLength;
}

class SafetyReportReceipt {
  const SafetyReportReceipt({required this.id, required this.reference});

  factory SafetyReportReceipt.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader.of(json);
    return SafetyReportReceipt(id: reader.str('id'), reference: reader.strOr('reference', ''));
  }

  final String id;
  final String reference;
}
