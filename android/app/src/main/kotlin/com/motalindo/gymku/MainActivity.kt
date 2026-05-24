package com.motalindo.gymku

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.motalindo.gymku/hce"
    private var methodChannel: MethodChannel? = null

    private val hceReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            runOnUiThread {
                methodChannel?.invokeMethod("onHceTapped", null)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val flutterEngineInstance = flutterEngine ?: return
        methodChannel = MethodChannel(flutterEngineInstance.dartExecutor.binaryMessenger, CHANNEL)
        
        val filter = IntentFilter("com.motalindo.gymku.HCE_TAP")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(hceReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(hceReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(hceReceiver)
        } catch (e: Exception) {
            // Ignore
        }
    }
}
