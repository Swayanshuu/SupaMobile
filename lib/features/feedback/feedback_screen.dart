import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_drawer.dart';
import '../../widgets/supa_button.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  Future<void> _launchURL(String url, BuildContext context) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Feedback & Requests', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 48),
                _buildPlayStoreCard(context),
                const SizedBox(height: 24),
                _buildFeatureRequestCard(context),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.supaGreen.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.forum_rounded, color: AppColors.supaGreen, size: 48),
        ),
        const SizedBox(height: 24),
        const Text(
          'We Value Your Voice',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const SizedBox(height: 12),
        Text(
          'SupaMobile is built for the community. Your feedback and ideas directly shape the future of this app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildPlayStoreCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shop_rounded, color: Colors.blueAccent, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rate & Comment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Have general feedback or just want to show some love? Leave a rating and comment on the Google Play Store! It helps us grow immensely.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SupaButton(
            text: 'Open Play Store',
            width: double.infinity,
            color: Colors.blueAccent,
            onPressed: () {
              // Replace with actual Play Store package name URL when published
              _launchURL('https://play.google.com/store/apps/details?id=com.example.supamobile', context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRequestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withOpacity(0.6),
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
            child: const Icon(Icons.lightbulb_rounded, color: AppColors.supaGreen, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Feature Requests & Bugs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Missing a specific Supabase feature? Found a bug? Send us an email with your request and we will look into adding it in the next update.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SupaButton(
            text: 'Submit Request',
            width: double.infinity,
            color: AppColors.supaGreen,
            onPressed: () {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'support@supamobile.app',
                queryParameters: {'subject': 'SupaMobile Feature Request / Feedback'},
              );
              _launchURL(emailUri.toString(), context);
            },
          ),
        ],
      ),
    );
  }
}
