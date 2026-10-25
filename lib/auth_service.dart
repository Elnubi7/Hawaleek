import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'core.dart';
import 'validators.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<Map<String, dynamic>?> profile(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();
    return snapshot.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileChanges(String uid) =>
      _db.collection('users').doc(uid).snapshots();

  Future<void> register({
    required UserRole role,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    String? emergencyContact,
    String? relationship,
    String? specialty,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    await saveCurrentProfile(
      role: role,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      emergencyContact: emergencyContact,
      relationship: relationship,
      specialty: specialty,
    );
  }

  Future<void> saveCurrentProfile({
    required UserRole role,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? emergencyContact,
    String? relationship,
    String? specialty,
  }) async {
    final user = _auth.currentUser;
    if (user == null ||
        user.email?.toLowerCase() != email.trim().toLowerCase()) {
      throw StateError('No matching signed-in account');
    }
    final existing = await _db.collection('users').doc(user.uid).get();
    if (existing.exists) {
      if (existing.data()?['role'] != role.value) {
        throw StateError('The account role cannot be changed');
      }
      return;
    }
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'uid': user.uid,
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phoneNumber': Validators.normalizeEgyptianPhone(phoneNumber),
      'role': role.value,
      'isActive': true,
      'createdAt': now,
      'updatedAt': now,
    };
    final emergency = emergencyContact?.trim();
    if (emergency != null && emergency.isNotEmpty) {
      data['emergencyContact'] = Validators.normalizeEgyptianPhone(emergency);
    }
    if (role == UserRole.family && (relationship?.trim().isNotEmpty ?? false)) {
      data['relationship'] = relationship!.trim();
    }
    if (role == UserRole.doctor) {
      data['verificationStatus'] = 'pending';
      if (specialty?.trim().isNotEmpty ?? false)
        data['specialty'] = specialty!.trim();
    }
    await _db.collection('users').doc(user.uid).set(data);
  }

  Future<void> signIn(String email, String password) async =>
      _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

  Future<void> sendPasswordReset(String email) async =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  Future<void> signOut() => _auth.signOut();

  Future<void> updateOwnProfile({
    required String fullName,
    required String phoneNumber,
    String? emergencyContact,
  }) async {
    final user = _auth.currentUser!;
    final emergency = emergencyContact?.trim();
    await _db.collection('users').doc(user.uid).update({
      'fullName': fullName.trim(),
      'phoneNumber': Validators.normalizeEgyptianPhone(phoneNumber),
      if (emergency != null && emergency.isNotEmpty)
        'emergencyContact': Validators.normalizeEgyptianPhone(emergency)
      else
        'emergencyContact': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createFamilyRequest(String patientUid) async {
    final familyUid = _auth.currentUser!.uid;
    await _db
        .collection('patientFamilyLinks')
        .doc('${patientUid.trim()}_$familyUid')
        .set({
          'patientUid': patientUid.trim(),
          'familyUid': familyUid,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> setFamilyRequestStatus(String linkId, String status) async {
    await _db.collection('patientFamilyLinks').doc(linkId).update({
      'status': status,
      if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> familyLinks(String uid) => _db
      .collection('patientFamilyLinks')
      .where('familyUid', isEqualTo: uid)
      .snapshots();
}

String firebaseMessage(Object error) {
  if (error is FirebaseAuthException) {
    if (kDebugMode) {
      debugPrint(
        'Firebase Authentication failed [${error.code}]: ${error.message}',
      );
    }
    return switch (error.code) {
      'email-already-in-use' =>
        'هذا البريد مسجل بالفعل. سجّل الدخول بدلًا من إنشاء حساب جديد.',
      'invalid-email' => 'صيغة البريد الإلكتروني غير صحيحة.',
      'weak-password' => 'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' =>
        'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
      'user-disabled' => 'تم إيقاف هذا الحساب. تواصل مع الدعم.',
      'operation-not-allowed' =>
        'فعّل تسجيل الدخول بالبريد وكلمة المرور من إعدادات Firebase.',
      'network-request-failed' =>
        'تعذر الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.',
      'too-many-requests' => 'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.',
      _ => 'تعذر إكمال العملية. حاول مرة أخرى.',
    };
  }
  if (error is FirebaseException) {
    if (kDebugMode) {
      debugPrint('Cloud Firestore failed [${error.code}]: ${error.message}');
    }
    return switch (error.code) {
      'permission-denied' => 'ليست لديك صلاحية لتنفيذ هذا الإجراء.',
      'unavailable' => 'الخدمة غير متاحة حاليًا. تحقق من اتصالك بالإنترنت.',
      _ => 'تعذر حفظ البيانات. حاول مرة أخرى.',
    };
  }
  return 'تعذر إكمال العملية. حاول مرة أخرى.';
}
