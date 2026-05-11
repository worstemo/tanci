import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../services/word_provider.dart';
import '../services/settings_provider.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  Word? _currentWord;
  List<String> _options = [];
  int? _selectedOption;
  bool _showResult = false;
  bool _isCorrect = false;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNextWord();
  }

  void _loadNextWord() {
    final provider = context.read<WordProvider>();
    final word = provider.getRandomUnfamiliarWord();

    if (word == null) {
      setState(() {
        _currentWord = null;
      });
      return;
    }

    // 生成选项
    final options = _generateOptions(word, provider.words);

    setState(() {
      _currentWord = word;
      _options = options;
      _selectedOption = null;
      _showResult = false;
      _isCorrect = false;
    });
  }

  List<String> _generateOptions(Word correctWord, List<Word> allWords) {
    final random = Random();
    final options = <String>[correctWord.meaning];

    // 获取其他单词的意思作为干扰项
    final otherMeanings = allWords
        .where((w) => w.id != correctWord.id)
        .map((w) => w.meaning)
        .toList();

    otherMeanings.shuffle(random);

    // 添加3个干扰项
    for (int i = 0; i < 3 && i < otherMeanings.length; i++) {
      options.add(otherMeanings[i]);
    }

    // 如果干扰项不够，添加默认选项
    while (options.length < 4) {
      options.add('其他意思 ${options.length}');
    }

    options.shuffle(random);
    return options;
  }

  void _selectOption(int index) {
    if (_showResult) return;

    final isCorrect = _options[index] == _currentWord!.meaning;

    setState(() {
      _selectedOption = index;
      _showResult = true;
      _isCorrect = isCorrect;
      _totalCount++;
      if (isCorrect) _correctCount++;
    });

    // 记录结果
    context.read<WordProvider>().recordReview(_currentWord!.id!, isCorrect);
  }

  void _nextWord() {
    setState(() {
      _currentIndex++;
    });
    _loadNextWord();
  }

  void _resetStudy() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _totalCount = 0;
    });
    _loadNextWord();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习'),
        actions: [
          if (_totalCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_correctCount/$_totalCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Consumer<WordProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_currentWord == null) {
            return _buildEmptyState();
          }

          return _buildStudyCard(provider);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration, size: 80, color: Colors.amber[300]),
          const SizedBox(height: 24),
          const Text(
            '太棒了！',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '所有单词都已掌握',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<WordProvider>().loadUnfamiliarWords();
              _resetStudy();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重新开始'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyCard(WordProvider provider) {
    final settingsProvider = context.read<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 进度指示
          LinearProgressIndicator(
            value: provider.unfamiliarWords.isEmpty
                ? 0
                : (_currentIndex + 1) / provider.unfamiliarWords.length.clamp(1, 100),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 32),

          // 单词卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _currentWord!.word,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentWord!.phonetic != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _currentWord!.phonetic!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 记忆技巧（可选显示）
          if (settingsProvider.showMemoryTip &&
              _currentWord!.memoryTip != null &&
              _currentWord!.memoryTip!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentWord!.memoryTip!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // 选项
          ...List.generate(4, (index) {
            final isSelected = _selectedOption == index;
            final isCorrectOption = _options[index] == _currentWord!.meaning;

            Color backgroundColor = Theme.of(context).colorScheme.surface;
            Color borderColor = Colors.grey[300]!;
            Color textColor = Colors.black87;

            if (_showResult) {
              if (isCorrectOption) {
                backgroundColor = Colors.green.withOpacity(0.1);
                borderColor = Colors.green;
                textColor = Colors.green;
              } else if (isSelected && !isCorrectOption) {
                backgroundColor = Colors.red.withOpacity(0.1);
                borderColor = Colors.red;
                textColor = Colors.red;
              }
            } else if (isSelected) {
              backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
              borderColor = Theme.of(context).colorScheme.primary;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _selectOption(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _options[index],
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (_showResult && isCorrectOption)
                        const Icon(Icons.check_circle, color: Colors.green),
                      if (_showResult && isSelected && !isCorrectOption)
                        const Icon(Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // 结果和下一步按钮
          if (_showResult) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.cancel,
                    color: _isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isCorrect ? '回答正确！' : '答错了，正确答案是：${_currentWord!.meaning}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextWord,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '下一个',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
