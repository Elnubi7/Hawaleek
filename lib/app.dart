import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'core.dart';
import 'validators.dart';

class HawaleekApp extends StatelessWidget {
  const HawaleekApp({super.key, required this.firebaseReady});
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'حواليك',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.data,
        home: AuthGate(firebaseReady: firebaseReady),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.firebaseReady});
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) return const RoleSelectionScreen(firebaseReady: false);
    return StreamBuilder<User?>(
      stream: AuthService.instance.authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: navy)));
        }
        final user = snapshot.data;
        if (user == null) return const RoleSelectionScreen(firebaseReady: true);
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          key: ValueKey(user.uid),
          stream: AuthService.instance.profileChanges(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: navy)));
            }
            if (profileSnapshot.hasError) {
              return _ProblemScreen(message: firebaseMessage(profileSnapshot.error!), retry: () => (context as Element).markNeedsBuild());
            }
            final document = profileSnapshot.data;
            final profile = document?.data();
            if (profile == null || profile['role'] == null) {
              return const _IncompleteProfileScreen();
            }
            if (profile['isActive'] == false) {
              return const _ProblemScreen(message: 'تم إيقاف هذا الحساب. تواصل مع الدعم.');
            }
            final role = UserRoleText.parse(profile['role']);
            return DashboardScreen(role: role, profile: profile);
          },
        );
      },
    );
  }
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key, required this.firebaseReady});
  final bool firebaseReady;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selected = UserRole.patient;

  @override
  Widget build(BuildContext context) {
    final options = [
      (UserRole.patient, 'مريض', 'تابع صحتك، خد دوائك، واطلب مساعدة', patientPink, Icons.favorite_rounded),
      (UserRole.family, 'فرد عائلة', 'تابع حد بتحبه واستقبل التنبيهات', familyBlue, Icons.people_alt_rounded),
      (UserRole.doctor, 'دكتور', 'تابع المرضى المسجلين لديك وراجع بياناتهم', doctorGreen, Icons.medical_services_rounded),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 30, 22, 18),
                      children: [
                        const Text('حواليك', style: TextStyle(color: selectedGreen, fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        Text('اختار دورك، وابدأ', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 25),
                        for (final option in options)
                          _RoleCard(
                            role: option.$1,
                            title: option.$2,
                            description: option.$3,
                            color: option.$4,
                            icon: option.$5,
                            selected: _selected == option.$1,
                            onTap: () => setState(() => _selected = option.$1),
                          ),
                        const SizedBox(height: 7),
                        HawaleekButton(
                          label: 'متابعة',
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => LoginScreen(role: _selected, firebaseReady: widget.firebaseReady),
                          )),
                        ),
                        if (!widget.firebaseReady) ...[
                          const SizedBox(height: 13),
                          const Text('يلزم ربط مشروع Firebase لتفعيل الحسابات وحفظ البيانات.', textAlign: TextAlign.center, style: TextStyle(color: secondaryText, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  const _ReferenceBottomBar(active: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.title, required this.description, required this.color, required this.icon, required this.selected, required this.onTap});
  final UserRole role;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '$title، $description${selected ? '، مختار' : ''}',
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? selectedGreen : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), shape: BoxShape.circle), child: Icon(icon, color: navy)),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 18)), const SizedBox(height: 3), Text(description, style: const TextStyle(color: secondaryText, fontSize: 13, height: 1.4))])),
                if (selected) Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: selectedGreen, borderRadius: BorderRadius.circular(20)), child: const Text('مختار', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        ),
      );
}

class _ReferenceBottomBar extends StatelessWidget {
  const _ReferenceBottomBar({required this.active, this.onSelected, this.disabledItems = const {}});
  final int active;
  final ValueChanged<int>? onSelected;
  final Set<int> disabledItems;

