import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_sizes.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String role;

  const ProfileCard({
    super.key,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.textWhite.withAlpha(10), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.purple.shade900,
            child: Icon(Icons.person_rounded, size: 35, color: AppColors.textWhite),
          ),
          SizedBox(width: AppSizes.spaceLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: AppSizes.fontTitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                SizedBox(height: AppSizes.spaceXSmall),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: AppSizes.fontXLarge,
                    color: AppColors.textWhite54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
