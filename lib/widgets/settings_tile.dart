import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_sizes.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMedium)),
        leading: Container(
          padding: EdgeInsets.all(AppSizes.paddingSmall),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
          child: Icon(icon, color: iconColor, size: AppSizes.iconXLarge),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.fontXLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: AppSizes.fontSmall,
            color: AppColors.textWhite54,
          ),
        ),
        trailing: onTap != null
            ? Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textWhite24, size: AppSizes.iconSmall)
            : null,
      ),
    );
  }
}
