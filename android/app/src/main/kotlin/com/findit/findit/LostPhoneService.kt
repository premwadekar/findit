package com.findit.findit

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import java.util.Locale

class LostPhoneService : Service() {

    companion object {
        private const val TAG = "LostPhoneService"
        const val CHANNEL_ID = "findit_lost_phone_channel"
        const val NOTIFICATION_ID = 9021

        const val ACTION_START = "com.findit.findit.ACTION_START_LOST_PHONE"
        const val ACTION_STOP = "com.findit.findit.ACTION_STOP_LOST_PHONE"
        const val ACTION_STOP_ALARM = "com.findit.findit.ACTION_STOP_ALARM"
        const val ACTION_TEST_ALARM = "com.findit.findit.ACTION_TEST_ALARM"
        const val ACTION_TALK = "com.findit.findit.ACTION_TALK_TO_IRIS"
        const val ACTION_CONFIG = "com.findit.findit.ACTION_IRIS_CONFIG"
        const val ACTION_RING = "com.findit.findit.ACTION_RING_ALARM"

        const val EXTRA_CONFIG = "extra_iris_config"
        private const val IRIS_PREFS = "findit_iris_config"
        private const val COMMAND_WINDOW_MS = 8000L
        private const val TRIGGER_COOLDOWN_MS = 2000L
        private const val DART_REPLY_FALLBACK_MS = 20000L

        @Volatile
        var instance: LostPhoneService? = null
            private set

        // A command that Dart has not acknowledged yet (e.g. app cold-starting
        // from the screen-off state). Dart pulls it once its handler exists.
        @Volatile
        var pendingCommand: String? = null
        @Volatile
        var pendingCommandAtMs: Long = 0L

        fun takePendingCommand(): String? {
            val cmd = pendingCommand
            val fresh = SystemClock.uptimeMillis() - pendingCommandAtMs < 15000L
            pendingCommand = null
            return if (fresh) cmd else null
        }

        const val EXTRA_TIMEOUT_MINUTES = "extra_timeout_minutes"

        @Volatile
        var isRunning: Boolean = false
            private set

        @Volatile
        var isAlarmRinging: Boolean = false
            private set

        var eventListener: LostPhoneListener? = null
    }

    interface LostPhoneListener {
        fun onServiceStateChanged(running: Boolean)
        fun onAlarmTriggered(phrase: String)
        fun onAlarmStopped()
        fun onIrisWakeup(phrase: String)
        fun onVoiceCommand(command: String)
        fun onServiceError(error: String)
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var speechRecognizer: SpeechRecognizer? = null
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var batteryReceiver: BroadcastReceiver? = null

    private var timeoutMinutes: Int = 20
    private var isRecognizing: Boolean = false
    private var consecutiveErrors: Int = 0

    // 1. Alarm Trigger: ONLY when the user explicitly asks where the phone is or to ring the phone
    private val alarmTriggerRegex = Regex(
        """(?i)\bwhere\s+are\s+you\b|""" +
        """(?i)\b(find|ring|locate|where\s+is)\s*(my\s+|the\s+)?phone\b|""" +
        """(?i)\bphone\s*(ring|where)\b|""" +
        """\b(कहाँ\s+हो|कहा\s+हो|फोन\s+कहाँ\s+है|फोन\s+ढूंढो|फोन\s+बजाओ|खोया\s+फोन)\b|""" +
        """\b(ಫೋನ್\s+ಎಲ್ಲಿದೆ|ಎಲ್ಲಿದ್ದೀಯಾ?|ಫೋನ್\s+ರಿಂಗ್\s+ಮಾಡು|ಕಳೆದುಹೋದ\s+ಫೋನ್)\b"""
    )

    // 2. Assistant wake word. The pattern is owned by Dart (IrisWakeWord.pattern,
    // unit-tested) and delivered in the Iris config; this simple fallback only
    // applies if the service starts before any config was ever saved.
    private val fallbackWakePattern = """\b(?:hey|hi|ok|okay)?\s*iris\b"""
    private var wakeRegexCache: Regex? = null
    private var wakeRegexCachePattern: String? = null

    private fun irisPrefs() = getSharedPreferences(IRIS_PREFS, Context.MODE_PRIVATE)

