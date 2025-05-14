class Subscription {
  final String id;
  final String name;
  final double price;
  final String billingCycle;
  final int credits;
  final String mealsRange;
  final String mealPriceRange;
  final int freeDeliveries;
  final List<String> features;
  final bool isPopular;

  Subscription({
    this.id = '',
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.credits,
    required this.mealsRange,
    required this.mealPriceRange,
    required this.freeDeliveries,
    required this.features,
    required this.isPopular,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'billing_cycle': billingCycle,
      'credits': credits,
      'meals_range': mealsRange,
      'meal_price_range': mealPriceRange,
      'free_deliveries': freeDeliveries,
      'features': features,
      'is_popular': isPopular,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map, String docId) {
    return Subscription(
      id: docId,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      billingCycle: map['billing_cycle'] ?? 'weekly',
      credits: map['credits'] ?? 0,
      mealsRange: map['meals_range'] ?? '',
      mealPriceRange: map['meal_price_range'] ?? '',
      freeDeliveries: map['free_deliveries'] ?? 0,
      features: List<String>.from(map['features'] ?? []),
      isPopular: map['is_popular'] ?? false,
    );
  }
}