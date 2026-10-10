package com.findit.findit

import android.accessibilityservice.AccessibilityService
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

/**
 * "FindIt Iris trigger": used ONLY to detect a long press of Volume Up so the
 * Iris assistant can be started with the screen off. It requests no
 * accessibility events and cannot read window content (see
 * res/xml/iris_accessibility_config.xml); nothing is stored or sent.
 *
 * Short presses are passed through untouched, so volume changes normally.
 * Once a long press has triggered Iris, the rest of that press (repeats and
 * key-up) is consumed so the volume does not keep changing.
 * Triggering goes through the same [LostPhoneService.triggerIris] path as the
 * wake word: beep, vibrate, "Yes, tell me", listen once.
 */
class IrisAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "IrisA11yService"
        private const val LONG_PRESS_MS = 700L

        @Volatile
        var isConnected: Boolean = false
            private set
    }

    private val handler = Handler(Looper.getMainLooper())
    private var longPressFired = false

    private val fireRunnable = Runnable {
        // Runs on the main thread, like all accessibility callbacks.
        longPressFired = LostPhoneService.instance?.triggerIris("volume_long_press") == true
        Log.i(TAG, "Long press -> Iris trigger accepted=$longPressFired")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isConnected = true
        Log.i(TAG, "Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Intentionally empty: no screen content is read.
    }

    override fun onInterrupt() {}

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode != KeyEvent.KEYCODE_VOLUME_UP) return false

        when (event.action) {
            KeyEvent.ACTION_DOWN -> {
                if (event.repeatCount == 0) {
                    longPressFired = false
                    handler.removeCallbacks(fireRunnable)
                    // Only watch for a long press while Iris is armed.
                    if (LostPhoneService.isRunning) {
                        handler.postDelayed(fireRunnable, LONG_PRESS_MS)
                    }
                }
                // Pass the first press through (normal volume); swallow the
                // remainder of a press that already triggered Iris.
                return longPressFired
            }
            KeyEvent.ACTION_UP -> {
                handler.removeCallbacks(fireRunnable)
                val consumed = longPressFired
                longPressFired = false
                return consumed
            }
        }
        return false
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        isConnected = false
        handler.removeCallbacks(fireRunnable)
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        isConnected = false
        handler.removeCallbacks(fireRunnable)
        super.onDestroy()
    }
}
