// lib/state/app_state.dart
import 'package:flutter/foundation.dart';

class User {
  final String firstName;
  final String lastName;
  final String username;
  final String password; // demo only
  const User({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
  });
}

enum CouponStatus { active, redeemed, expired }

@immutable
class Coupon {
  final String id;
  final String giver; // username of issuer
  final String receiver; // name/username of current owner
  final String note;
  final DateTime expiresAt;
  final CouponStatus status;
  final DateTime? redeemedAt;

  const Coupon({
    required this.id,
    required this.giver,
    required this.receiver,
    required this.note,
    required this.expiresAt,
    required this.status,
    this.redeemedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Coupon copyWith({
    String? id,
    String? giver,
    String? receiver,
    String? note,
    DateTime? expiresAt,
    CouponStatus? status,
    DateTime? redeemedAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      giver: giver ?? this.giver,
      receiver: receiver ?? this.receiver,
      note: note ?? this.note,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      redeemedAt: redeemedAt ?? this.redeemedAt,
    );
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class ActivityItem {
  final String text;
  final DateTime at;
  const ActivityItem(this.text, this.at);
}

class AppState extends ChangeNotifier {
  // Demo users/friends
  final List<User> users = [
    const User(
      firstName: 'Luca',
      lastName: 'Stovell',
      username: 'luca',
      password: 'pass123',
    ),
    const User(
      firstName: 'Mia',
      lastName: 'Tran',
      username: 'mia',
      password: 'pass123',
    ),
    const User(
      firstName: 'Sam',
      lastName: 'Lee',
      username: 'sam',
      password: 'pass123',
    ),
  ];
  final List<String> friends = [
    'Luca',
    'Guy',
    'Jack',
    'Matt',
    'Kayla',
    'Zane',
    'Bridie',
    'Cailaen',
  ];

  String? currentUsername;

  // --- Legacy getters used by the current UI ---
  List<Coupon> get activeCoupons =>
      _coupons.where((c) => c.status == CouponStatus.active).toList();

  List<Coupon> get redeemedCoupons =>
      _coupons.where((c) => c.status == CouponStatus.redeemed).toList();

  List<Coupon> get expiredCoupons =>
      _coupons.where((c) => c.status == CouponStatus.expired).toList();

  // Optional: keep old UI calls working if it used redeemCoupon(...)
  void redeemCoupon(String id) => redeem(id);

  // Demo coupons
  final List<Coupon> _coupons = [
    Coupon(
      id: Coupon.newId(),
      giver: 'Luca',
      receiver: 'Sam', // first name variant
      note: 'Friday night drinks 🍻',
      expiresAt: DateTime.now().add(const Duration(days: 10)),
      status: CouponStatus.active,
    ),
    Coupon(
      id: Coupon.newId(),
      giver: 'Matt',
      receiver: 'luca', // username variant
      note: 'Beach day 🏄',
      expiresAt: DateTime.now().add(const Duration(days: 3)),
      status: CouponStatus.active,
    ),
  ];

  final List<ActivityItem> _activity = [
    ActivityItem(
      'guy issued a coupon to Luca (Beach day)',
      DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ActivityItem(
      'Luca created a coupon for Sam (Friday drinks)',
      DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ---- Auth ----
  bool login(String username, String password) {
    final ok = users.any(
      (u) => u.username == username && u.password == password,
    );
    if (ok) {
      currentUsername = username;
      notifyListeners();
    }
    return ok;
  }

  bool register({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
  }) {
    if (users.any((u) => u.username == username)) return false;
    users.add(
      User(
        firstName: firstName,
        lastName: lastName,
        username: username,
        password: password,
      ),
    );
    currentUsername = username;
    notifyListeners();
    return true;
  }

  void logout() {
    currentUsername = null;
    notifyListeners();
  }

  // ---- Coupons ----
  List<Coupon> get allCoupons => List.unmodifiable(_coupons);

  // Kept for backward compatibility (expects "me" to be username; matches strictly)
  List<Coupon> issuedByMe(String me) =>
      _coupons.where((c) => c.giver == me).toList();

  // Kept for backward compatibility (strict username match)
  List<Coupon> receivedByMe(String me) => _coupons
      .where((c) => c.receiver.toLowerCase() == me.toLowerCase())
      .toList();

  /// New: robust ownership filter. Works if `receiver` stores either username or first name/full name.
  List<Coupon> couponsOwnedBy(String who) {
    final handle = _canon(who);
    // Try to resolve to a known user for name variants
    final u = _userByUsername(who) ?? _userByFirstOrFullName(who);
    final first = u?.firstName.toLowerCase();
    final full = u == null
        ? null
        : '${u.firstName} ${u.lastName}'.toLowerCase();

    return _coupons.where((c) {
      final r = c.receiver.toLowerCase();
      return r == handle ||
          (first != null && r == first) ||
          (full != null && r == full);
    }).toList();
  }

  void addCoupon(Coupon c) {
    _coupons.add(c);
    _activity.insert(
      0,
      ActivityItem(
        '${c.giver} issued a coupon to ${c.receiver} (${c.note})',
        DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void redeem(String id) {
    final idx = _coupons.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final c = _coupons[idx];
    if (c.isExpired) {
      _coupons[idx] = c.copyWith(status: CouponStatus.expired);
    } else {
      _coupons[idx] = c.copyWith(
        status: CouponStatus.redeemed,
        redeemedAt: DateTime.now(),
      );
      _activity.insert(
        0,
        ActivityItem(
          '${c.receiver} redeemed a coupon from ${c.giver}',
          DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  void expireOverdue() {
    bool changed = false;
    for (var i = 0; i < _coupons.length; i++) {
      if (_coupons[i].isExpired && _coupons[i].status == CouponStatus.active) {
        _coupons[i] = _coupons[i].copyWith(status: CouponStatus.expired);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  List<ActivityItem> recentActivity([int limit = 5]) =>
      _activity.take(limit).toList();

  // ---------------------------
  // Trade feature
  // ---------------------------

  /// Swap ownership (receiver) of two active, non-expired coupons.
  /// - `myCouponId`: coupon you currently own
  /// - `theirCouponId`: coupon owned by someone else
  ///
  /// Throws ArgumentError / StateError with user-friendly messages on invalid input.
  void tradeCoupons({
    required String myCouponId,
    required String theirCouponId,
  }) {
    if (currentUsername == null) {
      throw StateError('Not logged in.');
    }
    final me = currentUsername!;

    final i = _coupons.indexWhere((c) => c.id == myCouponId);
    final j = _coupons.indexWhere((c) => c.id == theirCouponId);
    if (i == -1) throw ArgumentError('Your selected coupon was not found.');
    if (j == -1) throw ArgumentError('The other coupon was not found.');
    if (i == j) throw ArgumentError('Choose two different coupons to trade.');

    final mine = _coupons[i];
    final theirs = _coupons[j];

    if (mine.status != CouponStatus.active ||
        theirs.status != CouponStatus.active) {
      throw ArgumentError('Only active coupons can be traded.');
    }
    if (mine.isExpired || theirs.isExpired) {
      throw ArgumentError('One of the coupons is expired.');
    }
    if (!_ownsCoupon(mine, me)) {
      throw ArgumentError('You do not own the selected “your” coupon.');
    }
    if (_ownsCoupon(theirs, me)) {
      throw ArgumentError('The selected “their” coupon is already yours.');
    }

    // Swap current owners.
    final otherOwnerString =
        theirs.receiver; // preserve exactly how it’s stored
    final myOwnerString = me; // store your username (consistent)

    _coupons[i] = mine.copyWith(receiver: otherOwnerString);
    _coupons[j] = theirs.copyWith(receiver: myOwnerString);

    // Activity log entry (nice readable names)
    final meLabel = _labelForUsername(me);
    final otherLabel =
        otherOwnerString; // already human-friendly (may be "Sam")

    _activity.insert(
      0,
      ActivityItem(
        '$meLabel traded “${mine.note}” with $otherLabel for “${theirs.note}”.',
        DateTime.now(),
      ),
    );

    notifyListeners();
  }

  /// Convenience: your currently-owned coupons (resolves username/name correctly).
  List<Coupon> myCoupons() =>
      currentUsername == null ? <Coupon>[] : couponsOwnedBy(currentUsername!);

  // ---------------------------
  // Private helpers
  // ---------------------------

  String _canon(String s) => s.trim().toLowerCase();

  User? _userByUsername(String username) {
    final h = _canon(username);
    for (final u in users) {
      if (u.username.toLowerCase() == h) return u;
    }
    return null;
  }

  User? _userByFirstOrFullName(String name) {
    final h = _canon(name);
    for (final u in users) {
      if (u.firstName.toLowerCase() == h) return u;
      final full = '${u.firstName} ${u.lastName}'.toLowerCase();
      if (full == h) return u;
    }
    return null;
  }

  bool _ownsCoupon(Coupon c, String meUsername) {
    final r = c.receiver.toLowerCase();
    final me = _userByUsername(meUsername);
    if (r == meUsername.toLowerCase()) return true;
    if (me == null) return false;
    if (r == me.firstName.toLowerCase()) return true;
    if (r == ('${me.firstName} ${me.lastName}').toLowerCase()) return true;
    return false;
    // (Add more variants here if you later allow nicknames/displayNames)
  }

  String _labelForUsername(String username) {
    final u = _userByUsername(username);
    return u?.firstName ?? username;
  }
}
