import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_app_bar_switcher.dart';
import '../../widgets/supa_card.dart';
import '../../widgets/supa_skeleton.dart';
import '../../widgets/supa_badge.dart';
import 'database_insights_provider.dart';

// --- INDEXES SCREEN ---
class IndexesScreen extends ConsumerWidget {
  final String projectRef;
  const IndexesScreen({super.key, required this.projectRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(indexesProvider(projectRef));
    return Scaffold(
      appBar: SupaAppBarSwitcher(title: 'Database Indexes'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(indexesProvider(projectRef).future),
        child: state.when(
          data: (data) {
            if (data.isEmpty) return const Center(child: Text('No custom indexes found.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SupaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: AppColors.supaGreen, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item['indexname'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Table: ${item['schemaname']}.${item['tablename']}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.bgBase,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: Text(item['indexdef'] ?? '', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.textCode)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

// --- TRIGGERS SCREEN ---
class TriggersScreen extends ConsumerWidget {
  final String projectRef;
  const TriggersScreen({super.key, required this.projectRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(triggersProvider(projectRef));
    return Scaffold(
      appBar: SupaAppBarSwitcher(title: 'Database Triggers'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(triggersProvider(projectRef).future),
        child: state.when(
          data: (data) {
            if (data.isEmpty) return const Center(child: Text('No triggers found.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SupaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.offline_bolt_rounded, color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item['trigger_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
                            SupaBadge(text: item['timing'] ?? 'UNKNOWN', color: Colors.orangeAccent),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Table: ${item['schema_name']}.${item['table_name']}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('Event: ${item['event']}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.bgBase,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: Text(item['definition'] ?? '', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.textCode)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

// --- PUBLICATIONS SCREEN ---
class PublicationsScreen extends ConsumerWidget {
  final String projectRef;
  const PublicationsScreen({super.key, required this.projectRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publicationsProvider(projectRef));
    return Scaffold(
      appBar: SupaAppBarSwitcher(title: 'Publications (Realtime)'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(publicationsProvider(projectRef).future),
        child: state.when(
          data: (data) {
            if (data.isEmpty) return const Center(child: Text('No publications found.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SupaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.podcasts_rounded, color: Colors.purpleAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item['pubname'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
                            if (item['puballtables'] == true)
                              const SupaBadge(text: 'ALL TABLES', color: Colors.purpleAccent),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildEventBadge('INSERT', item['pubinsert'] == true),
                            _buildEventBadge('UPDATE', item['pubupdate'] == true),
                            _buildEventBadge('DELETE', item['pubdelete'] == true),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildEventBadge(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.supaGreen.withOpacity(0.1) : AppColors.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? AppColors.supaGreen.withOpacity(0.5) : AppColors.borderDefault),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: active ? AppColors.supaGreen : AppColors.textMuted,
        ),
      ),
    );
  }
}

// --- DATABASE FUNCTIONS SCREEN ---
class DatabaseFunctionsScreen extends ConsumerWidget {
  final String projectRef;
  const DatabaseFunctionsScreen({super.key, required this.projectRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseFunctionsProvider(projectRef));
    return Scaffold(
      appBar: SupaAppBarSwitcher(title: 'Database Functions'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(databaseFunctionsProvider(projectRef).future),
        child: state.when(
          data: (data) {
            if (data.isEmpty) return const Center(child: Text('No database functions found.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final isTrigger = item['type'] == 'trigger';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SupaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isTrigger ? Icons.bolt_rounded : Icons.functions_rounded, 
                              color: isTrigger ? Colors.orangeAccent : Colors.blueAccent, 
                              size: 20
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item['function_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
                            SupaBadge(
                              text: item['schema_name'] ?? 'public', 
                              color: Colors.grey
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Result Type: ${item['result_type']}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        if (item['arguments'] != null && (item['arguments'] as String).isNotEmpty) ...[
                          Text('Arguments:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.bgBase,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderDefault),
                            ),
                            child: Text(item['arguments'] ?? '', style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.textCode)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

// --- AUTH PROVIDERS SCREEN ---
class AuthProvidersScreen extends ConsumerWidget {
  final String projectRef;
  const AuthProvidersScreen({super.key, required this.projectRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvidersProvider(projectRef));
    return Scaffold(
      appBar: SupaAppBarSwitcher(title: 'Active Auth Providers'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(authProvidersProvider(projectRef).future),
        child: state.when(
          data: (data) {
            if (data.isEmpty) return const Center(child: Text('No active auth providers found.'));
            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : (MediaQuery.of(context).size.width > 550 ? 3 : 2),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final provider = (item['provider'] as String).toLowerCase();
                final count = item['user_count'];
                
                IconData providerIcon = Icons.login_rounded;
                Color providerColor = Colors.grey;

                if (provider.contains('google')) { providerIcon = Icons.g_mobiledata_rounded; providerColor = Colors.redAccent; }
                else if (provider.contains('github')) { providerIcon = Icons.code_rounded; providerColor = Colors.white; }
                else if (provider.contains('email')) { providerIcon = Icons.email_rounded; providerColor = AppColors.supaGreen; }
                else if (provider.contains('apple')) { providerIcon = Icons.apple_rounded; providerColor = Colors.white; }

                return SupaCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(providerIcon, color: providerColor, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        provider.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count users',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}


