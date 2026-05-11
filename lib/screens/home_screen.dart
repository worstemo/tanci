import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../services/word_provider.dart';
import '../services/settings_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/word_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('弹词'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 显示通知设置
            },
          ),
        ],
      ),
      body: Consumer2<WordProvider, SettingsProvider>(
        builder: (context, wordProvider, settingsProvider, child) {
          if (wordProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => wordProvider.loadAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 今日学习统计
                  _buildTodayStats(context, wordProvider, settingsProvider),
                  const SizedBox(height: 20),

                  // 快速操作
                  _buildQuickActions(context, wordProvider, settingsProvider),
                  const SizedBox(height: 20),

                  // 待复习单词
                  _buildUnfamiliarWords(context, wordProvider),
                  const SizedBox(height: 20),

                  // 学习建议
                  _buildStudyTips(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 今日学习统计
  Widget _buildTodayStats(
    BuildContext context,
    WordProvider wordProvider,
    SettingsProvider settingsProvider,
  ) {
    final stats = wordProvider.todayStats;
    final progress = settingsProvider.dailyGoal > 0
        ? (stats?.totalWords ?? 0) / settingsProvider.dailyGoal
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日学习',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '目标: ${settingsProvider.dailyGoal}词',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '已复习',
                  '${stats?.totalWords ?? 0}',
                  Icons.refresh,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  '正确',
                  '${stats?.correctCount ?? 0}',
                  Icons.check_circle,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  '错误',
                  '${stats?.wrongCount ?? 0}',
                  Icons.cancel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 进度条
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '今日进度',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 快速操作
  Widget _buildQuickActions(
    BuildContext context,
    WordProvider wordProvider,
    SettingsProvider settingsProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速操作',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.school,
                title: '开始学习',
                subtitle: '${wordProvider.unfamiliarWords.length}个待复习',
                color: Colors.blue,
                onTap: () {
                  // 跳转到学习页 - 使用Navigator
                  Navigator.of(context).pushNamed('/study');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.camera_alt,
                title: '图片导入',
                subtitle: 'OCR识别单词',
                color: Colors.green,
                onTap: () {
                  _showImportDialog(context);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: settingsProvider.popupEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                title: '弹窗复习',
                subtitle: settingsProvider.popupEnabled ? '已开启' : '已关闭',
                color: settingsProvider.popupEnabled ? Colors.orange : Colors.grey,
                onTap: () {
                  _showPopupSettings(context, settingsProvider);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.add_circle,
                title: '添加单词',
                subtitle: '手动录入',
                color: Colors.purple,
                onTap: () {
                  _showAddWordDialog(context, wordProvider);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 待复习单词
  Widget _buildUnfamiliarWords(BuildContext context, WordProvider wordProvider) {
    final words = wordProvider.unfamiliarWords.take(5).toList();

    if (words.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.celebration, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                '太棒了！没有待复习的单词',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '待复习单词',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/words');
              },
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...words.map((word) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: WordCard(
            word: word,
            onTap: () => _showWordDetail(context, word),
          ),
        )),
      ],
    );
  }

  /// 学习建议
  Widget _buildStudyTips(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  '学习小贴士',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• 开启弹窗复习，利用碎片时间巩固记忆\n'
              '• 每天复习不熟悉的单词，加深印象\n'
              '• 使用记忆梗帮助联想，效果更佳\n'
              '• 坚持打卡，养成学习习惯',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示弹窗设置
  void _showPopupSettings(BuildContext context, SettingsProvider settingsProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '弹窗复习设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('开启弹窗复习'),
              subtitle: const Text('玩手机时随机弹出不熟单词'),
              value: settingsProvider.popupEnabled,
              onChanged: (value) {
                settingsProvider.setPopupEnabled(value);
              },
            ),
            ListTile(
              title: const Text('弹窗间隔'),
              trailing: DropdownButton<int>(
                value: settingsProvider.popupInterval,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5分钟')),
                  DropdownMenuItem(value: 15, child: Text('15分钟')),
                  DropdownMenuItem(value: 30, child: Text('30分钟')),
                  DropdownMenuItem(value: 60, child: Text('1小时')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setPopupInterval(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('免打扰时段'),
              subtitle: Text(
                '${settingsProvider.quietHoursStart} - ${settingsProvider.quietHoursEnd}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 设置免打扰时段
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示添加单词对话框
  void _showAddWordDialog(BuildContext context, WordProvider wordProvider) {
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
                  labelText: '单词',
                  hintText: '输入英文单词',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: meaningController,
                decoration: const InputDecoration(
                  labelText: '意思',
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
                  hintText: '输入记忆梗或技巧',
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
                  const SnackBar(content: Text('请填写单词和意思')),
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

              await wordProvider.addWord(word);
              
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

  /// 显示导入对话框
  void _showImportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '导入单词',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('拍照识别'),
              subtitle: const Text('拍摄单词卡片'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现拍照识别
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('拍照识别功能开发中...')),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo, color: Colors.green),
              ),
              title: const Text('从相册选择'),
              subtitle: const Text('选择已有图片'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现相册选择
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('相册选择功能开发中...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示单词详情
  void _showWordDetail(BuildContext context, Word word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
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
                Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (word.phonetic != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    word.phonetic!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
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
                if (word.memoryTip != null) ...[
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip('熟悉度', '${word.familiarity}/5'),
                    const SizedBox(width: 8),
                    _buildInfoChip('✓', '${word.checkCount}'),
                    const SizedBox(width: 8),
                    _buildInfoChip('X', '${word.crossCount}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}
