import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/swap_item.dart';
import '../models/user.dart';
import '../models/swap.dart';
import '../models/message.dart';
import '../models/call_record.dart';
import 'db_factory_stub.dart' if (dart.library.html) 'db_factory_web.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final webFactory = getWebDatabaseFactory();
    if (webFactory != null) {
      // On web, use the FFI web factory (persists to IndexedDB).
      databaseFactory = webFactory;
    }

    final String path = join(await getDatabasesPath(), 'snapswap.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Makes sure we have base data when the app boots (first run or cleared db).
  Future<void> ensureSeedData() async {
    final db = await database;
    final userCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;

    if (userCount == 0) {
      await _insertDemoData(db);
      return;
    }

    // Ensure achievements exist for all demo users if the table was cleared.
    const demoUserIds = ['user_demo', 'user_thanos', 'user_nikolas'];
    for (final uid in demoUserIds) {
      final achievementsCount = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM achievements WHERE userId = ?',
              [uid],
            ),
          ) ??
          0;

      if (achievementsCount == 0) {
        await _insertAchievements(db, uid);
      }
    }

    await _seedExtraDemoMessagesIfMissing(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        avatarUrl TEXT,
        swapScore INTEGER DEFAULT 0,
        level TEXT DEFAULT 'Νέος Χρήστης',
        totalSwaps INTEGER DEFAULT 0,
        successRate INTEGER DEFAULT 0,
        rating REAL DEFAULT 0,
        location TEXT,
        memberSince TEXT
      )
    ''');

    // Swap items table
    await db.execute('''
      CREATE TABLE swap_items (
        id TEXT PRIMARY KEY,
        itemName TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        wantsCategory TEXT NOT NULL,
        imageUrl TEXT,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userScore INTEGER DEFAULT 0,
        latitude REAL DEFAULT 0,
        longitude REAL DEFAULT 0,
        distance REAL DEFAULT 0,
        createdAt TEXT,
        isActive INTEGER DEFAULT 1,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Swaps table (transactions)
    await db.execute('''
      CREATE TABLE swaps (
        id TEXT PRIMARY KEY,
        myItemId TEXT NOT NULL,
        myItemName TEXT NOT NULL,
        theirItemId TEXT NOT NULL,
        theirItemName TEXT NOT NULL,
        partnerId TEXT NOT NULL,
        partnerName TEXT NOT NULL,
        status INTEGER DEFAULT 0,
        createdAt TEXT,
        completedAt TEXT,
        rating INTEGER,
        review TEXT
      )
    ''');

    // Swiped items table (to track which items user has seen)
    await db.execute('''
      CREATE TABLE swiped_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        liked INTEGER NOT NULL,
        swipedAt TEXT,
        UNIQUE(userId, itemId)
      )
    ''');

    // Achievements table
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        unlocked INTEGER DEFAULT 0,
        description TEXT,
        unlockedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        senderName TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        receiverName TEXT NOT NULL,
        text TEXT NOT NULL,
        sentAt TEXT,
        isRead INTEGER DEFAULT 0
      )
    ''');

    // Calls table
    await db.execute('''
      CREATE TABLE calls (
        id TEXT PRIMARY KEY,
        partnerId TEXT NOT NULL,
        partnerName TEXT NOT NULL,
        direction INTEGER DEFAULT 0,
        status INTEGER DEFAULT 0,
        startedAt TEXT,
        durationSeconds INTEGER DEFAULT 0
      )
    ''');

    // Insert demo data
    await _insertDemoData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE messages (
          id TEXT PRIMARY KEY,
          conversationId TEXT NOT NULL,
          senderId TEXT NOT NULL,
          senderName TEXT NOT NULL,
          receiverId TEXT NOT NULL,
          receiverName TEXT NOT NULL,
          text TEXT NOT NULL,
          sentAt TEXT,
          isRead INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE calls (
          id TEXT PRIMARY KEY,
          partnerId TEXT NOT NULL,
          partnerName TEXT NOT NULL,
          direction INTEGER DEFAULT 0,
          status INTEGER DEFAULT 0,
          startedAt TEXT,
          durationSeconds INTEGER DEFAULT 0
        )
      ''');

      await _insertDemoMessages(db);
      await _insertDemoCalls(db);
    }
  }

  Future<void> _insertDemoData(Database db) async {
    String img(String path) =>
        'https://images.unsplash.com/$path?auto=format&fit=crop&w=900&q=80';

    // Create demo user
    final demoUser = User(
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
    await db.insert('users', demoUser.toMap());

    // Extra visible users
    final thanos = User(
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

    final nikolas = User(
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

    await db.insert('users', thanos.toMap());
    await db.insert('users', nikolas.toMap());

    // Create demo swap items
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
        id: 'item_7',
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
        id: 'item_8',
        itemName: 'Mechanical Keyboard',
        description: 'Hot-swap, blue switches, RGB',
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
        id: 'item_9',
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
        id: 'item_10',
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
        id: 'item_13',
        itemName: 'Leather Backpack',
        description: 'Χειροποίητο, χωρά laptop 15"',
        category: 'Fashion',
        wantsCategory: 'Electronics',
        imageUrl: img('photo-1521572267360-ee0c2909d518'),
        userId: 'user_thanos',
        userName: 'Θάνος Σταθόπουλος',
        userScore: 210,
        distance: 2.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 9, minutes: 5)),
      ),
      SwapItem(
        id: 'item_14',
        itemName: 'Chemex Coffee Set',
        description: 'Γυάλινη καράφα + φίλτρα, άριστη κατάσταση',
        category: 'Kitchen',
        wantsCategory: 'Books',
        imageUrl: img('photo-1485808191679-5f86510681a2'),
        userId: 'user_nikolas',
        userName: 'Νικόλας Φράγκος',
        userScore: 175,
        distance: 1.3,
        createdAt: DateTime.now().subtract(const Duration(hours: 10, minutes: 20)),
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

    for (final item in demoItems) {
      await db.insert('swap_items', item.toMap());
    }

    // Create demo swaps
    final demoSwaps = [
      Swap(
        id: 'swap_1',
        myItemId: 'my_item_1',
        myItemName: 'Bluetooth Speaker',
        theirItemId: 'their_item_1',
        theirItemName: 'Headphones',
        partnerId: 'user_other_1',
        partnerName: 'Maria K.',
        status: SwapStatus.pending,
        createdAt: DateTime(2025, 10, 19),
      ),
      Swap(
        id: 'swap_2',
        myItemId: 'my_item_2',
        myItemName: 'Book Collection',
        theirItemId: 'their_item_2',
        theirItemName: 'Board Games',
        partnerId: 'user_other_2',
        partnerName: 'Nikos P.',
        status: SwapStatus.confirmed,
        createdAt: DateTime(2025, 10, 18),
      ),
      Swap(
        id: 'swap_3',
        myItemId: 'my_item_3',
        myItemName: 'Vintage Camera',
        theirItemId: 'their_item_3',
        theirItemName: 'Art Supplies',
        partnerId: 'user_other_3',
        partnerName: 'Elena S.',
        status: SwapStatus.completed,
        createdAt: DateTime(2025, 10, 17),
        completedAt: DateTime(2025, 10, 17),
        rating: 5,
      ),
      Swap(
        id: 'swap_4',
        myItemId: 'my_item_4',
        myItemName: 'Running Shoes',
        theirItemId: 'their_item_4',
        theirItemName: 'Yoga Mat',
        partnerId: 'user_other_4',
        partnerName: 'Dimitris A.',
        status: SwapStatus.completed,
        createdAt: DateTime(2025, 10, 14),
        completedAt: DateTime(2025, 10, 14),
        rating: 5,
      ),
      Swap(
        id: 'swap_5',
        myItemId: 'my_item_5',
        myItemName: 'Coffee Maker',
        theirItemId: 'their_item_5',
        theirItemName: 'Blender',
        partnerId: 'user_other_5',
        partnerName: 'Sofia L.',
        status: SwapStatus.completed,
        createdAt: DateTime(2025, 10, 12),
        completedAt: DateTime(2025, 10, 12),
        rating: 4,
      ),
      Swap(
        id: 'swap_6',
        myItemId: 'my_item_6',
        myItemName: 'Camping Stove',
        theirItemId: 'their_item_6',
        theirItemName: 'Hammock',
        partnerId: 'user_other_6',
        partnerName: 'Giannis M.',
        status: SwapStatus.confirmed,
        createdAt: DateTime(2025, 10, 10),
      ),
      Swap(
        id: 'swap_7',
        myItemId: 'my_item_7',
        myItemName: 'Old Vinyl Player',
        theirItemId: 'their_item_7',
        theirItemName: 'Studio Headphones',
        partnerId: 'user_other_7',
        partnerName: 'Anna T.',
        status: SwapStatus.pending,
        createdAt: DateTime(2025, 10, 9),
      ),
      Swap(
        id: 'swap_8',
        myItemId: 'my_item_8',
        myItemName: 'Guitar Pedal',
        theirItemId: 'their_item_8',
        theirItemName: 'Mechanical Keyboard',
        partnerId: 'user_other_8',
        partnerName: 'Petros V.',
        status: SwapStatus.completed,
        createdAt: DateTime(2025, 10, 6),
        completedAt: DateTime(2025, 10, 6),
        rating: 5,
      ),
    ];

    for (final swap in demoSwaps) {
      await db.insert('swaps', swap.toMap());
    }

    // Create achievements for all demo users
    await _insertAchievements(db, 'user_demo');
    await _insertAchievements(db, 'user_thanos');
    await _insertAchievements(db, 'user_nikolas');

    await _insertDemoMessages(db);
    await _insertDemoCalls(db);
  }

  Future<void> _insertAchievements(Database db, String userId) async {
    for (final achievement in Achievement.defaultAchievements()) {
      final unlocked = achievement.id == '1' ||
          achievement.id == '2' ||
          achievement.id == '3';
      await db.insert('achievements', {
        ...achievement.toMap(),
        'userId': userId,
        'unlocked': unlocked ? 1 : 0,
        'unlockedAt': unlocked ? DateTime.now().toIso8601String() : null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _insertDemoMessages(Database db) async {
    final now = DateTime.now();
    final messages = [
      Message(
        conversationId: _conversationId('user_demo', 'user_thanos'),
        senderId: 'user_thanos',
        senderName: 'Θάνος Σταθόπουλος',
        receiverId: 'user_demo',
        receiverName: 'Γρηγόρης Σταματόπουλος',
        text: 'Γεια! Η κάμερα είναι διαθέσιμη;',
        sentAt: now.subtract(const Duration(minutes: 95)),
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_thanos'),
        senderId: 'user_demo',
        senderName: 'Γρηγόρης Σταματόπουλος',
        receiverId: 'user_thanos',
        receiverName: 'Θάνος Σταθόπουλος',
        text: 'Ναι, αλλά θέλω να τη δω από κοντά. Έχει σημάδια στο φακό;',
        sentAt: now.subtract(const Duration(minutes: 78)),
        isRead: true,
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_thanos'),
        senderId: 'user_thanos',
        senderName: 'Θάνος Σταθόπουλος',
        receiverId: 'user_demo',
        receiverName: 'Γρηγόρης Σταματόπουλος',
        text: 'Είναι σε θήκη, ο φακός καθαρός. Σε βολεύει Κηφισιά αύριο 18:15;',
        sentAt: now.subtract(const Duration(minutes: 42)),
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_thanos'),
        senderId: 'user_demo',
        senderName: 'Γρηγόρης Σταματόπουλος',
        receiverId: 'user_thanos',
        receiverName: 'Θάνος Σταθόπουλος',
        text: 'Οκ, φέρνω και τρίποδο να δω σταθερότητα. Τα λέμε εκεί.',
        sentAt: now.subtract(const Duration(minutes: 22)),
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_thanos'),
        senderId: 'user_thanos',
        senderName: 'Θάνος Σταθόπουλος',
        receiverId: 'user_demo',
        receiverName: 'Γρηγόρης Σταματόπουλος',
        text: 'Τέλεια, θα είμαι στην έξοδο στις 18:15.',
        sentAt: now.subtract(const Duration(minutes: 8)),
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_nikolas'),
        senderId: 'user_nikolas',
        senderName: 'Νικόλας Φράγκος',
        receiverId: 'user_demo',
        receiverName: 'Γρηγόρης Σταματόπουλος',
        text: 'Έχεις ακόμη το βιβλίο κιθάρας;',
        sentAt: now.subtract(const Duration(hours: 2, minutes: 5)),
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_nikolas'),
        senderId: 'user_demo',
        senderName: 'Γρηγόρης Σταματόπουλος',
        receiverId: 'user_nikolas',
        receiverName: 'Νικόλας Φράγκος',
        text: 'Ναι! Είναι καθαρό χωρίς σημειώσεις. Είμαι Πειραιά το απόγευμα.',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 50)),
        isRead: true,
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_nikolas'),
        senderId: 'user_nikolas',
        senderName: 'Νικόλας Φράγκος',
        receiverId: 'user_demo',
        receiverName: 'Γρηγόρης Σταματόπουλος',
        text: 'Ωραία, 18:30 στο μετρό Πανεπιστήμιο. Θα σε βρω στην έξοδο.',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 10)),
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_nikolas'),
        senderId: 'user_demo',
        senderName: 'Γρηγόρης Σταματόπουλος',
        receiverId: 'user_nikolas',
        receiverName: 'Νικόλας Φράγκος',
        text: 'Οκ, θα είμαι εκεί στην ώρα μου.',
        sentAt: now.subtract(const Duration(minutes: 50)),
        isRead: true,
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_other_3'),
        senderId: 'user_demo',
        senderName: 'Γρηγόρης Σταματόπουλος',
        receiverId: 'user_other_3',
        receiverName: 'Elena S.',
        text: 'Έχεις ακόμα τα παπούτσια; Μπορώ σήμερα.',
        sentAt: now.subtract(const Duration(minutes: 50)),
        isRead: true,
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_other_3'),
        senderId: 'user_other_3',
        senderName: 'Elena S.',
        receiverId: 'user_demo',
        receiverName: 'Γρηγόρης Σταματόπουλος',
        text: 'Ναι, θα είμαι στο κέντρο στις 19:00.',
        sentAt: now.subtract(const Duration(minutes: 35)),
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_other_4'),
        senderId: 'user_other_4',
        senderName: 'Dimitris A.',
        receiverId: 'user_demo',
        receiverName: 'Γρηγόρης Σταματόπουλος',
        text: 'Σε βολεύει κλήση για λεπτομέρειες;',
        sentAt: now.subtract(const Duration(minutes: 20)),
      ),
      Message(
        conversationId: _conversationId('user_demo', 'user_other_4'),
        senderId: 'user_demo',
        senderName: 'Γρηγόρης Σταματόπουλος',
        receiverId: 'user_other_4',
        receiverName: 'Dimitris A.',
        text: 'Ναι, κάλεσέ με στις 19:15 ή στείλε σημείωμα με specs.',
        sentAt: now.subtract(const Duration(minutes: 12)),
      ),
    ];

    for (final message in messages) {
      await db.insert('messages', message.toMap());
    }
  }

  Future<void> _seedExtraDemoMessagesIfMissing(Database db) async {
    final convoId = _conversationId('user_thanos', 'user_nikolas');
    final existing = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM messages WHERE conversationId = ?',
            [convoId],
          ),
        ) ??
        0;

    if (existing > 0) return;

    final now = DateTime.now();
    final extras = [
      Message(
        conversationId: convoId,
        senderId: 'user_thanos',
        senderName: 'Θάνος Σταθόπουλος',
        receiverId: 'user_nikolas',
        receiverName: 'Νικόλας Φράγκος',
        text: 'Είδα την κιθάρα σου, είναι διαθέσιμη για ανταλλαγή;',
        sentAt: now.subtract(const Duration(hours: 3, minutes: 20)),
      ),
      Message(
        conversationId: convoId,
        senderId: 'user_nikolas',
        senderName: 'Νικόλας Φράγκος',
        receiverId: 'user_thanos',
        receiverName: 'Θάνος Σταθόπουλος',
        text: 'Ναι, ενδιαφέρομαι για φακό 50mm ή action cam.',
        sentAt: now.subtract(const Duration(hours: 3, minutes: 5)),
      ),
      Message(
        conversationId: convoId,
        senderId: 'user_thanos',
        senderName: 'Θάνος Σταθόπουλος',
        receiverId: 'user_nikolas',
        receiverName: 'Νικόλας Φράγκος',
        text: 'Έχω έναν φακό 50mm, σχεδόν καινούργιο. Να τον δεις από κοντά;',
        sentAt: now.subtract(const Duration(hours: 2, minutes: 40)),
      ),
      Message(
        conversationId: convoId,
        senderId: 'user_nikolas',
        senderName: 'Νικόλας Φράγκος',
        receiverId: 'user_thanos',
        receiverName: 'Θάνος Σταθόπουλος',
        text: 'Τέλεια, πάμε για Σάββατο πρωί στο κέντρο;',
        sentAt: now.subtract(const Duration(hours: 2, minutes: 20)),
      ),
    ];

    for (final message in extras) {
      await db.insert('messages', message.toMap());
    }
  }

  Future<void> _insertDemoCalls(Database db) async {
    final calls = [
      CallRecord(
        partnerId: 'user_other_1',
        partnerName: 'Maria K.',
        direction: CallDirection.outgoing,
        status: CallStatus.ended,
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        durationSeconds: 120,
      ),
      CallRecord(
        partnerId: 'user_other_2',
        partnerName: 'Nikos P.',
        direction: CallDirection.incoming,
        status: CallStatus.missed,
        startedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      CallRecord(
        partnerId: 'user_thanos',
        partnerName: 'Θάνος Σταθόπουλος',
        direction: CallDirection.outgoing,
        status: CallStatus.ended,
        startedAt: DateTime.now().subtract(const Duration(hours: 6)),
        durationSeconds: 305,
      ),
      CallRecord(
        partnerId: 'user_nikolas',
        partnerName: 'Νικόλας Φράγκος',
        direction: CallDirection.incoming,
        status: CallStatus.ended,
        startedAt: DateTime.now().subtract(const Duration(hours: 9)),
        durationSeconds: 210,
      ),
    ];

    for (final call in calls) {
      await db.insert('calls', call.toMap());
    }
  }

  // User methods
  Future<User?> getUser(String id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // Swap items methods
  Future<List<SwapItem>> getAvailableItems(String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT * FROM swap_items 
      WHERE userId != ? 
      AND isActive = 1
      AND id NOT IN (
        SELECT itemId FROM swiped_items WHERE userId = ?
      )
      ORDER BY createdAt DESC
    ''', [userId, userId]);
    return result.map((map) => SwapItem.fromMap(map)).toList();
  }

  Future<List<SwapItem>> getUserItems(String userId) async {
    final db = await database;
    final result = await db.query(
      'swap_items',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => SwapItem.fromMap(map)).toList();
  }

  Future<void> insertItem(SwapItem item) async {
    final db = await database;
    await db.insert('swap_items', item.toMap());
  }

  Future<void> recordSwipe(String userId, String itemId, bool liked) async {
    final db = await database;
    await db.insert('swiped_items', {
      'userId': userId,
      'itemId': itemId,
      'liked': liked ? 1 : 0,
      'swipedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Swaps methods
  Future<List<Swap>> getActiveSwaps(String userId) async {
    final db = await database;
    final result = await db.query(
      'swaps',
      where: 'status IN (0, 1)',
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Swap.fromMap(map)).toList();
  }

  Future<List<Swap>> getCompletedSwaps(String userId) async {
    final db = await database;
    final result = await db.query(
      'swaps',
      where: 'status = 2',
      orderBy: 'completedAt DESC',
    );
    return result.map((map) => Swap.fromMap(map)).toList();
  }

  Future<void> insertSwap(Swap swap) async {
    final db = await database;
    await db.insert('swaps', swap.toMap());
  }

  Future<void> updateSwapStatus(String swapId, SwapStatus status) async {
    final db = await database;
    await db.update(
      'swaps',
      {
        'status': status.index,
        if (status == SwapStatus.completed) 
          'completedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [swapId],
    );
  }

  // Achievements methods
  Future<List<Achievement>> getUserAchievements(String userId) async {
    final db = await database;
    final result = await db.query(
      'achievements',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return result.map((map) => Achievement.fromMap(map)).toList();
  }

  /// Ensure a user has the default achievements seeded.
  /// For demo users we overwrite to keep them consistent across accounts.
  Future<void> ensureAchievementsForUser(String userId) async {
    final db = await database;
    const demoIds = {'user_demo', 'user_thanos', 'user_nikolas'};

    if (demoIds.contains(userId)) {
      await db.delete('achievements', where: 'userId = ?', whereArgs: [userId]);
      await _insertAchievements(db, userId);
      return;
    }

    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM achievements WHERE userId = ?',
            [userId],
          ),
        ) ??
        0;

    if (count == 0) {
      await _insertAchievements(db, userId);
    }
  }

  // Messaging methods
  Future<void> insertMessage(Message message) async {
    final db = await database;
    await db.insert('messages', message.toMap());
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'sentAt ASC',
    );
    return result.map((m) => Message.fromMap(m)).toList();
  }

  Future<List<Message>> getAllMessagesForUser(String userId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'senderId = ? OR receiverId = ?',
      whereArgs: [userId, userId],
      orderBy: 'sentAt DESC',
    );
    return result.map((m) => Message.fromMap(m)).toList();
  }

  Future<void> markConversationRead(String conversationId, String userId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'conversationId = ? AND receiverId = ?',
      whereArgs: [conversationId, userId],
    );
  }

  // Calls methods
  Future<void> insertCall(CallRecord call) async {
    final db = await database;
    await db.insert('calls', call.toMap());
  }

  Future<List<CallRecord>> getRecentCalls(String userId) async {
    final db = await database;
    final result = await db.query(
      'calls',
      orderBy: 'startedAt DESC',
      limit: 20,
    );
    return result.map((m) => CallRecord.fromMap(m)).toList();
  }

  String _conversationId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }
}
