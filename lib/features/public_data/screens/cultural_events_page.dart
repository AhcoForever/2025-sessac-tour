import 'package:flutter/material.dart';
import 'package:sessactour/features/public_data/services/seoulapi_service.dart';

import '../models/cultural_event.dart';

class CulturalEventsPage extends StatefulWidget {
  const CulturalEventsPage({super.key});

  @override
  State<CulturalEventsPage> createState() => _CulturalEventsPageState();
}

class _CulturalEventsPageState extends State<CulturalEventsPage> {
  final SeoulApiService _apiService = SeoulApiService();
  List<CulturalEvent> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents(); // 화면이 시작되면 데이터 로드
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    final events = await _apiService.getCulturalEvent();

    setState(() {
      _events = events;
      _isLoading = false; // 로딩 종료
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('서울 문화행사')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩중
          : _events.isEmpty
          ? Center(child: Text('데이터가 없습니다.')) // 데이터 없음
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: event.thumbnail != null
                        ? Image.network(
                            event.thumbnail!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.event, size: 60);
                            },
                          )
                        : Icon(Icons.event, size: 60),
                    title: Text(
                      event.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(event.place),
                        Text('${event.startDate} ~ ${event.endDate}'),
                        Text(event.useFee),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
