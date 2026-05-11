import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 弹窗复习服务
/// 
/// 注意：完整的悬浮窗功能需要Android原生代码支持
/// 这里提供基础框架和通知提醒功能
class PopupService {
  static final PopupService _instance = PopupService._internal();
  factory PopupService() => _instance;
  PopupService._internal();

  Timer? _timer;
  bool _isRunning = false;
  int _intervalMinutes = 15;

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  /// 初始化通知
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// 开始弹窗服务
  Future<void> start({int intervalMinutes = 15}) async {
    if (_isRunning) return;

    _intervalMinutes = intervalMinutes;
    _isRunning = true;

    // 初始化通知
    await initialize();

    // 启动定时器
    _timer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _showReminder(),
    );
  }

  /// 停止弹窗服务
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// 显示提醒通知
  Future<void> _showReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'word_master_popup',
      '单词复习提醒',
      channelDescription: '定时提醒复习单词',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      '📚 该复习单词啦！',
      '点击开始学习，巩固记忆',
      details,
    );
  }

  /// 点击通知回调
  void _onNotificationTapped(NotificationResponse response) {
    // 这里可以导航到学习页面
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// 检查是否有悬浮窗权限
  Future<bool> checkOverlayPermission() async {
    if (Platform.isAndroid) {
      // 在实际应用中，需要调用原生代码检查 SYSTEM_ALERT_WINDOW 权限
      // 这里简化处理
      return true;
    }
    return false;
  }

  /// 请求悬浮窗权限
  Future<bool> requestOverlayPermission() async {
    if (Platform.isAndroid) {
      // 在实际应用中，需要调用原生代码打开系统设置页面
      // 引导用户授予悬浮窗权限
      return true;
    }
    return false;
  }

  bool get isRunning => _isRunning;
}

/// 悬浮窗弹窗页面
/// 
/// 这个页面会在其他应用上层显示
/// 需要在 AndroidManifest.xml 中添加权限：
/// <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
class OverlayPopupPage extends StatefulWidget {
  final String word;
  final String meaning;
  final List<String> options;
  final Function(bool isCorrect) onAnswer;

  const OverlayPopupPage({
    super.key,
    required this.word,
    required this.meaning,
    required this.options,
    required this.onAnswer,
  });

  @override
  State<OverlayPopupPage> createState() => _OverlayPopupPageState();
}

class _OverlayPopupPageState extends State<OverlayPopupPage> {
  int? _selectedIndex;
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                '复习时间到！',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.word,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(widget.options.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildOption(index, widget.options[index]),
                );
              }),
              if (_showResult) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('继续'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(int index, String text) {
    final isSelected = _selectedIndex == index;
    final isCorrect = text == widget.meaning;

    Color bgColor = Colors.grey[100]!;
    Color borderColor = Colors.grey[300]!;

    if (_showResult) {
      if (isCorrect) {
        bgColor = Colors.green[50]!;
        borderColor = Colors.green!;
      } else if (isSelected) {
        bgColor = Colors.red[50]!;
        borderColor = Colors.red!;
      }
    } else if (isSelected) {
      bgColor = Colors.blue[50]!;
      borderColor = Colors.blue!;
    }

    return GestureDetector(
      onTap: _showResult
          ? null
          : () {
              setState(() {
                _selectedIndex = index;
                _showResult = true;
              });
              widget.onAnswer(isCorrect);
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
