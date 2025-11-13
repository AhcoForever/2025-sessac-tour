/// 날짜 포맷팅 유틸리티
class DateFormatter {
  /// yyyy.MM.dd 형식으로 날짜 포맷
  static String formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// yyyy년 MM월 dd일 형식으로 날짜 포맷
  static String formatDateKorean(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  /// MM/dd 형식으로 날짜 포맷
  static String formatDateShort(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
