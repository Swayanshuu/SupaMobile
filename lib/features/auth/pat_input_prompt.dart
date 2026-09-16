import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/supa_button.dart';
import '../../widgets/supa_text_field.dart';

void showPatInputPrompt(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Experimental Access Token',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Create a token in your Supabase Account Settings > Access Tokens.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SupaTextField(
            controller: controller,
            label: 'Access Token',
            placeholder: 'sbp_...',
            isPassword: true,
            prefixIcon: Icons.vpn_key_outlined,
          ),
          const SizedBox(height: 24),
          SupaButton(
            text: 'Save Token',
            width: double.infinity,
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await ref.read(patActionsProvider).setPat(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Experimental Access Token saved')),
                );
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}

