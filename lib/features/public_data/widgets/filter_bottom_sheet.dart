import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String initialLang;
  final String initialSort;
  final Function(String lang, String sort) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialLang,
    required this.initialSort,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();

  static void show(
    BuildContext context, {
    required String initialLang,
    required String initialSort,
    required Function(String lang, String sort) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        initialLang: initialLang,
        initialSort: initialSort,
        onApply: onApply,
      ),
    );
  }
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedLang;
  late String _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.initialLang;
    _selectedSort = widget.initialSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildLanguageSection(),
          const SizedBox(height: 20),
          _buildSortSection(),
          const SizedBox(height: 20),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '필터',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('언어', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildLanguageChip('한국어', 'ko'),
            _buildLanguageChip('English', 'en'),
            _buildLanguageChip('日本語', 'ja'),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedLang == value,
      onSelected: (selected) {
        setState(() => _selectedLang = value);
      },
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('정렬', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildSortChip('최신순', 'latest'),
            _buildSortChip('가나다순', 'abc'),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedSort == value,
      onSelected: (selected) {
        setState(() => _selectedSort = value);
      },
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          widget.onApply(_selectedLang, _selectedSort);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('적용하기'),
      ),
    );
  }
}
