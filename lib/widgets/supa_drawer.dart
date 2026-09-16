import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/projects/projects_provider.dart';
import '../core/providers/core_providers.dart';
import '../core/providers/app_logger_provider.dart';
import '../core/services/subscription_service.dart';
import 'supa_button.dart';

class SupaDrawer extends ConsumerWidget {
  const SupaDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProject = ref.watch(activeProjectProvider).value;
    final projectRef = activeProject?.ref ?? '';
    final themeMode = ref.watch(themeModeProvider);
    final hasUnreadError = ref.watch(appLoggerProvider).hasUnreadError;

    return ListenableBuilder(
      listenable: themeMode,
      builder: (context, _) => Drawer(
      backgroundColor: AppColors.bgBase,
      child: Column(
        children: [
          _buildHeader(context, activeProject),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (activeProject == null) ...[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No project selected.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ] else ...[
                  _buildNavItem(context, Icons.home_outlined, 'Overview', '/projects/$projectRef/dashboard'),
                  _buildNavItem(context, Icons.table_view_outlined, 'Table Editor', '/projects/$projectRef/tables'),
                  _buildNavItem(context, Icons.code_rounded, 'SQL Editor', '/projects/$projectRef/sql'),
                  
                  Divider(color: AppColors.borderDefault, height: 1),
                  _buildSectionHeader(context, 'Management'),
                  _buildNavItem(context, Icons.storage_rounded, 'Database', '/projects/$projectRef/database'),
                  _buildNavItem(context, Icons.people_outline_rounded, 'Authentication', '/projects/$projectRef/auth'),
                  _buildNavItem(context, Icons.security_rounded, 'Providers', '/projects/$projectRef/auth/providers'),
                  _buildNavItem(context, Icons.folder_outlined, 'Storage', '/projects/$projectRef/storage'),
                  _buildNavItem(context, Icons.bolt, 'Edge Functions', '/projects/$projectRef/functions'),
                  _buildNavItem(context, Icons.sensors, 'Realtime', '/projects/$projectRef/realtime'),
                  
                  Divider(color: AppColors.borderDefault, height: 1),
                  _buildSectionHeader(context, 'Reports'),
                  _buildNavItem(context, Icons.history_rounded, 'Logs Explorer', '/projects/$projectRef/logs'),
                  _buildNavItem(context, Icons.assignment_outlined, 'Audit Logs', '/projects/$projectRef/audit'),
                  _buildNavItem(context, Icons.analytics_outlined, 'Infrastructure', '/projects/$projectRef/infrastructure'),
                  _buildNavItem(context, Icons.settings_outlined, 'Project Settings', '/projects/$projectRef/settings'),
                ],
                
                const SizedBox(height: 20),
                Divider(color: AppColors.borderDefault, height: 1),
                _buildNavItem(context, Icons.swap_horiz, 'Switch Project List', '/projects'),
                _buildNavItem(context, Icons.info_outline_rounded, 'About App', '/profile'),
                _buildNavItem(context, Icons.terminal_rounded, 'App Logs', '/app-logs', showBadge: hasUnreadError),
                _buildNavItem(context, Icons.forum_outlined, 'Feedback & Requests', '/feedback'),
                _buildNavItem(context, Icons.volunteer_activism_outlined, 'Support Supamobile', '/support'),
              ],
            ),
          ),
          _buildFooter(context, ref),
        ],
      ),
    ),
  );
}

  Widget _buildHeader(BuildContext context, dynamic activeProject) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: AppColors.bgOverlay,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/logo.png'),
                fit: BoxFit.contain,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            activeProject?.name ?? 'Supamobile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
          ),
          Text(
            activeProject?.region ?? 'Global Cluster',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route, {bool showBadge = false}) {
    final String currentPath = GoRouterState.of(context).uri.toString();
    final bool isSelected = currentPath == route || (route != '/projects' && currentPath.startsWith(route));

    return ListTile(
      leading: Badge(
        isLabelVisible: showBadge,
        backgroundColor: Colors.redAccent,
        smallSize: 8,
        child: Icon(icon, color: isSelected ? AppColors.supaGreen : AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? AppColors.supaGreen : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          context.push(route);
        }
      },
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Theme', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildThemeIcon(ref, ThemeMode.light, Icons.wb_sunny_outlined),
              const SizedBox(width: 8),
              _buildThemeIcon(ref, ThemeMode.dark, Icons.nightlight_round_outlined),
              const SizedBox(width: 8),
              _buildThemeIcon(ref, ThemeMode.system, Icons.settings_brightness_outlined),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('v1.1.0-stable', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
              const Spacer(),

              Icon(Icons.verified_user_outlined, size: 12, color: AppColors.supaGreen),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildThemeIcon(WidgetRef ref, ThemeMode mode, IconData icon) {
    final currentMode = ref.watch(themeModeProvider).value;
    final isSelected = currentMode == mode;

    return InkWell(
      onTap: () => ref.read(themeModeProvider).value = mode,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.supaGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? AppColors.supaGreen.withOpacity(0.5) : Colors.transparent),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? AppColors.supaGreen : AppColors.textMuted,
        ),
      ),
    );
  }
}


