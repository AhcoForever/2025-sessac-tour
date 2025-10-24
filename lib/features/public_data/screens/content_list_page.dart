import 'package:flutter/material.dart';
import '../services/visitseoul_api_service.dart';
import '../models/content_list_item.dart';
import 'content_detail_page.dart';

class ContentListPage extends StatefulWidget {
  const ContentListPage({Key? key}) : super(key: key);

  @override
  State<ContentListPage> createState() => _ContentListPageState();
}

class _ContentListPageState extends State<ContentListPage> {
  final VisitSeoulApiService _apiService = VisitSeoulApiService();
  List<ContentListItem> _contents = [];
  PagingInfo? _pagingInfo;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // 검색 필터
  String _selectedLang = 'ko';
  String _selectedSort = 'latest';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 콘텐츠 로드 (첫 페이지)
  Future<void> _loadContents({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _contents.clear();
        _pagingInfo = null;
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _apiService.getContentList(
      langCodeId: _selectedLang,
      keyword: _searchController.text.isEmpty ? null : _searchController.text,
      sortType: _selectedSort,
      pageNo: 1,
    );

    setState(() {
      _isLoading = false;
      if (response != null) {
        // 진행 중인 콘텐츠만 필터링
        _contents = response.data.where((content) => content.isOngoing()).toList();
        _pagingInfo = response.paging;
      } else {
        _errorMessage = '데이터를 불러올 수 없습니다.';
      }
    });
  }

  // 더 많은 콘텐츠 로드 (다음 페이지)
  Future<void> _loadMoreContents() async {
    if (_pagingInfo == null || !_pagingInfo!.hasNextPage || _isLoadingMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _pagingInfo!.pageNo + 1;

    final response = await _apiService.getContentList(
      langCodeId: _selectedLang,
      keyword: _searchController.text.isEmpty ? null : _searchController.text,
      sortType: _selectedSort,
      pageNo: nextPage,
    );

    setState(() {
      _isLoadingMore = false;
      if (response != null) {
        // 진행 중인 콘텐츠만 필터링하여 추가
        _contents.addAll(response.data.where((content) => content.isOngoing()).toList());
        _pagingInfo = response.paging;
      }
    });
  }

  // 검색 실행
  void _performSearch() {
    _loadContents(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('서울 관광 정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadContents(refresh: true),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 및 필터 영역
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Column(
              children: [
                // 검색창
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '검색어를 입력하세요',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 8),

                // 필터 버튼들
                Row(
                  children: [
                    // 언어 선택
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLang,
                        decoration: InputDecoration(
                          labelText: '언어',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ko', child: Text('한국어')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'ja', child: Text('日本語')),
                          DropdownMenuItem(value: 'zh-CN', child: Text('简体中文')),
                          DropdownMenuItem(value: 'zh-TW', child: Text('繁體中文')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLang = value;
                            });
                            _performSearch();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 정렬 선택
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSort,
                        decoration: InputDecoration(
                          labelText: '정렬',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'latest', child: Text('최신순')),
                          DropdownMenuItem(value: 'abc', child: Text('가나다순')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSort = value;
                            });
                            _performSearch();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 검색 버튼
                    ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 결과 개수 표시
          if (_pagingInfo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '전체 ${_pagingInfo!.totalCount}개',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_pagingInfo!.pageNo} / ${_pagingInfo!.totalPages} 페이지',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

          // 콘텐츠 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadContents(refresh: true),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
                : _contents.isEmpty
                ? const Center(
              child: Text('검색 결과가 없습니다'),
            )
                : ListView.builder(
              itemCount: _contents.length + 1,
              itemBuilder: (context, index) {
                // 마지막 아이템: 더보기 버튼
                if (index == _contents.length) {
                  if (_pagingInfo?.hasNextPage ?? false) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: _isLoadingMore
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                          onPressed: _loadMoreContents,
                          child: const Text('더보기'),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                // 일반 아이템
                final content = _contents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContentDetailPage(
                            cid: content.cid,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 썸네일 이미지
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: content.mainImg.isNotEmpty
                                ? Image.network(
                              content.mainImg,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                  ),
                                );
                              },
                            )
                                : Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image,
                                size: 50,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 콘텐츠 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 카테고리
                                if (content.cateDepth.isNotEmpty)
                                  Text(
                                    content.cateDepth.join(' > '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                const SizedBox(height: 4),

                                // 제목
                                Text(
                                  content.postSj,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // 요약
                                Text(
                                  content.sumry.trim(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // 수정일
                                Text(
                                  '수정일: ${content.updtDtText}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 화살표 아이콘
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}