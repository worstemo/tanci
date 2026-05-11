/// 词书模型
class WordBook {
  final int? id;
  final String name;
  final String? description;
  final int wordCount;
  final int learnedCount;
  final DateTime createdAt;

  WordBook({
    this.id,
    required this.name,
    this.description,
    this.wordCount = 0,
    this.learnedCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 学习进度
  double get progress => wordCount == 0 ? 0 : learnedCount / wordCount;

  factory WordBook.fromMap(Map<String, dynamic> map) {
    return WordBook(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      wordCount: map['word_count'] as int? ?? 0,
      learnedCount: map['learned_count'] as int? ?? 0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'word_count': wordCount,
      'learned_count': learnedCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WordBook copyWith({
    int? id,
    String? name,
    String? description,
    int? wordCount,
    int? learnedCount,
    DateTime? createdAt,
  }) {
    return WordBook(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      wordCount: wordCount ?? this.wordCount,
      learnedCount: learnedCount ?? this.learnedCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 学习记录模型
class StudyRecord {
  final int? id;
  final int wordId;
  final String word;
  final bool isCorrect;
  final DateTime reviewedAt;

  StudyRecord({
    this.id,
    required this.wordId,
    required this.word,
    required this.isCorrect,
    DateTime? reviewedAt,
  }) : reviewedAt = reviewedAt ?? DateTime.now();

  factory StudyRecord.fromMap(Map<String, dynamic> map) {
    return StudyRecord(
      id: map['id'] as int?,
      wordId: map['word_id'] as int,
      word: map['word'] as String,
      isCorrect: map['is_correct'] == 1,
      reviewedAt: map['reviewed_at'] != null 
          ? DateTime.parse(map['reviewed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word_id': wordId,
      'word': word,
      'is_correct': isCorrect ? 1 : 0,
      'reviewed_at': reviewedAt.toIso8601String(),
    };
  }
}

/// 每日统计
class DailyStats {
  final DateTime date;
  final int totalWords;
  final int correctCount;
  final int wrongCount;
  final int newWords;

  DailyStats({
    required this.date,
    this.totalWords = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.newWords = 0,
  });

  double get accuracy => 
      (correctCount + wrongCount) == 0 ? 0 : correctCount / (correctCount + wrongCount);

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      date: DateTime.parse(map['date'] as String),
      totalWords: map['total_words'] as int? ?? 0,
      correctCount: map['correct_count'] as int? ?? 0,
      wrongCount: map['wrong_count'] as int? ?? 0,
      newWords: map['new_words'] as int? ?? 0,
    );
  }
}
