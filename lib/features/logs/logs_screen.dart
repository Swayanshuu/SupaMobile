import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_app_bar_switcher.dart';
import '../../widgets/supa_card.dart';
import '../../widgets/supa_card.dart';
import '../../core/api/analytics_api.dart';
import 'logs_provider.dart';

class LogsScreen extends ConsumerStatefulWidget {
  final String projectRef;
  const LogsScreen({super.key, required this.projectRef});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCollectionId;
  String? _selectedCollectionLabel;

  @override
  Widget build(BuildContext context) {
    return _selectedCollectionId == null
        ? _buildCollectionPicker()
        : _buildLogsExplorer();
  }

  Widget _buildCollectionPicker() {
    return Scaffold(
      appBar: const SupaAppBarSwitcher(title: 'Logs Explorer'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a Collection',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'View real-time event streams from your project infrastructure.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : (MediaQuery.of(context).size.width > 550 ? 3 : 2),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: AnalyticsApi.collections.length,
              itemBuilder: (context, index) {
                final col = AnalyticsApi.collections[index];
                return _buildCollectionCard(col);
              },
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(Map<String, String> col) {
    return SupaCard(
      onTap: () {
        setState(() {
          _selectedCollectionId = col['id'];
          _selectedCollectionLabel = col['label'];
        });
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIcon(col['id']!),
            size: 28,
            color: AppColors.supaGreen,
          ),
          const SizedBox(height: 12),
          Text(
            col['label']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String id) {
    switch (id) {
      case 'api': return Icons.hub_outlined;
      case 'postgres': return Icons.storage_outlined;
      case 'postgrest': return Icons.api_outlined;
      case 'pooler': return Icons.sync_alt;
      case 'auth': return Icons.fingerprint_outlined;
      case 'storage': return Icons.cloud_outlined;
      case 'realtime': return Icons.bolt_outlined;
      case 'functions': return Icons.data_object_outlined;
      case 'cron': return Icons.schedule_outlined;
      default: return Icons.notes;
    }
  }

  Widget _buildLogsExplorer() {
    return Scaffold(
      appBar: SupaAppBarSwitcher(
        title: _selectedCollectionLabel ?? 'Logs',
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              _selectedCollectionId = null;
              _selectedCollectionLabel = null;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildLogList(_selectedCollectionId!),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search logs...',
                        hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.supaGreen),
            onPressed: () => ref.refresh(logsProvider((projectRef: widget.projectRef, collection: _selectedCollectionId!)).future),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(String category) {
    final logsState = ref.watch(logsProvider((projectRef: widget.projectRef, collection: category)));

    return logsState.when(
      data: (logs) {
        final filteredLogs = _searchController.text.isEmpty 
          ? logs 
          : logs.where((l) => (l['event_message'] ?? l['message'] ?? '').toString().toLowerCase()
              .contains(_searchController.text.toLowerCase())).toList();

        if (filteredLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('No logs found', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(logsProvider((projectRef: widget.projectRef, collection: category)).future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index] as Map<String, dynamic>;
              final metadata = log['metadata'] as Map<String, dynamic>? ?? {};
              final message = log['event_message'] ?? log['message'] ?? 'No message';
              final timestamp = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
              final isError = (metadata['status'] != null && (metadata['status'] as int) >= 400);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SupaCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(isError ? 'ERROR' : 'INFO', isError),
                          Text(
                            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'JetBrains Mono'),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        message,
                        style: TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono', height: 1.4),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          if (metadata['method'] != null)
                            _buildMetaTag(metadata['method'].toString()),
                          SizedBox(width: 8),
                          if (metadata['path'] != null)
                            _buildMetaTag(metadata['path'].toString()),
                          const Spacer(),
                          Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: AppColors.supaGreen)),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildStatusBadge(String text, bool isError) {
    final color = isError ? Colors.redAccent : AppColors.supaGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildMetaTag(String text) {
    if (text.length > 20) text = text.substring(0, 17) + '...';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.bgOverlay, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
      ),
    );
  }
}


