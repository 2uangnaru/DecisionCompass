package com.decisioncompass.decision_compass

import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewTreeObserver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var contentReady = false
    private val handler = Handler(Looper.getMainLooper())
    private val releaseSplash = Runnable {
        contentReady = true
        window.decorView.invalidate()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Keep Android's animated icon visible until Flutter has painted
            // onboarding or Home. This avoids switching to a second logo.
            val content = findViewById<View>(android.R.id.content)
            val observer = content.viewTreeObserver
            observer.addOnPreDrawListener(object : ViewTreeObserver.OnPreDrawListener {
                override fun onPreDraw(): Boolean {
                    if (!contentReady) return false
                    if (observer.isAlive) observer.removeOnPreDrawListener(this)
                    return true
                }
            })
            // If Dart cannot signal readiness, reveal the Flutter loading view.
            handler.postDelayed(releaseSplash, 8000)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "astracue/startup")
            .setMethodCallHandler { call, result ->
                if (call.method == "contentReady") {
                    contentReady = true
                    handler.removeCallbacks(releaseSplash)
                    window.decorView.invalidate()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        handler.removeCallbacks(releaseSplash)
        super.onDestroy()
    }
}
