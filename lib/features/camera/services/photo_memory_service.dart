import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/photo_memory.dart';

/// 사진 메모리 저장 및 관리 서비스
class PhotoMemoryService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 사진 업로드 및 메타데이터 저장
  Future<PhotoMemory?> savePhotoMemory({
    required String photoPath,
    required String destinationId,
    required String destinationName,
    required String destinationAddress,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // 1. 현재 사용자 확인
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      print('📸 사진 업로드 시작: $photoPath');

      // 2. Firebase Storage에 사진 업로드
      final photoUrl = await _uploadPhotoToStorage(
        photoPath: photoPath,
        userId: user.uid,
        destinationId: destinationId,
      );

      print('✅ 사진 업로드 완료: $photoUrl');

      // 3. Firestore에 메타데이터 저장
      final photoMemory = await _savePhotoMetadata(
        userId: user.uid,
        destinationId: destinationId,
        destinationName: destinationName,
        destinationAddress: destinationAddress,
        latitude: latitude,
        longitude: longitude,
        photoUrl: photoUrl,
      );

      print('✅ 메타데이터 저장 완료: ${photoMemory.id}');

      return photoMemory;
    } catch (e) {
      print('❌ 사진 저장 실패: $e');
      return null;
    }
  }

  /// Firebase Storage에 사진 업로드
  Future<String> _uploadPhotoToStorage({
    required String photoPath,
    required String userId,
    required String destinationId,
  }) async {
    final file = File(photoPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${userId}_${destinationId}_$timestamp.jpg';
    final storageRef = _storage.ref().child('photo_memories/$userId/$fileName');

    // 업로드
    final uploadTask = storageRef.putFile(file);

    // 진행 상황 모니터링 (선택 사항)
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
      print('📤 업로드 진행: ${progress.toStringAsFixed(2)}%');
    });

    // 업로드 완료 대기
    await uploadTask;

    // 다운로드 URL 가져오기
    final downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  }

  /// Firestore에 메타데이터 저장
  Future<PhotoMemory> _savePhotoMetadata({
    required String userId,
    required String destinationId,
    required String destinationName,
    required String destinationAddress,
    required double latitude,
    required double longitude,
    required String photoUrl,
  }) async {
    final docRef = _firestore.collection('photo_memories').doc();

    final photoMemory = PhotoMemory(
      id: docRef.id,
      userId: userId,
      destinationId: destinationId,
      destinationName: destinationName,
      destinationAddress: destinationAddress,
      latitude: latitude,
      longitude: longitude,
      photoUrl: photoUrl,
      timestamp: DateTime.now(),
    );

    await docRef.set(photoMemory.toFirestore());

    return photoMemory;
  }

  /// 사용자의 모든 사진 메모리 가져오기
  Future<List<PhotoMemory>> getUserPhotoMemories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('photo_memories')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PhotoMemory.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ 사진 메모리 로드 실패: $e');
      return [];
    }
  }

  /// 특정 사진 메모리 삭제
  Future<bool> deletePhotoMemory(String photoMemoryId, String photoUrl) async {
    try {
      // 1. Storage에서 사진 삭제
      final storageRef = _storage.refFromURL(photoUrl);
      await storageRef.delete();

      // 2. Firestore에서 메타데이터 삭제
      await _firestore.collection('photo_memories').doc(photoMemoryId).delete();

      print('✅ 사진 메모리 삭제 완료: $photoMemoryId');
      return true;
    } catch (e) {
      print('❌ 사진 메모리 삭제 실패: $e');
      return false;
    }
  }

  /// 특정 목적지의 사진 메모리 개수 가져오기
  Future<int> getDestinationVisitCount(String destinationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 0;
      }

      final querySnapshot = await _firestore
          .collection('photo_memories')
          .where('userId', isEqualTo: user.uid)
          .where('destinationId', isEqualTo: destinationId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ 방문 횟수 조회 실패: $e');
      return 0;
    }
  }
}
