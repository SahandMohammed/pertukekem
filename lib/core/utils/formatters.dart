import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date and time formatting utilities
class DateUtils {
  static final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormatter = DateFormat('MMM dd, yyyy HH:mm');
  static final DateFormat _shortDateFormatter = DateFormat('dd/MM/yyyy');

  /// Format date to readable string (e.g., "Jan 15, 2024")
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Format time to readable string (e.g., "14:30")
  static String formatTime(DateTime time) {
    return _timeFormatter.format(time);
  }

  /// Format date and time to readable string (e.g., "Jan 15, 2024 14:30")
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  /// Format date to short string (e.g., "15/01/2024")
  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  /// Get relative time string (e.g., "2 hours ago", "1 day ago")
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

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}

/// Currency formatting utilities
class CurrencyUtils {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: 'RM ',
    decimalDigits: 2,
  );

  /// Format amount to currency string (e.g., "RM 25.50")
  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Parse currency string to double
  static double? parseCurrency(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanValue);
  }
}

/// Number formatting utilities
class NumberUtils {
  /// Format number with thousand separators
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Format decimal number with specified decimal places
  static String formatDecimal(double number, {int decimalPlaces = 2}) {
    return number.toStringAsFixed(decimalPlaces);
  }

  /// Convert bytes to human readable format
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
