
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/management_api.dart';
import '../../core/api/management_api_client.dart';
import '../../core/providers/core_providers.dart';
import '../../widgets/supa_text_field.dart';
import '../../widgets/supa_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _patController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _patController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllKeysInBackground(ManagementApi api, List<dynamic> projects) async {
    final storage = ref.read(secureStorageProvider);
    for (final project in projects) {
      try {
        final projectRef = project.ref as String;
        final keys = await api.getApiKeys(projectRef);
        if (keys['service_role'] != null && keys['service_role']!.isNotEmpty) {
          await storage.saveServiceKey(projectRef, keys['service_role']!);
        }
        if (keys['anon'] != null && keys['anon']!.isNotEmpty) {
          await storage.saveAnonKey(projectRef, keys['anon']!);
        }
      } catch (_) {
        // Silently ignore individual project errors
      }
    }
  }

  Future<void> _handleConnect() async {
    final pat = _patController.text.trim();
    if (pat.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid token');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Real API validation call
      final api = ManagementApi(client: ManagementApiClient(pat: pat));
      final projects = await api.getProjects(); 
      
      await ref.read(patActionsProvider).setPat(pat);
      
      // Start background fetch for all project keys automatically
      _fetchAllKeysInBackground(api, projects);
      
      if (mounted) {
        context.go('/projects');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }


  void _showTokenHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to get a token',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '1. Go to supabase.com/dashboard',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '2. Click on your profile at the bottom left',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '3. Go to Access Tokens',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '4. Generate a new token and paste it here',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.contain,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Supamobile',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Connect your Supabase account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter your Experimental Access Token from supabase.com/dashboard/account/tokens',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                ),

                const SizedBox(height: 24),
                SupaTextField(
                  label: 'Experimental Access Token',
                  placeholder: 'sbp_...',
                  controller: _patController,
                  isPassword: true,
                  isCode: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.colorError,
                        ),
                  ),
                ],
                const SizedBox(height: 24),
                SupaButton(
                  text: _isLoading ? 'Connecting...' : 'Connect with Token',
                  isLoading: _isLoading,
                  onPressed: _handleConnect,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => _showTokenHelp(context),
                    child: Text(
                      'How to get a token →',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

