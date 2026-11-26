// lib/models/coupon.dart
class Coupon {
  final String id;
  final String title;
  String ownerId; // who currently holds/owns this coupon
  final String issuerId; // who originally created it
  final DateTime expiresAt;

  Coupon({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.issuerId,
    required this.expiresAt,
  });
}
