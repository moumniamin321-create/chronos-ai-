import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../models/task_model.dart';
import '../../services/database_service.dart';

class ProgressScreen extends StatefulWidget {
  final bool embedded;
  const ProgressScreen({super.key, this.embedded = false});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<double> _weeklyRates = List.filled(7, 0);
  Map<TaskCategory, int> _categoryCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final tasks = await DatabaseService.instance.getTasksBetween(weekStart, now.add(const Duration(days: 1)));

    final rates = List<double>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayTasks = tasks.where((t) =>
          t.startTime.year == day.year && t.startTime.month == day.month && t.startTime.day == day.day);
      if (dayTasks.isEmpty) {
        rates[i] = 0;
      } else {
        rates[i] = dayTasks.where((t) => t.isCompleted).length / dayTasks.length;
      }
    }

    final categoryCounts = <TaskCategory, int>{};
    for (final t in tasks.where((t) => t.isCompleted)) {
      categoryCounts[t.category] = (categoryCounts[t.category] ?? 0) + 1;
    }

    if (!mounted) return;
    setState(() {
      _weeklyRates = rates;
      _categoryCounts = categoryCounts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('الإنتاجية خلال 7 أيام', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(height: 180, child: _WeeklyChart(rates: _weeklyRates)),
              const SizedBox(height: 28),
              const Text('توزيع المهام المنجزة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_categoryCounts.isEmpty)
                const Text('أكمل بعض المهام لرؤية التحليل هنا', style: TextStyle(color: AppColors.textSecondary))
              else
                ..._categoryCounts.entries.map((e) => _CategoryBar(
                      label: e.key.labelAr,
                      count: e.value,
                      max: _categoryCounts.values.reduce((a, b) => a > b ? a : b),
                    )),
            ],
          );

    if (widget.embedded) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('الإحصائيات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('الإحصائيات')), body: content);
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<double> rates;
  const _WeeklyChart({required this.rates});

  @override
  Widget build(BuildContext context) {
    const labels = ['س-6', 'س-5', 'س-4', 'س-3', 'س-2', 'أمس', 'اليوم'];
    return BarChart(
      BarChartData(
        maxY: 1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(labels[value.toInt()],
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ),
          ),
        ),
        barGroups: List.generate(rates.length, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: rates[i],
              color: AppColors.primary,
              width: 18,
              borderRadius: BorderRadius.circular(6),
            ),
          ]);
        }),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  const _CategoryBar({required this.label, required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : count / max;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$count', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
