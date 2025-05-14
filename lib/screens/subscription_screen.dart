import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  final String? userId;

  const SubscriptionScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _selectedPlanId;
  Subscription? _selectedSubscription;
  bool _isCompareVisible = false;
  bool _isLoading = true;
  List<Subscription> _subscriptions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Directly query Firestore for subscriptions
      final subscriptionsSnapshot =
          await FirebaseFirestore.instance.collection('subscriptions').get();

      if (subscriptionsSnapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No subscription plans found in database';
          _isLoading = false;
        });
        return;
      }

      // Convert documents to Subscription objects
      final List<Subscription> subs =
          subscriptionsSnapshot.docs.map((doc) {
            return Subscription.fromMap(doc.data(), doc.id);
          }).toList();

      // Sort by price for better display
      subs.sort((a, b) => a.price.compareTo(b.price));

      setState(() {
        _subscriptions = subs;

        // Auto-select Balanced Bite or first plan
        final balancedBite = subs.firstWhere(
          (sub) => sub.name == 'Balanced Bite',
          orElse: () => subs.first,
        );

        _selectedPlanId = balancedBite.id;
        _selectedSubscription = balancedBite;
        _isLoading = false;
      });

      // Also load from provider for future use
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      await subscriptionProvider.loadSubscriptions();

      if (widget.userId != null) {
        await subscriptionProvider.loadUserActiveSubscription(widget.userId!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading subscriptions: $e';
        _isLoading = false;
      });
      print('Error loading subscriptions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Plans')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorScreen()
              : _subscriptions.isEmpty
              ? _buildEmptyScreen()
              : _buildSubscriptionContent(),
      bottomNavigationBar:
          widget.userId != null && _selectedPlanId != null
              ? _buildSubscribeButton()
              : null,
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadSubscriptions,
            child: const Text('Retry'),
          ),
          // Add debug button to initialize data
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeTestData,
            child: const Text('Initialize Test Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No subscription plans available',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializeTestData,
            child: const Text('Initialize Plans'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeTestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Check if subscriptions already exist
      final existingPlans =
          await firestore.collection('subscriptions').limit(1).get();
      if (existingPlans.docs.isNotEmpty) {
        // Delete existing subscriptions first to avoid duplicates
        for (var doc
            in (await firestore.collection('subscriptions').get()).docs) {
          await doc.reference.delete();
        }
      }

      // Add subscription plans
      await firestore.collection('subscriptions').add({
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

      await firestore.collection('subscriptions').add({
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

      await firestore.collection('subscriptions').add({
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

      await firestore.collection('subscriptions').add({
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

      // Reload subscriptions
      await _loadSubscriptions();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing data: $e';
        _isLoading = false;
      });
      print('Error initializing data: $e');
    }
  }

  Widget _buildSubscriptionContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a Meal Plan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Choose the plan that fits your needs',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                _buildSubscriptionOptions(),
                if (_selectedSubscription != null)
                  _buildSelectedPlanDetails(_selectedSubscription!),
                if (_isCompareVisible) _buildComparisonTable(),
              ],
            ),
          ),
        ),
        _buildCompareButton(),
      ],
    );
  }

  Widget _buildSubscriptionOptions() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = _subscriptions[index];
        final isSelected = subscription.id == _selectedPlanId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPlanId = subscription.id;
                _selectedSubscription = subscription;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Radio<String>(
                      value: subscription.id,
                      groupValue: _selectedPlanId,
                      onChanged: (value) {
                        setState(() {
                          _selectedPlanId = value;
                          _selectedSubscription = subscription;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        subscription.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '\$${subscription.price.toInt()}/week',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (subscription.isPopular)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Popular',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedPlanDetails(Subscription subscription) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subscription.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            '\$${subscription.price.toInt()}/week',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem('${subscription.credits} weekly credits'),
          _buildFeatureItem('~${subscription.mealsRange} meals covered'),
          _buildFeatureItem('${subscription.mealPriceRange} per meal'),
          _buildFeatureItem('${subscription.freeDeliveries} free deliveries'),
          ...subscription.features
              .map((feature) => _buildFeatureItem(feature))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildCompareButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _isCompareVisible = !_isCompareVisible;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCompareVisible ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'Compare All Plans',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Plan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Credits',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Meals',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Deliveries',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Table rows
          ..._subscriptions
              .map(
                (subscription) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              subscription.name,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${subscription.credits}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '\$${subscription.price.toInt()}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              subscription.mealsRange,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${subscription.freeDeliveries}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subscription != _subscriptions.last)
                      const Divider(height: 1),
                  ],
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          return ElevatedButton(
            onPressed: provider.isLoading ? null : () => _subscribeUser(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                      'Subscribe to ${_selectedSubscription?.name ?? "Selected Plan"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          );
        },
      ),
    );
  }

  Future<void> _subscribeUser() async {
    if (widget.userId == null || _selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot subscribe: Missing user ID or plan'),
        ),
      );
      return;
    }

    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final success = await subscriptionProvider.subscribeUserToPlan(
      widget.userId!,
      _selectedPlanId!,
      null, // No membership tier for basic test
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully subscribed to plan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to subscribe: ${subscriptionProvider.errorMessage}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
