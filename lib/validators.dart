class Validators {
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
    return value.length >= 8 ? null : 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
  }

  static String? egyptianPhone(String? value, {bool optional = false}) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return optional ? null : 'أدخل رقم الهاتف';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final local = digits.startsWith('0020')
        ? digits.substring(2)
        : digits.startsWith('20')
            ? digits
            : '20$digits';
    final isEgyptianMobile = RegExp(r'^201[0125][0-9]{8}$').hasMatch(local);
    return isEgyptianMobile ? null : 'أدخل رقم هاتف مصري صحيحًا مثل 01XXXXXXXXX';
  }

  static String normalizeEgyptianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final national = digits.startsWith('0020')
        ? digits.substring(4)
        : digits.startsWith('20')
            ? digits.substring(2)
            : digits;
    return '+20$national';
  }

  static String? dateOfBirth(DateTime? value, {DateTime? today}) {
    if (value == null) return 'اختر تاريخ الميلاد';
    final current = today ?? DateTime.now();
    final selected = DateTime(value.year, value.month, value.day);
    final dateNow = DateTime(current.year, current.month, current.day);
    return selected.isAfter(dateNow) ? 'تاريخ الميلاد لا يمكن أن يكون في المستقبل' : null;
  }
}
