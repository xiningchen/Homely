extension PhoneExtension on String {
  String normalizePhone() {
    final digitsOnly = replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length == 10) {
      return '+1$digitsOnly';
    }

    if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      return '+$digitsOnly';
    }

    return '+$digitsOnly';
  }
}
