import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateUtils {
  static final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormatter = DateFormat('MMM dd, yyyy HH:mm');
  static final DateFormat _shortDateFormatter = DateFormat('dd/MM/yyyy');

  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormatter.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}

class CurrencyUtils {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  static double? parseCurrency(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanValue);
  }
}

class NumberUtils {
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  static String formatDecimal(double number, {int decimalPlaces = 2}) {
    return number.toStringAsFixed(decimalPlaces);
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
