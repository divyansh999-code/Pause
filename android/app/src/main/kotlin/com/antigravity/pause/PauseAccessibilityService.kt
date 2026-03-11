package com.antigravity.pause

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class PauseAccessibilityService : AccessibilityService() {

    companion object {
        private val lastTriggerTimeMap = mutableMapOf<String, Long>()
        var lastTriggeredPackage: String? = null
        var lastTriggerTime: Long = 0L

        fun resetCooldown(packageName: String) {
            lastTriggerTimeMap.remove(packageName)
            if (lastTriggeredPackage == packageName) {
                lastTriggeredPackage = null
            }
        }

        fun unlockPackage(packageName: String) {
            // no-op
        }
    }

    private val COOLDOWN_MILLIS = 15000L // 15 seconds cooldown for same app
    private val TRANSITION_GRACE_MILLIS = 3000L // 3 seconds ignored launcher reset

    private val ignoredPackages = setOf(
        "com.antigravity.pause",
        "com.android.launcher",
        "com.android.launcher3",
        "com.google.android.apps.nexuslauncher",
        "com.android.systemui",
        "com.android.settings",
        "com.google.android.inputmethod.latin",
        "com.samsung.android.honeyboard",
        "com.sec.android.inputmethod",
        "com.touchtype.swiftkey",
        "com.android.inputmethod.latin"
    )

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        val currentTime = System.currentTimeMillis()

        Log.d("PauseAccessibility", "Window: $packageName (lastTriggered: $lastTriggeredPackage)")

        // 1. Ignore system UI / keyboards / Pause itself.
        if (ignoredPackages.contains(packageName)) {
            // RESET logic: Only reset if navigated to launcher AND we aren't in a transition grace period.
            // This prevents the overlay-closing "flick" to home from resetting the state.
            if (packageName.contains("launcher")) {
                if (currentTime - lastTriggerTime > TRANSITION_GRACE_MILLIS) {
                    Log.d("PauseAccessibility", "Launcher detected — resetting lastTriggeredPackage")
                    lastTriggeredPackage = null
                } else {
                    Log.d("PauseAccessibility", "Launcher detected during grace period — NOT resetting")
                }
            }
            return
        }

        // 2. Cooldown logic: If we triggered for this exact package very recently, skip.
        val lastTrigger = lastTriggerTimeMap[packageName] ?: 0L
        if (packageName == lastTriggeredPackage && (currentTime - lastTrigger < COOLDOWN_MILLIS)) {
            Log.d("PauseAccessibility", "Package $packageName in cooldown — skipping")
            return
        }

        // 3. New package or cooldown expired — trigger and remember.
        lastTriggeredPackage = packageName
        lastTriggerTime = currentTime
        lastTriggerTimeMap[packageName] = currentTime
        
        Log.d("PauseAccessibility", "TRIGGERING for: $packageName")
        MainActivity.onAppOpened(packageName)
    }

    override fun onInterrupt() {
        Log.d("PauseAccessibility", "Service Interrupted")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("PauseAccessibility", "Service Connected")
    }
}
