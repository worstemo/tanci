import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';
import '../models/word_book.dart';

/// 数据库服务
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'word_master.db';
  static const int _dbVersion = 1;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    // 词书表
    await db.execute('''
      CREATE TABLE word_books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        word_count INTEGER DEFAULT 0,
        learned_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 单词表
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        meaning TEXT NOT NULL,
        phonetic TEXT,
        familiarity INTEGER DEFAULT 0,
        check_count INTEGER DEFAULT 0,
        cross_count INTEGER DEFAULT 0,
        memory_tip TEXT,
        book_id INTEGER,
        created_at TEXT NOT NULL,
        last_review_at TEXT,
        FOREIGN KEY (book_id) REFERENCES word_books (id)
      )
    ''');

    // 学习记录表
    await db.execute('''
      CREATE TABLE study_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        reviewed_at TEXT NOT NULL,
        FOREIGN KEY (word_id) REFERENCES words (id)
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_words_familiarity ON words(familiarity)');
    await db.execute('CREATE INDEX idx_words_book_id ON words(book_id)');
    await db.execute('CREATE INDEX idx_study_records_reviewed_at ON study_records(reviewed_at)');

    // 插入默认词书
    await _insertDefaultData(db);
  }

  /// 插入默认数据
  Future<void> _insertDefaultData(Database db) async {
    // 默认词书
    final defaultBookId = await db.insert('word_books', {
      'name': '默认词库',
      'description': '我的单词本',
      'created_at': DateTime.now().toIso8601String(),
    });

    // 示例单词（带记忆梗）
    final sampleWords = [
      {
        'word': 'cotton',
        'meaning': 'n. 棉花',
        'phonetic': '/ˈkɒtn/',
        'memory_tip': '💡 cotton(棉花) → 想到采棉花的场景，印象深刻',
        'book_id': defaultBookId,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'word': 'abandon',
        'meaning': 'v. 放弃，抛弃',
        'phonetic': '/əˈbændən/',
        'memory_tip': '💡 a+band+on → 一个乐队在台上演出，观众都走了，被抛弃了',
        'book_id': defaultBookId,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'word': 'banana',
        'meaning': 'n. 香蕉',
        'phonetic': '/bəˈnɑːnə/',
        'memory_tip': '💡 ba-na-na → 爸拿那根香蕉',
        'book_id': defaultBookId,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'word': 'elephant',
        'meaning': 'n. 大象',
        'phonetic': '/ˈelɪfənt/',
        'memory_tip': '💡 ele-phant → 一来就胖的大象',
        'book_id': defaultBookId,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'word': 'ambition',
        'meaning': 'n. 雄心，野心',
        'phonetic': '/æmˈbɪʃn/',
        'memory_tip': '💡 我必胜 → ambition谐音"俺必胜"，有雄心壮志',
        'book_id': defaultBookId,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'word': 'economy',
        'meaning': 'n. 经济',
        'phonetic': '/ɪˈkɒnəmi/',
        'memory_tip': '💡 依靠农民 → economy谐音，经济发展依靠农民',
        'book_id': defaultBookId,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'word': 'memory',
        'meaning': 'n. 记忆，记忆力',
        'phonetic': '/ˈmeməri/',
        'memory_tip': '💡 me-mo-ry → 我摸热 → 我摸着热的东西，记忆犹新',
        'book_id': defaultBookId,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'word': 'delicious',
        'meaning': 'adj. 美味的',
        'phonetic': '/dɪˈlɪʃəs/',
        'memory_tip': '💡 得力蛇丝 → 得力的蛇肉丝，味道真美味',
        'book_id': defaultBookId,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final word in sampleWords) {
      await db.insert('words', word);
    }

    // 更新词书单词数量
    await db.update(
      'word_books',
      {'word_count': sampleWords.length},
      where: 'id = ?',
      whereArgs: [defaultBookId],
    );
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 后续版本升级逻辑
  }

  // ==================== 单词操作 ====================

  /// 获取所有单词
  Future<List<Word>> getAllWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  /// 根据ID获取单词
  Future<Word?> getWordById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Word.fromMap(maps.first);
  }

  /// 获取不熟悉的单词（用于弹窗复习）
  Future<List<Word>> getUnfamiliarWords({int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'familiarity < ?',
      whereArgs: [3],
      orderBy: 'familiarity ASC, cross_count DESC',
      limit: limit,
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  /// 搜索单词
  Future<List<Word>> searchWords(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'word LIKE ? OR meaning LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  /// 添加单词
  Future<int> insertWord(Word word) async {
    final db = await database;
    final id = await db.insert('words', word.toMap());
    
    // 更新词书单词数量
    if (word.bookId != null) {
      await db.rawUpdate('''
        UPDATE word_books SET word_count = word_count + 1 
        WHERE id = ?
      ''', [word.bookId]);
    }
    
    return id;
  }

  /// 批量添加单词
  Future<void> insertWords(List<Word> words) async {
    final db = await database;
    final batch = db.batch();
    
    for (final word in words) {
      batch.insert('words', word.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  /// 更新单词
  Future<int> updateWord(Word word) async {
    final db = await database;
    return await db.update(
      'words',
      word.toMap(),
      where: 'id = ?',
      whereArgs: [word.id],
    );
  }

  /// 记录复习结果
  Future<void> recordReview(int wordId, bool isCorrect) async {
    final db = await database;
    
    // 获取当前单词
    final word = await getWordById(wordId);
    if (word == null) return;

    // 更新单词统计
    final newFamiliarity = isCorrect 
        ? (word.familiarity < 5 ? word.familiarity + 1 : 5)
        : (word.familiarity > 0 ? word.familiarity - 1 : 0);

    await db.update(
      'words',
      {
        'familiarity': newFamiliarity,
        'check_count': isCorrect ? word.checkCount + 1 : word.checkCount,
        'cross_count': isCorrect ? word.crossCount : word.crossCount + 1,
        'last_review_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [wordId],
    );

    // 记录学习历史
    await db.insert('study_records', {
      'word_id': wordId,
      'word': word.word,
      'is_correct': isCorrect ? 1 : 0,
      'reviewed_at': DateTime.now().toIso8601String(),
    });
  }

  /// 删除单词
  Future<int> deleteWord(int id) async {
    final db = await database;
    
    // 获取单词信息
    final word = await getWordById(id);
    
    // 删除单词
    final result = await db.delete(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // 更新词书单词数量
    if (word?.bookId != null) {
      await db.rawUpdate('''
        UPDATE word_books SET word_count = word_count - 1 
        WHERE id = ?
      ''', [word!.bookId]);
    }
    
    return result;
  }

  // ==================== 词书操作 ====================

  /// 获取所有词书
  Future<List<WordBook>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'word_books',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => WordBook.fromMap(map)).toList();
  }

  /// 添加词书
  Future<int> insertBook(WordBook book) async {
    final db = await database;
    return await db.insert('word_books', book.toMap());
  }

  /// 删除词书（同时删除其中的单词）
  Future<int> deleteBook(int id) async {
    final db = await database;
    
    // 删除词书中的所有单词
    await db.delete('words', where: 'book_id = ?', whereArgs: [id]);
    
    // 删除词书
    return await db.delete('word_books', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== 统计操作 ====================

  /// 获取今日统计
  Future<DailyStats> getTodayStats() async {
    final db = await database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final records = await db.query(
      'study_records',
      where: 'reviewed_at LIKE ?',
      whereArgs: ['$todayStr%'],
    );

    int correctCount = 0;
    int wrongCount = 0;

    for (final record in records) {
      if (record['is_correct'] == 1) {
        correctCount++;
      } else {
        wrongCount++;
      }
    }

    return DailyStats(
      date: today,
      totalWords: records.length,
      correctCount: correctCount,
      wrongCount: wrongCount,
    );
  }

  /// 获取总单词数
  Future<int> getTotalWordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取已掌握单词数
  Future<int> getMasteredWordCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM words WHERE familiarity >= 3',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取最近7天学习记录
  Future<List<DailyStats>> getWeeklyStats() async {
    final db = await database;
    final List<DailyStats> stats = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final records = await db.query(
        'study_records',
        where: 'reviewed_at LIKE ?',
        whereArgs: ['$dateStr%'],
      );

      int correctCount = 0;
      int wrongCount = 0;

      for (final record in records) {
        if (record['is_correct'] == 1) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }

      stats.add(DailyStats(
        date: date,
        correctCount: correctCount,
        wrongCount: wrongCount,
      ));
    }

    return stats;
  }
}
