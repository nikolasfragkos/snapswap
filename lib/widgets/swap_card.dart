import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/swap_item.dart';
import '../assets/fallback_images.dart';

class SwapCard extends StatelessWidget {
  final SwapItem item;
  final bool isTop;

  const SwapCard({
    super.key,
    required this.item,
    this.isTop = true,
  });

  Widget _buildImage(String url) {
    final isNetwork = url.startsWith('http');

    if (!isNetwork) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.memory(
          FallbackImages.primary,
          fit: BoxFit.cover,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => Image.memory(
        FallbackImages.primary,
        fit: BoxFit.cover,
      ),
      errorWidget: (context, _, __) => Image.memory(
        FallbackImages.primary,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(item.imageUrl),
                  // Distance badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.distance} km',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Details section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name and wants category
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ζητάει: ${_getCategoryInGreek(item.wantsCategory)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // User info
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey[200]!,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              item.userName.isNotEmpty 
                                  ? item.userName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          // User name and score
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.userName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      size: 12,
                                      color: Colors.amber[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.userScore} Swap Score',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Time
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.getTimeAgo(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryInGreek(String category) {
    final categories = {
      'Electronics': 'Ηλεκτρονικά',
      'Books': 'Βιβλία',
      'Sports': 'Αθλητικά',
      'Kitchen': 'Κουζίνα',
      'Fitness': 'Fitness',
      'Fashion': 'Μόδα',
      'Music': 'Μουσική',
      'Games': 'Παιχνίδια',
    };
    return categories[category] ?? category;
  }
}

class SwipeableCard extends StatefulWidget {
  final SwapItem item;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const SwipeableCard({
    super.key,
    required this.item,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _dragOffset = 0;
  double _dragRotation = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating) return;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.delta.dx;
      _dragRotation = _dragOffset / 500 * 0.3;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.abs() > threshold || velocity.abs() > 500) {
      _animateSwipe(_dragOffset > 0);
    } else {
      _resetPosition();
    }
  }

  void _animateSwipe(bool isRight) {
    _isAnimating = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = isRight ? screenWidth * 1.5 : -screenWidth * 1.5;

    _animationController.reset();
    
    final Animation<double> offsetAnimation = Tween<double>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    final Animation<double> rotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: isRight ? 0.5 : -0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    offsetAnimation.addListener(() {
      setState(() {
        _dragOffset = offsetAnimation.value;
        _dragRotation = rotationAnimation.value;
      });
    });

    _animationController.forward().then((_) {
      _isAnimating = false;
      if (isRight) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
    });
  }

  void _resetPosition() {
    _animationController.reset();
    
    final Animation<double> offsetAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    final Animation<double> rotationAnimation = Tween<double>(
      begin: _dragRotation,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    offsetAnimation.addListener(() {
      setState(() {
        _dragOffset = offsetAnimation.value;
        _dragRotation = rotationAnimation.value;
      });
    });

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 500)).clamp(0.5, 1.0);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: Offset(_dragOffset, 0),
        child: Transform.rotate(
          angle: _dragRotation,
          child: Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                SwapCard(item: widget.item, isTop: true),
                
                // Swipe indicators
                if (_dragOffset != 0)
                  Positioned.fill(
                    child: _buildSwipeIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    final isRight = _dragOffset > 0;
    final progress = (_dragOffset.abs() / 100).clamp(0.0, 1.0);

    return Align(
      alignment: isRight ? Alignment.topRight : Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Transform.rotate(
          angle: isRight ? 0.2 : -0.2,
          child: Opacity(
            opacity: progress,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isRight ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: Text(
                isRight ? 'ΕΝΔΙΑΦΕΡΟΝ' : 'ΠΑΡΑΒΛΕΨΗ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
