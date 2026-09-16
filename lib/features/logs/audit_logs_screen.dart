import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_card.dart';
import '../../widgets/supa_app_bar_switcher.dart';
import '../projects/projects_provider.dart';
import 'logs_provider.dart';
import 'package:intl/intl.dart';

class AuditLogsScreen extends ConsumerWidget {
  final String projectRef;
  const AuditLogsScreen({super.key, required this.projectRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: SupaAppBarSwitcher(title: 'Audit Logs'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audit Logs',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Track clinical and administrative actions across your project.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildLogFilters(context),
            const SizedBox(height: 16),
            _buildLogsList(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildLogFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All Actions', true),
          _buildFilterChip('Schema Changes', false),
          _buildFilterChip('Auth Events', false),
          _buildFilterChip('Storage', false),
          _buildFilterChip('Database', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {},
        backgroundColor: AppColors.bgSubtle,
        selectedColor: AppColors.supaGreen.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.supaGreen : AppColors.textPrimary,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsProvider((projectRef: projectRef, collection: 'postgres')));

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('No audit logs found.')),
          );
        }
        return Column(
          children: logs.map((log) => _buildLogItem(context, log)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildLogItem(BuildContext context, dynamic logData) {
    final log = logData as Map<String, dynamic>;
    final timeStr = log['time'] ?? '';
    final msg = log['msg'] ?? '';
    final query = log['query'] ?? msg;
    final userName = log['user_name'] ?? 'System';
    
    DateTime? time;
    if (timeStr.isNotEmpty) {
      time = DateTime.tryParse(timeStr);
    }
    final displayTime = time != null ? DateFormat('MMM d, h:mm a').format(time) : 'Unknown time';

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: '$userName executed $query'));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log copied to clipboard')));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SupaCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgOverlay,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.storage, size: 18, color: AppColors.textMuted),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Inter'),
                        children: [
                          TextSpan(text: userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' executed query'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(query, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'JetBrains Mono')),
                    const SizedBox(height: 4),
                    Text(displayTime, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

