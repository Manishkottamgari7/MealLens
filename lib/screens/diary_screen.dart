import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../models/models.dart';
import '../providers/user_provider.dart';
import '../widgets/app_icons.dart';
import '../widgets/common_widgets.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  String _selectedDate = 'Today, May 15';
  DiaryEvent? _selectedEvent;
  bool _showEventDetails = false;
  final _formKey = GlobalKey<FormState>();
  String _newEventTitle = '';
  String _selectedEventType = 'food';
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

  void _showAddEventDialog() {
    showDialog(context: context, builder: (context) => _buildAddEventDialog());
  }

  void _handleDateChange(String direction) {
    setState(() {
      if (direction == 'prev') {
        _selectedDate = 'Yesterday, May 14';
      } else {
        _selectedDate = 'Tomorrow, May 16';
      }
    });
  }

  void _handleEventClick(DiaryEvent event) {
    setState(() {
      _selectedEvent = event;
      _showEventDetails = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final diaryEvents = userProvider.diaryEvents;

    // Calculate nutrition totals
    final totalCalories = diaryEvents
        .where((e) => e.type == EventType.food)
        .fold(0, (sum, e) => sum + (e.details['calories'] as int? ?? 0));

    final totalProtein = diaryEvents
        .where((e) => e.type == EventType.food)
        .fold(0, (sum, e) => sum + (e.details['protein'] as int? ?? 0));

    final totalCarbs = diaryEvents
        .where((e) => e.type == EventType.food)
        .fold(0, (sum, e) => sum + (e.details['carbs'] as int? ?? 0));

    final totalFat = diaryEvents
        .where((e) => e.type == EventType.food)
        .fold(0, (sum, e) => sum + (e.details['fat'] as int? ?? 0));

    final totalWater = diaryEvents
        .where((e) => e.type == EventType.water)
        .fold(0, (sum, e) => sum + (e.details['amount'] as int? ?? 0));

    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Diary',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          AppIcons.calendar,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    CircleIconButton(
                      icon: AppIcons.camera,
                      onPressed: () {
                        // Photo logging feature
                      },
                      size: 40,
                    ),
                    const SizedBox(width: 8),
                    CircleIconButton(
                      icon: AppIcons.add,
                      onPressed: _showAddEventDialog,
                      size: 40,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nutrition Summary
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nutrition Summary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalCalories / 2,000 cal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: totalCalories / 2000,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNutrientProgress(
                          theme,
                          'Protein',
                          totalProtein,
                          120,
                          'g',
                        ),
                        _buildNutrientProgress(
                          theme,
                          'Carbs',
                          totalCarbs,
                          250,
                          'g',
                        ),
                        _buildNutrientProgress(theme, 'Fat', totalFat, 65, 'g'),
                        _buildNutrientProgress(
                          theme,
                          'Water',
                          totalWater / 1000,
                          2.5,
                          'L',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // Calendar Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _handleDateChange('prev'),
                  icon: const Icon(AppIcons.arrowLeft, size: 16),
                  label: const Text('Previous'),
                ),
                TextButton.icon(
                  onPressed: () => _handleDateChange('next'),
                  icon: const Icon(AppIcons.arrowRight, size: 16),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),

          // Calendar View
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 17, // From 6 AM to 10 PM
              itemBuilder: (context, index) {
                final hour = index + 6;
                final time =
                    '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}';

                // Find events for this hour
                final hourEvents =
                    diaryEvents.where((event) {
                      final eventTime = event.time;
                      final eventHour = int.parse(eventTime.split(':')[0]);
                      final isPM = eventTime.contains('PM');
                      final normalizedEventHour =
                          isPM && eventHour != 12
                              ? eventHour + 12
                              : eventHour == 12 && !isPM
                              ? 0
                              : eventHour;
                      return normalizedEventHour == hour;
                    }).toList();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time column
                    SizedBox(
                      width: 64,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),

                    // Events column
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 8),
                        child:
                            hourEvents.isEmpty
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
                                      hourEvents
                                          .map(
                                            (event) =>
                                                _buildEventItem(theme, event),
                                          )
                                          .toList(),
                                ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientProgress(
    ThemeData theme,
    String label,
    num value,
    num target,
    String unit,
  ) {
    final percentage = (value / target * 100).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          '$value/$target $unit',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(ThemeData theme, DiaryEvent event) {
    Color backgroundColor;
    IconData iconData;

    switch (event.type) {
      case EventType.food:
        backgroundColor = Colors.green.withOpacity(0.1);
        iconData = AppIcons.food;
        break;
      case EventType.water:
        backgroundColor = Colors.blue.withOpacity(0.1);
        iconData = AppIcons.water;
        break;
      case EventType.activity:
        backgroundColor = Colors.orange.withOpacity(0.1);
        iconData = AppIcons.workout;
        break;
      case EventType.calendar:
        backgroundColor = Colors.purple.withOpacity(0.1);
        iconData = AppIcons.calendar;
        break;
    }

    return GestureDetector(
      onTap: () => _handleEventClick(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(iconData, size: 16, color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${event.time} ${event.title}',
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAddEventDialog() {
    final theme = Theme.of(context);

    return AlertDialog(
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
                decoration: const InputDecoration(labelText: 'Event Type'),
                value: _selectedEventType,
                items: const [
                  DropdownMenuItem(value: 'food', child: Text('Food')),
                  DropdownMenuItem(value: 'water', child: Text('Water')),
                  DropdownMenuItem(value: 'activity', child: Text('Activity')),
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
                      decoration: const InputDecoration(labelText: 'Time'),
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
                          (value) => _eventDuration = int.tryParse(value) ?? 30,
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
                            (value) => _foodCalories = int.tryParse(value) ?? 0,
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
                            (value) => _foodProtein = int.tryParse(value) ?? 0,
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
                            (value) => _foodCarbs = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Fat (g)'),
                        keyboardType: TextInputType.number,
                        onChanged:
                            (value) => _foodFat = int.tryParse(value) ?? 0,
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
                  decoration: const InputDecoration(labelText: 'Amount (ml)'),
                  initialValue: _waterAmount.toString(),
                  keyboardType: TextInputType.number,
                  onChanged:
                      (value) => _waterAmount = int.tryParse(value) ?? 250,
                ),
              ],

              if (_selectedEventType == 'activity') ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Activity Type'),
                  value: _activityType,
                  items: const [
                    DropdownMenuItem(value: 'Walking', child: Text('Walking')),
                    DropdownMenuItem(value: 'Running', child: Text('Running')),
                    DropdownMenuItem(value: 'Cycling', child: Text('Cycling')),
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
                      (value) => _activityCalories = int.tryParse(value) ?? 0,
                ),
              ],

              if (_selectedEventType == 'calendar') ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Location'),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(value: false, onChanged: (value) {}),
                    const Text('Sync with Apple Calendar'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _addNewEvent, child: const Text('Add Event')),
      ],
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
      late DiaryEvent newEvent;

      switch (_selectedEventType) {
        case 'food':
          newEvent = DiaryEvent(
            id: DateTime.now().millisecondsSinceEpoch,
            title: _newEventTitle.isEmpty ? 'Meal' : _newEventTitle,
            type: EventType.food,
            time: timeFormat,
            duration: _eventDuration,
            details: {
              'calories': _foodCalories,
              'protein': _foodProtein,
              'carbs': _foodCarbs,
              'fat': _foodFat,
              'items':
                  _foodItems.isEmpty
                      ? <String>[]
                      : _foodItems
                          .split('\n')
                          .where((line) => line.trim().isNotEmpty)
                          .toList(),
            },
          );
          break;
        case 'water':
          newEvent = DiaryEvent(
            id: DateTime.now().millisecondsSinceEpoch,
            title: _newEventTitle.isEmpty ? 'Hydration' : _newEventTitle,
            type: EventType.water,
            time: timeFormat,
            duration: _eventDuration,
            details: {'amount': _waterAmount},
          );
          break;
        case 'activity':
          newEvent = DiaryEvent(
            id: DateTime.now().millisecondsSinceEpoch,
            title: _newEventTitle.isEmpty ? _activityType : _newEventTitle,
            type: EventType.activity,
            time: timeFormat,
            duration: _eventDuration,
            details: {'type': _activityType, 'calories': _activityCalories},
          );
          break;
        case 'calendar':
          newEvent = DiaryEvent(
            id: DateTime.now().millisecondsSinceEpoch,
            title: _newEventTitle.isEmpty ? 'Meeting' : _newEventTitle,
            type: EventType.calendar,
            time: timeFormat,
            duration: _eventDuration,
            details: {
              'location': _eventLocation,
              'participants':
                  _eventParticipants.isEmpty
                      ? <String>[]
                      : _eventParticipants
                          .split('\n')
                          .where((line) => line.trim().isNotEmpty)
                          .toList(),
            },
          );
          break;
      }

      userProvider.addDiaryEvent(newEvent);
      Navigator.pop(context);
    }
  }

  Widget _buildEventDetailsDialog() {
    if (_selectedEvent == null) return const SizedBox();

    final theme = Theme.of(context);
    final event = _selectedEvent!;

    return AlertDialog(
      title: Text(event.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time & Duration
          Row(
            children: [
              Icon(AppIcons.time, size: 16),
              const SizedBox(width: 8),
              Text(
                '${event.time} • ${event.duration} min',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Event details based on type
          if (event.type == EventType.food) ...[
            // Nutrition grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionStat('Calories', event.details['calories']),
                _buildNutritionStat('Protein', '${event.details['protein']}g'),
                _buildNutritionStat('Carbs', '${event.details['carbs']}g'),
                _buildNutritionStat('Fat', '${event.details['fat']}g'),
              ],
            ),
            const SizedBox(height: 16),

            // Food items
            Text(
              'Items',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...((event.details['items'] as List<dynamic>?) ?? [])
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(item.toString()),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],

          if (event.type == EventType.water) ...[
            Center(
              child: Column(
                children: [
                  Icon(AppIcons.water, size: 48, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    '${event.details['amount']} ml',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Water intake',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (event.type == EventType.activity) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Activity Type',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      event.details['type'].toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Calories Burned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${event.details['calories']}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],

          if (event.type == EventType.calendar) ...[
            if (event.details.containsKey('location') &&
                event.details['location'] != null &&
                event.details['location'].toString().isNotEmpty) ...[
              Text(
                'Location',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                event.details['location'].toString(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (event.details.containsKey('participants') &&
                (event.details['participants'] as List<dynamic>?)?.isNotEmpty ==
                    true) ...[
              Text(
                'Participants',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    ((event.details['participants'] as List<dynamic>?) ?? [])
                        .map(
                          (person) => Chip(
                            label: Text(person.toString()),
                            backgroundColor: theme.colorScheme.surfaceVariant,
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Edit event (would open edit dialog)
            Navigator.pop(context);
          },
          child: const Text('Edit'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          onPressed: () {
            // Delete event
            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            userProvider.removeDiaryEvent(_selectedEvent!.id);
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Widget _buildNutritionStat(String label, dynamic value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Show event details dialog if needed
    if (_showEventDetails) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => _buildEventDetailsDialog(),
        ).then((_) {
          setState(() {
            _showEventDetails = false;
          });
        });
      });
    }
  }
}
