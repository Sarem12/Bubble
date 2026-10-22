import 'package:intl/intl.dart';

class DateHelpers {
  static String formatTimeAgo(dynamic dateInput) {
    if (dateInput == null) return '';
    try {
      final DateTime date;
      if (dateInput is DateTime) {
        date = dateInput.toLocal();
      } else {
        final dateString = dateInput.toString();
        if (dateString.isEmpty) return '';
        date = DateTime.parse(dateString).toLocal();
      }
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return DateFormat('MMM d, yyyy').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM yyyy').format(date.toLocal());
  }
}
