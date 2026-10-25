import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hawaleek/app.dart';
import 'package:hawaleek/core.dart';
import 'package:hawaleek/validators.dart';

void main() {
  group('Validators', () {
    test('rejects blank names and accepts trimmed non-empty names', () {
      expect(Validators.requiredText('   ', 'الاسم'), isNotNull);
      expect(Validators.requiredText(' مريم ', 'الاسم'), isNull);
    });

    test('normalizes and validates email', () {
      expect(Validators.email('  patient@example.com  '), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('requires passwords to contain at least eight characters', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('safe-pass-1'), isNull);
    });

    test('accepts Egyptian mobile numbers in local and international forms', () {
      expect(Validators.egyptianPhone('01012345678'), isNull);
      expect(Validators.egyptianPhone('+20 101 234 5678'), isNull);
      expect(Validators.egyptianPhone('00201012345678'), isNull);
      expect(Validators.egyptianPhone('012345'), isNotNull);
      expect(Validators.egyptianPhone('', optional: true), isNull);
      expect(Validators.normalizeEgyptianPhone('01012345678'), '+201012345678');
    });

    test('rejects future birth dates and accepts past dates', () {
      final today = DateTime(2026, 10, 25);
      expect(Validators.dateOfBirth(DateTime(2026, 10, 26), today: today), isNotNull);
      expect(Validators.dateOfBirth(DateTime(2000, 1, 1), today: today), isNull);
      expect(Validators.dateOfBirth(null, today: today), isNotNull);
    });
  });

  testWidgets('role selection defaults to patient and updates selection', (tester) async {
    await tester.pumpWidget(const HawaleekApp(firebaseReady: false));

    expect(find.text('اختار دورك، وابدأ'), findsOneWidget);
    expect(find.text('مختار'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Semantics && widget.selected == true && widget.label!.contains('مريض')), findsOneWidget);

    await tester.tap(find.text('دكتور'));
    await tester.pumpAndSettle();

    expect(find.text('مختار'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Semantics && widget.selected == true && widget.label!.contains('دكتور')), findsOneWidget);
  });

  testWidgets('patient registration exposes patient-specific optional fields', (tester) async {
    await tester.pumpWidget(const HawaleekApp(firebaseReady: false));
    await tester.ensureVisible(find.text('متابعة'));
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('إنشاء حساب جديد'));
    await tester.tap(find.text('إنشاء حساب جديد'));
    await tester.pumpAndSettle();

    expect(find.text('الاسم بالكامل'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('تاريخ الميلاد'), findsOneWidget);
    expect(find.text('أمراض مزمنة (اختياري)'), findsOneWidget);
    expect(find.text('رقم طوارئ (اختياري)'), findsOneWidget);
  });

  testWidgets('doctor dashboard shows pending verification without patient records', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DashboardScreen(
        role: UserRole.doctor,
        profile: const {
          'fullName': 'طبيب تجريبي',
          'role': 'doctor',
          'verificationStatus': 'pending',
        },
      ),
    ));
    expect(find.text('لوحة الطبيب'), findsOneWidget);
    expect(find.text('حسابك قيد المراجعة الإدارية.'), findsOneWidget);
    expect(find.text('لا تتوفر سجلات مرضى حتى يتم اعتماد الحساب وتحديد نطاق وصول موثق.'), findsOneWidget);
  });
}
