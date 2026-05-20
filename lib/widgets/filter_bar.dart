import 'package:flutter/material.dart';

enum FilterMode { monthly, yearly, allTime, custom }

class FilterBar extends StatelessWidget {
  final FilterMode filterMode;
  final DateTime selectedDate;
  final DateTime? customStart;
  final DateTime? customEnd;
  final ValueChanged<FilterMode> onFilterModeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Future<void> Function(DateTime start, DateTime end) onCustomRangeSelected;

  const FilterBar({
    super.key,
    required this.filterMode,
    required this.selectedDate,
    this.customStart,
    this.customEnd,
    required this.onFilterModeChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onCustomRangeSelected,
  });

  static const _months = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
  ];

  String _toBengali(String input) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return input.replaceAllMapped(RegExp(r'[0-9]'), (match) {
      return bengaliDigits[int.parse(match.group(0)!)];
    });
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${_toBengali(d.year.toString())}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.green.shade800,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          // ── Mode Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _modeChip(context, FilterMode.monthly, 'মাসিক'),
                const SizedBox(width: 8),
                _modeChip(context, FilterMode.yearly, 'বার্ষিক'),
                const SizedBox(width: 8),
                _modeChip(context, FilterMode.allTime, 'সব সময়'),
                const SizedBox(width: 8),
                _modeChip(context, FilterMode.custom, 'কাস্টম'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Navigator / Range ──
          if (filterMode == FilterMode.monthly) _monthNavigator(),
          if (filterMode == FilterMode.yearly) _yearNavigator(),
          if (filterMode == FilterMode.allTime) _allTimeLabel(),
          if (filterMode == FilterMode.custom) _customRangeRow(context),
        ],
      ),
    );
  }

  Widget _modeChip(BuildContext context, FilterMode mode, String label) {
    final isActive = filterMode == mode;
    return GestureDetector(
      onTap: () => onFilterModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.green.shade800 : Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _monthNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
          onPressed: onPrevious,
        ),
        Text(
          '${_months[selectedDate.month - 1]} ${_toBengali(selectedDate.year.toString())}',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          onPressed: onNext,
        ),
      ],
    );
  }

  Widget _yearNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
          onPressed: onPrevious,
        ),
        Text(
          _toBengali(selectedDate.year.toString()),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          onPressed: onNext,
        ),
      ],
    );
  }

  Widget _allTimeLabel() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'সব লেনদেন দেখাচ্ছে',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  Widget _customRangeRow(BuildContext context) {
    final hasRange = customStart != null && customEnd != null;
    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDateRange: hasRange
              ? DateTimeRange(start: customStart!, end: customEnd!)
              : DateTimeRange(
                  start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                  end: DateTime.now(),
                ),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.green.shade700,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          await onCustomRangeSelected(range.start, range.end);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              hasRange
                  ? '${_formatDate(customStart!)} — ${_formatDate(customEnd!)}'
                  : 'তারিখ সীমা বেছে নিন',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
