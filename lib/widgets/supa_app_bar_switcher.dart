import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/projects/projects_provider.dart';
import '../core/providers/core_providers.dart';
import '../core/providers/scaffold_key_provider.dart';
import '../core/providers/app_logger_provider.dart';

class SupaAppBarSwitcher extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;

  const SupaAppBarSwitcher({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsProvider);
    final activeProject = ref.watch(activeProjectProvider).value;
    final hasUnreadError = ref.watch(appLoggerProvider).hasUnreadError;

    return AppBar(
      backgroundColor: backgroundColor,
      leading: IconButton(
        icon: Badge(
          isLabelVisible: hasUnreadError,
          backgroundColor: Colors.redAccent,
          smallSize: 8,
          child: const Icon(Icons.menu),
        ),
        onPressed: () {
          ref.read(rootScaffoldKeyProvider).currentState?.openDrawer();
        },
      ),
      title: InkWell(
        onTap: () {
          _showProjectSelector(context, ref);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeProject?.name ?? 'Select Project',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: AppColors.supaGreen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
      actions: [
        ...?actions,
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            if (activeProject != null) {
              context.push('/projects/${activeProject.ref}/settings');
            }
          },
        ),
      ],
      bottom: bottom,
    );
  }

  void _showProjectSelector(BuildContext context, WidgetRef ref) {
    final projectsState = ref.read(projectsProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgOverlay,
      builder: (context) {
        return projectsState.when(
          data: (projects) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Switch Project', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final bool isCurrent = project.ref == ref.read(activeProjectProvider).value?.ref;

                      return ListTile(
                        leading: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.supaGreen : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(project.name),
                        subtitle: Text(project.region),
                        onTap: () {
                          ref.read(activeProjectProvider).value = project;
                          Navigator.pop(context);
                          context.go('/projects/${project.ref}/dashboard');
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          )),
          error: (e, s) => Center(child: Text('Error: $e')),
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