  @override
  Widget build(BuildContext context) {
    const icons = [Icons.person_outline_rounded, Icons.favorite_border_rounded, Icons.notifications_none_rounded, Icons.home_outlined];
    const labels = ['الملف الشخصي', 'العائلة', 'الإشعارات', 'الرئيسية'];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 9, 18, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final isActive = active == index;
            final enabled = onSelected != null && !disabledItems.contains(index);
            return Semantics(
              button: enabled,
              enabled: enabled,
              label: enabled ? labels[index] : '${labels[index]} غير متاح',
              child: InkWell(
                onTap: enabled ? () => onSelected!(index) : null,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: isActive ? lightBlue : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .09), blurRadius: 12, offset: const Offset(0, 3))]),
                  child: Icon(icons[index], color: isActive ? navy : gray, size: 23),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.role, required this.firebaseReady});
  final UserRole role;
  final bool firebaseReady;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.firebaseReady) { setState(() => _error = 'أكمل إعداد Firebase لتسجيل الدخول.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await AuthService.instance.signIn(_email.text, _password.text);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) setState(() => _error = firebaseMessage(error));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'أهلًا بيك',
        subtitle: 'سجّل الدخول للمتابعة كـ ${widget.role.label}',
        child: Column(children: [
          if (!widget.firebaseReady) const _FirebaseSetupBanner(),
          FormPanel(child: Form(key: _formKey, child: Column(children: [
            LabeledField(label: 'البريد الإلكتروني', controller: _email, hint: 'name@example.com', textDirection: TextDirection.ltr, keyboardType: TextInputType.emailAddress, validator: Validators.email),
            LabeledField(label: 'كلمة المرور', controller: _password, obscureText: !_showPassword, validator: (value) => value == null || value.isEmpty ? 'أدخل كلمة المرور' : null, suffix: IconButton(tooltip: _showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور', onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility))),
          ]))),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 15),
          HawaleekButton(label: 'تسجيل الدخول', onPressed: _login, busy: _busy),
          TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PasswordResetScreen(firebaseReady: widget.firebaseReady))), child: const Text('نسيت كلمة المرور؟')),
          TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RegistrationScreen(role: widget.role, firebaseReady: widget.firebaseReady))), child: const Text('إنشاء حساب جديد')),
        ]),
      );
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.role, required this.firebaseReady});
  final UserRole role;
  final bool firebaseReady;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _diseases = TextEditingController();
  final _emergency = TextEditingController();
  final _relationship = TextEditingController();
  final _specialty = TextEditingController();
  DateTime? _dateOfBirth;
  bool _busy = false;
  bool _showPassword = false;
  bool _profileRetry = false;
  String? _error;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); _phone.dispose(); _diseases.dispose(); _emergency.dispose(); _relationship.dispose(); _specialty.dispose(); super.dispose(); }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final value = await showDatePicker(context: context, initialDate: DateTime(today.year - 25, today.month, today.day), firstDate: DateTime(1900), lastDate: today, helpText: 'اختر تاريخ الميلاد', cancelText: 'إلغاء', confirmText: 'اختيار');
    if (value != null) setState(() => _dateOfBirth = value);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.role == UserRole.patient && Validators.dateOfBirth(_dateOfBirth) != null) { setState(() => _error = 'اختر تاريخ ميلاد صحيحًا قبل اليوم.'); return; }
    if (!widget.firebaseReady) { setState(() => _error = 'أكمل إعداد Firebase لإنشاء الحساب وحفظ الملف.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      if (_profileRetry) {
        await AuthService.instance.saveCurrentProfile(
          role: widget.role,
          fullName: _name.text,
          email: _email.text,
          phoneNumber: _phone.text,
          dateOfBirth: _dateOfBirth,
          chronicDiseases: _diseases.text,
          emergencyContact: _emergency.text,
          relationship: _relationship.text,
          specialty: _specialty.text,
        );
      } else {
        await AuthService.instance.register(
          role: widget.role,
          fullName: _name.text,
          email: _email.text,
          password: _password.text,
          phoneNumber: _phone.text,
          dateOfBirth: _dateOfBirth,
          chronicDiseases: _diseases.text,
          emergencyContact: _emergency.text,
          relationship: _relationship.text,
          specialty: _specialty.text,
        );
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) setState(() {
        _profileRetry = AuthService.instance.currentUser?.email?.toLowerCase() == _email.text.trim().toLowerCase();
        _error = _profileRetry
            ? 'تم إنشاء حساب الدخول، لكن لم يُحفظ الملف بعد. تحقق من اتصالك أو قواعد Firestore ثم أعد المحاولة.'
            : firebaseMessage(error);
      });
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'إنشاء حساب ${widget.role.label}',
        subtitle: 'أدخل بياناتك لإعداد ملفك الشخصي',
        child: Column(children: [
          if (!widget.firebaseReady) const _FirebaseSetupBanner(),
          FormPanel(child: Form(key: _formKey, child: Column(children: [
            LabeledField(label: 'الاسم بالكامل', controller: _name, validator: (value) => Validators.requiredText(value, 'الاسم بالكامل')),
            LabeledField(label: 'البريد الإلكتروني', controller: _email, hint: 'name@example.com', textDirection: TextDirection.ltr, keyboardType: TextInputType.emailAddress, validator: Validators.email),
            LabeledField(label: 'كلمة المرور', controller: _password, obscureText: !_showPassword, validator: Validators.password, suffix: IconButton(tooltip: _showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور', onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility))),
            LabeledField(label: 'رقم الهاتف', controller: _phone, hint: '01XXXXXXXXX', keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, validator: Validators.egyptianPhone),
            if (widget.role == UserRole.patient) ...[
              Padding(padding: const EdgeInsets.only(bottom: 13), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Padding(padding: EdgeInsets.only(right: 4, bottom: 6), child: Text('تاريخ الميلاد', style: TextStyle(color: navy, fontWeight: FontWeight.w600))), InkWell(onTap: _pickBirthDate, child: InputDecorator(decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_month_outlined)), child: Text(_dateOfBirth == null ? 'اختر تاريخ الميلاد' : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}', style: TextStyle(color: _dateOfBirth == null ? secondaryText : navy))))])),
              LabeledField(label: 'أمراض مزمنة (اختياري)', controller: _diseases, hint: 'معلومات صحية حساسة، أدخل ما ترغب بمشاركته فقط', maxLines: 3),
              LabeledField(label: 'رقم طوارئ (اختياري)', controller: _emergency, hint: '01XXXXXXXXX', keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, validator: (value) => Validators.egyptianPhone(value, optional: true)),
            ],
            if (widget.role == UserRole.family) LabeledField(label: 'صلة القرابة (اختياري)', controller: _relationship, hint: 'مثال: ابنة، أخ، زوجة'),
            if (widget.role == UserRole.doctor) LabeledField(label: 'التخصص (اختياري)', controller: _specialty, hint: 'مثال: طب الأسرة'),
            if (widget.role == UserRole.doctor) const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('سيظل حساب الطبيب قيد المراجعة حتى التحقق الإداري.', style: TextStyle(color: secondaryText, fontSize: 12))),
          ]))),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 14),
          HawaleekButton(label: _profileRetry ? 'إعادة محاولة حفظ الملف' : 'إنشاء الحساب', onPressed: _register, busy: _busy),
        ]),
      );
}

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key, required this.firebaseReady});
  final bool firebaseReady;
  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _message;
  bool _isError = false;
  @override
  void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.firebaseReady) { setState(() { _message = 'أكمل إعداد Firebase أولًا.'; _isError = true; }); return; }
    setState(() { _busy = true; _message = null; });
    try {
      await AuthService.instance.sendPasswordReset(_email.text);
      setState(() { _message = 'إذا كان البريد مسجلًا، ستصلك رسالة لإعادة تعيين كلمة المرور.'; _isError = false; });
    } catch (error) { setState(() { _message = firebaseMessage(error); _isError = true; }); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => PageFrame(title: 'استعادة كلمة المرور', subtitle: 'أدخل بريدك الإلكتروني وسنرسل رابط الاستعادة.', child: Column(children: [FormPanel(child: Form(key: _formKey, child: LabeledField(label: 'البريد الإلكتروني', controller: _email, textDirection: TextDirection.ltr, keyboardType: TextInputType.emailAddress, validator: Validators.email))), if (_message != null) _ErrorText(_message!, isError: _isError), const SizedBox(height: 14), HawaleekButton(label: 'إرسال رابط الاستعادة', onPressed: _send, busy: _busy)]));
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.role, required this.profile});
  final UserRole role;
  final Map<String, dynamic> profile;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 3;
  @override
  Widget build(BuildContext context) {
    final pages = [
      ProfileScreen(profile: widget.profile),
      FamilyLinksScreen(role: widget.role),
      const NotificationsScreen(),
      _homePage(),
    ];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: pages[_index]))),
      bottomNavigationBar: _ReferenceBottomBar(
        active: _index,
        onSelected: (index) => setState(() => _index = index),
        disabledItems: widget.role == UserRole.doctor ? const {1} : const {},
      ),
    ));
  }

  Widget _homePage() {
    final name = widget.profile['fullName'] as String? ?? 'مرحبًا';
    return ListView(padding: const EdgeInsets.fromLTRB(22, 26, 22, 24), children: [
      Text(switch (widget.role) { UserRole.patient => 'الرئيسية', UserRole.family => 'متابعة الأسرة', UserRole.doctor => 'لوحة الطبيب' }, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text('أهلًا $name', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 22),
      if (widget.role == UserRole.patient) ...[
        _InfoCard(icon: Icons.health_and_safety_outlined, title: 'ملفك الصحي', text: 'بياناتك الصحية محفوظة في ملفك الشخصي. لا توجد قياسات أو تشخيصات مضافة.'),
        if ((widget.profile['chronicDiseases'] as String?)?.isNotEmpty ?? false) _InfoCard(icon: Icons.lock_outline, title: 'معلومات صحية خاصة', text: widget.profile['chronicDiseases'] as String),
        _InfoCard(icon: Icons.people_outline, title: 'طلبات أفراد العائلة', text: 'راجع الطلبات ووافق فقط على الأشخاص الذين تعرفهم.', action: () => setState(() => _index = 1)),
      ],
      if (widget.role == UserRole.family) ...[
        const _InfoCard(icon: Icons.privacy_tip_outlined, title: 'خصوصية المريض', text: 'لن تظهر أي معلومات خاصة قبل موافقة المريض على طلب الربط.'),
        _InfoCard(icon: Icons.link, title: 'طلب ربط بمريض', text: 'استخدم معرّف حساب المريض لإرسال طلب موافقة.', action: () => setState(() => _index = 1)),
      ],
      if (widget.role == UserRole.doctor) ...[
        _InfoCard(icon: Icons.verified_user_outlined, title: 'حالة التحقق', text: _verificationText(widget.profile['verificationStatus'])),
        const _InfoCard(icon: Icons.medical_information_outlined, title: 'الوصول السريري', text: 'لا تتوفر سجلات مرضى حتى يتم اعتماد الحساب وتحديد نطاق وصول موثق.'),
      ],
      _InfoCard(icon: Icons.notifications_none, title: 'الإشعارات', text: 'لا توجد إشعارات حاليًا. تنبيهات الدفع لم يتم إعدادها بعد.', action: () => setState(() => _index = 2)),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () async { await AuthService.instance.signOut(); }, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
    ]);
  }

  String _verificationText(Object? status) => switch (status) { 'verified' => 'تم التحقق من الحساب.', 'rejected' => 'لم تتم الموافقة على الحساب. تواصل مع الإدارة.', _ => 'حسابك قيد المراجعة الإدارية.' };
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _name = TextEditingController(text: widget.profile['fullName'] as String? ?? '');
  late final _phone = TextEditingController(text: widget.profile['phoneNumber'] as String? ?? '');
  late final _email = TextEditingController(text: widget.profile['email'] as String? ?? '');
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _name.dispose(); _phone.dispose(); _email.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try { await AuthService.instance.updateOwnProfile(fullName: _name.text, phoneNumber: _phone.text); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الملف الشخصي'))); }
    catch (error) { if (mounted) setState(() => _error = firebaseMessage(error)); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(22, 26, 22, 24), children: [
    Text('الملف الشخصي', style: Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height: 20),
    FormPanel(child: Form(key: _formKey, child: Column(children: [
      LabeledField(label: 'الاسم بالكامل', controller: _name, validator: (value) => Validators.requiredText(value, 'الاسم')),
      LabeledField(label: 'البريد الإلكتروني', controller: _email, readOnly: true, textDirection: TextDirection.ltr),
      LabeledField(label: 'رقم الهاتف', controller: _phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, validator: Validators.egyptianPhone),
      Padding(padding: const EdgeInsets.only(bottom: 14), child: Align(alignment: Alignment.centerRight, child: Text('الدور: ${UserRoleText.parse(widget.profile['role']).label}', style: const TextStyle(color: secondaryText)))),
      HawaleekButton(label: 'حفظ التعديلات', onPressed: _save, busy: _busy),
    ]))),
    if (_error != null) _ErrorText(_error!),
    if (widget.profile['dateOfBirth'] is Timestamp) Padding(padding: const EdgeInsets.only(top: 15), child: Text('تاريخ الميلاد: ${(widget.profile['dateOfBirth'] as Timestamp).toDate().toLocal().toString().split(' ').first}')),
  ]);
}

class FamilyLinksScreen extends StatefulWidget {
  const FamilyLinksScreen({super.key, required this.role});
  final UserRole role;
  @override
  State<FamilyLinksScreen> createState() => _FamilyLinksScreenState();
}

class _FamilyLinksScreenState extends State<FamilyLinksScreen> {
  final _patientUid = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _patientUid.dispose(); super.dispose(); }

  Future<void> _request() async {
    if (_patientUid.text.trim().isEmpty) { setState(() => _error = 'أدخل معرّف حساب المريض.'); return; }
    setState(() { _busy = true; _error = null; });
    try { await AuthService.instance.createFamilyRequest(_patientUid.text); _patientUid.clear(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الربط للمريض'))); }
    catch (error) { if (mounted) setState(() => _error = firebaseMessage(error)); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) return const Center(child: Text('سجّل الدخول لعرض الروابط.'));
    final patient = widget.role == UserRole.patient;
    final stream = patient ? AuthService.instance.patientRequests(user.uid) : AuthService.instance.familyLinks(user.uid);
    return ListView(padding: const EdgeInsets.fromLTRB(22, 26, 22, 24), children: [
      Text(patient ? 'طلبات أفراد العائلة' : widget.role == UserRole.family ? 'روابط الأسرة' : 'روابط المرضى', style: Theme.of(context).textTheme.headlineMedium),
      if (widget.role == UserRole.family) ...[
        const SizedBox(height: 12),
        const Text('أرسل طلبًا باستخدام معرّف المريض. لن تحصل على معلوماته إلا بعد موافقته.'),
        const SizedBox(height: 12),
        FormPanel(child: Column(children: [LabeledField(label: 'معرّف حساب المريض', controller: _patientUid, textDirection: TextDirection.ltr), HawaleekButton(label: 'إرسال طلب الربط', onPressed: _request, busy: _busy)])),
        if (_error != null) _ErrorText(_error!),
      ],
      const SizedBox(height: 17),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: stream, builder: (context, snapshot) {
        if (snapshot.hasError) return _ErrorText(firebaseMessage(snapshot.error!));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: navy));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const _InfoCard(icon: Icons.people_outline, title: 'لا توجد طلبات', text: 'ستظهر هنا طلبات الربط وحالاتها.');
        return Column(children: docs.map((doc) {
          final data = doc.data();
          final status = data['status'] as String? ?? 'pending';
          final otherUid = patient ? data['familyUid'] : data['patientUid'];
          final canManage = patient && (status == 'pending' || status == 'approved');
          return Card(color: lightBlue, child: ListTile(title: Text(patient ? 'طلب من فرد عائلة' : 'طلب إلى مريض'), subtitle: Text('معرّف الطرف الآخر: $otherUid\nالحالة: ${_status(status)}'), isThreeLine: true, trailing: canManage ? PopupMenuButton<String>(tooltip: 'الإجراء', onSelected: (value) async { try { await AuthService.instance.setFamilyRequestStatus(doc.id, value); } catch (error) { if (mounted) setState(() => _error = firebaseMessage(error)); } }, itemBuilder: (_) => status == 'pending' ? const [PopupMenuItem(value: 'approved', child: Text('موافقة')), PopupMenuItem(value: 'rejected', child: Text('رفض'))] : const [PopupMenuItem(value: 'revoked', child: Text('إلغاء الربط'))]) : null));
        }).toList());
      }),
    ]);
  }

  String _status(String status) => switch (status) { 'approved' => 'مقبول', 'rejected' => 'مرفوض', 'revoked' => 'ملغي', _ => 'قيد الانتظار' };
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(22, 26, 22, 24), children: [Text('الإشعارات', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 20), const _InfoCard(icon: Icons.notifications_none, title: 'لا توجد إشعارات', text: 'الإشعارات الفورية لم يتم إعدادها بعد.')]);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.text, this.action});
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Card(color: lightBlue, elevation: 0, margin: const EdgeInsets.only(bottom: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: ListTile(leading: Icon(icon, color: navy), title: Text(title, style: const TextStyle(color: navy, fontWeight: FontWeight.w700)), subtitle: Text(text), onTap: action));
}

