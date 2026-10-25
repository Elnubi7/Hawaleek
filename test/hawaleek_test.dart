import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hawaleek/app.dart';
import 'package:hawaleek/core.dart';
import 'package:hawaleek/validators.dart';

void main() {
  group('Validators', () {
    test('only family and doctor are selectable roles', () {
      expect(UserRole.values.map((role) => role.value), ['family', 'doctor']);
    });

    test('rejects blank names and accepts trimmed non-empty names', () {
      expect(Validators.requiredText('   ', 'الاسم'), isNotNull);
      expect(Validators.requiredText(' مريم ', 'الاسم'), isNull);
    });

    test('normalizes and validates email', () {
      expect(Validators.email('  member@example.com  '), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('requires passwords to contain at least eight characters', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('safe-pass-1'), isNull);
    });

    test(
      'accepts Egyptian mobile numbers in local and international forms',
      () {
        expect(Validators.egyptianCountryPrefix, '+20');
        expect(Validators.egyptianPhone('01012345678'), isNull);
        expect(Validators.egyptianPhone('1012345678'), isNull);
        expect(Validators.egyptianPhone('+20 101 234 5678'), isNull);
        expect(Validators.egyptianPhone('00201012345678'), isNull);
        expect(Validators.egyptianPhone('012345'), isNotNull);
        expect(Validators.egyptianPhone('', optional: true), isNull);
        expect(
          Validators.normalizeEgyptianPhone('01012345678'),
          '+201012345678',
        );
        expect(
          Validators.normalizeEgyptianPhone('1012345678'),
          '+201012345678',
        );
        expect(
          Validators.normalizeEgyptianPhone('+20 101 234 5678'),
          '+201012345678',
        );
      },
    );
  });

  testWidgets('role selection defaults to family and updates selection', (
    tester,
  ) async {
    await tester.pumpWidget(const HawaleekApp(firebaseReady: false));

    expect(find.text('اختار دورك، وابدأ'), findsOneWidget);
    expect(find.text('مريض'), findsNothing);
    expect(find.text('مختار'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.selected == true &&
            widget.label!.contains('فرد عائلة'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('دكتور'));
    await tester.pumpAndSettle();

    expect(find.text('مختار'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.selected == true &&
            widget.label!.contains('دكتور'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'family registration keeps shared identity and emergency fields',
    (tester) async {
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
      expect(find.text('رقم طوارئ (اختياري)'), findsOneWidget);
      expect(find.text('صلة القرابة (اختياري)'), findsOneWidget);
    },
  );

  testWidgets(
    'doctor registration remains available without family or patient fields',
    (tester) async {
      await tester.pumpWidget(const HawaleekApp(firebaseReady: false));
      await tester.tap(find.text('دكتور'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('متابعة'));
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('إنشاء حساب جديد'));
      await tester.tap(find.text('إنشاء حساب جديد'));
      await tester.pumpAndSettle();

      expect(find.text('التخصص (اختياري)'), findsOneWidget);
      expect(find.text('رقم طوارئ (اختياري)'), findsOneWidget);
      expect(find.text('مريض'), findsNothing);
      expect(find.text('تاريخ الميلاد'), findsNothing);
      expect(find.text('أمراض مزمنة (اختياري)'), findsNothing);
    },
  );

  testWidgets(
    'doctor dashboard shows pending verification without patient records',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            role: UserRole.doctor,
            profile: const {
              'fullName': 'طبيب تجريبي',
              'role': 'doctor',
              'verificationStatus': 'pending',
            },
          ),
        ),
      );
      expect(find.text('لوحة الطبيب'), findsOneWidget);
      expect(find.text('حسابك قيد المراجعة الإدارية.'), findsOneWidget);
      expect(
        find.text(
          'لا تتوفر سجلات مرضى حتى يتم اعتماد الحساب وتحديد نطاق وصول موثق.',
        ),
        findsOneWidget,
      );
    },
  );
}
