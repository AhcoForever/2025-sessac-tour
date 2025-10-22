import 'package:flutter/material.dart';
import '../services/visitseoul_api_service.dart';
import '../models/content_info.dart';

class ContentDetailPage extends StatefulWidget {
  final String cid;

  const ContentDetailPage({
    Key? key,
    required this.cid,
  }) : super(key: key);

  @override
  State<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends State<ContentDetailPage> {
  final VisitSeoulApiService _apiService = VisitSeoulApiService();
  ContentInfo? _content;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final content = await _apiService.getContentInfo(widget.cid);

    setState(() {
      _content = content;
      _isLoading = false;
      if (content == null) {
        _errorMessage = '데이터를 불러올 수 없습니다.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('콘텐츠 상세'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContent,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      )
          : _content == null
          ? const Center(child: Text('데이터가 없습니다'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메인 이미지
            if (_content!.mainImg.isNotEmpty)
              Image.network(
                _content!.mainImg,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 100),
                  );
                },
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    _content!.postSj,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 카테고리
                  Wrap(
                    spacing: 8,
                    children: _content!.cateDepth.map((cat) {
                      return Chip(
                        label: Text(cat),
                        backgroundColor: Colors.blue[100],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 일정
                  if (_content!.schdulInfoBgnde.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_content!.schdulInfoBgnde} ~ ${_content!.schdulInfoEndde}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // 요약
                  if (_content!.sumry.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _content!.sumry.trim(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 상세 설명
                  const Text(
                    '상세 정보',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _content!.postDesc,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 24),

                  // 추가 정보
                  if (_content!.extra != null) ...[
                    const Divider(),
                    const Text(
                      '이용 안내',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_content!.extra!.cmmnTelno != null)
                      _buildInfoRow('전화번호', _content!.extra!.cmmnTelno!),

                    if (_content!.extra!.cmmnUseTime != null)
                      _buildInfoRow('이용시간', _content!.extra!.cmmnUseTime!),

                    if (_content!.extra!.closedDays != null)
                      _buildInfoRow('휴무일', _content!.extra!.closedDays!),
                  ],

                  // 교통 정보
                  if (_content!.traffic != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      '오시는 길',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_content!.traffic!.newAdres != null)
                      _buildInfoRow('주소', _content!.traffic!.newAdres!),

                    if (_content!.traffic!.subwayInfo != null)
                      _buildInfoRow('지하철', _content!.traffic!.subwayInfo!),
                  ],

                  // 태그
                  if (_content!.tag.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      '태그',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _content!.tag.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}