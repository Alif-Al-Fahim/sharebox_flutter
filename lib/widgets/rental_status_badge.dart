import 'package:flutter/material.dart';
import '../models/rental_model.dart';
import '../theme/app_theme.dart';

class RentalStatusBadge extends StatelessWidget {
  final RentalStatus status;
  final bool showEmoji;

  const RentalStatusBadge({
    super.key,
    required this.status,
    this.showEmoji = true,
  });

  Color get _color {
    switch (status) {
      case RentalStatus.pending:
        return AppTheme.warningColor;
      case RentalStatus.accepted:
        return AppTheme.primaryColor;
      case RentalStatus.active:
        return AppTheme.secondaryColor;
      case RentalStatus.completed:
        return AppTheme.successColor;
      case RentalStatus.cancelled:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        showEmoji
            ? '${status.emoji} ${status.displayName}'
            : status.displayName,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const AvailabilityBadge({super.key, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppTheme.successColor : AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
