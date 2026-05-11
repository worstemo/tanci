import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../services/word_provider.dart';
import '../widgets/word_card.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'time'; // time, familiarity, word
  bool _showFamiliar = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('词库'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'time', child: Text('按添加时间')),
              const PopupMenuItem(value: 'familiarity', child: Text('按熟悉度')),
              const PopupMenuItem(value: 'word', child: Text('按字母顺序')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索单词或意思...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // 筛选选项
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: _showFamiliar,
                  onSelected: (selected) {
                    setState(() {
                      _showFamiliar = selected;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('不熟悉'),
                  selected: !_showFamiliar,
                  onSelected: (selected) {
                    setState(() {
                      _showFamiliar = !selected;
                    });
                  },
                ),
                const Spacer(),
                Consumer<WordProvider>(
                  builder: (context, provider, _) {
                    return Text(
                      '共 ${provider.words.length} 词',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    );
                  },
                ),
              ],
            ),
          ),

          // 单词列表
          Expanded(
            child: Consumer<WordProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Word> displayWords = _searchQuery.isEmpty
                    ? provider.words
                    : provider.words.where((w) =>
                        w.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        w.meaning.contains(_searchQuery)).toList();

                // 筛选
                if (!_showFamiliar) {
                  displayWords = displayWords.where((w) => !w.isFamiliar).toList();
                }

                // 排序
                switch (_sortBy) {
                  case 'familiarity':
                    displayWords.sort((a, b) => a.familiarity.compareTo(b.familiarity));
                    break;
                  case 'word':
                    displayWords.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
                    break;
                  default:
                    // 默认按时间排序（已在数据库查询中处理）
                    break;
                }

                if (displayWords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? '暂无单词' : '未找到匹配的单词',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayWords.length,
                  itemBuilder: (context, index) {
                    final word = displayWords[index];
                    return Dismissible(
                      key: Key(word.id.toString()),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除单词 "${word.word}" 吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('删除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        provider.deleteWord(word.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已删除 ${word.word}')),
                        );
                      },
                      child: WordCard(
                        word: word,
                        onTap: () => _showWordDetail(context, word, provider),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWordDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddWordDialog(BuildContext context) {
    final wordController = TextEditingController();
    final meaningController = TextEditingController();
    final tipController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加单词'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordController,
                decoration: const InputDecoration(
                  labelText: '单词 *',
                  hintText: '输入英文单词',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: meaningController,
                decoration: const InputDecoration(
                  labelText: '意思 *',
                  hintText: '输入中文意思',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tipController,
                decoration: const InputDecoration(
                  labelText: '记忆技巧（可选）',
                  hintText: '例如：cotton → 棉花 → 采棉花场景',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (wordController.text.isEmpty || meaningController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写必填项')),
                );
                return;
              }

              final word = Word(
                word: wordController.text.trim(),
                meaning: meaningController.text.trim(),
                memoryTip: tipController.text.trim().isNotEmpty
                    ? tipController.text.trim()
                    : null,
              );

              await context.read<WordProvider>().addWord(word);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('添加成功')),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showWordDetail(BuildContext context, Word word, WordProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        word.word,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditWordDialog(context, word, provider);
                      },
                    ),
                  ],
                ),
                if (word.phonetic != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    word.phonetic!,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    word.meaning,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                if (word.memoryTip != null && word.memoryTip!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '记忆技巧',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(word.memoryTip!),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  '学习记录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('熟悉度', '${word.familiarity}/5', Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard('✓ 正确', '${word.checkCount}', Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard('X 错误', '${word.crossCount}', Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: word.accuracy,
                  backgroundColor: Colors.grey[200],
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  '正确率: ${(word.accuracy * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditWordDialog(BuildContext context, Word word, WordProvider provider) {
    final wordController = TextEditingController(text: word.word);
    final meaningController = TextEditingController(text: word.meaning);
    final tipController = TextEditingController(text: word.memoryTip);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑单词'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordController,
                decoration: const InputDecoration(
                  labelText: '单词',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: meaningController,
                decoration: const InputDecoration(
                  labelText: '意思',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tipController,
                decoration: const InputDecoration(
                  labelText: '记忆技巧',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedWord = word.copyWith(
                word: wordController.text.trim(),
                meaning: meaningController.text.trim(),
                memoryTip: tipController.text.trim().isNotEmpty
                    ? tipController.text.trim()
                    : null,
              );

              await provider.updateWord(updatedWord);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('更新成功')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
