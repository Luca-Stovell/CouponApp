// lib/screens/trade_coupon_screen.dart
import 'package:flutter/material.dart';
import '../state/app_state.dart';

class TradeCouponScreen extends StatefulWidget {
  final AppState state; // <-- pass state in
  final String? presetFriend; // optional preselection from Friends screen

  const TradeCouponScreen({super.key, required this.state, this.presetFriend});

  @override
  State<TradeCouponScreen> createState() => _TradeCouponScreenState();
}

class _TradeCouponScreenState extends State<TradeCouponScreen> {
  String? _selectedFriend; // friend is a String name in AppState
  Coupon? _myCoupon;
  Coupon? _theirCoupon;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedFriend = widget.presetFriend; // preselect if passed in
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.state; // <-- use the passed state (no Provider)

    // If not logged in, block the screen gracefully
    if (app.currentUsername == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trade Coupons')),
        body: const Center(child: Text('Please log in to trade coupons.')),
      );
    }

    final myHandle = app.currentUsername!; // username string
    final myCoupons = app.couponsOwnedBy(myHandle);
    final friendCoupons = _selectedFriend == null
        ? <Coupon>[]
        : app.couponsOwnedBy(_selectedFriend!);

    return Scaffold(
      appBar: AppBar(title: const Text('Trade Coupons')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text(
                'Choose a friend and pick one of your coupons to swap for one of theirs.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),

              // Friend picker (friends is List<String>)
              DropdownButtonFormField<String>(
                value: _selectedFriend,
                decoration: const InputDecoration(
                  labelText: 'Friend',
                  border: OutlineInputBorder(),
                ),
                items: app.friends
                    .map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    )
                    .toList(),
                onChanged: (name) {
                  setState(() {
                    _selectedFriend = name;
                    _theirCoupon =
                        null; // clear their coupon when friend changes
                  });
                },
              ),
              const SizedBox(height: 16),

              // My coupon picker
              DropdownButtonFormField<Coupon>(
                value: _myCoupon,
                decoration: const InputDecoration(
                  labelText: 'Your coupon',
                  border: OutlineInputBorder(),
                ),
                items: myCoupons
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        // Coupon has "note" (no "title" in your model)
                        child: Text('${c.note} (exp ${_fmt(c.expiresAt)})'),
                      ),
                    )
                    .toList(),
                onChanged: (c) => setState(() => _myCoupon = c),
              ),
              const SizedBox(height: 16),

              // Their coupon picker (depends on friend)
              DropdownButtonFormField<Coupon>(
                value: _theirCoupon,
                decoration: const InputDecoration(
                  labelText: 'Their coupon',
                  border: OutlineInputBorder(),
                ),
                items: friendCoupons
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.note} (exp ${_fmt(c.expiresAt)})'),
                      ),
                    )
                    .toList(),
                onChanged: (c) => setState(() => _theirCoupon = c),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed:
                    (_selectedFriend != null &&
                        _myCoupon != null &&
                        _theirCoupon != null &&
                        !_submitting)
                    ? () async {
                        setState(() => _submitting = true);
                        try {
                          app.tradeCoupons(
                            myCouponId: _myCoupon!.id,
                            theirCouponId: _theirCoupon!.id,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Trade completed!')),
                          );
                          Navigator.of(context).pop();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      }
                    : null,
                icon: const Icon(Icons.swap_horiz),
                label: Text(
                  _submitting ? 'Trading…' : 'Trade selected coupons',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().padLeft(4, '0')}';
}
