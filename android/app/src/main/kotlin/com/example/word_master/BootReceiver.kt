package com.example.word_master

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * 开机启动接收器
 * 
 * 用于在设备启动后自动启动弹窗服务
 */
class BootReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            // 可以在这里启动后台服务
            // 注意：需要用户在设置中开启弹窗功能才会生效
            // 实际启动逻辑需要根据 SharedPreferences 判断用户是否开启了弹窗功能
        }
    }
}
