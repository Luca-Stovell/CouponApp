// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'create_coupon_screen.dart';
import 'trade_coupon_screen.dart'; // <-- add this

class FriendsScreen extends StatelessWidget {
  final AppState state;
  const FriendsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final friends = state.friends;
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: friends.isEmpty
          ? const Center(child: Text('No friends yet'))
          : ListView.separated(
              itemCount: friends.length,
              separatorBuilder: (_, __) => const Divider(height: 5),
              itemBuilder: (_, i) {
                final name = friends[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(name[0])),
                  title: Text(name),
                  // Put Issue + Trade buttons side-by-side
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Issue'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateCouponScreen(
                                state: state,
                                presetReceiver: name,
                              ),
                            ),
                          );
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Trade'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TradeCouponScreen(
                                state: state,
                                presetFriend: name, // preselect this friend
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
