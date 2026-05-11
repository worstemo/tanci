import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../models/word_book.dart';
import 'database_service.dart';

/// 单词状态管理
class WordProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Word> _words = [];
  List<Word> _unfamiliarWords = [];
  List<WordBook> _books = [];
  DailyStats? _todayStats;
  bool _isLoading = false;

  // Getters
  List<Word> get words => _words;
  List<Word> get unfamiliarWords => _unfamiliarWords;
  List<WordBook> get books => _books;
  DailyStats? get todayStats => _todayStats;
  bool get isLoading => _isLoading;

  /// 加载所有数据
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadWords(),
        loadUnfamiliarWords(),
        loadBooks(),
        loadTodayStats(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载所有单词
  Future<void> loadWords() async {
    _words = await _db.getAllWords();
    notifyListeners();
  }

  /// 加载不熟悉的单词
  Future<void> loadUnfamiliarWords() async {
    _unfamiliarWords = await _db.getUnfamiliarWords();
    notifyListeners();
  }

  /// 加载词书
  Future<void> loadBooks() async {
    _books = await _db.getAllBooks();
    notifyListeners();
  }

  /// 加载今日统计
  Future<void> loadTodayStats() async {
    _todayStats = await _db.getTodayStats();
    notifyListeners();
  }

  /// 搜索单词
  Future<List<Word>> searchWords(String query) async {
    if (query.isEmpty) return _words;
    return await _db.searchWords(query);
  }

  /// 添加单词
  Future<void> addWord(Word word) async {
    await _db.insertWord(word);
    await loadWords();
    await loadUnfamiliarWords();
  }

  /// 批量添加单词
  Future<void> addWords(List<Word> words) async {
    await _db.insertWords(words);
    await loadWords();
    await loadUnfamiliarWords();
  }

  /// 更新单词
  Future<void> updateWord(Word word) async {
    await _db.updateWord(word);
    await loadWords();
    await loadUnfamiliarWords();
  }

  /// 记录复习结果
  Future<void> recordReview(int wordId, bool isCorrect) async {
    await _db.recordReview(wordId, isCorrect);
    await loadWords();
    await loadUnfamiliarWords();
    await loadTodayStats();
  }

  /// 删除单词
  Future<void> deleteWord(int id) async {
    await _db.deleteWord(id);
    await loadWords();
    await loadUnfamiliarWords();
  }

  /// 添加词书
  Future<void> addBook(WordBook book) async {
    await _db.insertBook(book);
    await loadBooks();
  }

  /// 删除词书
  Future<void> deleteBook(int id) async {
    await _db.deleteBook(id);
    await loadBooks();
    await loadWords();
  }

  /// 获取随机不熟悉单词（用于弹窗）
  Word? getRandomUnfamiliarWord() {
    if (_unfamiliarWords.isEmpty) return null;
    _unfamiliarWords.shuffle();
    return _unfamiliarWords.first;
  }

  /// 获取统计信息
  Future<Map<String, int>> getStats() async {
    final total = await _db.getTotalWordCount();
    final mastered = await _db.getMasteredWordCount();
    return {
      'total': total,
      'mastered': mastered,
      'learning': total - mastered,
    };
  }
}
