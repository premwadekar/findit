package com.findit.findit

/**
 * Detects two presses of the same button within [windowMs].
 *
 * Line-for-line mirror of the unit-tested Dart `DoublePressDetector`
 * (lib/services/iris_triggers.dart). Timestamps are injected.
 * Presses closer than [bounceMs] count as the same physical press, which also
 * protects against one key event reaching us through two code paths
 * (Activity key dispatch and the MediaSession volume provider).
 */
class DoublePressDetector(
    private val windowMs: Long = 600L,
    private val bounceMs: Long = 40L
) {
    private var lastPressMs: Long? = null

    @Synchronized
    fun onPress(nowMs: Long): Boolean {
        val last = lastPressMs
        if (last != null) {
            val gap = nowMs - last
            if (gap in 0 until bounceMs) return false
            if (gap in bounceMs..windowMs) {
                lastPressMs = null
                return true
            }
        }
        lastPressMs = nowMs
        return false
    }

    @Synchronized
    fun reset() {
        lastPressMs = null
    }
}
