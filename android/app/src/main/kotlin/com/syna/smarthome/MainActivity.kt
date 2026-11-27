package com.syna.smarthome

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val DIALER_CHANNEL = "com.syna.smarthome/dialer"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIALER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "dial") {
                    val rawNumber = call.argument<String>("number") ?: "115"
                    val number = rawNumber.trim().ifEmpty { "115" }
                    try {
                        val intent = Intent(Intent.ACTION_DIAL).apply {
                            data = Uri.parse("tel:$number")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DIAL_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
