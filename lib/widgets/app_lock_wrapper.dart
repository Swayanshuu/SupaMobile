import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/lock_provider.dart';
import '../core/providers/security_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/trial_provider.dart';
import '../core/services/subscription_service.dart';
import 'supa_button.dart';
import 'package:go_router/go_router.dart';

class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper> with WidgetsBindingObserver {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Use addPostFrameCallback to ensure all providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock when app is paused/hidden if enabled
    // Only lock when going to background (paused)
    if (state == AppLifecycleState.paused) {
      _lockIfEnabled();
    }
  }

  Future<void> _checkInitialLock() async {
    final enabled = await ref.read(biometricsEnabledProvider.future);
    final alreadyUnlocked = ref.read(appUnlockedProvider).value;

    if (enabled && !alreadyUnlocked) {
      // Keep _isChecking true while we're about to show the lock screen
      setState(() => _isChecking = false);
    } else {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _lockIfEnabled() async {
    final enabled = await ref.read(biometricsEnabledProvider.future);
    if (enabled) {
      ref.read(appUnlockedProvider).value = false;
    }
  }

  Future<void> _authenticate() async {
    final success = await ref.read(securityProvider).verify();
    if (success) {
      ref.read(appUnlockedProvider).value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final biometricsEnabledAsync = ref.watch(biometricsEnabledProvider);
    final unlockedNotifier = ref.watch(appUnlockedProvider);

    return ListenableBuilder(
      listenable: unlockedNotifier,
      builder: (context, _) {
        final isUnlocked = unlockedNotifier.value;
        final biometricsEnabled = biometricsEnabledAsync.asData?.value ?? false;

        final trialState = ref.watch(trialStateProvider);
        final isDonationDismissedNotifier = ref.watch(donationDismissedProvider);

        return ListenableBuilder(
          listenable: isDonationDismissedNotifier,
          builder: (context, _) {
            Widget? overlay;
            if (trialState == TrialState.free && !isDonationDismissedNotifier.value) {
              overlay = Scaffold(
            backgroundColor: AppColors.bgBase,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.supaGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.supaGreen, size: 64),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Enjoying SupaMobile?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You\'ve been using the app for 30 days! The app remains completely free with no locked features, but please consider a one-time donation to keep the project alive.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.6, fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'One-time Minimum Donation',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMinBox('₹179'),
                              const SizedBox(width: 12),
                              Text('OR', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              const SizedBox(width: 12),
                              _buildMinBox('\$2.99'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SupaButton(
                      text: 'Support the Developer',
                      width: double.infinity,
                      height: 64,
                      onPressed: () => context.push('/pricing'),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        ref.read(donationDismissedProvider).value = true;
                      },
                      child: Text(
                        'Dismiss',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Long live the developer community ❤️',
                      style: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (biometricsEnabled && !isUnlocked) {
          overlay = Scaffold(
            backgroundColor: AppColors.bgBase,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.supaGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fingerprint_rounded, size: 64, color: AppColors.supaGreen),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'App Locked',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please authenticate with biometrics\nto access your Supabase metrics',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 48),
                    SupaButton(
                      text: 'Unlock App',
                      onPressed: _authenticate,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

            return Stack(
              children: [
                widget.child,
                if (overlay != null) Positioned.fill(child: overlay),
              ],
            );
        },
      );
    });
  }
  Widget _buildMinBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.supaGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.supaGreen.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.supaGreen),
      ),
    );
  }
}
