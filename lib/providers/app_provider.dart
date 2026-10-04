import 'package:flutter/foundation.dart';
import '../models/swap_item.dart';
import '../models/user.dart';
import '../models/swap.dart';
import '../models/message.dart';
import '../models/call_record.dart';
import '../models/conversation.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  User? _currentUser;
  List<SwapItem> _availableItems = [];
  List<SwapItem> _userItems = [];
  List<Swap> _activeSwaps = [];
  List<Swap> _completedSwaps = [];
  List<Achievement> _achievements = [];
  List<Conversation> _conversations = [];
  List<Message> _activeMessages = [];
  List<CallRecord> _recentCalls = [];
  bool _isLoading = false;
  String? _error;
  bool _useDemoData = false;

  final Map<String, Map<String, String>> _loginAccounts = {
    'el22039@mail.ntua.gr': {
      'password': 'el22039',
      'userId': 'user_demo',
      'name': 'Γρηγόρης Σταματόπουλος',
    },
    'el22869@mail.ntua.gr': {
      'password': 'el22869',
      'userId': 'user_thanos',
      'name': 'Θάνος Σταθόπουλος',
    },
    'el22028@mail.ntua.gr': {
      'password': 'el22028',
      'userId': 'user_nikolas',
      'name': 'Νικόλας Φράγκος',
    },
  };

  User? get currentUser => _currentUser;
  List<SwapItem> get availableItems => _availableItems;
  List<SwapItem> get userItems => _userItems;
  List<Swap> get activeSwaps => _activeSwaps;
  List<Swap> get completedSwaps => _completedSwaps;
  List<Achievement> get achievements => _achievements;
  List<Conversation> get conversations => _conversations;
  List<Message> get activeMessages => _activeMessages;
  List<CallRecord> get recentCalls => _recentCalls;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    _setLoading(true);

    _useDemoData = kIsWeb;

    if (_useDemoData) {
      _setLoading(false);
      return;
    }

    try {
      await _db.ensureSeedData();
    } catch (e) {
      _error = e.toString();
      _useDemoData = true;
      _bootstrapDemoData(_demoUserById('user_demo'));
    }

    _setLoading(false);
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    final account = _loginAccounts[email.trim()];
    if (account == null || account['password'] != password.trim()) {
      _error = 'Λάθος email ή κωδικός';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    final userId = account['userId']!;

    if (_useDemoData) {
      _bootstrapDemoData(_demoUserById(userId));
      _setLoading(false);
      return true;
    }

    try {
      _currentUser = await _db.getUser(userId);

      if (_currentUser == null) {
        await _db.ensureSeedData();
        _currentUser = await _db.getUser(userId);
      }

      await refreshData();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _availableItems = [];
    _userItems = [];
    _activeSwaps = [];
    _completedSwaps = [];
    _achievements = [];
    _conversations = [];
    _activeMessages = [];
    _recentCalls = [];
    _error = null;
    notifyListeners();
  }

  Future<void> refreshData() async {
    if (_useDemoData) {
      notifyListeners();
      return;
    }

    if (_currentUser == null) return;
    
    try {
      _availableItems = await _db.getAvailableItems(_currentUser!.id);
      _userItems = await _db.getUserItems(_currentUser!.id);
      _activeSwaps = await _db.getActiveSwaps(_currentUser!.id);
      _completedSwaps = await _db.getCompletedSwaps(_currentUser!.id);
      await _db.ensureAchievementsForUser(_currentUser!.id);
      _achievements = await _db.getUserAchievements(_currentUser!.id);
      await _loadConversations();
      await _loadRecentCalls();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Messaging
  Future<void> _loadConversations() async {
    if (_useDemoData || _currentUser == null) {
      _conversations = _demoConversations();
      return;
    }

    final messages = await _db.getAllMessagesForUser(_currentUser!.id);
    _conversations = _buildConversationsFromMessages(messages, _currentUser!.id);
  }

  Future<void> openConversation(String partnerId, String partnerName) async {
    if (_useDemoData || _currentUser == null) {
      _activeMessages = _demoMessages(partnerId, partnerName);
      _conversations = _conversations
          .map((c) => c.partnerId == partnerId
              ? c.copyWith(unreadCount: 0)
              : c)
          .toList();
      notifyListeners();
      return;
    }

    final conversationId = _conversationId(_currentUser!.id, partnerId);
    _activeMessages = await _db.getMessages(conversationId);
    await _db.markConversationRead(conversationId, _currentUser!.id);
    await _loadConversations();
    notifyListeners();
  }

  Future<void> sendMessage({
    required String partnerId,
    required String partnerName,
    required String text,
  }) async {
    if (_currentUser == null) return;

    final message = Message(
      conversationId: _conversationId(_currentUser!.id, partnerId),
      senderId: _currentUser!.id,
      senderName: _currentUser!.name,
      receiverId: partnerId,
      receiverName: partnerName,
      text: text,
      isRead: false,
    );

    if (_useDemoData) {
      _activeMessages = [..._activeMessages, message];
      _conversations = _buildConversationsFromMessages(
        [..._activeMessages],
        _currentUser!.id,
      );
      notifyListeners();
      return;
    }

    await _db.insertMessage(message);
    _activeMessages = await _db.getMessages(message.conversationId);
    await _loadConversations();
    notifyListeners();
  }

  Future<void> markConversationRead(String partnerId) async {
    if (_useDemoData || _currentUser == null) {
      _conversations = _conversations
          .map((c) => c.partnerId == partnerId
              ? c.copyWith(unreadCount: 0)
              : c)
          .toList();
      notifyListeners();
      return;
    }
    final conversationId = _conversationId(_currentUser!.id, partnerId);
    await _db.markConversationRead(conversationId, _currentUser!.id);
    await _loadConversations();
    notifyListeners();
  }

  // Calls
  Future<void> _loadRecentCalls() async {
    if (_useDemoData || _currentUser == null) {
      _recentCalls = _demoCalls();
      return;
    }

    _recentCalls = await _db.getRecentCalls(_currentUser!.id);
  }

  Future<void> startCall({
    required String partnerId,
    required String partnerName,
    bool incoming = false,
    bool missed = false,
  }) async {
    final call = CallRecord(
      partnerId: partnerId,
      partnerName: partnerName,
      direction: incoming ? CallDirection.incoming : CallDirection.outgoing,
      status: missed ? CallStatus.missed : CallStatus.inProgress,
    );

    if (_useDemoData || _currentUser == null) {
      _recentCalls = [call, ..._recentCalls].take(20).toList();
      notifyListeners();
      return;
    }

    await _db.insertCall(call);
    await _loadRecentCalls();
    notifyListeners();
  }

  // Swipe actions
  Future<void> swipeLeft(SwapItem item) async {
    if (_currentUser == null) return;

    if (_useDemoData) {
      _availableItems.removeWhere((i) => i.id == item.id);
      notifyListeners();
      return;
    }
    
    try {
      await _db.recordSwipe(_currentUser!.id, item.id, false);
      _availableItems.removeWhere((i) => i.id == item.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> swipeRight(SwapItem item) async {
    if (_currentUser == null) return;

    if (_useDemoData) {
      _availableItems.removeWhere((i) => i.id == item.id);
      _activeSwaps = [
        Swap(
          myItemId: 'my_item_${DateTime.now().millisecondsSinceEpoch}',
          myItemName: 'Το αντικείμενό σου',
          theirItemId: item.id,
          theirItemName: item.itemName,
          partnerId: item.userId,
          partnerName: item.userName,
          status: SwapStatus.pending,
        ),
        ..._activeSwaps,
      ];
      notifyListeners();
      return;
    }
    
    try {
      await _db.recordSwipe(_currentUser!.id, item.id, true);
      
      // Simulate match - create a new swap request
      final swap = Swap(
        myItemId: 'my_item_new',
        myItemName: 'Το αντικείμενό σου',
        theirItemId: item.id,
        theirItemName: item.itemName,
        partnerId: item.userId,
        partnerName: item.userName,
        status: SwapStatus.pending,
      );
      await _db.insertSwap(swap);
      
      _availableItems.removeWhere((i) => i.id == item.id);
      _activeSwaps = await _db.getActiveSwaps(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Add new item
  Future<void> addItem({
    required String itemName,
    required String category,
    required String wantsCategory,
    required String imageUrl,
    String description = '',
  }) async {
    if (_currentUser == null) return;
    
    if (_useDemoData) {
      final item = SwapItem(
        itemName: itemName,
        description: description,
        category: category,
        wantsCategory: wantsCategory,
        imageUrl: imageUrl,
        userId: _currentUser!.id,
        userName: _currentUser!.name,
        userScore: _currentUser!.swapScore,
        distance: 0,
      );
      _userItems = [item, ..._userItems];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final item = SwapItem(
        itemName: itemName,
        description: description,
        category: category,
        wantsCategory: wantsCategory,
        imageUrl: imageUrl,
        userId: _currentUser!.id,
        userName: _currentUser!.name,
        userScore: _currentUser!.swapScore,
      );
      
      await _db.insertItem(item);
      _userItems = await _db.getUserItems(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  // Swap actions
  Future<void> confirmSwap(String swapId) async {
    if (_useDemoData) {
      _activeSwaps = _activeSwaps
          .map((swap) => swap.id == swapId
              ? swap.copyWith(status: SwapStatus.confirmed)
              : swap)
          .toList();
      notifyListeners();
      return;
    }

    try {
      await _db.updateSwapStatus(swapId, SwapStatus.confirmed);
      await refreshData();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> completeSwap(String swapId, int rating) async {
    if (_currentUser == null) return;

    if (_useDemoData) {
      final index = _activeSwaps.indexWhere((swap) => swap.id == swapId);
      if (index != -1) {
        final updated = _activeSwaps[index].copyWith(
          status: SwapStatus.completed,
          completedAt: DateTime.now(),
          rating: rating,
        );
        _activeSwaps.removeAt(index);
        _completedSwaps = [updated, ..._completedSwaps];

        final newScore = _currentUser!.swapScore + 10 + rating;
        final newTotalSwaps = _currentUser!.totalSwaps + 1;
        final newLevel = User.calculateLevel(newScore);

        _currentUser = _currentUser!.copyWith(
          swapScore: newScore,
          totalSwaps: newTotalSwaps,
          level: newLevel,
        );
        notifyListeners();
      }
      return;
    }
    
    try {
      await _db.updateSwapStatus(swapId, SwapStatus.completed);
      
      // Update user score
      final newScore = _currentUser!.swapScore + 10 + rating;
      final newTotalSwaps = _currentUser!.totalSwaps + 1;
      final newLevel = User.calculateLevel(newScore);
      
      _currentUser = _currentUser!.copyWith(
        swapScore: newScore,
        totalSwaps: newTotalSwaps,
        level: newLevel,
      );
      
      await _db.updateUser(_currentUser!);
      await refreshData();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> cancelSwap(String swapId) async {
    if (_useDemoData) {
      _activeSwaps = _activeSwaps
          .map((swap) => swap.id == swapId
              ? swap.copyWith(status: SwapStatus.cancelled)
              : swap)
          .toList();
      notifyListeners();
      return;
    }

    try {
      await _db.updateSwapStatus(swapId, SwapStatus.cancelled);
      await refreshData();
    } catch (e) {
      _error = e.toString();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  User _demoUserById(String id) {
    switch (id) {
      case 'user_thanos':
        return User(
          id: 'user_thanos',
          name: 'Θάνος Σταθόπουλος',
          email: 'el22869@mail.ntua.gr',
          swapScore: 210,
          level: 'Swap Pro',
          totalSwaps: 18,
          successRate: 88,
          rating: 4.6,
          location: 'Νέα Σμύρνη, Αττική',
          memberSince: DateTime(2024, 6, 10),
        );
      case 'user_nikolas':
        return User(
          id: 'user_nikolas',
          name: 'Νικόλας Φράγκος',
          email: 'el22028@mail.ntua.gr',
          swapScore: 175,
          level: 'Swap Pro',
          totalSwaps: 12,
          successRate: 82,
          rating: 4.5,
          location: 'Πειραιάς, Αττική',
          memberSince: DateTime(2024, 8, 5),
        );
      default:
        return User(
          id: 'user_demo',
          name: 'Γρηγόρης Σταματόπουλος',
          email: 'el22039@mail.ntua.gr',
          swapScore: 285,
          level: 'Swap Master',
          totalSwaps: 47,
          successRate: 94,
          rating: 4.8,
          location: 'Κηφισιά, Αττική',
          memberSince: DateTime(2024, 3, 1),
        );
    }
  }

  List<User> _demoUsers() {
    return [
      _demoUserById('user_demo'),
      _demoUserById('user_thanos'),
      _demoUserById('user_nikolas'),
    ];
  }

  void _bootstrapDemoData(User user) {
    _useDemoData = true;
    _currentUser = user;

    String img(String path) =>
        'https://images.unsplash.com/$path?auto=format&fit=crop&w=900&q=80';

    final achievements = Achievement.defaultAchievements().map((achievement) {
      final unlocked = achievement.id == '1' ||
          achievement.id == '2' ||
          achievement.id == '3';
      return Achievement(
        id: achievement.id,
        name: achievement.name,
        icon: achievement.icon,
        unlocked: unlocked,
        description: achievement.description,
      );
    }).toList();

    _achievements = achievements;

    final demoItems = [
      SwapItem(
        id: 'item_1',
        itemName: 'Vintage Camera',
        description: 'Παλιά φωτογραφική μηχανή σε άριστη κατάσταση',
        category: 'Electronics',
        wantsCategory: 'Books',
        imageUrl: img('photo-1516035069371-29a1b244cc32'),
        userId: 'user_thanos',
        userName: 'Θάνος Σταθόπουλος',
        userScore: 245,
        distance: 0.8,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      SwapItem(
        id: 'item_2',
        itemName: 'Guitar Lessons Book',
        description: 'Βιβλίο μαθημάτων κιθάρας για αρχάριους',
        category: 'Books',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1510915361894-db8b60106cb1'),
        userId: 'user_nikolas',
        userName: 'Νικόλας Φράγκος',
        userScore: 180,
        distance: 1.2,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      SwapItem(
        id: 'item_3',
        itemName: 'Running Shoes',
        description: 'Nike running shoes μέγεθος 43, σχεδόν καινούργια',
        category: 'Sports',
        wantsCategory: 'Sports',
        imageUrl: img('photo-1542291026-7eec264c27ff'),
        userId: 'user_other_3',
        userName: 'Elena S.',
        userScore: 320,
        distance: 0.5,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      SwapItem(
        id: 'item_4',
        itemName: 'Coffee Maker',
        description: 'Μηχανή καφέ espresso DeLonghi',
        category: 'Kitchen',
        wantsCategory: 'Kitchen',
        imageUrl: img('photo-1514432324607-a09d9b4aefdd'),
        userId: 'user_other_4',
        userName: 'Dimitris A.',
        userScore: 195,
        distance: 2.1,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      SwapItem(
        id: 'item_5',
        itemName: 'Yoga Mat',
        description: 'Επαγγελματικό στρώμα yoga 6mm',
        category: 'Fitness',
        wantsCategory: 'Fitness',
        imageUrl: img('photo-1544367567-0f2fcb009e0b'),
        userId: 'user_other_5',
        userName: 'Sofia L.',
        userScore: 275,
        distance: 1.5,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SwapItem(
        id: 'item_6',
        itemName: 'Mechanical Keyboard',
        description: 'RGB, hot-swap, σχεδόν καινούργιο',
        category: 'Electronics',
        wantsCategory: 'Music',
        imageUrl: img('photo-1517336714731-489689fd1ca8'),
        userId: 'user_other_8',
        userName: 'Petros V.',
        userScore: 305,
        distance: 1.1,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      SwapItem(
        id: 'item_7',
        itemName: 'Vinyl Records Pack',
        description: '10 classic rock δίσκοι',
        category: 'Music',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1511671782779-c97d3d27a1d4'),
        userId: 'user_other_9',
        userName: 'Katerina L.',
        userScore: 190,
        distance: 3.2,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      SwapItem(
        id: 'item_8',
        itemName: 'LEGO Technic Set',
        description: 'Σχεδόν καινούργιο, πλήρες σετ',
        category: 'Games',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1581291518857-4e27b48ff24e'),
        userId: 'user_other_10',
        userName: 'Alex S.',
        userScore: 260,
        distance: 4.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      ),
      SwapItem(
        id: 'item_9',
        itemName: 'Mountain Bike Helmet',
        description: 'MIPS certified, μέγεθος L',
        category: 'Sports',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1506377247377-2a5b3b417ebb'),
        userId: 'user_thanos',
        userName: 'Θάνος Σταθόπουλος',
        userScore: 210,
        distance: 2.4,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      SwapItem(
        id: 'item_10',
        itemName: 'Espresso Cups Set',
        description: 'Σετ 6 φλιτζανιών πορσελάνης',
        category: 'Kitchen',
        wantsCategory: 'Books',
        imageUrl: img('photo-1504674900247-0877df9cc836'),
        userId: 'user_nikolas',
        userName: 'Νικόλας Φράγκος',
        userScore: 160,
        distance: 0.9,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      SwapItem(
        id: 'item_11',
        itemName: 'Analog Synth',
        description: 'Mini synth, ιδανικό για jam sessions',
        category: 'Music',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1511379938547-c1f69419868d'),
        userId: 'user_other_11',
        userName: 'Irene P.',
        userScore: 240,
        distance: 1.7,
        createdAt: DateTime.now().subtract(const Duration(hours: 6, minutes: 30)),
      ),
      SwapItem(
        id: 'item_12',
        itemName: 'Road Cycling Jersey',
        description: 'Breathable, μέγεθος M, καθαρό',
        category: 'Sports',
        wantsCategory: 'Books',
        imageUrl: img('photo-1476480862126-209bfaa8edc8'),
        userId: 'user_other_12',
        userName: 'Lefteris Z.',
        userScore: 205,
        distance: 3.5,
        createdAt: DateTime.now().subtract(const Duration(hours: 8, minutes: 10)),
      ),
      SwapItem(
        id: 'item_15',
        itemName: 'Hiking Backpack 40L',
        description: 'Αδιάβροχο, ελαφρύ, με θήκη υδροδοχείου',
        category: 'Outdoor',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1500530855697-b586d89ba3ee'),
        userId: 'user_other_13',
        userName: 'Christos M.',
        userScore: 215,
        distance: 2.8,
        createdAt: DateTime.now().subtract(const Duration(hours: 11)),
      ),
      SwapItem(
        id: 'item_16',
        itemName: 'Instant Pot Duo',
        description: 'Multi-cooker 6L, δουλεύει άψογα',
        category: 'Kitchen',
        wantsCategory: 'Books',
        imageUrl: img('photo-1546069901-ba9599a7e63c'),
        userId: 'user_other_14',
        userName: 'Jenny P.',
        userScore: 260,
        distance: 1.9,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      SwapItem(
        id: 'item_17',
        itemName: 'Electric Scooter',
        description: '40km range, πρόσφατη μπαταρία',
        category: 'Electronics',
        wantsCategory: 'Outdoor',
        imageUrl: img('photo-1502877828070-33b167ad6860'),
        userId: 'user_other_15',
        userName: 'Alexandros K.',
        userScore: 300,
        distance: 3.6,
        createdAt: DateTime.now().subtract(const Duration(hours: 13)),
      ),
      SwapItem(
        id: 'item_18',
        itemName: 'Standing Desk',
        description: 'Ρυθμιζόμενο ύψος, 120x60, λευκό',
        category: 'Furniture',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1524758631624-e2822e304c36'),
        userId: 'user_other_16',
        userName: 'Eleni D.',
        userScore: 240,
        distance: 2.2,
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      SwapItem(
        id: 'item_19',
        itemName: 'Smartwatch Garmin',
        description: 'GPS, HR, 10 ημέρες μπαταρία',
        category: 'Electronics',
        wantsCategory: 'Sports',
        imageUrl: img('photo-1511707171634-5f897ff02aa9'),
        userId: 'user_other_17',
        userName: 'Nefeli T.',
        userScore: 255,
        distance: 1.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 6, minutes: 45)),
      ),
      SwapItem(
        id: 'item_20',
        itemName: 'DJI Mini Drone',
        description: 'Ελαφρύ, 2 μπαταρίες, 4K video',
        category: 'Electronics',
        wantsCategory: 'Photography',
        imageUrl: img('photo-1473186578172-c141e6798cf4'),
        userId: 'user_other_18',
        userName: 'Stavros L.',
        userScore: 285,
        distance: 3.9,
        createdAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
      ),
      SwapItem(
        id: 'item_21',
        itemName: 'Canon 50mm Lens',
        description: 'F1.8, καθαρό γυαλί, με καπάκια',
        category: 'Photography',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1473654729523-203e25dfda10'),
        userId: 'user_thanos',
        userName: 'Θάνος Σταθόπουλος',
        userScore: 210,
        distance: 1.6,
        createdAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 10)),
      ),
      SwapItem(
        id: 'item_22',
        itemName: 'Acoustic Guitar',
        description: 'Yamaha, καινούργιες χορδές',
        category: 'Music',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1510915361894-db8b60106cb1'),
        userId: 'user_nikolas',
        userName: 'Νικόλας Φράγκος',
        userScore: 175,
        distance: 0.7,
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
      ),
    ];

    _availableItems = demoItems.where((item) => item.userId != user.id).toList();

    _userItems = [
      SwapItem(
        id: 'my_item_1',
        itemName: 'Bluetooth Speaker',
        description: 'Φορητό ηχείο με 10 ώρες αυτονομία',
        category: 'Electronics',
        wantsCategory: 'Books',
        imageUrl: img('photo-1505740420928-5e560c06d30e'),
        userId: user.id,
        userName: user.name,
        userScore: user.swapScore,
        distance: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SwapItem(
        id: 'my_item_2',
        itemName: 'Book Collection',
        description: 'Συλλογή με 12 best sellers',
        category: 'Books',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1524578475443-58b4c1d91a5c'),
        userId: user.id,
        userName: user.name,
        userScore: user.swapScore,
        distance: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    _activeSwaps = [
      Swap(
        id: 'swap_active_1',
        myItemId: 'my_item_1',
        myItemName: 'Bluetooth Speaker',
        theirItemId: 'item_1',
        theirItemName: 'Vintage Camera',
        partnerId: 'user_other_1',
        partnerName: 'Maria K.',
        status: SwapStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Swap(
        id: 'swap_active_2',
        myItemId: 'my_item_2',
        myItemName: 'Book Collection',
        theirItemId: 'item_2',
        theirItemName: 'Guitar Lessons Book',
        partnerId: 'user_other_2',
        partnerName: 'Nikos P.',
        status: SwapStatus.confirmed,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    _completedSwaps = [
      Swap(
        id: 'swap_completed_1',
        myItemId: 'my_item_3',
        myItemName: 'Vintage Camera',
        theirItemId: 'their_item_3',
        theirItemName: 'Art Supplies',
        partnerId: 'user_other_3',
        partnerName: 'Elena S.',
        status: SwapStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        completedAt: DateTime.now().subtract(const Duration(days: 5)),
        rating: 5,
      ),
      Swap(
        id: 'swap_completed_2',
        myItemId: 'my_item_4',
        myItemName: 'Running Shoes',
        theirItemId: 'their_item_4',
        theirItemName: 'Yoga Mat',
        partnerId: 'user_other_4',
        partnerName: 'Dimitris A.',
        status: SwapStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        completedAt: DateTime.now().subtract(const Duration(days: 8)),
        rating: 5,
      ),
    ];

    final peers = _demoUsers().where((u) => u.id != user.id).toList();
    _conversations = _demoConversations();
    _activeMessages = peers.isNotEmpty
        ? _demoMessages(peers.first.id, peers.first.name)
        : [];
    _recentCalls = _demoCalls();

    notifyListeners();
  }

  List<Conversation> _buildConversationsFromMessages(
    List<Message> messages,
    String currentUserId,
  ) {
    final Map<String, Conversation> map = {};

    for (final msg in messages) {
      final isCurrentUserSender = msg.senderId == currentUserId;
      final partnerId = isCurrentUserSender ? msg.receiverId : msg.senderId;
      final partnerName = isCurrentUserSender ? msg.receiverName : msg.senderName;
      final key = msg.conversationId;

      final unreadCountIncrement = (!isCurrentUserSender && !msg.isRead) ? 1 : 0;

      if (!map.containsKey(key)) {
        map[key] = Conversation(
          conversationId: key,
          partnerId: partnerId,
          partnerName: partnerName,
          lastMessage: msg.text,
          lastTimestamp: msg.sentAt,
          unreadCount: unreadCountIncrement,
        );
      } else {
        final existing = map[key]!;
        map[key] = existing.copyWith(
          lastMessage: msg.sentAt.isAfter(existing.lastTimestamp)
              ? msg.text
              : existing.lastMessage,
          lastTimestamp: msg.sentAt.isAfter(existing.lastTimestamp)
              ? msg.sentAt
              : existing.lastTimestamp,
          unreadCount: existing.unreadCount + unreadCountIncrement,
        );
      }
    }

    final list = map.values.toList()
      ..sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
    return list;
  }

  String _conversationId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  List<Conversation> _demoConversations() {
    if (_currentUser == null) return [];

    final now = DateTime.now();
    final peers = _demoUsers().where((u) => u.id != _currentUser!.id).toList();
    if (peers.isEmpty) return [];

    final firstPeer = peers[0];
    final secondPeer = peers.length > 1 ? peers[1] : null;

    String _lastText(String pid) {
      if (pid == 'user_thanos') {
        return 'Τέλεια, τα λέμε αύριο στην Κηφισιά.';
      }
      if (pid == 'user_nikolas') {
        return 'Ωραία, 18:30 στο Πανεπιστήμιο. Θα σε βρω στην έξοδο.';
      }
      return 'Στείλε το σημείο συνάντησης και έρχομαι.';
    }

    Duration _delta(String pid) {
      if (pid == 'user_nikolas') return const Duration(minutes: 40);
      if (pid == 'user_thanos') return const Duration(minutes: 8);
      return const Duration(minutes: 20);
    }

    return [
      Conversation(
        conversationId: _conversationId(_currentUser!.id, firstPeer.id),
        partnerId: firstPeer.id,
        partnerName: firstPeer.name,
        lastMessage: _lastText(firstPeer.id),
        lastTimestamp: now.subtract(_delta(firstPeer.id)),
        unreadCount: 1,
      ),
      if (secondPeer != null)
        Conversation(
          conversationId: _conversationId(_currentUser!.id, secondPeer.id),
          partnerId: secondPeer.id,
          partnerName: secondPeer.name,
          lastMessage: _lastText(secondPeer.id),
          lastTimestamp: now.subtract(_delta(secondPeer.id)),
          unreadCount: 1,
        ),
    ];
  }

  List<Message> _demoMessages(String partnerId, String partnerName) {
    if (_currentUser == null) return [];

    final now = DateTime.now();
    final meId = _currentUser!.id;
    final meName = _currentUser!.name;

    final script = <String, List<Map<String, dynamic>>>{
      'user_thanos': [
        {
          'text': 'Γεια σου! Η κάμερα είναι διαθέσιμη;',
          'delta': const Duration(minutes: 75),
          'fromMe': false,
        },
        {
          'text': 'Ναι, είναι οκ. Μόνο μια μικρή γρατζουνιά στη βάση.',
          'delta': const Duration(minutes: 60),
          'fromMe': true,
        },
        {
          'text': 'Δεν πειράζει. Μπορούμε να τη δούμε από κοντά;',
          'delta': const Duration(minutes: 35),
          'fromMe': false,
        },
        {
          'text': 'Ναι, αύριο γύρω στις 18:00;',
          'delta': const Duration(minutes: 18),
          'fromMe': true,
        },
        {
          'text': 'Τέλεια, τα λέμε αύριο στην Κηφισιά.',
          'delta': const Duration(minutes: 8),
          'fromMe': false,
        },
      ],
      'user_nikolas': [
        {
          'text': 'Έχεις ακόμη το βιβλίο κιθάρας;',
          'delta': const Duration(minutes: 95),
          'fromMe': false,
        },
        {
          'text': 'Το έχω, είναι καθαρό χωρίς σημειώσεις.',
          'delta': const Duration(minutes: 72),
          'fromMe': true,
        },
        {
          'text': 'Ωραία, σε βολεύει κέντρο;',
          'delta': const Duration(minutes: 55),
          'fromMe': false,
        },
        {
          'text': 'Ναι, είμαι εκεί το απόγευμα.',
          'delta': const Duration(minutes: 45),
          'fromMe': true,
        },
        {
          'text': 'Ωραία, 18:30 στο Πανεπιστήμιο. Θα σε βρω στην έξοδο.',
          'delta': const Duration(minutes: 40),
          'fromMe': false,
        },
      ],
    };

    final messages = script[partnerId] ?? [
      {
        'text': 'Καλησπέρα! Είναι διαθέσιμο το αντικείμενο;',
        'delta': const Duration(minutes: 70),
        'fromMe': false,
      },
      {
        'text': 'Ναι, είναι σε καλή κατάσταση.',
        'delta': const Duration(minutes: 48),
        'fromMe': true,
      },
      {
        'text': 'Τέλεια, πού συναντιόμαστε;',
        'delta': const Duration(minutes: 30),
        'fromMe': false,
      },
      {
        'text': 'Στείλε το σημείο συνάντησης και έρχομαι.',
        'delta': const Duration(minutes: 20),
        'fromMe': false,
      },
    ];

    return messages.map((entry) {
      final fromMe = entry['fromMe'] as bool;
      final text = entry['text'] as String;
      final delta = entry['delta'] as Duration;
      return Message(
        conversationId: _conversationId(meId, partnerId),
        senderId: fromMe ? meId : partnerId,
        senderName: fromMe ? meName : partnerName,
        receiverId: fromMe ? partnerId : meId,
        receiverName: fromMe ? partnerName : meName,
        text: text,
        sentAt: now.subtract(delta),
        isRead: fromMe,
      );
    }).toList();
  }

  List<CallRecord> _demoCalls() {
    return [
      CallRecord(
        partnerId: 'user_other_1',
        partnerName: 'Maria K.',
        direction: CallDirection.outgoing,
        status: CallStatus.ended,
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        durationSeconds: 185,
      ),
      CallRecord(
        partnerId: 'user_other_2',
        partnerName: 'Nikos P.',
        direction: CallDirection.incoming,
        status: CallStatus.missed,
        startedAt: DateTime.now().subtract(const Duration(hours: 5)),
        durationSeconds: 0,
      ),
    ];
  }
}
