import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';

class SubNavItem {
  final String label;
  final String route;
  const SubNavItem({required this.label, required this.route});
}

class SupaSubNav extends StatelessWidget implements PreferredSizeWidget {
  final List<SubNavItem> items;
  final String currentRoute;
  const SupaSubNav({super.key, required this.items, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.bgOverlay,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final bool isSelected = currentRoute == item.route;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: () {
                if (!isSelected) {
                  context.push(item.route);
                }
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.supaGreen : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

