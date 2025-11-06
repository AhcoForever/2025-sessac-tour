class Recommendation {
  final String category; // 힐링형, 활력형 등
  final String title; // 제목
  final String description; // 설명
  final String? distance; // 거리 (예: "2.3km")
  final String? duration; // 소요 시간 (예: "45분")
  final String? cost; // 비용 (예: "무료", "5,000원")
  final double? rating; // 별점 (1-5)
  final String? imageUrl; // 이미지 URL (선택)
  final String? locationId; // 장소 ID (지도 연동용)

  Recommendation({
    required this.category,
    required this.title,
    required this.description,
    this.distance,
    this.duration,
    this.cost,
    this.rating,
    this.imageUrl,
    this.locationId,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      distance: json['distance'] as String?,
      duration: json['duration'] as String?,
      cost: json['cost'] as String?,
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'] as String?,
      locationId: json['locationId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'distance': distance,
      'duration': duration,
      'cost': cost,
      'rating': rating,
      'imageUrl': imageUrl,
      'locationId': locationId,
    };
  }
}
