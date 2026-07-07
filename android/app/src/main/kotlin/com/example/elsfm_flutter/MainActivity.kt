package com.example.elsfm_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val plugin = ElsfmPlayerPlugin(applicationContext)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ElsfmPlayerPlugin.METHOD_CHANNEL
        ).setMethodCallHandler(plugin)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ElsfmPlayerPlugin.EVENT_CHANNEL
        ).setStreamHandler(plugin)
    }
}
