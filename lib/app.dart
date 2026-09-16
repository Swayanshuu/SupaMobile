import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/providers/core_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/projects/projects_screen.dart';
import 'features/projects/projects_provider.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/tables/tables_screen.dart';
import 'features/sql/sql_editor_screen.dart';
import 'features/auth_users/auth_users_screen.dart';
import 'features/auth_users/auth_statistics_screen.dart';
import 'features/storage/storage_screen.dart';
import 'features/functions/functions_screen.dart';
import 'features/functions/secrets_screen.dart';
import 'features/projects/project_settings_screen.dart';
import 'features/dashboard/placeholder_screen.dart';
import 'features/logs/logs_screen.dart';
import 'features/logs/audit_logs_screen.dart';
import 'features/auth_users/policies_screen.dart';
import 'features/tables/schema_screen.dart';
import 'features/infrastructure/infrastructure_screen.dart';
import 'features/database/database_sub_page.dart';
import 'features/subscription/pricing_screen.dart';
import 'features/settings/app_logs_screen.dart';
import 'widgets/supa_bottom_nav.dart';
import 'widgets/app_lock_wrapper.dart';
import 'features/profile/profile_screen.dart';
import 'features/feedback/feedback_screen.dart';
import 'features/database/database_insights_screens.dart';
import 'features/realtime/realtime_console_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SupaMobileApp extends ConsumerStatefulWidget {
  const SupaMobileApp({super.key});

  @override
  ConsumerState<SupaMobileApp> createState() => _SupaMobileAppState();
}

class _SupaMobileAppState extends ConsumerState<SupaMobileApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ListenableBuilder(
      listenable: themeMode,
      builder: (context, _) {
        if (themeMode.value == ThemeMode.light) {
          AppColors.brightness = Brightness.light;
        } else if (themeMode.value == ThemeMode.dark) {
          AppColors.brightness = Brightness.dark;
        } else {
          AppColors.brightness = null; // Follow system
        }

        return MaterialApp.router(
          key: ValueKey(themeMode.value),
          title: 'Supamobile',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode.value,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => AppTheme.buildBackground(
            context: context,
            child: AppLockWrapper(child: child!),
          ),
        );
      });
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final patAsync = ref.watch(patProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/';
      final hasPat = patAsync.asData?.value != null;

      if (!hasPat && !isLoggingIn) {
        return '/';
      }
      if (hasPat && isLoggingIn) {
        return '/projects';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const PricingScreen(),
      ),
      GoRoute(
        path: '/pricing',
        builder: (context, state) => const PricingScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/app-logs',
        builder: (context, state) => const AppLogsScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final ref_str = state.pathParameters['ref'];
          if (ref_str != null) {
            // Wait for next frame to set state
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _syncActiveProject(ref, ref_str);
            });
          }
          return SupaBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/projects/:ref/dashboard',
            builder: (context, state) => DashboardScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/tables',
            builder: (context, state) => TablesScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/sql',
            builder: (context, state) => SqlEditorScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/auth',
            builder: (context, state) => AuthUsersScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/storage',
            builder: (context, state) => StorageScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/functions',
            builder: (context, state) => FunctionsScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/functions/secrets',
            builder: (context, state) => SecretsScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/settings',
            builder: (context, state) => ProjectSettingsScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/schema',
            builder: (context, state) => SchemaScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/policies',
            builder: (context, state) => PoliciesScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/realtime',
            builder: (context, state) => RealtimeConsoleScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/logs',
            builder: (context, state) => LogsScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/audit',
            builder: (context, state) => AuditLogsScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/infrastructure',
            builder: (context, state) => InfrastructureScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/sql',
            builder: (context, state) => SqlEditorScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/database',
            builder: (context, state) => DatabaseFunctionsScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/database/indexes',
            builder: (context, state) => IndexesScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/database/publications',
            builder: (context, state) => PublicationsScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/database/triggers',
            builder: (context, state) => TriggersScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/auth/policies',
            builder: (context, state) => PoliciesScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/auth/providers',
            builder: (context, state) => AuthProvidersScreen(projectRef: state.pathParameters['ref']!),
          ),
          GoRoute(
            path: '/projects/:ref/auth/stats',
            builder: (context, state) => AuthStatisticsScreen(projectRef: state.pathParameters['ref']!),
          ),
        ],
      ),
    ],
  );
});

void _syncActiveProject(Ref ref, String projectRef) async {
  final projects = await ref.read(projectsProvider.future);
  final project = projects.firstWhere((p) => p.ref == projectRef);
  if (ref.read(activeProjectProvider).value == null || ref.read(activeProjectProvider).value?.ref != projectRef) {
    ref.read(activeProjectProvider).value = project;
  }
}

