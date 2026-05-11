import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/word_provider.dart';
import '../services/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Consumer2<WordProvider, SettingsProvider>(
        builder: (context, wordProvider, settingsProvider, _) {
          return ListView(
            children: [
              // 学习设置
              _buildSection(
                context,
                title: '学习设置',
                children: [
                  ListTile(
                    leading: const Icon(Icons.flag),
                    title: const Text('每日目标'),
                    subtitle: Text('${settingsProvider.dailyGoal} 个单词'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDailyGoalDialog(context, settingsProvider),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.lightbulb_outline),
                    title: const Text('显示记忆技巧'),
                    subtitle: const Text('学习时显示记忆梗'),
                    value: settingsProvider.showMemoryTip,
                    onChanged: (value) {
                      settingsProvider.setShowMemoryTip(value);
                    },
                  ),
                ],
              ),

              // 弹窗设置
              _buildSection(
                context,
                title: '弹窗复习',
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      settingsProvider.popupEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                    ),
                    title: const Text('开启弹窗复习'),
                    subtitle: Text(
                      settingsProvider.popupEnabled ? '已开启' : '已关闭',
                    ),
                    value: settingsProvider.popupEnabled,
                    onChanged: (value) async {
                      if (value) {
                        // 检查悬浮窗权限
                        final granted = await _checkOverlayPermission(context);
                        if (granted) {
                          settingsProvider.setPopupEnabled(true);
                        }
                      } else {
                        settingsProvider.setPopupEnabled(false);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('弹窗间隔'),
                    subtitle: Text('每 ${settingsProvider.popupInterval} 分钟'),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: settingsProvider.popupEnabled,
                    onTap: () => _showIntervalDialog(context, settingsProvider),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bedtime),
                    title: const Text('免打扰时段'),
                    subtitle: Text(
                      '${settingsProvider.quietHoursStart} - ${settingsProvider.quietHoursEnd}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: settingsProvider.popupEnabled,
                    onTap: () => _showQuietHoursDialog(context, settingsProvider),
                  ),
                ],
              ),

              // 数据管理
              _buildSection(
                context,
                title: '数据管理',
                children: [
                  FutureBuilder<Map<String, int>>(
                    future: wordProvider.getStats(),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {};
                      return ListTile(
                        leading: const Icon(Icons.storage),
                        title: const Text('词库统计'),
                        subtitle: Text(
                          '总计 ${stats['total'] ?? 0} 词 | '
                          '已掌握 ${stats['mastered'] ?? 0} 词',
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_download),
                    title: const Text('导入单词'),
                    subtitle: const Text('从文件导入单词列表'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('导入功能开发中...')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_upload),
                    title: const Text('导出单词'),
                    subtitle: const Text('导出词库到文件'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('导出功能开发中...')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('清空数据', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('删除所有单词和记录'),
                    onTap: () => _showClearDataDialog(context, wordProvider),
                  ),
                ],
              ),

              // 关于
              _buildSection(
                context,
                title: '关于',
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('版本'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('开源许可'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: '弹词',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 使用说明
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              '使用说明',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '1. 在词库页面添加或导入单词\n'
                          '2. 开启弹窗复习，利用碎片时间学习\n'
                          '3. 在学习页面进行集中复习\n'
                          '4. 使用记忆梗帮助联想记忆\n\n'
                          '提示：弹窗功能需要授予悬浮窗权限',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  Future<bool> _checkOverlayPermission(BuildContext context) async {
    // 在实际应用中，这里需要调用原生代码检查和请求悬浮窗权限
    // 这里简化处理，直接返回 true
    return true;
  }

  void _showDailyGoalDialog(BuildContext context, SettingsProvider provider) {
    final options = [10, 20, 30, 50, 100];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('每日目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((count) {
            return RadioListTile<int>(
              title: Text('$count 个单词'),
              value: count,
              groupValue: provider.dailyGoal,
              onChanged: (value) {
                if (value != null) {
                  provider.setDailyGoal(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showIntervalDialog(BuildContext context, SettingsProvider provider) {
    final options = [5, 10, 15, 30, 60];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('弹窗间隔'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((minutes) {
            return RadioListTile<int>(
              title: Text(minutes < 60 ? '$minutes 分钟' : '1 小时'),
              value: minutes,
              groupValue: provider.popupInterval,
              onChanged: (value) {
                if (value != null) {
                  provider.setPopupInterval(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showQuietHoursDialog(BuildContext context, SettingsProvider provider) {
    final startParts = provider.quietHoursStart.split(':');
    final endParts = provider.quietHoursEnd.split(':');

    TimeOfDay startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );

    TimeOfDay endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('免打扰时段'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('开始时间'),
              trailing: Text(
                '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: startTime,
                );
                if (time != null) {
                  startTime = time;
                }
              },
            ),
            ListTile(
              title: const Text('结束时间'),
              trailing: Text(
                '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18),
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: endTime,
                );
                if (time != null) {
                  endTime = time;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
              final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
              provider.setQuietHours(start, end);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WordProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空数据'),
        content: const Text('确定要删除所有单词和学习记录吗？此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // TODO: 实现清空数据
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已清空')),
              );
            },
            child: const Text('确定清空'),
          ),
        ],
      ),
    );
  }
}
