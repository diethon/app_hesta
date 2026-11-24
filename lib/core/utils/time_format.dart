/// "HH:mm:ss" from whatever the backend sent ("07:30", "07:30:15", "07:30:15.000").
String formatHms(String? time, {String fallback = '00:00:00'}) {
  final parts = (time == null || time.isEmpty ? fallback : time).split(':');
  String two(int i) =>
      (i < parts.length ? parts[i].split('.').first : '0').padLeft(2, '0');
  return '${two(0)}:${two(1)}:${two(2)}';
}

/// "22:03:00" → "22:03"; keeps the seconds only when they are set ("22:03:15").
String displayTime(String? time) {
  final hms = formatHms(time);
  return hms.endsWith(':00') ? hms.substring(0, 5) : hms;
}

/// Next run in plain words: "hôm nay 22:03", "ngày mai 07:00", "T4 26/11 22:03".
String formatNextRun(DateTime at, {DateTime? now}) {
  final t = at.toLocal();
  final today = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final hm = '${two(t.hour)}:${two(t.minute)}';
  final days = DateTime(t.year, t.month, t.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  if (days == 0) return 'hôm nay $hm';
  if (days == 1) return 'ngày mai $hm';
  const wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  return '${wd[t.weekday - 1]} ${two(t.day)}/${two(t.month)} $hm';
}
