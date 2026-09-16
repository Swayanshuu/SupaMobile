import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SupportSupaAndroidCard extends StatelessWidget {
  const SupportSupaAndroidCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/support'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.supaGreen.withOpacity(0.05),
          border: Border.all(color: AppColors.supaGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.supaGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Support Supamobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Help us keep the project free forever.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
