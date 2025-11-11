/// 중기예보 데이터 모델
class WeatherForecast {
  final String baseDate; // 발표일시
  final List<DailyForecast> dailyForecasts; // 일별 예보 리스트

  WeatherForecast({
    required this.baseDate,
    required this.dailyForecasts,
  });

  /// 중기예보 API 데이터에서 생성
  factory WeatherForecast.fromMidForecast(
    Map<String, dynamic> landData,
    Map<String, dynamic> tempData,
  ) {
    final tmFc = landData['tmFc'] ?? tempData['tmFc'] ?? '';
    final dailyForecasts = <DailyForecast>[];

    // 3일 후부터 10일 후까지
    for (int day = 3; day <= 10; day++) {
      final dayKey = day.toString();

      // 육상예보 데이터
      final rnStAm = landData['rnSt${day}Am']; // 오전 강수확률
      final rnStPm = landData['rnSt${day}Pm']; // 오후 강수확률
      final wfAm = landData['wf${day}Am']; // 오전 하늘상태
      final wfPm = landData['wf${day}Pm']; // 오후 하늘상태

      // 기온예보 데이터
      final taMin = tempData['taMin$dayKey']; // 최저기온
      final taMax = tempData['taMax$dayKey']; // 최고기온

      dailyForecasts.add(DailyForecast(
        day: day,
        minTemp: taMin,
        maxTemp: taMax,
        rainProbAm: rnStAm,
        rainProbPm: rnStPm,
        skyAm: wfAm ?? '',
        skyPm: wfPm ?? '',
      ));
    }

    return WeatherForecast(
      baseDate: tmFc,
      dailyForecasts: dailyForecasts,
    );
  }

  /// AI 프롬프트에 사용할 요약 문자열
  String toSummaryString() {
    final buffer = StringBuffer();
    buffer.writeln('📅 서울 중기예보 (${_formatBaseDate(baseDate)}):\n');

    for (final daily in dailyForecasts) {
      buffer.writeln(daily.toSummaryString());
    }

    return buffer.toString();
  }

  String _formatBaseDate(String tmFc) {
    // YYYYMMDD0600 -> YYYY년 MM월 DD일 발표
    if (tmFc.length >= 8) {
      final year = tmFc.substring(0, 4);
      final month = tmFc.substring(4, 6);
      final day = tmFc.substring(6, 8);
      return '$year년 $month월 $day일 발표';
    }
    return tmFc;
  }
}

/// 일별 예보 데이터
class DailyForecast {
  final int day; // 3~10일 후
  final int? minTemp; // 최저기온
  final int? maxTemp; // 최고기온
  final int? rainProbAm; // 오전 강수확률
  final int? rainProbPm; // 오후 강수확률
  final String skyAm; // 오전 하늘상태
  final String skyPm; // 오후 하늘상태

  DailyForecast({
    required this.day,
    this.minTemp,
    this.maxTemp,
    this.rainProbAm,
    this.rainProbPm,
    required this.skyAm,
    required this.skyPm,
  });

  /// 요약 문자열
  String toSummaryString() {
    final buffer = StringBuffer();
    buffer.write('${day}일 후: ');

    // 기온
    if (minTemp != null && maxTemp != null) {
      buffer.write('$minTemp°C ~ $maxTemp°C');
    }

    // 날씨
    final weather = _getWeatherEmoji();
    if (weather.isNotEmpty) {
      buffer.write(' $weather');
    }

    // 강수확률
    if (rainProbAm != null || rainProbPm != null) {
      final am = rainProbAm ?? 0;
      final pm = rainProbPm ?? 0;
      buffer.write(' (강수확률 오전 $am%, 오후 $pm%)');
    }

    return buffer.toString();
  }

  /// 날씨 이모지 반환
  String _getWeatherEmoji() {
    // 하루 중 더 악천후 쪽을 우선 표시
    final conditions = [skyAm, skyPm];

    if (conditions.any((c) => c.contains('비') || c.contains('소나기'))) {
      return '🌧️ 비';
    } else if (conditions.any((c) => c.contains('눈'))) {
      return '❄️ 눈';
    } else if (conditions.any((c) => c.contains('흐림'))) {
      return '☁️ 흐림';
    } else if (conditions.any((c) => c.contains('구름많음'))) {
      return '⛅ 구름많음';
    } else if (conditions.any((c) => c.contains('맑음'))) {
      return '☀️ 맑음';
    }

    return '';
  }

  /// 실내 활동 추천 여부
  bool get recommendIndoor {
    // 비/눈이 오거나 강수확률 60% 이상이면 실내 추천
    final hasRain = skyAm.contains('비') ||
        skyPm.contains('비') ||
        skyAm.contains('눈') ||
        skyPm.contains('눈');

    final highRainProb = (rainProbAm ?? 0) >= 60 || (rainProbPm ?? 0) >= 60;

    return hasRain || highRainProb;
  }

  /// 날씨가 좋은지 여부
  bool get isNiceWeather {
    // 맑거나 구름조금이고 강수확률 30% 미만
    final clearSky = (skyAm.contains('맑음') || skyAm.contains('구름조금')) &&
        (skyPm.contains('맑음') || skyPm.contains('구름조금'));

    final lowRainProb = (rainProbAm ?? 0) < 30 && (rainProbPm ?? 0) < 30;

    return clearSky && lowRainProb;
  }
}
