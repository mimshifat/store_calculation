import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/report_provider.dart';
import '../utils/app_utils.dart';
import '../widgets/filter_bar.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now();
  FilterMode _filterMode = FilterMode.monthly;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    // Load after first frame so Provider is ready
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  void _loadReport() {
    if (!mounted) return;
    DateTime start;
    DateTime end;
    switch (_filterMode) {
      case FilterMode.monthly:
        start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        end = DateTime(
            _selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
        break;
      case FilterMode.yearly:
        start = DateTime(_selectedDate.year, 1, 1);
        end = DateTime(_selectedDate.year, 12, 31, 23, 59, 59);
        break;
      case FilterMode.allTime:
        start = DateTime(2000);
        end = DateTime(2100);
        break;
      case FilterMode.custom:
        start = _customStart ??
            DateTime(_selectedDate.year, _selectedDate.month, 1);
        end = _customEnd != null
            ? DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day, 23,
                59, 59)
            : DateTime(
                _selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
        break;
    }
    Provider.of<ReportProvider>(context, listen: false).loadReport(start, end);
  }

  String _periodLabel() {
    switch (_filterMode) {
      case FilterMode.monthly:
        const months = [
          'জানুয়ারি',
          'ফেব্রুয়ারি',
          'মার্চ',
          'এপ্রিল',
          'মে',
          'জুন',
          'জুলাই',
          'আগস্ট',
          'সেপ্টেম্বর',
          'অক্টোবর',
          'নভেম্বর',
          'ডিসেম্বর'
        ];
        return '${months[_selectedDate.month - 1]} ${_selectedDate.year}';
      case FilterMode.yearly:
        return '${_selectedDate.year} সালের রিপোর্ট';
      case FilterMode.allTime:
        return 'সর্বকালীন রিপোর্ট';
      case FilterMode.custom:
        if (_customStart != null && _customEnd != null) {
          return '${_customStart!.day}/${_customStart!.month}/${_customStart!.year} — ${_customEnd!.day}/${_customEnd!.month}/${_customEnd!.year}';
        }
        return 'কাস্টম রিপোর্ট';
    }
  }

  // ── Filter callbacks — update state then load ────────────────────
  void _onFilterModeChanged(FilterMode mode) {
    setState(() => _filterMode = mode);
    // Use post-frame to avoid calling Provider inside build
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  void _onPrevious() {
    setState(() {
      if (_filterMode == FilterMode.monthly) {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else if (_filterMode == FilterMode.yearly) {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
    });
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  void _onNext() {
    setState(() {
      if (_filterMode == FilterMode.monthly) {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else if (_filterMode == FilterMode.yearly) {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
    });
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  void _onCustomRange(DateTime start, DateTime end) {
    setState(() {
      _customStart = start;
      _customEnd = end;
      _filterMode = FilterMode.custom;
    });
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বিজনেস রিপোর্ট'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _periodLabel(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Bar (always visible) ──
          FilterBar(
            filterMode: _filterMode,
            selectedDate: _selectedDate,
            customStart: _customStart,
            customEnd: _customEnd,
            onFilterModeChanged: _onFilterModeChanged,
            onPrevious: _onPrevious,
            onNext: _onNext,
            onCustomRangeSelected: (start, end) async =>
                _onCustomRange(start, end),
          ),

          // ── Scrollable content driven by provider ──
          Expanded(
            child: Consumer<ReportProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.green));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Inflow Section ──
                      _buildSectionHeader('ইনফ্লো (টাকা এসেছে)',
                          Icons.trending_up, Colors.green),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildReportCard(
                              'মোট বিক্রি',
                              provider.totalSales,
                              Colors.teal,
                              Icons.shopping_cart),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildReportCard(
                              'আদায় (কাস্টমার থেকে)',
                              provider.totalCollection,
                              Colors.green,
                              Icons.people),
                          const SizedBox(width: 12),
                          _buildReportCard(
                              'এখনো বাকি',
                              provider.totalSales - provider.totalCollection,
                              Colors.orange,
                              Icons.pending_actions),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Outflow Section ──
                      _buildSectionHeader('আউটফ্লো (টাকা গেছে)',
                          Icons.trending_down, Colors.red),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildReportCard(
                              'সাপ্লায়ার পেমেন্ট',
                              provider.totalSupplierPayments,
                              Colors.red,
                              Icons.local_shipping),
                          const SizedBox(width: 12),
                          _buildReportCard(
                              'দোকানের খরচ',
                              provider.totalCashExpense,
                              Colors.red,
                              Icons.remove_circle_outline),
                        ],
                      ),
                      const SizedBox(height: 32),

                      if (provider.totalSales > 0 ||
                          provider.totalCollection > 0) ...[
                        const Text(
                          'বিক্রি বনাম আদায়',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _buildSalesCollectionChart(
                            provider.totalSales, provider.totalCollection),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800),
        ),
      ],
    );
  }

  Widget _buildReportCard(
      String title, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                '৳${AppUtils.toBengali(amount.toStringAsFixed(0))}',
                style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCollectionChart(double sales, double collection) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (sales > collection ? sales : collection) * 1.2,
          barTouchData: const BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style =
                      TextStyle(fontSize: 13, fontWeight: FontWeight.bold);
                  if (value == 0) {
                    return SideTitleWidget(
                        meta: meta,
                        child: const Text('মোট বিক্রি', style: style));
                  }
                  if (value == 1) {
                    return SideTitleWidget(
                        meta: meta, child: const Text('আদায়', style: style));
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                  toY: sales,
                  color: Colors.teal.shade600,
                  width: 45,
                  borderRadius: BorderRadius.circular(8))
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                  toY: collection,
                  color: Colors.green.shade600,
                  width: 45,
                  borderRadius: BorderRadius.circular(8))
            ]),
          ],
        ),
      ),
    );
  }
}
