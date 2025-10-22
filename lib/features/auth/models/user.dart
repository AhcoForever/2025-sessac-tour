// lib/features/auth/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  final String uid;              // Firebase Auth 자동 생성
  final String email;            // 이메일
  final String? displayName;     // 이름 (선택)
  final String? phoneNumber;     // 핸드폰 번호
  final String? photoURL;        // 프로필 사진 URL (선택)
  final DateTime createdAt;      // 가입 날짜
  final DateTime? lastLoginAt;   // 마지막 로그인

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
  });

  // Firebase Auth User에서 UserModel 생성
  factory UserModel.fromFirebaseUser(
      firebase_auth.User firebaseUser,
      ) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName,
      phoneNumber: firebaseUser.phoneNumber,
      photoURL: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  // Firestore에 저장할 때 사용 (Map 변환)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
    };
  }

  // Firestore에서 불러올 때 사용 (Map → UserModel)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoURL: json['photoURL'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastLoginAt: json['lastLoginAt'] != null
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }

  // UserModel 복사본 생성 (일부 필드만 수정할 때)
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName)';
  }
}