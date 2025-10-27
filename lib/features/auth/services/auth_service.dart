// lib/features/auth/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class AuthService {
  // Firebase Auth 인스턴스
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 로그인된 사용자 스트림
  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      // Firestore에서 추가 정보 가져오기
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      } else {
        // Firestore에 정보가 없으면 Firebase Auth 정보만 사용
        return UserModel.fromFirebaseUser(firebaseUser);
      }
    });
  }

  // 현재 사용자 (일회성 조회)
  Future<UserModel?> get currentUser async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    } else {
      return UserModel.fromFirebaseUser(firebaseUser);
    }
  }

  // 회원가입
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      // 1. Firebase Auth로 계정 생성
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user!;

      // 2. UserModel 생성
      final user = UserModel(
        uid: firebaseUser.uid,
        email: email,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // 3. Firestore에 사용자 정보 저장
      await _firestore.collection('users').doc(user.uid).set(user.toJson());

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // 에러 처리
      throw _handleAuthException(e);
    }
  }

  // 로그인
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase Auth로 로그인
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user!;

      // 2. Firestore에서 사용자 정보 가져오기
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists) {
        final user = UserModel.fromJson(doc.data()!);

        // 3. 마지막 로그인 시간 업데이트
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': Timestamp.now(),
        });

        return user.copyWith(lastLoginAt: DateTime.now());
      } else {
        return UserModel.fromFirebaseUser(firebaseUser);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw '로그인된 사용자가 없습니다.';
      }

      final uid = firebaseUser.uid;

      // 1. Firestore에서 사용자 데이터 삭제
      await _firestore.collection('users').doc(uid).delete();

      // 2. Firebase Auth 계정 삭제
      await firebaseUser.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 비밀번호 재확인 (계정 삭제 전 필요할 수 있음)
  Future<void> reauthenticate(String password) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null || firebaseUser.email == null) {
        throw '로그인된 사용자가 없습니다.';
      }

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: password,
      );

      await firebaseUser.reauthenticateWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Firebase Auth 에러 처리
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'operation-not-allowed':
        return '이메일/비밀번호 로그인이 비활성화되어 있습니다.';
      default:
        return '오류가 발생했습니다: ${e.message}';
    }
  }
}