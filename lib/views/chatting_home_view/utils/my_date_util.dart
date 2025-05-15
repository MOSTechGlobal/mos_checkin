import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyDateUtil {
  static String getFormattedTime({
    required BuildContext context,
    required Timestamp time,
  }) {
    final dt = time.toDate();
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  static String getLastActiveTime({
    required BuildContext context,
    required dynamic lastActive,
  }) {
    DateTime dt;
    if (lastActive is Timestamp) {
      dt = lastActive.toDate();
    } else if (lastActive is String) {
      dt = DateTime.fromMillisecondsSinceEpoch(int.parse(lastActive));
    } else {
      throw ArgumentError('lastActive must be a String or Timestamp');
    }
    return '${dt.day} ${_getMonthName(dt.month)} ${dt.year}, ${TimeOfDay.fromDateTime(dt).format(context)}';
  }

  static String getLastActiveTimeOnly({
    required BuildContext context,
    required dynamic lastActive,
  }) {
    DateTime dt;
    if (lastActive is Timestamp) {
      dt = lastActive.toDate();
    } else if (lastActive is String) {
      dt = DateTime.fromMillisecondsSinceEpoch(int.parse(lastActive));
    } else {
      throw ArgumentError('lastActive must be a String or Timestamp');
    }
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  static String getMessageDateLabel(BuildContext context, Timestamp sent) {
    final date = sent.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(messageDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  static String _getMonthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }
}