    private fun cfg(key: String, default: String): String =
        irisPrefs().getString(key, null)?.takeIf { it.isNotBlank() } ?: default

    private fun wakeRegex(): Regex {
        val pattern = cfg("wake_pattern", fallbackWakePattern)
        if (wakeRegexCache == null || wakeRegexCachePattern != pattern) {
            wakeRegexCache = try {
                Regex(pattern, RegexOption.IGNORE_CASE)
            } catch (e: Exception) {
                Log.e(TAG, "Bad wake pattern, using fallback: ${e.message}")
                Regex(fallbackWakePattern, RegexOption.IGNORE_CASE)
            }
            wakeRegexCachePattern = pattern
        }
        return wakeRegexCache!!
    }

    private fun saveIrisConfig(config: Bundle?) {
        if (config == null) return
        val editor = irisPrefs().edit()
        for (key in config.keySet()) {
            config.getString(key)?.let { editor.putString(key, it) }
        }
        editor.apply()
    }

    // 3. Stop Alarm: Voice commands to silence ringing alarm
    private val stopAlarmRegex = Regex(
        """(?i)\b(stop(\s+(the|this))?\s*alarm|stop\s*(it|this|please|now)?|alarm\s*stop|silence(\s*alarm)?|quiet|shut\s*up|cancel|mute(\s*alarm)?|turn\s*off(\s+(the|this))?\s*alarm|off(\s+(the|this))?\s*alarm|found(\s*(it|my\s*phone|the\s*phone))?|i\s*found\s*(it|my\s*phone)|got\s*it|i\s*got\s*it|phone\s*found)\b|""" +
        """(?i)\b(hey\s+|hi\s+|ok\s+|okay\s+)?(iris|irish|ayres|aires|eris|here\s+is)\s+(stop|top|talk|quiet|silence|cancel|off|close)\b|""" +
        """\b(अलार्म\s*(बंद\s*(करो|कर\s*दो)?|रोको?)|बंद\s*(करो|कर\s*दो)|फोन\s*मिल\s*गया|मिल\s*गया|चुप\s*(हो\s*जाओ|रहो)?|रुको|आवाज\s*बंद\s*(करो)?)\b|""" +
        """\b(ಅಲಾರಂ\s*ನಿಲ್ಲಿಸು|ನಿಲ್ಲಿಸು|ಆಫ್\s*ಮಾಡು|ಫೋನ್\s*ಸಿಕ್ತು|ಸಾಕು)\b"""
    )

    private var isAwaitingUserCommand: Boolean = false
    private var isSpeakingPrompt: Boolean = false

    // One Iris session = trigger -> beep -> "Yes, tell me" -> one command -> reply.
    @Volatile private var irisSessionActive: Boolean = false
    private var lastTriggerMs: Long = -TRIGGER_COOLDOWN_MS
    private val volumeDetector = DoublePressDetector()
    private var mediaSession: MediaSession? = null

    /** Nothing was heard within the command window: say so, then go idle. */
    private val commandTimeoutRunnable = Runnable {
        Log.i(TAG, "Command window timed out (no speech heard).")
        isAwaitingUserCommand = false
        isSpeakingPrompt = true
        try {
            speechRecognizer?.cancel()
            isRecognizing = false
        } catch (_: Exception) {}
        if (!speakIris(cfg("didnt_hear", "I didn't hear anything."), "iris_no_input")) {
            endIrisSession(500L)
        }
    }

    /** Safety net: Dart never reported that its reply finished. */
    private val dartReplyFallbackRunnable = Runnable {
        Log.w(TAG, "Dart reply did not finish in time; resuming wake-word listening.")
        endIrisSession(350L)
    }

    private fun endIrisSession(restartDelayMs: Long) {
        irisSessionActive = false
        isAwaitingUserCommand = false
        isSpeakingPrompt = false
        mainHandler.removeCallbacks(commandTimeoutRunnable)
        mainHandler.removeCallbacks(dartReplyFallbackRunnable)
        scheduleRestart(restartDelayMs)
    }

    /** Called when Dart finished speaking the command's reply. */
    fun onIrisReplyDone() {
        mainHandler.post { if (irisSessionActive) endIrisSession(350L) }
    }

