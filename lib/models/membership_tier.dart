class MembershipTier {
  final String id;
  final String name;
  final double price;
  final String billingCycle;
  final List<String> features;
  final bool isPopular;
  final List<String> compatibleSubscriptions;

  MembershipTier({
    this.id = '',
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.features,
    required this.isPopular,
    required this.compatibleSubscriptions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'billing_cycle': billingCycle,
      'features': features,
      'is_popular': isPopular,
      'compatible_subscriptions': compatibleSubscriptions,
    };
  }

  factory MembershipTier.fromMap(Map<String, dynamic> map, String docId) {
    return MembershipTier(
      id: docId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      billingCycle: map['billing_cycle'] ?? 'monthly',
      features: List<String>.from(map['features'] ?? []),
      isPopular: map['is_popular'] ?? false,
      compatibleSubscriptions: List<String>.from(
        map['compatible_subscriptions'] ?? [],
      ),
    );
  }
}
