import 'package:cloud_firestore/cloud_firestore.dart';

class UserSubscription {
  final String id;
  final String userId;
  final String subscriptionId;
  final DateTime startDate;
  final DateTime nextBillingDate;
  final String status;
  final int remainingCredits;
  final int remainingDeliveries;
  final String? membershipTierId;

  UserSubscription({
    this.id = '',
    required this.userId,
    required this.subscriptionId,
    required this.startDate,
    required this.nextBillingDate,
    required this.status,
    required this.remainingCredits,
    required this.remainingDeliveries,
    this.membershipTierId,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'subscription_id': subscriptionId,
      'start_date': Timestamp.fromDate(startDate),
      'next_billing_date': Timestamp.fromDate(nextBillingDate),
      'status': status,
      'remaining_credits': remainingCredits,
      'remaining_deliveries': remainingDeliveries,
      'membership_tier': membershipTierId,
    };
  }

  factory UserSubscription.fromMap(Map<String, dynamic> map, String docId) {
    return UserSubscription(
      id: docId,
      userId: map['user_id'] ?? '',
      subscriptionId: map['subscription_id'] ?? '',
      startDate: (map['start_date'] as Timestamp).toDate(),
      nextBillingDate: (map['next_billing_date'] as Timestamp).toDate(),
      status: map['status'] ?? 'inactive',
      remainingCredits: map['remaining_credits'] ?? 0,
      remainingDeliveries: map['remaining_deliveries'] ?? 0,
      membershipTierId: map['membership_tier'],
    );
  }
}
