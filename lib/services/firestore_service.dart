import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_service.dart';
import 'membership_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();
  final MembershipService _membershipService = MembershipService();

  Future<void> initializeDatabase() async {
    try {
      // Check if collections already exist
      QuerySnapshot subsSnapshot =
          await _firestore.collection('subscriptions').limit(1).get();
      QuerySnapshot membersSnapshot =
          await _firestore.collection('membership_tiers').limit(1).get();

      if (subsSnapshot.docs.isEmpty) {
        await _subscriptionService.addSubscriptionPlans();
      }

      if (membersSnapshot.docs.isEmpty) {
        await _membershipService.addMembershipTiers();
      }

      // After adding subscription plans, get Ultra Life subscription ID
      // and update Pro membership tier to include it as compatible
      if (subsSnapshot.docs.isEmpty && membersSnapshot.docs.isEmpty) {
        // Wait for data to be properly written
        await Future.delayed(const Duration(seconds: 1));

        // Get Ultra Life subscription
        QuerySnapshot ultraLifeQuery =
            await _firestore
                .collection('subscriptions')
                .where('name', isEqualTo: 'Ultra Life')
                .get();

        if (ultraLifeQuery.docs.isNotEmpty) {
          String ultraLifeId = ultraLifeQuery.docs.first.id;

          // Get Pro membership tier
          QuerySnapshot proTierQuery =
              await _firestore
                  .collection('membership_tiers')
                  .where('name', isEqualTo: 'Pro')
                  .get();

          if (proTierQuery.docs.isNotEmpty) {
            String proTierId = proTierQuery.docs.first.id;

            // Update Pro tier with Ultra Life subscription
            await _membershipService.updateCompatibleSubscriptions(proTierId, [
              ultraLifeId,
            ]);
          }
        }
      }
    } catch (e) {
      print('Error initializing database: $e');
    }
  }
}