class _FirebaseSetupBanner extends StatelessWidget {
  const _FirebaseSetupBanner();
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF4D8), borderRadius: BorderRadius.circular(15)), child: const Text('Firebase غير مربوط حاليًا. أضف إعدادات مشروعك لتفعيل تسجيل الدخول وقاعدة البيانات.', style: TextStyle(color: navy, fontSize: 13)));
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message, {this.isError = true});
  final String message;
  final bool isError;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 10), child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: isError ? Colors.red.shade700 : selectedGreen, fontSize: 13)));
}

class _ProblemScreen extends StatelessWidget {
  const _ProblemScreen({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => PageFrame(title: 'تعذر تحميل الحساب', child: Column(children: [Text(message), const SizedBox(height: 18), if (retry != null) HawaleekButton(label: 'إعادة المحاولة', onPressed: retry), const SizedBox(height: 10), TextButton(onPressed: () async => AuthService.instance.signOut(), child: const Text('تسجيل الخروج'))]));
}

class _IncompleteProfileScreen extends StatefulWidget {
  const _IncompleteProfileScreen();
  @override
  State<_IncompleteProfileScreen> createState() => _IncompleteProfileScreenState();
}

class _IncompleteProfileScreenState extends State<_IncompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _diseases = TextEditingController();
  final _emergency = TextEditingController();
  final _relationship = TextEditingController();
  final _specialty = TextEditingController();
  final _email = AuthService.instance.currentUser?.email ?? '';
  late final _emailController = TextEditingController(text: _email);
  UserRole _role = UserRole.patient;
  DateTime? _birthDate;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _diseases.dispose();
    _emergency.dispose();
    _relationship.dispose();
    _specialty.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == UserRole.patient && Validators.dateOfBirth(_birthDate) != null) {
      setState(() => _error = 'اختر تاريخ ميلاد صحيحًا قبل اليوم.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await AuthService.instance.saveCurrentProfile(
        role: _role,
        fullName: _name.text,
        email: _email,
        phoneNumber: _phone.text,
        dateOfBirth: _birthDate,
        chronicDiseases: _diseases.text,
        emergencyContact: _emergency.text,
        relationship: _relationship.text,
        specialty: _specialty.text,
      );
    } catch (error) {
      if (mounted) setState(() => _error = firebaseMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 25, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'اختر تاريخ الميلاد',
    );
    if (value != null) setState(() => _birthDate = value);
  }

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'استكمال إعداد الحساب',
        subtitle: 'تم تسجيل الدخول، وبقي حفظ ملفك الشخصي.',
        child: Column(children: [
          FormPanel(child: Form(key: _formKey, child: Column(children: [
            LabeledField(label: 'الاسم بالكامل', controller: _name, validator: (value) => Validators.requiredText(value, 'الاسم بالكامل')),
            LabeledField(label: 'البريد الإلكتروني', controller: _emailController, readOnly: true, textDirection: TextDirection.ltr),
            LabeledField(label: 'رقم الهاتف', controller: _phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, validator: Validators.egyptianPhone),
            Padding(padding: const EdgeInsets.only(bottom: 14), child: DropdownButtonFormField<UserRole>(value: _role, decoration: const InputDecoration(labelText: 'نوع الحساب'), items: UserRole.values.map((role) => DropdownMenuItem(value: role, child: Text(role.label))).toList(), onChanged: (value) => setState(() => _role = value ?? UserRole.patient))),
            if (_role == UserRole.patient) ...[
              ListTile(contentPadding: EdgeInsets.zero, title: const Text('تاريخ الميلاد'), subtitle: Text(_birthDate == null ? 'اختر تاريخ الميلاد' : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'), trailing: const Icon(Icons.calendar_month_outlined), onTap: _pickBirthDate),
              LabeledField(label: 'أمراض مزمنة (اختياري)', controller: _diseases, maxLines: 2),
              LabeledField(label: 'رقم طوارئ (اختياري)', controller: _emergency, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, validator: (value) => Validators.egyptianPhone(value, optional: true)),
            ],
            if (_role == UserRole.family) LabeledField(label: 'صلة القرابة (اختياري)', controller: _relationship),
            if (_role == UserRole.doctor) ...[
              LabeledField(label: 'التخصص (اختياري)', controller: _specialty),
              const Text('سيظل حساب الطبيب قيد المراجعة حتى التحقق الإداري.'),
            ],
          ]))),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 14),
          HawaleekButton(label: 'حفظ الملف الشخصي', onPressed: _save, busy: _busy),
          TextButton(onPressed: () async => AuthService.instance.signOut(), child: const Text('تسجيل الخروج')),
        ]),
      );
}
