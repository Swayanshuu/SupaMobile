import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_app_bar_switcher.dart';
import '../../widgets/supa_card.dart';
import '../../widgets/supa_badge.dart';
import 'auth_analytics_provider.dart';

class AuthStatisticsScreen extends ConsumerWidget {
  final String projectRef;
  const AuthStatisticsScreen({super.key, required this.projectRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(authStatsProvider(projectRef));

    return Scaffold(
      appBar: SupaAppBarSwitcher(title: 'Auth Statistics'),
      body: statsState.when(
        data: (data) => _buildContent(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading stats: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final growth = data['growth'] as List<dynamic>;
    final status = data['status'] as List<dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(growth, status),
          const SizedBox(height: 32),
          Text('User Growth (Last 30 Days)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildGrowthChart(growth),
          const SizedBox(height: 32),
          Text('User Distribution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStatusPie(status),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<dynamic> growth, List<dynamic> status) {
    int totalUsers = 0;
    for (var s in status) {
      totalUsers += (s['count'] as num).toInt();
    }

    int last30Days = 0;
    for (var g in growth) {
      last30Days += (g['count'] as num).toInt();
    }

    return Row(
      children: [
        Expanded(
          child: SupaCard(
            child: Column(
              children: [
                Text('Total Users', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Text('$totalUsers', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.supaGreen)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SupaCard(
            child: Column(
              children: [
                Text('Last 30 Days', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Text('+$last30Days', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthChart(List<dynamic> growth) {
    if (growth.isEmpty) return SupaCard(height: 200, child: const Center(child: Text('Not enough data')));

    final List<FlSpot> spots = [];
    for (int i = 0; i < growth.length; i++) {
      spots.add(FlSpot(i.toDouble(), (growth[i]['count'] as num).toDouble()));
    }

    return SupaCard(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 7 != 0) return const SizedBox.shrink();
                  if (value.toInt() >= growth.length) return const SizedBox.shrink();
                  final dateStr = growth[value.toInt()]['date'];
                  final date = DateTime.parse(dateStr);
                  return Text(DateFormat('MMM d').format(date), style: TextStyle(fontSize: 10, color: AppColors.textMuted));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.supaGreen,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.supaGreen.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPie(List<dynamic> status) {
    if (status.isEmpty) return const SizedBox.shrink();

    return SupaCard(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: status.map((s) {
            final label = s['status'] as String;
            final count = (s['count'] as num).toDouble();
            final isConfirmed = label == 'Confirmed';
            return PieChartSectionData(
              color: isConfirmed ? AppColors.supaGreen : Colors.orangeAccent,
              value: count,
              title: '$label\n${count.toInt()}',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }
}
