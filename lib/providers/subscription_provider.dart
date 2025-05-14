import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../models/user_subscription.dart';
import '../models/membership_tier.dart';
import '../services/subscription_service.dart';
import '../services/membership_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final MembershipService _membershipService = MembershipService();

  List<Subscription> _subscriptions = [];
  List<MembershipTier> _membershipTiers = [];

  UserSubscription? _activeSubscription;
  MembershipTier? _activeMembershipTier;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Subscription> get subscriptions => _subscriptions;
  List<MembershipTier> get membershipTiers => _membershipTiers;
  UserSubscription? get activeSubscription => _activeSubscription;
  MembershipTier? get activeMembershipTier => _activeMembershipTier;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all subscriptions
  Future<void> loadSubscriptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscriptions = await _subscriptionService.getAllSubscriptions();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load subscriptions: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all membership tiers
  Future<void> loadMembershipTiers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _membershipTiers = await _membershipService.getAllMembershipTiers();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load membership tiers: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user's active subscription
  Future<void> loadUserActiveSubscription(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeSubscription = await _subscriptionService
          .getUserActiveSubscription(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load active subscription: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe user to a plan
  Future<bool> subscribeUserToPlan(
    String userId,
    String subscriptionId,
    String? membershipTierId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _subscriptionService.subscribeUserToPlan(
        userId: userId,
        subscriptionId: subscriptionId,
        membershipTierId: membershipTierId,
      );

      // Refresh active subscription
      await loadUserActiveSubscription(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to subscribe user to plan: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create order with subscription
  Future<String?> createSubscriptionOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String deliveryType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderId = await _subscriptionService.createSubscriptionOrder(
        userId: userId,
        items: items,
        deliveryAddress: deliveryAddress,
        deliveryType: deliveryType,
      );

      // Refresh active subscription
      await loadUserActiveSubscription(userId);
      return orderId;
    } catch (e) {
      _errorMessage = 'Failed to create order: $e';
      print(_errorMessage);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
