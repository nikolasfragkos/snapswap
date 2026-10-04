import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/swap.dart';
import 'chat_screen.dart';

class MySwapsScreen extends StatefulWidget {
  const MySwapsScreen({super.key});

  @override
  State<MySwapsScreen> createState() => _MySwapsScreenState();
}

class _MySwapsScreenState extends State<MySwapsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Οι Ανταλλαγές μου',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: Colors.white,
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  return TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        text: 'Ενεργές (${provider.activeSwaps.length})',
                      ),
                      Tab(
                        text: 'Ολοκληρωμένες (${provider.completedSwaps.length})',
                      ),
                    ],
                  );
                },
              ),
            ),

            // Tab content
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActiveSwaps(provider),
                      _buildCompletedSwaps(provider),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSwaps(AppProvider provider) {
    if (provider.activeSwaps.isEmpty) {
      return _buildEmptyState(
        icon: Icons.swap_horiz_rounded,
        title: 'Δεν έχεις ενεργές ανταλλαγές',
        subtitle: 'Swipe δεξιά σε μια πρόταση για να ξεκινήσεις!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.activeSwaps.length,
      itemBuilder: (context, index) {
        final swap = provider.activeSwaps[index];
        return _buildSwapCard(swap, isActive: true);
      },
    );
  }

  Widget _buildCompletedSwaps(AppProvider provider) {
    if (provider.completedSwaps.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'Δεν έχεις ολοκληρωμένες ανταλλαγές',
        subtitle: 'Οι ανταλλαγές που ολοκληρώνεις θα εμφανίζονται εδώ',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.completedSwaps.length,
      itemBuilder: (context, index) {
        final swap = provider.completedSwaps[index];
        return _buildSwapCard(swap, isActive: false);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapCard(Swap swap, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with partner info and status
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isActive 
                      ? Colors.blue[100] 
                      : Colors.green[100],
                  child: Text(
                    swap.partnerName.isNotEmpty 
                        ? swap.partnerName[0].toUpperCase() 
                        : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isActive 
                          ? Colors.blue[700] 
                          : Colors.green[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Partner name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        swap.partnerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        swap.getFormattedDate(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                _buildStatusBadge(swap.status),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Swap details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // My item
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'Προσφέρεις' : 'Πρόσφερες',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          swap.myItemName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Swap icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.swap_horiz,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ),
                  
                  // Their item
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'Λαμβάνεις' : 'Έλαβες',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          swap.theirItemName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Status message or rating
            if (isActive)
              _buildStatusMessage(swap)
            else if (swap.rating != null)
              _buildRatingSection(swap),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SwapStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case SwapStatus.pending:
        backgroundColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        text = 'Εκκρεμής';
        break;
      case SwapStatus.confirmed:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'Επιβεβαιωμένη';
        break;
      case SwapStatus.completed:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        text = 'Ολοκληρώθηκε';
        break;
      case SwapStatus.cancelled:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = 'Ακυρώθηκε';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatusMessage(Swap swap) {
    IconData icon;
    Color color;
    String message;

    switch (swap.status) {
      case SwapStatus.pending:
        icon = Icons.schedule;
        color = Colors.amber[700]!;
        message = 'Αναμονή επιβεβαίωσης από τον χρήστη';
        break;
      case SwapStatus.confirmed:
        icon = Icons.check_circle;
        color = Colors.green[700]!;
        message = 'Συνεννοηθείτε για τη συνάντηση';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Άνοιγμα συνομιλίας',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    partnerId: swap.partnerId,
                    partnerName: swap.partnerName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat, size: 18),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(Swap swap) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                size: 18,
                color: index < (swap.rating ?? 0) 
                    ? Colors.amber[500] 
                    : Colors.grey[300],
              );
            }),
          ),
          // Points
          Text(
            '+${10 + (swap.rating ?? 0)} Swap Score',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
