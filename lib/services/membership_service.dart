import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/membership_tier.dart';

class MembershipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add membership tiers
  Future<void> addMembershipTiers() async {
    try {
      // Free tier
      await _firestore.collection('membership_tiers').add({
        'name': 'Free',
        'price': 0,
        'billing_cycle': 'monthly',
        'features': ['Basic dashboard'],
        'is_popular': false,
        'compatible_subscriptions': [],
      });

      // Pro tier
      await _firestore.collection('membership_tiers').add({
        'name': 'Pro',
        'price': 9.99,
        'billing_cycle': 'monthly',
        'features': [
          'Free delivery on all orders',
          'Personalized meal recommendations',
          'Full reward access',
          'Double points',
        ],
        'is_popular': true,
        'compatible_subscriptions':
            [], // Add Ultra Life subscription ID once created
      });

      // Ultra tier
      await _firestore.collection('membership_tiers').add({
        'name': 'Ultra',
        'price': 19.99,
        'billing_cycle': 'monthly',
        'features': ['All Pro features'],
        'is_popular': false,
        'compatible_subscriptions': [],
      });
    } catch (e) {
      print('Error adding membership tiers: $e');
    }
  }

  // Get all membership tiers
  Future<List<MembershipTier>> getAllMembershipTiers() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('membership_tiers').get();
      return snapshot.docs
          .map(
            (doc) => MembershipTier.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting membership tiers: $e');
      return [];
    }
  }

  // Assign membership tier to user
  Future<void> assignMembershipToUser(String userId, String tierId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'membership_tier_id': tierId,
      });
    } catch (e) {
      print('Error assigning membership tier: $e');
    }
  }

  // Update compatible subscriptions for a tier
  Future<void> updateCompatibleSubscriptions(
    String tierId,
    List<String> subscriptionIds,
  ) async {
    try {
      await _firestore.collection('membership_tiers').doc(tierId).update({
        'compatible_subscriptions': subscriptionIds,
      });
    } catch (e) {
      print('Error updating compatible subscriptions: $e');
    }
  }
}
