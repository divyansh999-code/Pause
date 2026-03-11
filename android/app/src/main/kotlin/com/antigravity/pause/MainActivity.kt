package com.antigravity.pause

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity.pause/accessibility"

    companion object {
        private var methodChannel: MethodChannel? = null
        private var monitoredPackages = mutableSetOf<String>()

        fun onAppOpened(packageName: String) {
            Handler(Looper.getMainLooper()).post {
                val channel = methodChannel
                if (channel == null) {
                    Log.e("PauseMainActivity", "Cannot send event to Flutter: MethodChannel is NULL. Engine might not be running.")
                    return@post
                }

                Log.d("PauseMainActivity", "Sending onAppOpened to Flutter: $packageName")
                channel.invokeMethod("onAppOpened", packageName)
                
                if (monitoredPackages.contains(packageName)) {
                    Log.d("PauseMainActivity", "Triggering overlay for monitored package: $packageName")
                    channel.invokeMethod("triggerOverlay", packageName)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateMonitoredApps" -> {
                    val apps = call.arguments as? List<String>
                    if (apps != null) {
                        monitoredPackages.clear()
                        monitoredPackages.addAll(apps)
                        Log.d("PauseMainActivity", "Updated monitored apps: $monitoredPackages")
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Expected List<String>", null)
                    }
                }
                "isServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "resetCooldown" -> {
                    val packageName = call.arguments as? String
                    if (packageName != null) {
                        PauseAccessibilityService.resetCooldown(packageName)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Expected String", null)
                    }
                }
                "unlockPackage" -> {
                    val packageName = call.arguments as? String
                    if (packageName != null) {
                        PauseAccessibilityService.unlockPackage(packageName)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Expected String", null)
                    }
                }
                "requestPermission" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedServiceName = "${packageName}/${PauseAccessibilityService::class.java.canonicalName}"
        val enabledServices = android.provider.Settings.Secure.getString(
            contentResolver,
            android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(packageName) == true
    }

    private fun openAccessibilitySettings() {
        val intent = android.content.Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    override fun onDestroy() {
        methodChannel = null
        super.onDestroy()
    }
}
