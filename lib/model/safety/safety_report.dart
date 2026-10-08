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

  factory SafetyReportReceipt.fromJson(Map<String, dynamic> json) =>
      SafetyReportReceipt(id: json['id'] as String, reference: json['reference'] as String);

  final String id;
  final String reference;
}
