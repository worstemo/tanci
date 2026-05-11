/// 单词模型
class Word {
  final int? id;
  final String word;
  final String meaning;
  final String? phonetic; // 音标
  final int familiarity; // 熟悉度 0-5
  final int checkCount; // ✓ 次数
  final int crossCount; // X 次数
  final String? memoryTip; // 记忆技巧/梗
  final int? bookId; // 所属词书ID
  final DateTime createdAt;
  final DateTime? lastReviewAt;

  Word({
    this.id,
    required this.word,
    required this.meaning,
    this.phonetic,
    this.familiarity = 0,
    this.checkCount = 0,
    this.crossCount = 0,
    this.memoryTip,
    this.bookId,
    DateTime? createdAt,
    this.lastReviewAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 是否熟悉（熟悉度>=3）
  bool get isFamiliar => familiarity >= 3;

  /// 总复习次数
  int get totalReview => checkCount + crossCount;

  /// 正确率
  double get accuracy => totalReview == 0 ? 0 : checkCount / totalReview;

  /// 从Map创建
  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      word: map['word'] as String,
      meaning: map['meaning'] as String,
      phonetic: map['phonetic'] as String?,
      familiarity: map['familiarity'] as int? ?? 0,
      checkCount: map['check_count'] as int? ?? 0,
      crossCount: map['cross_count'] as int? ?? 0,
      memoryTip: map['memory_tip'] as String?,
      bookId: map['book_id'] as int?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      lastReviewAt: map['last_review_at'] != null 
          ? DateTime.parse(map['last_review_at']) 
          : null,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'phonetic': phonetic,
      'familiarity': familiarity,
      'check_count': checkCount,
      'cross_count': crossCount,
      'memory_tip': memoryTip,
      'book_id': bookId,
      'created_at': createdAt.toIso8601String(),
      'last_review_at': lastReviewAt?.toIso8601String(),
    };
  }

  /// 复制并修改
  Word copyWith({
    int? id,
    String? word,
    String? meaning,
    String? phonetic,
    int? familiarity,
    int? checkCount,
    int? crossCount,
    String? memoryTip,
    int? bookId,
    DateTime? createdAt,
    DateTime? lastReviewAt,
  }) {
    return Word(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      phonetic: phonetic ?? this.phonetic,
      familiarity: familiarity ?? this.familiarity,
      checkCount: checkCount ?? this.checkCount,
      crossCount: crossCount ?? this.crossCount,
      memoryTip: memoryTip ?? this.memoryTip,
      bookId: bookId ?? this.bookId,
      createdAt: createdAt ?? this.createdAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
    );
  }

  @override
  String toString() {
    return 'Word(id: $id, word: $word, meaning: $meaning, familiarity: $familiarity)';
  }
}
