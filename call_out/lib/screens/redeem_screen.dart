import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/coupon_card.dart';
import 'home_screen.dart'; // keep this to get confirmRedeem()

class RedeemScreen extends StatelessWidget {
  final AppState state;
  const RedeemScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final items = state.activeCoupons;
    return Scaffold(
      appBar: AppBar(title: const Text('Redeem')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.how_to_reg_outlined,
              text: 'No coupons available to redeem.',
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final c = items[i];
                return CouponCard(
                  coupon: c,
                  onRedeem: () => confirmRedeem(context, state, c),
                );
              },
            ),
    );
  }
}
