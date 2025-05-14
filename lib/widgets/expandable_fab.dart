import 'package:flutter/material.dart';
import 'dart:math' as math;

// Class to represent the data for each action button
class FloatingActionButtonItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  FloatingActionButtonItem({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

// The main expandable FAB widget
class ExpandableFab extends StatefulWidget {
  final List<FloatingActionButtonItem> items;
  final Color? backgroundColor;
  final IconData? mainIcon;
  final double mainButtonSize;
  final double childButtonSize;

  const ExpandableFab({
    Key? key,
    required this.items,
    this.backgroundColor,
    this.mainIcon,
    this.mainButtonSize = 56.0,
    this.childButtonSize = 48.0,
  }) : super(key: key);

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: math.pi / 4).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop overlay when menu is expanded - tapping it collapses the menu
        _buildBackdrop(),

        // Child buttons that appear when expanded
        ..._buildExpandingActionButtons(),

        // Main floating action button
        _buildMainButton(),
      ],
    );
  }

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isExpanded,
        child: GestureDetector(
          onTap: _isExpanded ? _toggleExpanded : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color:
                _isExpanded
                    ? Colors.black.withOpacity(0.3)
                    : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;

    return FloatingActionButton(
      backgroundColor: backgroundColor,
      onPressed: _toggleExpanded,
      child: AnimatedBuilder(
        animation: _rotateAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateAnimation.value,
            child: Icon(
              _isExpanded ? Icons.close : (widget.mainIcon ?? Icons.add),
              size: 24,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final theme = Theme.of(context);
    final buttonColor = widget.backgroundColor ?? theme.primaryColor;
    final children = <Widget>[];

    final count = widget.items.length;

    for (var i = 0; i < count; i++) {
      final item = widget.items[i];
      final childFab = AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          final double itemDistance =
              70.0 + (i * 10.0); // Customize this value for spacing
          return Transform.translate(
            offset: Offset(0, _expandAnimation.value * -itemDistance),
            child: Opacity(opacity: _expandAnimation.value, child: child),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            if (_isExpanded)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(item.label, style: const TextStyle(fontSize: 13)),
              ),

            // Button
            FloatingActionButton(
              heroTag: 'expandableFabItem$i',
              backgroundColor: buttonColor,
              mini: true,
              onPressed: () {
                _toggleExpanded(); // Close the menu
                item.onPressed(); // Execute the action
              },
              child: Icon(item.icon, size: 20),
            ),
          ],
        ),
      );

      children.add(childFab);
    }

    return children;
  }
}
