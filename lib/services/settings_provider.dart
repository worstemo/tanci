import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置状态管理
class SettingsProvider extends ChangeNotifier {
  // 设置项
  bool _popupEnabled = false;
  int _popupInterval = 15; // 分钟
  String _quietHoursStart = '23:00';
  String _quietHoursEnd = '07:00';
  bool _showMemoryTip = true;
  int _dailyGoal = 20;

  // Getters
  bool get popupEnabled => _popupEnabled;
  int get popupInterval => _popupInterval;
  String get quietHoursStart => _quietHoursStart;
  String get quietHoursEnd => _quietHoursEnd;
  bool get showMemoryTip => _showMemoryTip;
  int get dailyGoal => _dailyGoal;

  /// 加载设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _popupEnabled = prefs.getBool('popup_enabled') ?? false;
    _popupInterval = prefs.getInt('popup_interval') ?? 15;
    _quietHoursStart = prefs.getString('quiet_hours_start') ?? '23:00';
    _quietHoursEnd = prefs.getString('quiet_hours_end') ?? '07:00';
    _showMemoryTip = prefs.getBool('show_memory_tip') ?? true;
    _dailyGoal = prefs.getInt('daily_goal') ?? 20;
    
    notifyListeners();
  }

  /// 设置弹窗开关
  Future<void> setPopupEnabled(bool value) async {
    _popupEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('popup_enabled', value);
    notifyListeners();
  }

  /// 设置弹窗间隔
  Future<void> setPopupInterval(int minutes) async {
    _popupInterval = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('popup_interval', minutes);
    notifyListeners();
  }

  /// 设置免打扰时段
  Future<void> setQuietHours(String start, String end) async {
    _quietHoursStart = start;
    _quietHoursEnd = end;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quiet_hours_start', start);
    await prefs.setString('quiet_hours_end', end);
    notifyListeners();
  }

  /// 设置是否显示记忆技巧
  Future<void> setShowMemoryTip(bool value) async {
    _showMemoryTip = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_memory_tip', value);
    notifyListeners();
  }

  /// 设置每日目标
  Future<void> setDailyGoal(int count) async {
    _dailyGoal = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_goal', count);
    notifyListeners();
  }

  /// 检查当前是否在免打扰时段
  bool isInQuietHours() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    final startParts = _quietHoursStart.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    
    final endParts = _quietHoursEnd.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    
    // 处理跨天的情况（如23:00-07:00）
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }
}
