package com.decisioncompass.decision_compass

import android.os.Build
import android.os.Bundle
import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.StoreBytesData
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                splashScreenView.remove()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "astracue/startup")
            .setMethodCallHandler { call, result ->
                if (call.method == "contentReady") {
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        // Failures answer null: the Dart side then falls back to app storage.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "astracue/block_store")
            .setMethodCallHandler { call, result ->
                val client = Blockstore.getClient(this)
                when (call.method) {
                    "readGuidanceCount" -> client
                        .retrieveBytes(
                            RetrieveBytesRequest.Builder()
                                .setKeys(listOf(GUIDANCE_COUNT_KEY))
                                .build()
                        )
                        .addOnSuccessListener { response ->
                            result.success(
                                response.blockstoreDataMap[GUIDANCE_COUNT_KEY]
                                    ?.bytes
                                    ?.let { String(it).toIntOrNull() }
                            )
                        }
                        .addOnFailureListener { result.success(null) }
                    "writeGuidanceCount" -> {
                        val value = call.arguments as? Int
                        if (value == null) {
                            result.success(null)
                        } else {
                            client
                                .storeBytes(
                                    StoreBytesData.Builder()
                                        .setKey(GUIDANCE_COUNT_KEY)
                                        .setBytes(value.toString().toByteArray())
                                        .setShouldBackupToCloud(true)
                                        .build()
                                )
                                .addOnSuccessListener { result.success(null) }
                                .addOnFailureListener { result.success(null) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val GUIDANCE_COUNT_KEY = "astracue.guidance_reading_count"
    }
}

