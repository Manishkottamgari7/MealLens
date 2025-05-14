import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/food_log_entry.dart';
import '../providers/food_log_provider.dart';
import '../widgets/food_item_card.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({Key? key}) : super(key: key);

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  DateTime _selectedDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    final foodLogProvider = Provider.of<FoodLogProvider>(context);
    final logsForDate = foodLogProvider.getLogsForDate(_selectedDate);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: logsForDate.isEmpty
                ? _buildEmptyState()
                : _buildLogList(logsForDate),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateSelector() {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedDate.isBefore(DateTime.now()) ? () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            } : null,
          ),
        ],
      ),
    );
  }
  
  void _selectDate(BuildContext context) async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (_) {
          return Container(
            height: 250,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  height: 40,
                  color: Colors.grey[200],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() {
                        _selectedDate = newDate;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No food logged for ${DateFormat('MMMM d').format(_selectedDate)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogList(List<FoodLogEntry> logs) {
    // Group logs by meal type
    final Map<String, List<FoodLogEntry>> mealLogs = {
      'Breakfast': logs.where((log) => log.mealType == 'Breakfast').toList(),
      'Lunch': logs.where((log) => log.mealType == 'Lunch').toList(),
      'Dinner': logs.where((log) => log.mealType == 'Dinner').toList(),
      'Snack': logs.where((log) => log.mealType == 'Snack').toList(),
    };
    
    return ListView(
      children: [
        for (final mealType in ['Breakfast', 'Lunch', 'Dinner', 'Snack'])
          if (mealLogs[mealType]!.isNotEmpty)
            _buildMealSection(mealType, mealLogs[mealType]!),
      ],
    );
  }
  
  Widget _buildMealSection(String mealType, List<FoodLogEntry> mealLogs) {
    // Calculate total calories for this meal
    final totalCalories = mealLogs.fold<double>(
      0, (total, log) => total + log.calories);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mealType,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${totalCalories.toInt()} kcal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mealLogs.length,
          itemBuilder: (context, index) {
            final log = mealLogs[index];
            return FoodItemCard(
              foodLogEntry: log,
              onDelete: () => _confirmDeleteLog(log),
            );
          },
        ),
        const Divider(height: 32),
      ],
    );
  }
  
  void _confirmDeleteLog(FoodLogEntry log) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Delete Food Log'),
          content: Text('Are you sure you want to delete ${log.foodItem.name}?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _deleteLog(log);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Food Log'),
          content: Text('Are you sure you want to delete ${log.foodItem.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteLog(log);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }
  
  void _deleteLog(FoodLogEntry log) {
    final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
    foodLogProvider.deleteFoodLog(log.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${log.foodItem.name} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Ideally, we'd have an undo function in the provider
          },
        ),
      ),
    );
  }
}