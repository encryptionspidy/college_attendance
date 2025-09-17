package com.college_attendance_marker.app

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	private val channelName = "app/security"

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		// Ensure screenshots are allowed (clear any secure flag possibly set by plugins/policies)
		window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
		scheduleReclear()
	}

	override fun onResume() {
		super.onResume()
		// Re-clear in case another activity/plugin re-applied it
		window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
		scheduleReclear()
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
			if (call.method == "allowScreenshots") {
				try {
					window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
					scheduleReclear()
					result.success(true)
				} catch (e: Exception) {
					result.error("ERROR", e.message, null)
				}
			} else {
				result.notImplemented()
			}
		}
	}

	private fun scheduleReclear() {
		// Some plugins or transitions might reapply the flag; clear again shortly after.
		Handler(Looper.getMainLooper()).postDelayed({
			try { window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE) } catch (_: Exception) {}
		}, 500)
	}

	override fun onWindowFocusChanged(hasFocus: Boolean) {
		super.onWindowFocusChanged(hasFocus)
		if (hasFocus) {
			try {
				window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
				scheduleReclear()
			} catch (_: Exception) {}
		}
	}

	override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
		super.cleanUpFlutterEngine(flutterEngine)
	}
}
