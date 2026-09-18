import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single labeled info row inside the Profile screen, e.g.
/// "HEIGHT" / "170 cm".
class ProfileInfoTile {
  const ProfileInfoTile({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;
}

/// Card that displays a group of profile info tiles (e.g. Height,
/// Weight, Fitness Level, Activity, Fitness Goal) with the GrindFit
/// dark/neon styling.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.tiles});

  final List<ProfileInfoTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            _buildTile(tiles[i]),
            if (i != tiles.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(color: AppColors.border, height: 1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(ProfileInfoTile tile) {
    return Row(
      children: [
        if (tile.icon != null) ...[
          Icon(tile.icon, size: 18, color: AppColors.neonCyan),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tile.label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(letterSpacing: 0.6),
              ),
              const SizedBox(height: 2),
              Text(tile.value, style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

/// Header card showing the user's name + email at the top of the
/// Profile screen.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key, required this.fullName, required this.email});

  final String fullName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonCyan, width: 1.5),
              boxShadow: AppShadows.neonGlow,
            ),
            child: const Icon(Icons.person, color: AppColors.neonCyan, size: 30),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            fullName.isEmpty ? 'GrindFit User' : fullName,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(email, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
