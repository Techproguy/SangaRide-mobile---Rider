import 'package:flutter/services.dart';

extension HapticFunction0<R> on R Function()? {
  R Function()? _wrap(Future<void> Function() feedback) {
    if (this == null) return null;

    return () {
      feedback();
      return this!();
    };
  }

  R Function()? addLowHaptic() => _wrap(HapticFeedback.lightImpact);

  R Function()? addMediumHaptic() => _wrap(HapticFeedback.mediumImpact);

  R Function()? addHeavyHaptic() => _wrap(HapticFeedback.heavyImpact);
}

extension HapticFunction1<A, R> on R Function(A)? {
  R Function(A)? _wrap(Future<void> Function() feedback) {
    if (this == null) return null;

    return (a) {
      feedback();
      return this!(a);
    };
  }

  R Function(A)? addLowHaptic() => _wrap(HapticFeedback.lightImpact);

  R Function(A)? addMediumHaptic() => _wrap(HapticFeedback.mediumImpact);

  R Function(A)? addHeavyHaptic() => _wrap(HapticFeedback.heavyImpact);
}

extension HapticFunction2<A, B, R> on R Function(A, B)? {
  R Function(A, B)? _wrap(Future<void> Function() feedback) {
    if (this == null) return null;

    return (a, b) {
      feedback();
      return this!(a, b);
    };
  }

  R Function(A, B)? addLowHaptic() => _wrap(HapticFeedback.lightImpact);

  R Function(A, B)? addMediumHaptic() => _wrap(HapticFeedback.mediumImpact);

  R Function(A, B)? addHeavyHaptic() => _wrap(HapticFeedback.heavyImpact);
}