    private var textToSpeech: TextToSpeech? = null
    private var isTtsReady: Boolean = false

    private fun initTextToSpeech() {
        try {
            textToSpeech = TextToSpeech(applicationContext) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    isTtsReady = true
                    Log.i(TAG, "Native TextToSpeech initialized successfully.")
                    val locale = getPreferredLocale()
                    try {
                        val setLangRes = textToSpeech?.setLanguage(locale)
                        Log.i(TAG, "TTS setLanguage($locale) = $setLangRes")
                    } catch (e: Exception) {
                        Log.w(TAG, "TTS setLanguage error: ${e.message}")
                    }
                    textToSpeech?.setSpeechRate(0.95f)
                    textToSpeech?.setPitch(1.0f)
                    try {
                        val audioAttrs = AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                        textToSpeech?.setAudioAttributes(audioAttrs)
                    } catch (_: Exception) {}

                    textToSpeech?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) {
                            Log.i(TAG, "TTS onStart: $utteranceId")
                        }

                        override fun onDone(utteranceId: String?) {
                            Log.i(TAG, "TTS onDone: $utteranceId")
                            onIrisUtteranceFinished(utteranceId)
                        }

                        override fun onError(utteranceId: String?) {
                            Log.w(TAG, "TTS onError: $utteranceId")
                            onIrisUtteranceFinished(utteranceId)
                        }
                    })
                } else {
                    Log.e(TAG, "Native TTS initialization failed with status: $status")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "initTextToSpeech error: ${e.message}")
        }
    }

    private fun getPreferredLocale(): Locale {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val langCode = prefs.getString("flutter.findit_preferred_language", "en") ?: "en"
            return when (langCode.lowercase()) {
                "hi", "hin", "hindi" -> Locale("hi", "IN")
                "kn", "kan", "kannada" -> Locale("kn", "IN")
                "te", "tel", "telugu" -> Locale("te", "IN")
                "ta", "tam", "tamil" -> Locale("ta", "IN")
                else -> Locale.ENGLISH
            }
        } catch (_: Exception) {
            return Locale.ENGLISH
        }
    }

    private fun onIrisUtteranceFinished(utteranceId: String?) {
        when (utteranceId) {
            // 350ms pause lets speaker reverberation clear before the mic opens
            "iris_wakeup_prompt" -> mainHandler.postDelayed({ openCommandWindow() }, 350L)
            "iris_no_input" -> mainHandler.postDelayed({ endIrisSession(0L) }, 350L)
        }
    }

    /** Mic opens for exactly ONE command, with an 8 second window. */
    private fun openCommandWindow() {
        if (!irisSessionActive || !isRunning) return
        isSpeakingPrompt = false
        isAwaitingUserCommand = true
        mainHandler.removeCallbacks(commandTimeoutRunnable)
        mainHandler.postDelayed(commandTimeoutRunnable, COMMAND_WINDOW_MS)
        startSpeechRecognizer()
    }

    /** Speaks [text] in the user's language; returns false if TTS is unavailable. */
    private fun speakIris(text: String, utteranceId: String): Boolean {
        if (textToSpeech != null && isTtsReady) {
            try {
                textToSpeech?.language = getPreferredLocale()
                val params = Bundle().apply {
                    putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
                    putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
                }
                val res = textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
                Log.i(TAG, "TTS speak('$text') result: $res")
                return res == TextToSpeech.SUCCESS
            } catch (e: Exception) {
                Log.e(TAG, "TTS speak failed: ${e.message}")
            }
        }
        return false
    }

    private fun speakYesAndListen() {
        val prompt = cfg("yes_tell_me", "Yes, tell me.")

        // Unmute and elevate media stream volume if low so a blind user clearly hears it
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            val currentVol = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
            val maxVol = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 15
            if (currentVol < maxVol / 2) {
                audioManager?.setStreamVolume(AudioManager.STREAM_MUSIC, (maxVol * 0.75).toInt(), 0)
            }
        } catch (_: Exception) {}

        isSpeakingPrompt = true
        mainHandler.removeCallbacks(restartRunnable)
        if (speakIris(prompt, "iris_wakeup_prompt")) return

        // TTS not ready: wait 1.8s, then listen anyway
        mainHandler.postDelayed({ openCommandWindow() }, 1800L)
    }

    private val restartRunnable = Runnable {
        if (isRunning) {
            startSpeechRecognizer()
        }
    }

    private val serviceAutoStopRunnable = Runnable {
        Log.i(TAG, "Lost Phone Mode reached auto-timeout ($timeoutMinutes min) to conserve battery.")
        eventListener?.onServiceError("Lost Phone Mode auto-stopped after $timeoutMinutes min to save battery.")
        stopSelf()
    }

    private val alarmAutoStopRunnable = Runnable {
        Log.i(TAG, "Alarm reached 3-minute auto-silence safety limit.")
        stopAlarm()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        registerBatteryMonitor()
        initTextToSpeech()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START

        when (action) {
            ACTION_STOP -> {
                stopAlarm()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_STOP_ALARM -> {
                stopAlarm()
                return START_STICKY
            }
            ACTION_TEST_ALARM -> {
                triggerAlarm("Test Alarm")
                return START_STICKY
            }
            ACTION_RING -> {
                if (isRunning) triggerAlarm("Iris")
                return START_STICKY
            }
            ACTION_TALK -> {
                if (isRunning) {
                    beginIrisSession("notification")
                } else {
                    stopSelf()
                }
                return START_STICKY
            }
            ACTION_CONFIG -> {
                saveIrisConfig(intent?.getBundleExtra(EXTRA_CONFIG))
                if (isRunning) {
                    try {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        if (!isAlarmRinging) nm.notify(NOTIFICATION_ID, buildListeningNotification())
                    } catch (_: Exception) {}
                } else {
                    stopSelf()
                }
                return START_STICKY
            }
            ACTION_START -> {
                saveIrisConfig(intent?.getBundleExtra(EXTRA_CONFIG))
                timeoutMinutes = intent?.getIntExtra(EXTRA_TIMEOUT_MINUTES, 20)?.coerceIn(5, 60) ?: 20
                startForegroundServiceMode()
                return START_STICKY
            }
        }

        return START_NOT_STICKY
    }

    private fun startForegroundServiceMode() {
        if (isRunning) {
            return
        }
        isRunning = true
        eventListener?.onServiceStateChanged(true)

        // 1. Acquire partial wake lock to keep CPU active during detection window
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "FindIt:LostPhoneWakeLock"
            ).apply {
                acquire(timeoutMinutes * 60 * 1000L)
            }
        } catch (e: Exception) {
            Log.e(TAG, "WakeLock acquire failed: ${e.message}")
        }

        // 2. Start Foreground Service with microphone type on Android 10+
        val notification = buildListeningNotification()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed: ${e.message}")
            eventListener?.onServiceError("Could not start foreground microphone service: ${e.message}")
            stopSelf()
            return
        }

        // 3. Schedule auto-timeout to prevent indefinite battery drain
        mainHandler.removeCallbacks(serviceAutoStopRunnable)
        mainHandler.postDelayed(serviceAutoStopRunnable, timeoutMinutes * 60 * 1000L)

        // 4. Try to receive Volume Up double-presses with the screen off
        startVolumeSession()

        // 5. Start hotword recognition
        startSpeechRecognizer()
    }

    private fun resetSpeechRecognizer() {
        try {
            speechRecognizer?.cancel()
            speechRecognizer?.destroy()
        } catch (_: Exception) {}
        speechRecognizer = null
        isRecognizing = false
    }

    private fun startSpeechRecognizer() {
        mainHandler.post {
            if (!isRunning || isSpeakingPrompt) return@post
            try {
                if (speechRecognizer == null) {
                    if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                        Log.e(TAG, "Android SpeechRecognizer is unavailable on this device.")
                        eventListener?.onServiceError("Android SpeechRecognizer is unavailable on this device.")
                        return@post
                    }
                    speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
                        setRecognitionListener(speechListener)
                    }
                }

                // Always cancel previous session before starting a new listening pass
                try {
                    speechRecognizer?.cancel()
                } catch (_: Exception) {}

                val locale = getPreferredLocale()
                val langTag = when (locale.language) {
                    "hi" -> "hi-IN"
                    "kn" -> "kn-IN"
                    "te" -> "te-IN"
                    "ta" -> "ta-IN"
                    else -> "en-IN"
                }

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, langTag)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, langTag)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 10)
                    putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
                    if (isAlarmRinging) {
                        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 500L)
                        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 600L)
                        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 600L)
                    } else {
                        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 500L)
                        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 800L)
                        putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 800L)
                    }
                }
                isRecognizing = true
                speechRecognizer?.startListening(intent)
                Log.i(TAG, "SpeechRecognizer started listening (lang=$langTag, awaitingReply=$isAwaitingUserCommand)")
            } catch (e: Exception) {
                Log.e(TAG, "startSpeechRecognizer error: ${e.message}")
                resetSpeechRecognizer()
                scheduleRestart(1000)
            }
        }
    }

    private val speechListener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            isRecognizing = true
            consecutiveErrors = 0
            Log.i(TAG, "Ready for speech (awaitingCommand=$isAwaitingUserCommand)")
        }

        override fun onBeginningOfSpeech() {
            Log.i(TAG, "Beginning of speech detected")
        }

        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}

        override fun onEndOfSpeech() {
            isRecognizing = false
            Log.i(TAG, "End of speech detected")
        }

        override fun onError(error: Int) {
            isRecognizing = false
            Log.w(TAG, "SpeechRecognizer onError: $error (awaitingCommand=$isAwaitingUserCommand)")
            if (!isRunning || isSpeakingPrompt) return

            // Errors 6 (SPEECH_TIMEOUT) and 7 (NO_MATCH) are expected in silence
            val delayMs = when (error) {
                SpeechRecognizer.ERROR_NO_MATCH,
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> 250L
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY,
                SpeechRecognizer.ERROR_CLIENT -> {
                    consecutiveErrors++
                    resetSpeechRecognizer()
                    500L
                }
                SpeechRecognizer.ERROR_AUDIO,
                SpeechRecognizer.ERROR_SERVER,
                SpeechRecognizer.ERROR_NETWORK -> {
                    consecutiveErrors++
                    if (consecutiveErrors > 2) {
                        resetSpeechRecognizer()
                        1500L
                    } else {
                        500L
                    }
                }
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> {
                    eventListener?.onServiceError("Microphone permission missing for Lost Phone Mode.")
                    stopSelf()
                    return
                }
                else -> {
                    resetSpeechRecognizer()
                    500L
                }
            }
            scheduleRestart(delayMs)
        }

        override fun onResults(results: Bundle?) {
            isRecognizing = false
            if (!isRunning || isSpeakingPrompt) return
            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            if (!checkMatches(matches, isPartial = false)) {
                scheduleRestart(250)
            }
        }

        override fun onPartialResults(partialResults: Bundle?) {
            if (!isRunning || isSpeakingPrompt) return
            val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            checkMatches(matches, isPartial = true)
        }

        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    private fun stripIrisHotword(phrase: String): String {
        return try {
            val prefix = Regex("""^\s*(?:""" + wakeRegex().pattern + """)[:,\s]*""", RegexOption.IGNORE_CASE)
            phrase.replace(prefix, "").trim()
        } catch (_: Exception) {
            phrase.trim()
        }
    }

    /** Short system beep (no asset) so the user knows Iris is listening. */
    private fun playListenBeep() {
        try {
            val tone = ToneGenerator(AudioManager.STREAM_MUSIC, 80)
            tone.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
            mainHandler.postDelayed({ try { tone.release() } catch (_: Exception) {} }, 400L)
        } catch (e: Exception) {
            Log.w(TAG, "Beep failed: ${e.message}")
        }
    }

    private fun vibrateOnce() {
        try {
            val vibrator = getVibrator()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createOneShot(80L, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(80L)
            }
        } catch (_: Exception) {}
    }

    /**
     * Single entry point for EVERY trigger (wake word, double Volume Up,
     * notification button, home-screen button). Debounced so one physical
     * trigger can never start two sessions.
     *
     * Flow: beep + vibrate -> pause wake-word loop -> "Yes, tell me" ->
     * listen for ONE command (8 s) -> deliver to Dart -> idle.
     */
    private fun beginIrisSession(source: String, directCommand: String? = null) {
        if (!isRunning) return
        if (isAlarmRinging) {
            // Any trigger while the alarm sounds silences it first.
            stopAlarm()
            return
        }
        val now = SystemClock.uptimeMillis()
        if (irisSessionActive || now - lastTriggerMs < TRIGGER_COOLDOWN_MS) {
            Log.i(TAG, "Iris trigger from '$source' ignored (debounced).")
            return
        }
        lastTriggerMs = now
        irisSessionActive = true
        Log.i(TAG, "Iris session started by '$source'")

        // Pause the wake-word loop so the mic never hears the beep or our own voice.
        mainHandler.removeCallbacks(restartRunnable)
        isSpeakingPrompt = true
        isAwaitingUserCommand = false
        try {
            speechRecognizer?.cancel()
            isRecognizing = false
        } catch (_: Exception) {}

        playListenBeep()
        vibrateOnce()
        eventListener?.onIrisWakeup(source)

        if (!directCommand.isNullOrEmpty()) {
            // "Hey Iris, find my bottle": the command was already spoken.
            deliverCommand(directCommand, launchApp = true)
        } else {
            // Let the beep finish before speaking.
            mainHandler.postDelayed({ speakYesAndListen() }, 300L)
        }
    }

    /** Hands the transcript to Dart and waits (bounded) for its spoken reply to end. */
    private fun deliverCommand(command: String, launchApp: Boolean) {
        isAwaitingUserCommand = false
        isSpeakingPrompt = true
        mainHandler.removeCallbacks(commandTimeoutRunnable)
        Log.i(TAG, "Delivering Iris command: '$command'")

        if (launchApp) {
            try {
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("from_voice_command", true)
                    putExtra("command", command)
                }
                if (launchIntent != null) startActivity(launchIntent)
            } catch (e: Exception) {
                Log.e(TAG, "Launch activity on voice command error: ${e.message}")
            }
        }

        pendingCommand = command
        pendingCommandAtMs = SystemClock.uptimeMillis()
        eventListener?.onVoiceCommand(command)
        mainHandler.removeCallbacks(dartReplyFallbackRunnable)
        mainHandler.postDelayed(dartReplyFallbackRunnable, DART_REPLY_FALLBACK_MS)
    }

    private fun handleIrisWakeup(phrase: String) {
        Log.i(TAG, "Iris wakeup detected: '$phrase'")
        val cleaned = stripIrisHotword(phrase)
        beginIrisSession("wake_word", if (cleaned.length >= 3) cleaned else null)
    }

    /** Volume Up pressed (Activity or MediaSession). True when it triggered Iris. */
    fun onVolumeUpPress(): Boolean {
        if (!isRunning) return false
        val triggered = volumeDetector.onPress(SystemClock.uptimeMillis())
        if (triggered) mainHandler.post { beginIrisSession("volume_double_press") }
        return triggered
    }

    /**
     * Best-effort: an active MediaSession with a remote VolumeProvider lets the
     * service see Volume keys when the screen is off or the app is in the
     * background. Some OEM builds do not route keys to it; then only the
     * in-app, wake-word and notification triggers work. Never fatal.
     */
    private fun startVolumeSession() {
        try {
            val session = MediaSession(this, "FindItIris")
            session.setPlaybackState(
                PlaybackState.Builder()
                    .setActions(0L)
                    .setState(PlaybackState.STATE_PLAYING, 0L, 1f)
                    .build()
            )
            session.setPlaybackToRemote(object : VolumeProvider(VOLUME_CONTROL_RELATIVE, 100, 50) {
                override fun onAdjustVolume(direction: Int) {
                    mainHandler.post { handleSessionVolumeKey(direction) }
                }
            })
            session.isActive = true
            mediaSession = session
            Log.i(TAG, "Volume MediaSession active.")
        } catch (e: Exception) {
            Log.w(TAG, "Volume MediaSession unavailable: ${e.message}")
            mediaSession = null
        }
    }

    private fun handleSessionVolumeKey(direction: Int) {
        if (direction > 0 && isAlarmRinging) {
            stopAlarm()
            return
        }
        // Keep normal volume behaviour: only a SECOND press within the window triggers Iris.
        if (direction > 0 && onVolumeUpPress()) return
        if (direction == 0) return
        try {
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.adjustSuggestedStreamVolume(
                if (direction > 0) AudioManager.ADJUST_RAISE else AudioManager.ADJUST_LOWER,
                AudioManager.USE_DEFAULT_STREAM_TYPE,
                AudioManager.FLAG_SHOW_UI
            )
        } catch (_: Exception) {}
    }

    private fun stopVolumeSession() {
        try {
            mediaSession?.isActive = false
            mediaSession?.release()
        } catch (_: Exception) {}
        mediaSession = null
    }

    private fun checkMatches(matches: ArrayList<String>?, isPartial: Boolean): Boolean {
        if (matches == null || matches.isEmpty()) return false
        for (phrase in matches) {
            val clean = phrase.trim()
            Log.i(TAG, "Speech candidate (partial=$isPartial, awaitingReply=$isAwaitingUserCommand): '$clean'")

            if (isAlarmRinging) {
                if (stopAlarmRegex.containsMatchIn(clean)) {
                    Log.i(TAG, "Stop alarm command matched: '$clean'")
                    stopAlarm()
                    return true
                }
            } else if (isAwaitingUserCommand) {
                // IMPORTANT: Never consume replies on partial results! Wait for full utterance onResults
                if (!isPartial) {
                    Log.i(TAG, "User command final reply candidate: '$clean'")
                    if (alarmTriggerRegex.containsMatchIn(clean)) {
                        Log.i(TAG, "Alarm trigger matched in reply: '$clean'")
                        triggerAlarm(clean)
                        return true
                    }
                    val cmd = stripIrisHotword(clean)
                    // Ensure candidate is NOT just a repeated "Hey Iris"
                    if (cmd.isNotEmpty() && cmd.length >= 2 && !wakeRegex().matches(clean)) {
                        Log.i(TAG, "Voice command received in reply: '$cmd'")
                        deliverCommand(cmd, launchApp = true)
                        return true
                    }
                }
            } else {
                if (alarmTriggerRegex.containsMatchIn(clean)) {
                    Log.i(TAG, "Alarm trigger matched by candidate: '$clean'")
                    triggerAlarm(clean)
                    return true
                } else if (!isPartial && wakeRegex().containsMatchIn(clean)) {
                    // Final results only: a partial "hey iris find my" would cut the command short.
                    Log.i(TAG, "Iris hotword detected by candidate: '$clean'")
                    handleIrisWakeup(clean)
                    return true
                }
            }
        }
        return false
    }

    private fun scheduleRestart(delayMs: Long) {
        mainHandler.removeCallbacks(restartRunnable)
        if (isRunning && !isSpeakingPrompt) {
            mainHandler.postDelayed(restartRunnable, delayMs)
        }
    }

    private fun triggerAlarm(phrase: String) {
        if (isAlarmRinging) return
        isAlarmRinging = true

        // An alarm ends any Iris session in progress.
        irisSessionActive = false
        isAwaitingUserCommand = false
        isSpeakingPrompt = false
        mainHandler.removeCallbacks(commandTimeoutRunnable)
        mainHandler.removeCallbacks(dartReplyFallbackRunnable)

        // 1. Stop speech listener briefly for audio initialization
        try {
            speechRecognizer?.stopListening()
            speechRecognizer?.cancel()
            isRecognizing = false
        } catch (_: Exception) {}

        // 2. Maximize alarm stream volume
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVol, 0)
        } catch (e: Exception) {
            Log.e(TAG, "Volume set error: ${e.message}")
        }

        // 3. Play loud alarm ringtone
        try {
            val alertUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alertUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e(TAG, "MediaPlayer error: ${e.message}")
        }

        // 4. Vibrate in heavy SOS cadence
        try {
            val vibrator = getVibrator()
            val pattern = longArrayOf(0, 600, 200, 600, 200, 1000)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Vibrator error: ${e.message}")
        }

        // 5. Update notification to high priority alarm banner
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, buildAlarmNotification(phrase))
        } catch (e: Exception) {
            Log.e(TAG, "Notification update error: ${e.message}")
        }

        // 6. Bring MainActivity to foreground
        try {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("from_lost_phone_alarm", true)
                putExtra("triggered_phrase", phrase)
            }
            if (launchIntent != null) {
                startActivity(launchIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Launch activity error: ${e.message}")
        }

        // 7. Notify listeners
        eventListener?.onAlarmTriggered(phrase)

        // 8. 3-minute safety timeout to auto-stop ringing
        mainHandler.removeCallbacks(alarmAutoStopRunnable)
        mainHandler.postDelayed(alarmAutoStopRunnable, 3 * 60 * 1000L)

        // 9. Schedule speech listener to listen for "Stop" command after audio initializes
        scheduleRestart(600)
    }

    fun stopAlarm() {
        if (!isAlarmRinging) return
        isAlarmRinging = false
        mainHandler.removeCallbacks(alarmAutoStopRunnable)

        // Cancel active recognizer pass so "stop" is not interpreted as next hotword
        try {
            speechRecognizer?.stopListening()
            speechRecognizer?.cancel()
            isRecognizing = false
        } catch (_: Exception) {}

        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (_: Exception) {}

        try {
            getVibrator()?.cancel()
        } catch (_: Exception) {}

        if (isRunning) {
            try {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, buildListeningNotification())
            } catch (_: Exception) {}
            scheduleRestart(500)
        }

        eventListener?.onAlarmStopped()
    }

    private fun getVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vm?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Lost Phone Mode",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "FindIt microphone service listening for 'Hey Iris'"
                setShowBadge(true)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun buildListeningNotification(): Notification {
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingOpen = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, LostPhoneService::class.java).apply {
            action = ACTION_STOP
        }
        val pendingStop = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val talkIntent = Intent(this, LostPhoneService::class.java).apply {
            action = ACTION_TALK
        }
        val pendingTalk = PendingIntent.getService(
            this,
            3,
            talkIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val howTo = cfg(
            "notif_text",
            "Say \"Hey Iris\", double-press Volume Up, or tap Talk to Iris. Auto-off in $timeoutMinutes min."
        )

        builder.setContentTitle("FindIt: Iris is on")
            .setContentText(howTo)
            .setStyle(Notification.BigTextStyle().bigText(howTo))
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pendingOpen)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_btn_speak_now, cfg("talk_action", "Talk to Iris"), pendingTalk)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "STOP", pendingStop)

        return builder.build()
    }

    private fun buildAlarmNotification(phrase: String): Notification {
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("from_lost_phone_alarm", true)
        }
        val pendingOpen = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val silenceIntent = Intent(this, LostPhoneService::class.java).apply {
            action = ACTION_STOP_ALARM
        }
        val pendingSilence = PendingIntent.getService(
            this,
            2,
            silenceIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder.setContentTitle("🚨 PHONE FOUND! ALARM RINGING 🚨")
            .setContentText("Heard: \"$phrase\". Tap below to silence.")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentIntent(pendingOpen)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_lock_silent_mode_off, "SILENCE ALARM", pendingSilence)

        return builder.build()
    }

    private fun registerBatteryMonitor() {
        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (Intent.ACTION_BATTERY_LOW == intent?.action) {
                    Log.w(TAG, "Battery low detected (<15%). Auto-stopping Lost Phone Mode.")
                    eventListener?.onServiceError("Lost Phone Mode auto-stopped: Device battery is low (<15%).")
                    stopSelf()
                }
            }
        }
        val filter = IntentFilter(Intent.ACTION_BATTERY_LOW)
        registerReceiver(batteryReceiver, filter)
    }

    override fun onDestroy() {
        isRunning = false
        isAlarmRinging = false
        isSpeakingPrompt = false
        isAwaitingUserCommand = false
        irisSessionActive = false
        instance = null
        mainHandler.removeCallbacksAndMessages(null)
        stopVolumeSession()

        stopAlarm()

        try {
            speechRecognizer?.destroy()
            speechRecognizer = null
        } catch (_: Exception) {}

        try {
            textToSpeech?.stop()
            textToSpeech?.shutdown()
            textToSpeech = null
            isTtsReady = false
        } catch (_: Exception) {}

        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}

        try {
            if (batteryReceiver != null) {
                unregisterReceiver(batteryReceiver)
                batteryReceiver = null
            }
        } catch (_: Exception) {}

        eventListener?.onServiceStateChanged(false)
        super.onDestroy()
    }
}
