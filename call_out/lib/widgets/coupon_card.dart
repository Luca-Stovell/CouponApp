// lib/widgets/coupon_card.dart
import 'package:flutter/material.dart';
import '../state/app_state.dart';

class CouponCard extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback? onRedeem;
  const CouponCard({super.key, required this.coupon, this.onRedeem});

  Color _statusColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (coupon.status) {
      case CouponStatus.active:
        return scheme.primaryContainer;
      case CouponStatus.redeemed:
        return scheme.secondaryContainer;
      case CouponStatus.expired:
        return scheme.errorContainer;
    }
  }

  IconData _statusIcon() {
    switch (coupon.status) {
      case CouponStatus.active:
        return Icons.local_activity_outlined;
      case CouponStatus.redeemed:
        return Icons.verified_outlined;
      case CouponStatus.expired:
        return Icons.hourglass_disabled_outlined;
    }
  }

  String _statusLabel() {
    switch (coupon.status) {
      case CouponStatus.active:
        return 'Active';
      case CouponStatus.redeemed:
        return 'Redeemed';
      case CouponStatus.expired:
        return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final expires =
        'Expires: ${coupon.expiresAt.year}-${_pad(coupon.expiresAt.month)}-${_pad(coupon.expiresAt.day)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onRedeem,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _statusColor(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.note,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${coupon.giver} → ${coupon.receiver}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    expires,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (onRedeem != null)
                    FilledButton.icon(
                      onPressed: onRedeem,
                      icon: const Icon(Icons.how_to_reg),
                      label: const Text('Redeem'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// keep helpers OUTSIDE the widget class
String _pad(int n) => n < 10 ? '0$n' : '$n';
