import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';
import '../models/user_subscription.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add subscription plans
  Future<void> addSubscriptionPlans() async {
    try {
      // Balanced Bite plan
      await _firestore.collection('subscriptions').add({
        'name': 'Balanced Bite',
        'price': 138,
        'billing_cycle': 'weekly',
        'credits': 8,
        'meals_range': '7-9',
        'meal_price_range': '\$15-\$17.25',
        'free_deliveries': 2,
        'features': ['Free tier access'],
        'is_popular': true,
      });

      // Smart Start plan
      await _firestore.collection('subscriptions').add({
        'name': 'Smart Start',
        'price': 75,
        'billing_cycle': 'weekly',
        'credits': 5,
        'meals_range': '5-6',
        'meal_price_range': '\$15-\$17',
        'free_deliveries': 1,
        'features': [],
        'is_popular': false,
      });

      // Flex Fuel plan
      await _firestore.collection('subscriptions').add({
        'name': 'Flex Fuel',
        'price': 105,
        'billing_cycle': 'weekly',
        'credits': 6,
        'meals_range': '6-7',
        'meal_price_range': '\$15-\$17',
        'free_deliveries': 2,
        'features': [],
        'is_popular': true,
      });

      // Ultra Life plan
      await _firestore.collection('subscriptions').add({
        'name': 'Ultra Life',
        'price': 159,
        'billing_cycle': 'weekly',
        'credits': 11,
        'meals_range': '9-12',
        'meal_price_range': '\$15-\$17.25',
        'free_deliveries': 3,
        'features': ['Pro membership included'],
        'is_popular': false,
      });
    } catch (e) {
      print('Error adding subscription plans: $e');
    }
  }

  // Get all subscriptions
  Future<List<Subscription>> getAllSubscriptions() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('subscriptions').get();
      return snapshot.docs
          .map(
            (doc) => Subscription.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting subscriptions: $e');
      return [];
    }
  }

  // Subscribe a user to a plan
  Future<String> subscribeUserToPlan({
    required String userId,
    required String subscriptionId,
    String? membershipTierId,
  }) async {
    try {
      // Get subscription details
      DocumentSnapshot subscriptionDoc =
          await _firestore
              .collection('subscriptions')
              .doc(subscriptionId)
              .get();
      Map<String, dynamic> subscriptionData =
          subscriptionDoc.data() as Map<String, dynamic>;

      // Create user subscription
      DocumentReference userSubRef = await _firestore
          .collection('user_subscriptions')
          .add({
            'user_id': userId,
            'subscription_id': subscriptionId,
            'start_date': Timestamp.now(),
            'next_billing_date': Timestamp.fromDate(
              DateTime.now().add(
                const Duration(days: 7),
              ), // Weekly billing cycle
            ),
            'status': 'active',
            'remaining_credits': subscriptionData['credits'],
            'remaining_deliveries': subscriptionData['free_deliveries'],
            'membership_tier': membershipTierId,
          });

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'active_subscription_id': userSubRef.id,
        'membership_tier_id': membershipTierId,
        'credits_balance': subscriptionData['credits'],
      });

      return userSubRef.id;
    } catch (e) {
      print('Error subscribing user to plan: $e');
      return '';
    }
  }

  // Get user's active subscription
  Future<UserSubscription?> getUserActiveSubscription(String userId) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('user_subscriptions')
              .where('user_id', isEqualTo: userId)
              .where('status', isEqualTo: 'active')
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      DocumentSnapshot doc = snapshot.docs.first;
      return UserSubscription.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('Error getting active subscription: $e');
      return null;
    }
  }

  // Create an order using subscription
  Future<String> createSubscriptionOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String deliveryType,
  }) async {
    try {
      // Get user's document to find active subscription
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? userSubId = userData['active_subscription_id'];

      if (userSubId == null) {
        throw Exception('No active subscription found');
      }

      // Get subscription details
      DocumentSnapshot userSubDoc =
          await _firestore
              .collection('user_subscriptions')
              .doc(userSubId)
              .get();
      Map<String, dynamic> userSubData =
          userSubDoc.data() as Map<String, dynamic>;

      // Calculate total items
      int totalQuantity = 0;
      for (var item in items) {
        totalQuantity += (item['quantity'] as int);
      }

      // Check if enough credits
      int remainingCredits = userSubData['remaining_credits'];
      if (remainingCredits < totalQuantity) {
        throw Exception('Not enough credits remaining');
      }

      // Check if free delivery available
      int remainingDeliveries = userSubData['remaining_deliveries'];
      bool isFreeDel = remainingDeliveries > 0;

      // Create order
      DocumentReference orderRef = await _firestore.collection('orders').add({
        'created_at': Timestamp.now(),
        'user_id': userId,
        'items': items,
        'delivery_address': deliveryAddress,
        'delivery_type': deliveryType,
        'user_subscription_id': userSubId,
        'credits_used': totalQuantity,
        'is_free_delivery': isFreeDel,
      });

      // Update subscription
      await _firestore.collection('user_subscriptions').doc(userSubId).update({
        'remaining_credits': remainingCredits - totalQuantity,
        'remaining_deliveries':
            isFreeDel ? remainingDeliveries - 1 : remainingDeliveries,
      });

      return orderRef.id;
    } catch (e) {
      print('Error creating subscription order: $e');
      return '';
    }
  }
}
