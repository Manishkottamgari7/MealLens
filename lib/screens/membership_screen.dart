import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/membership_tier.dart';
import '../providers/subscription_provider.dart';

class MembershipScreen extends StatefulWidget {
  final String? userId;

  const MembershipScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  String? _selectedTierId;
  MembershipTier? _selectedTier;
  bool _isCompareVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    await subscriptionProvider.loadMembershipTiers();

    // Auto-select the Pro tier to match your screenshots
    if (subscriptionProvider.membershipTiers.isNotEmpty) {
      final proTier = subscriptionProvider.membershipTiers.firstWhere(
        (tier) => tier.name == 'Pro',
        orElse: () => subscriptionProvider.membershipTiers.first,
      );
      setState(() {
        _selectedTierId = proTier.id;
        _selectedTier = proTier;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${provider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (provider.membershipTiers.isEmpty) {
            return const Center(child: Text('No membership tiers available'));
          }

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
                              'Select a Membership Tier',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Choose your membership level',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildMembershipOptions(provider.membershipTiers),
                      if (_selectedTier != null)
                        _buildSelectedTierDetails(_selectedTier!),
                      if (_isCompareVisible)
                        _buildComparisonTable(provider.membershipTiers),
                    ],
                  ),
                ),
              ),
              _buildCompareButton(),
              if (widget.userId != null && _selectedTierId != null)
                _buildUpgradeButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMembershipOptions(List<MembershipTier> tiers) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tiers.length,
      itemBuilder: (context, index) {
        final tier = tiers[index];
        final isSelected = tier.id == _selectedTierId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedTierId = tier.id;
                _selectedTier = tier;
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
                      value: tier.id,
                      groupValue: _selectedTierId,
                      onChanged: (value) {
                        setState(() {
                          _selectedTierId = value;
                          _selectedTier = tier;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        tier.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      tier.price > 0
                          ? '\$${tier.price.toStringAsFixed(2)}/mo'
                          : '\$0/mo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (tier.isPopular)
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

  Widget _buildSelectedTierDetails(MembershipTier tier) {
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
            tier.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            tier.price > 0
                ? '\$${tier.price.toStringAsFixed(2)}/month'
                : 'Free',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...tier.features
              .map((feature) => _buildFeatureItem(feature))
              .toList(),

          if (tier.name == 'Pro')
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'FREE for users on the Ultra Life Meal Plan',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          Expanded(child: Text(text)),
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
              'Compare All Tiers',
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

  Widget _buildComparisonTable(List<MembershipTier> tiers) {
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
                    'Tier',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Key Benefits',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Table rows
          ...tiers
              .map(
                (tier) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tier.name,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tier.price > 0
                                      ? '\$${tier.price.toStringAsFixed(2)}/mo'
                                      : '\$0/mo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child:
                                tier.features.isNotEmpty
                                    ? Text(tier.features.first)
                                    : const Text('Basic features'),
                          ),
                        ],
                      ),
                    ),
                    if (tier != tiers.last) const Divider(height: 1),
                  ],
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          return ElevatedButton(
            onPressed: provider.isLoading ? null : () => _upgradeMembership(),
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
                      'Upgrade to ${_selectedTier?.name ?? "Selected Tier"}',
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

  Future<void> _upgradeMembership() async {
    if (widget.userId == null || _selectedTierId == null) return;

    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    // Implement the membership upgrade logic here

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membership upgraded successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}
