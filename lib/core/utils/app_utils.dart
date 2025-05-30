class AppUtils {
  static String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
