import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/swap_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Quick Stats
              _buildQuickStats(),
              
              // Swap Cards
              Expanded(
                child: _buildSwapCards(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SnapSwap',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Κοντινές ανταλλαγές',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: Colors.green[600],
              ),
              const SizedBox(width: 8),
              Text(
                '${provider.availableItems.length} διαθέσιμα αντικείμενα σε ακτίνα 5km',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwapCards() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.availableItems.isEmpty) {
          return _buildEmptyState();
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Instructions
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Swipe δεξιά για ενδιαφέρον • Swipe αριστερά για παράβλεψη',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              // Card Stack
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background cards (showing stack effect)
                    if (provider.availableItems.length > 2)
                      Positioned(
                        child: Transform.scale(
                          scale: 0.9,
                          child: Transform.translate(
                            offset: const Offset(0, 20),
                            child: Opacity(
                              opacity: 0.5,
                              child: SwapCard(
                                item: provider.availableItems[2],
                                isTop: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (provider.availableItems.length > 1)
                      Positioned(
                        child: Transform.scale(
                          scale: 0.95,
                          child: Transform.translate(
                            offset: const Offset(0, 10),
                            child: Opacity(
                              opacity: 0.7,
                              child: SwapCard(
                                item: provider.availableItems[1],
                                isTop: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Top card (swipeable)
                    SwipeableCard(
                      key: ValueKey(provider.availableItems.first.id),
                      item: provider.availableItems.first,
                      onSwipeLeft: () {
                        HapticFeedback.lightImpact();
                        provider.swipeLeft(provider.availableItems.first);
                      },
                      onSwipeRight: () {
                        HapticFeedback.mediumImpact();
                        provider.swipeRight(provider.availableItems.first);
                        _showMatchSnackBar(context);
                      },
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.close,
                      color: Colors.red,
                      onTap: () {
                        if (provider.availableItems.isNotEmpty) {
                          HapticFeedback.lightImpact();
                          provider.swipeLeft(provider.availableItems.first);
                        }
                      },
                    ),
                    const SizedBox(width: 32),
                    _buildActionButton(
                      icon: Icons.favorite,
                      color: Colors.green,
                      onTap: () {
                        if (provider.availableItems.isNotEmpty) {
                          HapticFeedback.mediumImpact();
                          provider.swipeRight(provider.availableItems.first);
                          _showMatchSnackBar(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Δεν υπάρχουν άλλες προτάσεις',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Τράβα μια φωτογραφία για να βρεις νέες ανταλλαγές!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 32,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showMatchSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Αίτημα ανταλλαγής στάλθηκε!'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
