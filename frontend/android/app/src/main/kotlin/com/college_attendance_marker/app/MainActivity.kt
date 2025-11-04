package com.college_attendance_marker.app

import android.os.Bundle
import android.view.WindowManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	private val CHANNEL = "app/security"
	private val TAG = "MainActivity"

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		Log.d(TAG, "onCreate - Enabling screenshots")
		enableScreenshots()
	}

	override fun onResume() {
		super.onResume()
		Log.d(TAG, "onResume - Enabling screenshots")
		enableScreenshots()
	}

	override fun onStart() {
		super.onStart()
		Log.d(TAG, "onStart - Enabling screenshots")
		enableScreenshots()
	}

	override fun onPostCreate(savedInstanceState: Bundle?) {
		super.onPostCreate(savedInstanceState)
		Log.d(TAG, "onPostCreate - Enabling screenshots")
		enableScreenshots()
	}

	override fun onPostResume() {
		super.onPostResume()
		Log.d(TAG, "onPostResume - Enabling screenshots")
		enableScreenshots()
	}

	override fun onWindowFocusChanged(hasFocus: Boolean) {
		super.onWindowFocusChanged(hasFocus)
		Log.d(TAG, "onWindowFocusChanged - Enabling screenshots (hasFocus: $hasFocus)")
		enableScreenshots()
	}

	override fun onAttachedToWindow() {
		super.onAttachedToWindow()
		Log.d(TAG, "onAttachedToWindow - Enabling screenshots")
		enableScreenshots()
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		Log.d(TAG, "configureFlutterEngine - Enabling screenshots")

		enableScreenshots()

		// Setup method channel for manual screenshot control
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"allowScreenshots" -> {
					Log.d(TAG, "Method channel called - Enabling screenshots")
					enableScreenshots()
					result.success(true)
				}
				else -> result.notImplemented()
			}
		}
	}

	/**
	 * Aggressively enable screenshots by clearing FLAG_SECURE
	 * This method uses multiple approaches to ensure FLAG_SECURE is removed
	 */
	private fun enableScreenshots() {
		try {
			val w = window
			if (w != null) {
				// Method 1: Clear FLAG_SECURE using clearFlags
				w.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)

				// Method 2: Manually remove FLAG_SECURE from window attributes
				val attrs = w.attributes
				if (attrs != null) {
					// Use bitwise AND with inverted FLAG_SECURE to remove it
					attrs.flags = attrs.flags and WindowManager.LayoutParams.FLAG_SECURE.inv()
					w.attributes = attrs
					Log.d(TAG, "✅ Screenshots enabled - FLAG_SECURE removed from window attributes")
				}
			} else {
				Log.w(TAG, "⚠️ Window is null, cannot enable screenshots yet")
			}
		} catch (e: Exception) {
			Log.e(TAG, "❌ Error enabling screenshots: ${e.message}", e)
		}
	}
}
