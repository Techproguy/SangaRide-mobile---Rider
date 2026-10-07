enum DurationFormat { hour, mins, secs }

extension DurationFormatting on Duration {
  String format({DurationFormat format = DurationFormat.mins}) {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    switch (format) {
      case DurationFormat.hour:
        return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';

      case DurationFormat.mins:
        final totalMinutes = inMinutes;
        return '${twoDigits(totalMinutes)}:${twoDigits(seconds)}';

      case DurationFormat.secs:
        return twoDigits(inSeconds);
    }
  }
}
