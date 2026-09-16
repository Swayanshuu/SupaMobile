import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_drawer.dart';
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('About SupaMobile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const SupaDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                const SizedBox(height: 32),
                _buildPrivacyCard(),
                const SizedBox(height: 24),
                _buildArchitectureCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: AppColors.supaGreen, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 60,
            backgroundImage: const AssetImage('assets/logo.png'),
            backgroundColor: AppColors.bgSurface,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'SupaMobile',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        Text(
          'The Unofficial Pocket Admin for Supabase',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.supaGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_moon_rounded, color: AppColors.supaGreen, size: 32),
          ),
          const SizedBox(height: 24),
          const Text(
            '100% Privacy Focused',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'This app collects absolutely nothing from you. No analytics, no telemetry, no tracking. We don\'t know who you are, what projects you have, or what data you manage.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.borderDefault.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The only exception is if you choose to make a donation to support the developer, in which case the payment processor will process your transaction securely.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildArchitectureCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.architecture_rounded, color: AppColors.textPrimary, size: 24),
              const SizedBox(width: 12),
              const Text(
                'How it Works',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'SupaMobile operates completely without its own backend server. But how does the app show your data?',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildAnalogy(),
        ],
      ),
    );
  }

  Widget _buildAnalogy() {
    return Column(
      children: [
        _buildAnalogyStep(
          icon: Icons.water_drop_rounded,
          title: 'The Reservoir (Supabase)',
          description: 'Think of your actual Supabase project as a massive water reservoir holding all your precious data.',
        ),
        _buildArrow(),
        _buildAnalogyStep(
          icon: Icons.key_rounded,
          title: 'The Pipeline (Access Token)',
          description: 'Your Experimental Access Token acts as a direct, secure pipeline. It connects the app straight to your reservoir.',
        ),
        _buildArrow(),
        _buildAnalogyStep(
          icon: Icons.view_quilt_rounded,
          title: 'The Containers (SupaMobile)',
          description: 'The screens in this app (like the SQL Editor or Tables) are just empty containers. The moment you enter your token, data flows directly from the reservoir into your containers.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.supaGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.supaGreen.withOpacity(0.2)),
          ),
          child: const Text(
            'There are no middlemen intercepting the flow. Your data travels straight from Supabase directly to your phone screen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.supaGreen, fontWeight: FontWeight.bold, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalogyStep({required IconData icon, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Icon(Icons.arrow_downward_rounded, color: AppColors.textMuted, size: 20),
    );
  }
}
