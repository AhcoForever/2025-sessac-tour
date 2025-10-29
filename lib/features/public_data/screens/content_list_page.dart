import 'package:flutter/material.dart';
import '../services/visitseoul_api_service.dart';
import '../models/content_list_item.dart';
import '../widgets/content_list_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'content_detail_page.dart';

class ContentListPage extends StatefulWidget {
  const ContentListPage({super.key});

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
  String? _selectedCategory;

  // 카테고리 목록
  final List<Map<String, dynamic>> _categories = [
    {'name': '전체', 'icon': Icons.grid_view, 'value': null},
    {'name': '축제', 'icon': Icons.celebration, 'value': '축제'},
    {'name': '맛집', 'icon': Icons.restaurant, 'value': '맛집'},
    {'name': '명소', 'icon': Icons.attractions, 'value': '명소'},
    {'name': '쇼핑', 'icon': Icons.shopping_bag, 'value': '쇼핑'},
    {'name': '숙박', 'icon': Icons.hotel, 'value': '숙박'},
  ];

  @override
  void initState() {
    super.initState();
    _loadContents();
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
      keyword: _selectedCategory,
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
      keyword: _selectedCategory,
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

  // 필터 바텀시트 표시
  void _showFilterBottomSheet() {
    FilterBottomSheet.show(
      context,
      initialLang: _selectedLang,
      initialSort: _selectedSort,
      onApply: (lang, sort) {
        setState(() {
          _selectedLang = lang;
          _selectedSort = sort;
        });
        _loadContents(refresh: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '서울 여행',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadContents(refresh: true),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 히어로 배너
          SliverToBoxAdapter(
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[500]!,
                    Colors.cyan[400]!,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        '서울을 탐험하세요',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_pagingInfo?.totalCount ?? 0}개의 멋진 장소가 기다려요',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 카테고리 칩
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['value'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            size: 18,
                            color: isSelected ? Colors.white : Colors.blue[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.blue[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      selectedColor: Colors.blue[700],
                      backgroundColor: Colors.blue[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.blue[700]! : Colors.transparent,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category['value'];
                        });
                        _loadContents(refresh: true);
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // 콘텐츠 리스트
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(_errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadContents(refresh: true),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          else if (_contents.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('검색 결과가 없습니다'),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // 마지막 아이템: 더보기 버튼
                  if (index == _contents.length) {
                    if (_pagingInfo?.hasNextPage ?? false) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: _isLoadingMore
                              ? const CircularProgressIndicator()
                              : OutlinedButton(
                                  onPressed: _loadMoreContents,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('더 보기'),
                                ),
                        ),
                      );
                    }
                    return const SizedBox(height: 20);
                  }

                  // 큰 카드 아이템
                  final content = _contents[index];
                  return ContentListCard(
                    content: content,
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
                  );
                },
                childCount: _contents.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}