import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/subscription_service.dart';
import 'projects_provider.dart';
import 'project_card.dart';
import '../../widgets/supa_skeleton.dart';
import '../../widgets/supa_app_bar_switcher.dart';
import '../../widgets/supa_drawer.dart';
import '../dashboard/widgets/support_card.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsProvider);
    final isPro = ref.watch(isProUserProvider).value ?? false;

    return Scaffold(
      drawer: const SupaDrawer(),
      appBar: const SupaAppBarSwitcher(
        title: 'Projects',
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(projectsProvider.future),
        color: AppColors.supaGreen,
        backgroundColor: AppColors.bgSurface,
        child: projectsState.when(
          data: (projects) {
            if (projects.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: SupportSupaAndroidCard(),
                  );
                }
                final project = projects[index - 1];
                return ProjectCard(
                  project: project,
                  onTap: () {
                    ref.read(activeProjectProvider).value = project;
                    context.go('/projects/${project.ref}/dashboard');
                  },
                );
              },
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SupaSkeleton(width: double.infinity, height: 120),
              );
            },
          ),
          error: (error, stack) => _buildErrorState(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a project on the Supabase dashboard.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.colorError,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load projects',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceAll('Exception: ', ''),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.colorError,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.refresh(projectsProvider.future);
              },
              icon: Icon(Icons.refresh, color: AppColors.bgBase),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.supaGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

