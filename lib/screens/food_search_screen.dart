import 'package:flutter/material.dart';
import 'package:nutrition_ai/nutrition_ai.dart';
import 'package:provider/provider.dart';

import '../providers/passio_provider.dart';
import 'food_details_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  final String? initialMealType;

  const FoodSearchScreen({Key? key, this.initialMealType}) : super(key: key);

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PassioFoodDataInfo> _searchResults = [];
  bool _isSearching = false;
  String _errorMessage = '';
  
  // Debounce variables
  DateTime? _lastSearchTime;
  static const _searchDelay = Duration(milliseconds: 300);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchFood(String query) {
    // Debounce the search to avoid multiple API calls
    final now = DateTime.now();
    _lastSearchTime = now;
    
    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });
    
    Future.delayed(_searchDelay, () {
      // Only proceed if this is still the latest search request
      if (_lastSearchTime != now) return;
      
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }
      
      final passioProvider = Provider.of<PassioProvider>(context, listen: false);
      passioProvider.searchFood(query).then((results) {
        // Only update if this is still the latest search request
        if (_lastSearchTime != now) return;
        
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }).catchError((error) {
        // Only update if this is still the latest search request
        if (_lastSearchTime != now) return;
        
        setState(() {
          _errorMessage = 'Error searching for food: $error';
          _isSearching = false;
        });
      });
    });
  }

  Future<void> _openFoodDetails(PassioFoodDataInfo foodInfo) async {
    // Create a PassioAdvisorFoodInfo with the required fields
    final advisorFoodInfo = PassioAdvisorFoodInfo(
      recognisedName: foodInfo.foodName,
      portionSize: '${foodInfo.nutritionPreview?.servingQuantity ?? 1} ${foodInfo.nutritionPreview?.servingUnit ?? "serving"}',
      weightGrams: foodInfo.nutritionPreview?.weightQuantity ?? 100,
      resultType: PassioFoodResultType.foodItem, // Required field 
      foodDataInfo: foodInfo,
    );
    
    // Navigate to details screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodDetailsScreen(
            foodInfo: advisorFoodInfo,
            initialMealType: widget.initialMealType,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Food'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _errorMessage.isNotEmpty
                ? _buildErrorMessage()
                : _isSearching
                    ? _buildLoadingIndicator()
                    : _searchResults.isEmpty
                        ? _buildEmptyState()
                        : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for food...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _searchFood,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _searchFood(_searchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty ? Icons.search : Icons.no_food,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Enter a food name to search'
                : 'No results found for "${_searchController.text}"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final foodInfo = _searchResults[index];
        return _buildFoodListItem(foodInfo);
      },
    );
  }

  Widget _buildFoodListItem(PassioFoodDataInfo foodInfo) {
    // Extract nutrition preview
    final nutritionPreview = foodInfo.nutritionPreview;
    final calories = nutritionPreview?.calories ?? 0;
    final servingSize = '${nutritionPreview?.servingQuantity ?? 1} ${nutritionPreview?.servingUnit ?? "serving"}';
    
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: foodInfo.iconID.isNotEmpty
            ? FutureBuilder<String>(
                future: NutritionAI.instance.iconURLFor(foodInfo.iconID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return Image.network(
                      snapshot.data!,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.fastfood);
                      },
                    );
                  }
                  return const Icon(Icons.fastfood);
                },
              )
            : const Icon(Icons.fastfood),
      ),
      title: Text(
        foodInfo.foodName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(servingSize),
          const SizedBox(width: 8),
          Text('$calories kcal'),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openFoodDetails(foodInfo),
    );
  }
}