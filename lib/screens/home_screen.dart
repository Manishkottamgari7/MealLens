import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrition_ai/nutrition_ai.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart'; // This should contain DiaryEvent and EventType
import '../models/food_log_entry.dart';
import '../models/food_item.dart';
import '../providers/food_log_provider.dart';
import '../providers/passio_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_provider.dart';
import 'camera_screen.dart';
import 'food_log_screen.dart';
import 'food_search_screen.dart';
import 'subscription_screen.dart';
import 'membership_screen.dart';
import 'diary_screen.dart';
import 'food_details_screen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../widgets/expandable_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _userId;

  // Map to store time slots and their events
  final Map<String, List<Map<String, dynamic>>> _timeSlots = {};

  // Form state variables for add event dialog
  final _formKey = GlobalKey<FormState>();
  String _selectedEventType = 'food';
  String _newEventTitle = '';
  String _eventTime = '15:30';
  int _eventDuration = 30;

  // For food event
  int _foodCalories = 0;
  int _foodProtein = 0;
  int _foodCarbs = 0;
  int _foodFat = 0;
  String _foodItems = '';

  // For water event
  int _waterAmount = 250;

  // For activity event
  String _activityType = 'Walking';
  int _activityCalories = 0;

  // For calendar event
  String _eventLocation = '';
  String _eventParticipants = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _initializeTimeSlots();
  }

  void _initializeTimeSlots() {
    // Initialize time slots from 6 AM to 9 PM
    for (int hour = 6; hour <= 21; hour++) {
      final timeString =
          '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}';
      _timeSlots[timeString] = [];
    }

    // Add sample events - in a real app, these would come from your provider
    _timeSlots['08:00 AM'] = [
      {'type': 'food', 'time': '08:30 AM', 'title': 'Breakfast'},
    ];
    _timeSlots['10:00 AM'] = [
      {'type': 'calendar', 'time': '10:00 AM', 'title': 'Morning Meeting'},
      {'type': 'water', 'time': '10:30 AM', 'title': 'Hydration'},
    ];
    _timeSlots['12:00 PM'] = [
      {'type': 'food', 'time': '12:30 PM', 'title': 'Lunch'},
    ];
    _timeSlots['1:00 PM'] = [
      {'type': 'water', 'time': '01:30 PM', 'title': 'Hydration'},
    ];

    // Load food logs later to ensure FoodLogProvider is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFoodLogsIntoTimeSlots();
    });
  }

  // Load food logs into time slots
  void _loadFoodLogsIntoTimeSlots() {
    if (!mounted) return;

    final foodLogProvider = Provider.of<FoodLogProvider>(
      context,
      listen: false,
    );
    final dailyLogs = foodLogProvider.getLogsForDate(_selectedDate);

    // Clear existing food entries to prevent duplicates
    for (final timeSlotKey in _timeSlots.keys) {
      _timeSlots[timeSlotKey] =
          _timeSlots[timeSlotKey]!
              .where(
                (event) => event['type'] != 'food' || event['fromLog'] != true,
              )
              .toList();
    }

    // Add logs to time slots
    for (final log in dailyLogs) {
      final timeFormatted = DateFormat('h:mm a').format(log.dateTime);
      final hour = log.dateTime.hour;

      // Find the appropriate time slot
      final String timeSlotKey =
          '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}';

      // Create event from log
      final newEvent = {
        'type': 'food',
        'time': timeFormatted,
        'title': log.foodItem.name,
        'calories': log.calories.toInt(),
        'protein': log.protein,
        'carbs': log.carbs,
        'fat': log.fat,
        'quantity': log.quantity,
        'unit': log.unit,
        'fromLog': true,
        'logId': log.id,
      };

      // Add to time slot
      if (_timeSlots.containsKey(timeSlotKey)) {
        setState(() {
          _timeSlots[timeSlotKey]!.add(newEvent);
        });
      }
    }
  }

  Future<void> _initializeApp() async {
    // Initialize the Passio SDK
    final passioProvider = Provider.of<PassioProvider>(context, listen: false);
    await passioProvider.initializePassioSDK();

    // Load saved food logs
    final foodLogProvider = Provider.of<FoodLogProvider>(
      context,
      listen: false,
    );
    await foodLogProvider.loadFoodLogs();

    // Get or create test user for subscriptions
    _getUserOrCreate();

    // Initialize subscription provider
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    await subscriptionProvider.loadSubscriptions();
    await subscriptionProvider.loadMembershipTiers();
    if (_userId != null) {
      await subscriptionProvider.loadUserActiveSubscription(_userId!);
    }
  }

  Future<void> _getUserOrCreate() async {
    try {
      // Check if we have any users
      final userSnapshot =
          await FirebaseFirestore.instance.collection('users').limit(1).get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          _userId = userSnapshot.docs.first.id;
        });
      } else {
        // Create a test user if none exists
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .add({
              'name': 'Test User',
              'email': 'test@example.com',
              'created_at': Timestamp.now(),
            });

        setState(() {
          _userId = userDoc.id;
        });
      }

      print('User ID set to: $_userId');
    } catch (e) {
      print('Error getting/creating user: $e');
    }
  }

  void _handleDateChange(String direction) {
    setState(() {
      if (direction == 'prev') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      } else {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      }

      // Reload food logs for the new date
      _loadFoodLogsIntoTimeSlots();
    });
  }

  void _showAddEventDialog() {
    // Reset form values
    _selectedEventType = 'food';
    _newEventTitle = '';
    _eventTime = '15:30';
    _eventDuration = 30;
    _foodCalories = 0;
    _foodProtein = 0;
    _foodCarbs = 0;
    _foodFat = 0;
    _foodItems = '';
    _waterAmount = 250;
    _activityType = 'Walking';
    _activityCalories = 0;
    _eventLocation = '';
    _eventParticipants = '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Event'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                      ),
                      value: _selectedEventType,
                      items: const [
                        DropdownMenuItem(value: 'food', child: Text('Food')),
                        DropdownMenuItem(value: 'water', child: Text('Water')),
                        DropdownMenuItem(
                          value: 'activity',
                          child: Text('Activity'),
                        ),
                        DropdownMenuItem(
                          value: 'calendar',
                          child: Text('Calendar Event'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEventType = value!;
                          if (_selectedEventType == 'water') {
                            _eventDuration = 5;
                          } else {
                            _eventDuration = 30;
                          }
                        });
                        Navigator.pop(context);
                        _showAddEventDialog(); // Reopen with new type
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Title'),
                      initialValue: _newEventTitle,
                      onChanged: (value) => _newEventTitle = value,
                    ),
                    const SizedBox(height: 16),

                    // Time & Duration
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Time',
                            ),
                            initialValue: _eventTime,
                            onChanged: (value) => _eventTime = value,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Duration (min)',
                            ),
                            initialValue: _eventDuration.toString(),
                            keyboardType: TextInputType.number,
                            onChanged:
                                (value) =>
                                    _eventDuration = int.tryParse(value) ?? 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Type-specific fields
                    if (_selectedEventType == 'food') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Calories',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged:
                                  (value) =>
                                      _foodCalories = int.tryParse(value) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Protein (g)',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged:
                                  (value) =>
                                      _foodProtein = int.tryParse(value) ?? 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Carbs (g)',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged:
                                  (value) =>
                                      _foodCarbs = int.tryParse(value) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Fat (g)',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged:
                                  (value) =>
                                      _foodFat = int.tryParse(value) ?? 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Food Items',
                          hintText: 'Enter food items, one per line',
                        ),
                        maxLines: 3,
                        onChanged: (value) => _foodItems = value,
                      ),
                    ],

                    if (_selectedEventType == 'water') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Amount (ml)',
                        ),
                        initialValue: _waterAmount.toString(),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (value) =>
                                _waterAmount = int.tryParse(value) ?? 250,
                      ),
                    ],

                    if (_selectedEventType == 'activity') ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Activity Type',
                        ),
                        value: _activityType,
                        items: const [
                          DropdownMenuItem(
                            value: 'Walking',
                            child: Text('Walking'),
                          ),
                          DropdownMenuItem(
                            value: 'Running',
                            child: Text('Running'),
                          ),
                          DropdownMenuItem(
                            value: 'Cycling',
                            child: Text('Cycling'),
                          ),
                          DropdownMenuItem(
                            value: 'Swimming',
                            child: Text('Swimming'),
                          ),
                          DropdownMenuItem(
                            value: 'Weight Training',
                            child: Text('Weight Training'),
                          ),
                          DropdownMenuItem(value: 'Yoga', child: Text('Yoga')),
                        ],
                        onChanged: (value) => _activityType = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Calories Burned',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (value) =>
                                _activityCalories = int.tryParse(value) ?? 0,
                      ),
                    ],

                    if (_selectedEventType == 'calendar') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Location',
                        ),
                        onChanged: (value) => _eventLocation = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Participants',
                          hintText: 'Enter participants, one per line',
                        ),
                        maxLines: 3,
                        onChanged: (value) => _eventParticipants = value,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _addNewEvent,
                child: const Text('Add Event'),
              ),
            ],
          ),
    );
  }

  void _addNewEvent() {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Parse time
      String timeFormat = _eventTime;
      if (!timeFormat.contains('AM') && !timeFormat.contains('PM')) {
        // Convert 24-hour format to 12-hour format with AM/PM
        final hour = int.parse(_eventTime.split(':')[0]);
        final minute = int.parse(_eventTime.split(':')[1]);
        final isPM = hour >= 12;
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        timeFormat =
            '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${isPM ? 'PM' : 'AM'}';
      }

      // Create event based on type
      final Map<String, dynamic> newEvent = {
        'type': _selectedEventType,
        'time': timeFormat,
        'title': _newEventTitle.isEmpty ? _getDefaultTitle() : _newEventTitle,
      };

      // Add specific properties based on event type
      if (_selectedEventType == 'food') {
        newEvent['calories'] = _foodCalories;
        newEvent['protein'] = _foodProtein;
        newEvent['carbs'] = _foodCarbs;
        newEvent['fat'] = _foodFat;
        newEvent['items'] = _foodItems.isEmpty ? [] : _foodItems.split('\n');

        // Also add this to the food log using your existing DiaryEvent implementation
        _addFoodEventToDiary(newEvent);
      } else if (_selectedEventType == 'water') {
        newEvent['amount'] = _waterAmount;
      } else if (_selectedEventType == 'activity') {
        newEvent['activityType'] = _activityType;
        newEvent['calories'] = _activityCalories;
      } else if (_selectedEventType == 'calendar') {
        newEvent['location'] = _eventLocation;
        newEvent['participants'] =
            _eventParticipants.isEmpty ? [] : _eventParticipants.split('\n');
      }

      // Add to appropriate time slot
      _addEventToTimeSlot(newEvent);

      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Replace the _addFoodEventToDiary method with this:
  void _addFoodEventToDiary(Map<String, dynamic> foodEvent) {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Create a DiaryEvent using your existing model
      // Import the DiaryEvent and EventType from your models
      final diaryEvent = DiaryEvent(
        id: DateTime.now().millisecondsSinceEpoch,
        title: foodEvent['title'] ?? 'Meal',
        type: EventType.food, // Make sure to import this enum from your models
        time: foodEvent['time'] ?? DateFormat('h:mm a').format(DateTime.now()),
        duration: 30,
        details: {
          'calories': foodEvent['calories'] ?? 0,
          'protein': foodEvent['protein'] ?? 0,
          'carbs': foodEvent['carbs'] ?? 0,
          'fat': foodEvent['fat'] ?? 0,
          'items': foodEvent['items'] ?? <String>[],
        },
      );

      // Add the event to the user's diary
      userProvider.addDiaryEvent(diaryEvent);

      // Update the time slots display
      _loadFoodLogsIntoTimeSlots();
    } catch (e) {
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding food to diary: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDefaultTitle() {
    switch (_selectedEventType) {
      case 'food':
        return 'Meal';
      case 'water':
        return 'Hydration';
      case 'activity':
        return _activityType;
      case 'calendar':
        return 'Meeting';
      default:
        return 'Event';
    }
  }

  void _addEventToTimeSlot(Map<String, dynamic> event) {
    // Find the nearest time slot
    final eventTime = event['time'];
    String? nearestSlot;

    // Parse event time to get hour
    final hourStr = eventTime.split(':')[0];
    final isPM = eventTime.contains('PM') && hourStr != '12';
    final hour = int.parse(hourStr);
    final adjustedHour = isPM ? hour + 12 : hour;

    // Find nearest slot
    for (final timeSlot in _timeSlots.keys) {
      final slotHour = int.parse(timeSlot.split(':')[0]);
      final slotIsPM = timeSlot.contains('PM') && slotHour != 12;
      final adjustedSlotHour = slotIsPM ? slotHour + 12 : slotHour;

      if (nearestSlot == null ||
          (adjustedSlotHour <= adjustedHour &&
              adjustedHour - adjustedSlotHour < 2)) {
        nearestSlot = timeSlot;
      }
    }

    if (nearestSlot != null) {
      setState(() {
        _timeSlots[nearestSlot]!.add(event);
      });
    } else {
      // Add to 6 AM as fallback
      setState(() {
        _timeSlots.values.first.add(event);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final passioProvider = Provider.of<PassioProvider>(context);
    final foodLogProvider = Provider.of<FoodLogProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final dailyLogs = foodLogProvider.getLogsForDate(_selectedDate);
    final nutrients = foodLogProvider.getDailyNutrients(_selectedDate);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog, // Your add event method
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        child:
            passioProvider.sdkStatus == PassioSdkStatus.initializing
                ? _buildLoadingScreen()
                : passioProvider.sdkStatus == PassioSdkStatus.failed
                ? _buildErrorScreen(passioProvider.lastError)
                : _buildDiaryContent(context, dailyLogs, nutrients),
      ),

      // Using the SpeedDial package
      floatingActionButton: SpeedDial(
        // Icon when the dial is closed
        icon: Icons.add,

        // Icon when the dial is open
        activeIcon: Icons.close,

        // Colors
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,

        // Optional settings
        elevation: 8.0,
        shape: const CircleBorder(),
        curve: Curves.bounceIn,

        // Menu items
        children: [
          SpeedDialChild(
            child: const Icon(Icons.camera_alt),
            backgroundColor: Colors.lightGreen,
            foregroundColor: Colors.white,
            label: 'Camera',
            labelStyle: const TextStyle(fontSize: 14.0),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.search),
            backgroundColor: Colors.lightGreen,
            foregroundColor: Colors.white,
            label: 'Search',
            labelStyle: const TextStyle(fontSize: 14.0),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FoodSearchScreen(),
                  ),
                ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.list),
            backgroundColor: Colors.lightGreen,
            foregroundColor: Colors.white,
            label: 'View All Logs',
            labelStyle: const TextStyle(fontSize: 14.0),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FoodLogScreen(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryContent(
    BuildContext context,
    List<FoodLogEntry> logs,
    Map<String, double> nutrients,
  ) {
    final formattedDate = DateFormat('EEEE, MMMM d').format(_selectedDate);

    return Column(
      children: [
        // Date and calendar icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Today, ${DateFormat('MMMM d').format(_selectedDate)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

        // Nutrition summary card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nutrition Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${nutrients['calories']?.toInt() ?? 0} / 2,000 cal',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (nutrients['calories'] ?? 0) / 2000,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNutrientItem(
                        'Protein',
                        nutrients['protein'] ?? 0,
                        120,
                        'g',
                      ),
                      _buildNutrientItem(
                        'Carbs',
                        nutrients['carbs'] ?? 0,
                        250,
                        'g',
                      ),
                      _buildNutrientItem('Fat', nutrients['fat'] ?? 0, 65, 'g'),
                      _buildNutrientItem('Water', 0.75, 2.5, 'L'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _handleDateChange('prev'),
                icon: const Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: Colors.green,
                ),
                label: const Text(
                  'Previous',
                  style: TextStyle(color: Colors.green),
                ),
              ),
              TextButton.icon(
                onPressed: () => _handleDateChange('next'),
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Colors.green,
                ),
                label: const Text(
                  'Next',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),

        // Time slots list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _timeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = _timeSlots.keys.elementAt(index);
              final events = _timeSlots[timeSlot] ?? [];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  SizedBox(
                    width: 64,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        timeSlot,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // Events column
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 8),
                      child:
                          events.isEmpty
                              ? GestureDetector(
                                onTap: _showAddEventDialog,
                                child: Container(
                                  height: 48,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              )
                              : Column(
                                children:
                                    events.map((event) {
                                      return _buildEventItem(event);
                                    }).toList(),
                              ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientItem(
    String label,
    double value,
    double target,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}/$target $unit',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: (value / target).clamp(0.0, 1.0),
            backgroundColor: Colors.green.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    Color backgroundColor;
    IconData iconData;

    // Set color and icon based on event type
    switch (event['type']) {
      case 'food':
        backgroundColor = Colors.green.withOpacity(0.1);
        iconData = Icons.restaurant;
        break;
      case 'water':
        backgroundColor = Colors.blue.withOpacity(0.1);
        iconData = Icons.water_drop;
        break;
      case 'activity':
        backgroundColor = Colors.orange.withOpacity(0.1);
        iconData = Icons.fitness_center;
        break;
      case 'calendar':
        backgroundColor = Colors.purple.withOpacity(0.1);
        iconData = Icons.calendar_today;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        iconData = Icons.event_note;
    }

    return GestureDetector(
      onTap:
          _showAddEventDialog, // Show dialog when tapping on any event for simplicity
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(iconData, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${event['time']} ${event['title']}',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event['type'] == 'food' && event['calories'] != null)
              Text(
                '${event['calories']} kcal',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Nutrition Tracker',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(height: 8),
                Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Food Log'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FoodLogScreen()),
              );
            },
          ),
          const Divider(),
          // Subscription-related menu items
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Meal Plans'),
            subtitle:
                subscriptionProvider.activeSubscription != null
                    ? Text(
                      'Active: ${subscriptionProvider.activeSubscription!.subscriptionId}',
                    )
                    : const Text('Subscribe to a meal plan'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionScreen(userId: _userId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Membership'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MembershipScreen(userId: _userId),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Daily Diary'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DiaryScreen()),
              );
            },
          ),
          const Divider(),
          // Test functionality button
          ListTile(
            leading: const Icon(Icons.science),
            title: const Text('Test Subscription'),
            onTap: () {
              Navigator.pop(context);
              _testSubscriptionFunctionality();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _testSubscriptionFunctionality() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user ID available for testing')),
      );
      return;
    }

    try {
      // Get first subscription (for testing)
      final subsSnapshot =
          await FirebaseFirestore.instance
              .collection('subscriptions')
              .limit(1)
              .get();

      if (subsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No subscriptions found. Initialize database first.'),
          ),
        );
        return;
      }

      final subscriptionId = subsSnapshot.docs.first.id;
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );

      // Subscribe the user
      final success = await subscriptionProvider.subscribeUserToPlan(
        _userId!,
        subscriptionId,
        null, // No membership tier for basic test
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully subscribed to plan!'),
            backgroundColor: Colors.green,
          ),
        );
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing Nutrition AI...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to initialize Nutrition AI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final passioProvider = Provider.of<PassioProvider>(
                context,
                listen: false,
              );
              passioProvider.initializePassioSDK();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showAddFoodOptions(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoModalPopup(
        context: context,
        builder:
            (BuildContext context) => CupertinoActionSheet(
              title: const Text('Add Food'),
              message: const Text('Choose how to add food'),
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToCameraScreen();
                  },
                  child: const Text('Camera'),
                ),
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToSearchScreen();
                  },
                  child: const Text('Search'),
                ),
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FoodLogScreen(),
                      ),
                    );
                  },
                  child: const Text('View All Logs'),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToCameraScreen();
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToSearchScreen();
                },
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('View All Logs'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FoodLogScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Navigate to camera screen using your existing implementation
  // For camera screen navigation:
  void _navigateToCameraScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    ).then((_) {
      // Simply refresh the food logs when returning
      setState(() {
        _loadFoodLogsIntoTimeSlots();
      });
    });
  }

  // For search screen navigation:
  void _navigateToSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FoodSearchScreen()),
    ).then((_) {
      // Simply refresh the food logs when returning
      setState(() {
        _loadFoodLogsIntoTimeSlots();
      });
    });
  }
}
