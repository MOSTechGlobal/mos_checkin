// calculateShiftDuration(shift['StartTime'], shift['EndTime'])

String calculateShiftDuration(String startTime, String endTime) {
  final DateTime start = DateTime.parse(startTime);
  final DateTime end = DateTime.parse(endTime);
  final Duration difference = end.difference(start);
  final int hours = difference.inHours;
  final int minutes = difference.inMinutes.remainder(60);
  return minutes == 0 ? '$hours hr' : '$hours hr $minutes m';
}
