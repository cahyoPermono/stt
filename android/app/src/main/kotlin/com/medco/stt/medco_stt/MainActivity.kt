package com.medco.stt.medco_stt

import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.medco.stt/engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "resetRecognizer" -> {
                    val success = forceResetSpeechRecognizer()
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onPause() {
        super.onPause()
        forceResetSpeechRecognizer()
    }

    override fun onResume() {
        super.onResume()
        forceResetSpeechRecognizer()
    }

    private fun forceResetSpeechRecognizer(): Boolean {
        return try {
            @Suppress("UNCHECKED_CAST")
            val pluginClass = Class.forName("com.csdcorp.speech_to_text.SpeechToTextPlugin") as Class<out io.flutter.embedding.engine.plugins.FlutterPlugin>
            val plugin = flutterEngine?.plugins?.get(pluginClass)
            if (plugin != null) {
                val recognizerField = pluginClass.getDeclaredField("speechRecognizer")
                recognizerField.isAccessible = true
                val recognizer = recognizerField.get(plugin) as? SpeechRecognizer
                recognizer?.let {
                    Log.d("MainActivity", "Destroying stale SpeechRecognizer on lifecycle transition")
                    it.destroy()
                }
                recognizerField.set(plugin, null)

                val lastOnDeviceField = pluginClass.getDeclaredField("lastOnDevice")
                lastOnDeviceField.isAccessible = true
                lastOnDeviceField.set(plugin, false)

                val listeningField = pluginClass.getDeclaredField("listening")
                listeningField.isAccessible = true
                listeningField.set(plugin, false)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "forceResetSpeechRecognizer warning: ${e.message}")
            false
        }
    }
}
