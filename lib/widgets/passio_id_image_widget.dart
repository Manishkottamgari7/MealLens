import 'package:flutter/material.dart';
import 'package:nutrition_ai/nutrition_ai.dart';

class PassioIDImageWidget extends StatefulWidget {
  final String iconId;
  final IconSize size;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? errorWidget;

  const PassioIDImageWidget(
      this.iconId, {
        Key? key,
        this.size = IconSize.px90,
        this.width = 40,
        this.height = 40,
        this.fit = BoxFit.cover,
        this.errorWidget,
      }) : super(key: key);

  @override
  State<PassioIDImageWidget> createState() => _PassioIDImageWidgetState();
}

class _PassioIDImageWidgetState extends State<PassioIDImageWidget> {
  String? _iconUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadIconUrl();
  }

  @override
  void didUpdateWidget(PassioIDImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconId != widget.iconId || oldWidget.size != widget.size) {
      _loadIconUrl();
    }
  }

  Future<void> _loadIconUrl() async {
    if (widget.iconId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fetch the icon URL from Nutrition AI
      final iconUrl = await NutritionAI.instance.iconURLFor(
        widget.iconId,
        iconSize: widget.size,
      );

      if (mounted) {
        setState(() {
          _iconUrl = iconUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error retrieving icon URL for ${widget.iconId}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_hasError || _iconUrl == null) {
      return _buildFallbackIcon();
    }

    return Image.network(
      _iconUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image from $_iconUrl: $error');
        return _buildFallbackIcon();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingIndicator();
      },
      cacheWidth: widget.width.toInt() * 2, // For better resolution
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Icon(
        Icons.fastfood,
        size: widget.width * 0.7,
        color: Colors.grey,
      ),
    );
  }
}