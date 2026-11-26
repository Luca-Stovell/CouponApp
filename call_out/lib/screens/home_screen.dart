// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../widgets/stat_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/coupon_card.dart';
import 'create_coupon_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _expiringSoonOnly = false; // filter: only active expiring in 7 days
  bool _sortAscending = true; // sort by expiry asc/desc

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => widget.state.expireOverdue());
  }

  @override
  Widget build(BuildContext context) {
    widget.state.expireOverdue();

    final q = _searchCtrl.text.trim().toLowerCase();

    // Active — optional expiring-soon filter + search + sort
    List<Coupon> active =
        widget.state.activeCoupons.where((c) {
          final matchesSearch =
              q.isEmpty ||
              c.receiver.toLowerCase().contains(q) ||
              c.giver.toLowerCase().contains(q) ||
              c.note.toLowerCase().contains(q);
          final expiringSoon =
              !_expiringSoonOnly ||
              c.expiresAt.isBefore(DateTime.now().add(const Duration(days: 7)));
          return matchesSearch && expiringSoon;
        }).toList()..sort(
          (a, b) => _sortAscending
              ? a.expiresAt.compareTo(b.expiresAt)
              : b.expiresAt.compareTo(a.expiresAt),
        );

    // History — merged & searched, newest first
    final history =
        [...widget.state.redeemedCoupons, ...widget.state.expiredCoupons].where(
          (c) {
            final matchesSearch =
                q.isEmpty ||
                c.receiver.toLowerCase().contains(q) ||
                c.giver.toLowerCase().contains(q) ||
                c.note.toLowerCase().contains(q);
            return matchesSearch;
          },
        ).toList()..sort((a, b) => b.expiresAt.compareTo(a.expiresAt));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateCouponScreen(state: widget.state),
            ),
          );
          setState(() {}); // refresh after returning
        },
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              title: const Text('Call out'),
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.blurBackground,
                  StretchMode.fadeTitle,
                ],
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3A0CA3), Color(0xFF7B5CE8)],
                    ),
                  ),
                ),
              ),
            ),

            // Stats row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatChip(
                        label: 'Active',
                        value: widget.state.activeCoupons.length,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatChip(
                        label: 'Redeemed',
                        value: widget.state.redeemedCoupons.length,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatChip(
                        label: 'Expired',
                        value: widget.state.expiredCoupons.length,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search + filters card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search notes, giver, receiver',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            FilterChip(
                              label: const Text('Expiring ≤ 7 days'),
                              selected: _expiringSoonOnly,
                              onSelected: (v) =>
                                  setState(() => _expiringSoonOnly = v),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text(
                                _sortAscending
                                    ? 'Soonest first'
                                    : 'Latest first',
                              ),
                              selected: !_sortAscending,
                              onSelected: (_) => setState(
                                () => _sortAscending = !_sortAscending,
                              ),
                              avatar: Icon(
                                _sortAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            _sectionHeader("Your Coupons"),

            // Active list / Empty state
            if (active.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const EmptyState(
                        icon: Icons.post_add,
                        text: 'No active coupons — tap Create to issue one.',
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateCouponScreen(state: widget.state),
                            ),
                          );
                          setState(() {});
                        },
                        label: const Text('Create coupon'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: CouponCard(
                      coupon: active[i],
                      onRedeem: () =>
                          confirmRedeem(context, widget.state, active[i]),
                    ),
                  ),
                  childCount: active.length,
                ),
              ),

            _sectionHeader('History'),

            if (history.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyState(
                    icon: Icons.history,
                    text:
                        'No history yet. Redeemed and expired coupons will show here.',
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: CouponCard(coupon: history[i], onRedeem: null),
                  ),
                  childCount: history.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 72)),
          ],
        ),
      ),
    );
  }
}

/// Shared dialog helper (top-level) so RedeemScreen can call it too.
Future<void> confirmRedeem(
  BuildContext context,
  AppState state,
  Coupon c,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Redeem coupon?'),
      content: Text('Call out ${c.receiver} for “${c.note}”?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check_circle),
          onPressed: () => Navigator.pop(ctx, true),
          label: const Text('Redeem'),
        ),
      ],
    ),
  );
  if (ok == true) state.redeem(c.id);
}

// helper outside the class
SliverToBoxAdapter _sectionHeader(String title) => SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(thickness: 1, endIndent: 8)),
      ],
    ),
  ),
);
