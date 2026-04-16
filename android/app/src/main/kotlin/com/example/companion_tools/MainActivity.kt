package com.N3k0chan.cashly

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.ByteArrayOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.N3k0chan.cashly/settings"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge
        WindowCompat.setDecorFitsSystemWindows(window, false)

        super.onCreate(savedInstanceState)

        // Use WindowInsetsControllerCompat for modern system UI control
        val windowInsetsController = WindowInsetsControllerCompat(window, window.decorView)
        windowInsetsController.isAppearanceLightNavigationBars = true
        windowInsetsController.isAppearanceLightStatusBars = true

        // Set up edge-to-edge behavior
        ViewCompat.setOnApplyWindowInsetsListener(window.decorView) { view, windowInsets ->
            val insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPadding(insets.left, 0, insets.right, 0)
            WindowInsetsCompat.CONSUMED
        }

        // Configurar solo para ocultar la barra de navegación
        window.decorView.post {
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationListenerSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    finishAndRemoveTask()
                    result.success(true)
                }
                "getInstalledApps" -> {
                    try {
                        val pm = packageManager
                        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                            .filter { app ->
                                // Only show apps with a launcher intent (user-visible apps)
                                pm.getLaunchIntentForPackage(app.packageName) != null
                            }
                            .map { app ->
                                mapOf(
                                    "packageName" to app.packageName,
                                    "appName" to pm.getApplicationLabel(app).toString()
                                )
                            }
                            .sortedBy { it["appName"]?.lowercase() }
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get installed apps: ${e.message}", null)
                    }
                }
                "getAppName" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("ERROR", "packageName required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val pm = packageManager
                        val appInfo = pm.getApplicationInfo(packageName, 0)
                        result.success(pm.getApplicationLabel(appInfo).toString())
                    } catch (e: PackageManager.NameNotFoundException) {
                        result.success(packageName)
                    }
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("ERROR", "packageName required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val pm = packageManager
                        val drawable = pm.getApplicationIcon(packageName)
                        val bitmap = if (drawable is BitmapDrawable) {
                            drawable.bitmap
                        } else {
                            val bmp = Bitmap.createBitmap(
                                drawable.intrinsicWidth.coerceAtLeast(1),
                                drawable.intrinsicHeight.coerceAtLeast(1),
                                Bitmap.Config.ARGB_8888
                            )
                            val canvas = Canvas(bmp)
                            drawable.setBounds(0, 0, canvas.width, canvas.height)
                            drawable.draw(canvas)
                            bmp
                        }
                        val stream = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                        result.success(stream.toByteArray())
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get app icon: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
