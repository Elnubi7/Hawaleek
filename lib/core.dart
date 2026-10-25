import 'package:flutter/material.dart';

const navy = Color(0xFF19192D);
const gray = Color(0xFFA9A9B0);
const lightBlue = Color(0xFFEAF0FC);
const patientPink = Color(0xFFFBE4F8);
const familyBlue = Color(0xFFDDE7FC);
const doctorGreen = Color(0xFFF1FBE3);
const selectedGreen = Color(0xFF24785E);
const secondaryText = Color(0xFF656575);

enum UserRole { patient, family, doctor }

extension UserRoleText on UserRole {
  String get label => switch (this) {
        UserRole.patient => 'مريض',
        UserRole.family => 'فرد عائلة',
        UserRole.doctor => 'دكتور',
      };

  String get value => name;

  static UserRole parse(Object? value) => UserRole.values.firstWhere(
        (role) => role.value == value,
        orElse: () => UserRole.patient,
      );
}

class AppTheme {
  static ThemeData get data => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          surface: Colors.white,
        ),
        fontFamily: 'Cairo',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: navy,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
          titleLarge: TextStyle(
            color: navy,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(color: secondaryText, fontSize: 15, height: 1.5),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFE7E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: selectedGreen, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      );
}

class HawaleekButton extends StatelessWidget {
  const HawaleekButton({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          child: busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(label),
        ),
      );
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('حواليك', style: TextStyle(color: selectedGreen, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                    const SizedBox(height: 10),
                    Text(title, style: Theme.of(context).textTheme.headlineMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 7),
                      Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.controller, this.hint, this.validator, this.keyboardType, this.obscureText = false, this.onTap, this.readOnly = false, this.suffix, this.maxLines = 1, this.textDirection});

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffix;
  final int maxLines;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 6),
              child: Text(label, style: const TextStyle(color: navy, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              obscureText: obscureText,
              readOnly: readOnly,
              onTap: onTap,
              maxLines: maxLines,
              textDirection: textDirection,
              textAlign: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right,
              decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
            ),
          ],
        ),
      );
}

class FormPanel extends StatelessWidget {
  const FormPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: const Color(0xFFF4F4F6), borderRadius: BorderRadius.circular(24)),
        child: child,
      );
}
