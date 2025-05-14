
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:nutrition_ai/nutrition_ai.dart';
import 'package:provider/provider.dart';

import '../models/food_item.dart';
import '../providers/food_log_provider.dart';
import '../widgets/nutrition_info_card.dart';

class FoodDetailsScreen extends StatefulWidget {
  final PassioAdvisorFoodInfo foodInfo;
  final String? initialMealType;

  const FoodDetailsScreen({
    Key? key,
    required this.foodInfo,
    this.initialMealType,
  }) : super(key: key);

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  FoodItem? _foodItem;
  late String _selectedMealType;
  late double _quantity;
  late String _unit;
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? 'Lunch';
    _loadFoodDetails();
  }

  Future<void> _loadFoodDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final foodItem = await FoodItem.fromPassioAdvisorFoodInfo(widget.foodInfo);
      
      if (foodItem != null) {
        setState(() {
          _foodItem = foodItem;
          _quantity = foodItem.servingQuantity;
          _unit = foodItem.servingUnit;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load food details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _updateQuantity(double newValue) {
    setState(() {
      _quantity = newValue;
    });
  }

  void _updateUnit(String newUnit) {
    setState(() {
      _unit = newUnit;
    });
    
    if (_foodItem != null) {
      _foodItem!.updateServingSize(_quantity, newUnit);
    }
  }

  Future<void> _logFood() async {
    if (_foodItem == null) return;
    
    try {
      final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
      await foodLogProvider.addFoodLog(_foodItem!, _selectedMealType, _quantity, _unit);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food added to log'),
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log food: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showServingSizeSelector() {
    if (_foodItem == null) return;
    
    final servingUnits = _foodItem!.passioFoodItem.amount.servingUnits.map((unit) => unit.unitName).toList();
    
    if (servingUnits.isEmpty) {
      servingUnits.add('g');
    }
    
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => SizedBox(
          height: 250,
          child: CupertinoPicker(
            backgroundColor: Colors.white,
            itemExtent: 32,
            onSelectedItemChanged: (index) {
              _updateUnit(servingUnits[index]);
            },
            children: servingUnits.map((unit) => Text(unit)).toList(),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Serving Unit'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: servingUnits.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(servingUnits[index]),
                  onTap: () {
                    _updateUnit(servingUnits[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorScreen()
              : _buildFoodDetailsContent(),
      bottomNavigationBar: _foodItem == null
          ? null
          : _buildBottomBar(),
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
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFoodDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodDetailsContent() {
    if (_foodItem == null) {
      return const Center(child: Text('No food data available'));
    }
    
    final foodItem = _foodItem!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFoodHeader(foodItem),
          const SizedBox(height: 24),
          _buildServingSection(foodItem),
          const SizedBox(height: 24),
          NutritionInfoCard(foodItem: foodItem),
          const SizedBox(height: 24),
          _buildMealTypeSelector(),
          const SizedBox(height: 16),
          if (foodItem.passioFoodItem.ingredients.isNotEmpty)
            _buildIngredientsSection(foodItem),
        ],
      ),
    );
  }

  Widget _buildFoodHeader(FoodItem foodItem) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: foodItem.iconId != null
              ? Image.network(
                  'https://storage.googleapis.com/passio-prod-env-public-cdn-data/label-icons/${foodItem.iconId}-180.jpg',
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.fastfood, size: 40);
                  },
                )
              : const Icon(Icons.fastfood, size: 40),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                foodItem.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (foodItem.details.isNotEmpty && foodItem.details != foodItem.name)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    foodItem.details,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '${foodItem.calories.toInt()} calories',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServingSection(FoodItem foodItem) {
    return Container(
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
          const Text(
            'Serving Size',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuantitySelector(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUnitSelector(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantity'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _quantity <= 0.1
                    ? null
                    : () {
                        _updateQuantity((_quantity - 0.5).clamp(0.1, 100));
                        if (_foodItem != null) {
                          _foodItem!.updateServingSize(_quantity, _unit);
                        }
                      },
              ),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _quantity.toString()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    final newValue = double.tryParse(value);
                    if (newValue != null && newValue > 0) {
                      _updateQuantity(newValue);
                      if (_foodItem != null) {
                        _foodItem!.updateServingSize(_quantity, _unit);
                      }
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _updateQuantity((_quantity + 0.5).clamp(0.1, 100));
                  if (_foodItem != null) {
                    _foodItem!.updateServingSize(_quantity, _unit);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Unit'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showServingSizeSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_unit),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTypeSelector() {
    return Container(
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
          const Text(
            'Meal Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _mealTypes.map((type) {
              final isSelected = type == _selectedMealType;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMealType = type;
                    });
                  }
                },
                backgroundColor: Colors.grey[200],
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(FoodItem foodItem) {
    final ingredients = foodItem.passioFoodItem.ingredients;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = ingredients[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ingredient.name),
              subtitle: Text(
                '${ingredient.amount.selectedQuantity} ${ingredient.amount.selectedUnit}',
              ),
              leading: SizedBox(
                width: 40,
                height: 40,
                child: ingredient.iconId.isNotEmpty
                    ? Image.network(
                        'https://storage.googleapis.com/passio-prod-env-public-cdn-data/label-icons/${ingredient.iconId}-90.jpg',
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.food_bank);
                        },
                      )
                    : const Icon(Icons.food_bank),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _logFood,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Add to Food Log',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
      ),
    );
  }
}