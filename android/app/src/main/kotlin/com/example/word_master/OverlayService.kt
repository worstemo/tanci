package com.example.word_master

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.Toast

/**
 * 悬浮窗服务
 * 
 * 用于在其他应用上层显示单词复习弹窗
 * 需要在 AndroidManifest.xml 中声明：
 * <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
 */
class OverlayService : Service() {
    
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isShowing = false
    
    // 当前单词数据
    private var currentWord: String = ""
    private var currentMeaning: String = ""
    private var currentOptions: List<String> = listOf()
    
    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 从 Intent 获取单词数据
        intent?.let {
            currentWord = it.getStringExtra("word") ?: ""
            currentMeaning = it.getStringExtra("meaning") ?: ""
            currentOptions = it.getStringArrayListExtra("options") ?: listOf()
        }
        
        // 显示悬浮窗
        if (!isShowing && currentWord.isNotEmpty()) {
            showOverlay()
        }
        
        return START_NOT_STICKY
    }
    
    /**
     * 显示悬浮窗
     */
    private fun showOverlay() {
        if (overlayView != null) {
            return
        }
        
        // 检查悬浮窗权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && 
            !android.provider.Settings.canDrawOverlays(this)) {
            Toast.makeText(this, "请授予悬浮窗权限", Toast.LENGTH_SHORT).show()
            return
        }
        
        // 创建悬浮窗布局
        overlayView = LayoutInflater.from(this).inflate(
            R.layout.overlay_popup, 
            null
        )
        
        // 设置布局参数
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        
        params.gravity = Gravity.CENTER
        
        // 设置单词内容
        overlayView?.findViewById<TextView>(R.id.tv_word)?.text = currentWord
        
        // 设置选项按钮
        val optionButtons = listOf(
            R.id.btn_option1,
            R.id.btn_option2,
            R.id.btn_option3,
            R.id.btn_option4
        )
        
        optionButtons.forEachIndexed { index, buttonId ->
            overlayView?.findViewById<Button>(buttonId)?.apply {
                if (index < currentOptions.size) {
                    text = currentOptions[index]
                    setOnClickListener {
                        onOptionSelected(currentOptions[index] == currentMeaning)
                    }
                }
            }
        }
        
        // 添加到窗口
        windowManager?.addView(overlayView, params)
        isShowing = true
        
        // 设置触摸监听（允许拖动）
        setupTouchListener(params)
    }
    
    /**
     * 设置触摸监听，允许拖动悬浮窗
     */
    private fun setupTouchListener(params: WindowManager.LayoutParams) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        
        overlayView?.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager?.updateViewLayout(overlayView, params)
                    true
                }
                else -> false
            }
        }
    }
    
    /**
     * 选项被选中
     */
    private fun onOptionSelected(isCorrect: Boolean) {
        // 显示结果
        overlayView?.findViewById<TextView>(R.id.tv_result)?.apply {
            visibility = View.VISIBLE
            text = if (isCorrect) "✓ 正确！" else "✗ 正确答案: $currentMeaning"
            setTextColor(
                if (isCorrect) {
                    resources.getColor(android.R.color.holo_green_dark, null)
                } else {
                    resources.getColor(android.R.color.holo_red_dark, null)
                }
            )
        }
        
        // 隐藏选项按钮
        overlayView?.findViewById<android.widget.LinearLayout>(R.id.options_container)?.visibility = View.GONE
        
        // 显示继续按钮
        overlayView?.findViewById<Button>(R.id.btn_continue)?.apply {
            visibility = View.VISIBLE
            setOnClickListener {
                hideOverlay()
            }
        }
        
        // 发送结果到 Flutter
        val intent = Intent("com.example.word_master.OVERLAY_RESULT")
        intent.putExtra("is_correct", isCorrect)
        intent.putExtra("word", currentWord)
        sendBroadcast(intent)
    }
    
    /**
     * 隐藏悬浮窗
     */
    private fun hideOverlay() {
        overlayView?.let {
            windowManager?.removeView(it)
            overlayView = null
            isShowing = false
        }
        stopSelf()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
    }
    
    companion object {
        const val TAG = "OverlayService"
    }
}
