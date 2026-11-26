// lib/screens/root_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../state/app_state.dart';
import 'challanges_screen.dart';
import 'home_screen.dart';
import 'create_coupon_screen.dart';
import 'friends_screen.dart';
import 'redeem_screen.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  final AppState state = AppState();
  int idx = 1;

  @override
  void initState() {
    super.initState();
    // Demo: the app starts on /home without going through login, so sign in
    // the demo user here. Otherwise Trade always says "Please log in".
    state.currentUsername ??= 'luca';
    state.addListener(_onStateChanged);
  }

  // HomeScreen calls state.expireOverdue() inside build(), which can notify
  // listeners mid-build. Defer the rebuild to after the frame in that case to
  // avoid "setState() called during build".
  void _onStateChanged() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    state.removeListener(_onStateChanged);
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CreateCouponScreen(state: state),
      ChallengesScreen(state: state),
      HomeScreen(state: state),
      FriendsScreen(state: state),
      RedeemScreen(state: state),
    ];

    return Scaffold(
      body: SafeArea(child: screens[idx]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Challenges', // <-- new tab
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: 'Redeem',
          ),
        ],
      ),
    );
  }
}
