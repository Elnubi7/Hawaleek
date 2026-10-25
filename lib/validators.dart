class Validators {
  static const egyptianCountryPrefix = '+20';

  static String? requiredText(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'أدخل $label من فضلك' : null;

  static String? email(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'أدخل البريد الإلكتروني';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)
        ? null
        : 'أدخل بريدًا إلكترونيًا صحيحًا';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'أدخل كلمة المرور';
    return value.length >= 8
        ? null
        : 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
  }

  static String? egyptianPhone(String? value, {bool optional = false}) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return optional ? null : 'أدخل رقم الهاتف';
    final national = egyptianPhoneNationalPart(phone);
    final isEgyptianMobile = RegExp(r'^1[0125][0-9]{8}$').hasMatch(national);
    return isEgyptianMobile
        ? null
        : 'أدخل رقم هاتف مصري صحيحًا مثل 01XXXXXXXXX';
  }

  static String normalizeEgyptianPhone(String value) {
    return '$egyptianCountryPrefix${egyptianPhoneNationalPart(value)}';
  }

  static String egyptianPhoneNationalPart(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    var national = digits.startsWith('0020')
        ? digits.substring(4)
        : digits.startsWith('20')
        ? digits.substring(2)
        : digits.startsWith('0')
        ? digits.substring(1)
        : digits;
    if (national.startsWith('0')) national = national.substring(1);
    return national;
  }
}
