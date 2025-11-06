import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자가 촬영한 인증샷 메모리 모델
class PhotoMemory {
  final String id;
  final String userId;
  final String destinationId;
  final String destinationName;
  final String destinationAddress;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final DateTime timestamp;

  PhotoMemory({
    required this.id,
    required this.userId,
    required this.destinationId,
    required this.destinationName,
    required this.destinationAddress,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    required this.timestamp,
  });

  /// Firestore로부터 데이터를 읽어올 때
  factory PhotoMemory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoMemory(
      id: doc.id,
      userId: data['userId'] ?? '',
      destinationId: data['destinationId'] ?? '',
      destinationName: data['destinationName'] ?? '',
      destinationAddress: data['destinationAddress'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      photoUrl: data['photoUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Firestore에 저장할 때
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'destinationAddress': destinationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'destinationAddress': destinationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
