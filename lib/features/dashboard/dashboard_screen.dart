import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/core_providers.dart';
import '../projects/projects_provider.dart';
import '../auth/service_key_prompt.dart';
import '../../widgets/supa_card.dart';
import '../../widgets/supa_skeleton.dart';
import '../../widgets/supa_app_bar_switcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dashboard_provider.dart';
import '../../core/providers/analytics_providers.dart';
import '../../widgets/time_range_selector.dart';
import 'widgets/flip_metric_card.dart';
import 'widgets/support_card.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/supa_button.dart';

class DashboardScreen extends ConsumerWidget {
  final String projectRef;
  const DashboardScreen({super.key, required this.projectRef});

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatBytes(num bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProject = ref.watch(activeProjectProvider);
    final usageState = ref.watch(dashboardUsageProvider(projectRef));
    final patAsync = ref.watch(patProvider);
    final hasPat = patAsync.asData?.value != null;
    final serviceKeyAsync = ref.watch(serviceRoleKeyProvider(projectRef));
    final hasServiceKey = serviceKeyAsync.asData?.value != null;

    return Scaffold(
      appBar: SupaAppBarSwitcher(title: 'Overview'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardUsageProvider(projectRef).future),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  if (usageState.isLoading && !usageState.hasValue) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (usageState.hasError && !usageState.hasValue) {
                    return Center(child: Text('Error: ${usageState.error}'));
                  }
                  if (!usageState.hasValue) return const SizedBox.shrink();
                  
                  final usage = usageState.value!;
                  final progress = usage['progress'] as Map<String, dynamic>;
                  final infra = usage['infra'] ?? {};
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Studio Header (Project Name + NANO + URL)
                      _buildStudioHeader(activeProject.value, projectRef, context),
                      const SizedBox(height: 24),

                      _buildInfrastructureRow(usage),
                      const SizedBox(height: 32),

                      // 4. Project Usage Header (Compact Row with Time Selector)
                      Row(
                        children: [
                          Expanded(
                            child: Text('Project Usage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.textPrimary, fontFamily: 'Inter')),
                          ),
                          const TimeRangeSelector(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SupportSupaAndroidCard(),
                      const SizedBox(height: 24),

                      if ((!hasServiceKey || !hasPat) && !serviceKeyAsync.isLoading && !patAsync.isLoading)
                        _buildMultiTokenAlert(context, !hasPat, !hasServiceKey),

                      // 5. Six Primary Metrics Grid (2x3)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 2;
                          if (constraints.maxWidth > 800) crossAxisCount = 4;
                          else if (constraints.maxWidth > 550) crossAxisCount = 3;
                          
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 0.9,
                            children: [
                          FlipMetricCard(
                            title: 'Total Requests',
                            value: usage['total_requests'].toString(),
                            subValue: 'Aggregated Over Time',
                            progress: 1.0, 
                            icon: Icons.analytics_rounded,
                            color: Colors.indigoAccent,
                            chartData: _mapToSpots(usage['database_requests_trend']), // Use DB trend as placeholder
                          ),
                          FlipMetricCard(
                            title: 'Database Requests',
                            value: usage['database_requests'].toString(),
                            subValue: 'Limit: 50,000',
                            progress: (progress['db'] as num).toDouble(),
                            icon: Icons.storage_rounded,
                            color: AppColors.supaGreen,
                            chartData: _mapToSpots(usage['database_requests_trend']),
                          ),
                          FlipMetricCard(
                            title: 'Auth Requests',
                            value: usage['auth_requests'].toString(),
                            subValue: 'Limit: 10,000',
                            progress: (progress['auth'] as num).toDouble(),
                            icon: Icons.people_rounded,
                            color: Colors.blueAccent,
                            chartData: _mapToSpots(usage['auth_requests_trend']),
                          ),
                          FlipMetricCard(
                            title: 'Storage Requests',
                            value: usage['storage_requests'].toString(),
                            subValue: 'Bandwidth: ${usage['total_egress']}',
                            progress: (progress['storage'] as num).toDouble(),
                            icon: Icons.folder_copy_rounded,
                            color: Colors.orangeAccent,
                            chartData: _mapToSpots(usage['storage_requests_trend']),
                          ),
                          FlipMetricCard(
                            title: 'Realtime Requests',
                            value: usage['realtime_messages'].toString(),
                            subValue: 'Auth Users: ${usage['total_users']}',
                            progress: (progress['realtime'] as num).toDouble(),
                            icon: Icons.sensors_rounded,
                            color: Colors.purpleAccent,
                            chartData: _mapToSpots(usage['realtime_messages_trend']),
                          ),
                          FlipMetricCard(
                            title: 'Database Connections',
                            value: usage['db_connections'].toString().split('.')[0],
                            subValue: 'Postgres Version: ${infra['db_version'] ?? 'Stable'}',
                            progress: (usage['db_connections'] / 50.0).clamp(0.0, 1.0),
                            icon: Icons.hub_rounded,
                            color: Colors.tealAccent,
                            chartData: _mapToSpots(usage['database_requests_trend']),
                          ),
                        ],
                          );
                        },
                      ),
                      const SizedBox(height: 48),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          TextButton(
                            onPressed: () => context.push('/projects/$projectRef/logs'),
                            child: const Row(
                              children: [
                                Text('View Explorer', style: TextStyle(color: AppColors.supaGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 16, color: AppColors.supaGreen),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if ((usage['recent_activity'] as List).isEmpty)
                        Text('No recent activity found', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                      ... (usage['recent_activity'] as List).map((log) {
                        final method = log['method'] ?? 'GET';
                        final path = log['path'] ?? '/';
                        final status = log['status_code'] ?? 200;
                        final timestamp = log['timestamp'] != null 
                            ? DateTime.fromMillisecondsSinceEpoch(log['timestamp'] ~/ 1000).toLocal().toString().substring(11, 16)
                            : '--:--';
                        
                        IconData icon;
                        Color statusColor;
                        if (status >= 500) {
                          icon = Icons.error_outline;
                          statusColor = Colors.redAccent;
                        } else if (status >= 400) {
                          icon = Icons.warning_amber_rounded;
                          statusColor = Colors.orangeAccent;
                        } else if (method == 'POST') {
                          icon = Icons.add_circle_outline;
                          statusColor = AppColors.supaGreen;
                        } else if (method == 'PATCH' || method == 'PUT') {
                          icon = Icons.edit_note_rounded;
                          statusColor = Colors.blueAccent;
                        } else if (method == 'DELETE') {
                          icon = Icons.delete_outline_rounded;
                          statusColor = Colors.redAccent;
                        } else {
                          icon = Icons.bolt;
                          statusColor = AppColors.supaGreen;
                        }

                        final collection = log['collection'] ?? 'Log';
                        
                        return _buildActivityItem(
                          '$method $path',
                          '$collection • Status: $status • $timestamp',
                          icon,
                          statusColor: statusColor,
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudioHeader(dynamic project, String ref, BuildContext context) {
    final url = 'https://$ref.supabase.co';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(project?.name ?? 'Loading...', 
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgOverlay,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Text('NANO', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text(url, style: TextStyle(color: AppColors.textMuted, fontSize: 14), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _copyToClipboard(context, url, 'URL Copied'),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgOverlay,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfrastructureRow(Map<String, dynamic> usage) {
    final infra = usage['infra'] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Primary Database Card (Full Width on Mobile)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.supaGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.storage_rounded, color: AppColors.supaGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Primary Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.supaGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('ACTIVE', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfraDetail('Region', infra['region'] ?? 'US-East-1'),
                  _buildInfraDetail('Provider', infra['cloud'] ?? 'AWS'),
                  _buildInfraDetail('Compute', infra['instance'] ?? 'Nano'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfraDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SupaCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: statusColor ?? AppColors.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14)),
                  Text(time, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiTokenAlert(BuildContext context, bool missingPat, bool missingServiceKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Preview Mode Active',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Showing synthetic data. To see real-time metrics, configure your credentials:',
            style: TextStyle(fontSize: 12, color: Colors.amber.withOpacity(0.9)),
          ),
          const SizedBox(height: 12),
          if (missingPat)
            _buildMissingItem('Experimental Access Token', 'Required for project usage and metrics'),
          if (missingServiceKey)
            _buildMissingItem('Service Role Key', 'Required for database management'),
          const SizedBox(height: 16),
          SupaButton(
            text: 'Configure Credentials',
            height: 36,
            color: Colors.amber,
            onPressed: () => context.push('/projects/$projectRef/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: Colors.amber, fontFamily: 'Inter'),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: TextStyle(color: Colors.amber.withOpacity(0.7))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _mapToSpots(dynamic data) {
    if (data == null || data is! List || data.isEmpty) {
      return List.generate(6, (i) => FlSpot(i.toDouble(), 0));
    }
    return List.generate(data.length, (i) {
      return FlSpot(i.toDouble(), (data[i] as num).toDouble());
    });
  }
}
