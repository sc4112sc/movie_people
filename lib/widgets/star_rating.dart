import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final double rating;
  final double size;
  final int starCount;
  final Function(double rating)? onRatingChanged;
  final Color color;

  const StarRating({
    super.key,
    this.rating = 0.0,
    this.size = 24.0,
    this.starCount = 5,
    this.onRatingChanged,
    this.color = Colors.amber,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(covariant StarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating && widget.onRatingChanged == null) {
      _currentRating = widget.rating;
    }
  }

  Widget _buildStar(int index) {
    IconData iconData;
    if (index >= _currentRating) {
      iconData = Icons.star_border_rounded;
    } else if (index > _currentRating - 1 && index < _currentRating) {
      iconData = Icons.star_half_rounded;
    } else {
      iconData = Icons.star_rounded;
    }

    return Icon(
      iconData,
      color: index >= _currentRating ? Colors.grey.withOpacity(0.5) : widget.color,
      size: widget.size,
    );
  }

  void _handleInteraction(Offset localPosition, double width) {
    if (widget.onRatingChanged == null) return;
    
    // Calculate new rating based on the position within the row
    final starWidth = width / widget.starCount;
    final rating = (localPosition.dx / starWidth).clamp(0.0, widget.starCount.toDouble());
    // Snap to nearest half rating
    final snappedRating = (rating * 2).round() / 2.0;

    setState(() {
      _currentRating = snappedRating;
    });
  }

  void _commitRating() {
    if (widget.onRatingChanged != null) {
      widget.onRatingChanged!(_currentRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) => _handleInteraction(details.localPosition, widget.size * widget.starCount),
          onPanUpdate: (details) => _handleInteraction(details.localPosition, widget.size * widget.starCount),
          onPanEnd: (_) => _commitRating(),
          onTapUp: (_) => _commitRating(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.starCount, (index) => _buildStar(index)),
          ),
        );
      },
    );
  }
}
