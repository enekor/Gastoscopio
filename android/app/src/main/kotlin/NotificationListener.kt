package com.N3k0chan.gastocopio

import android.content.Context
import android.content.pm.PackageManager
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationListener : NotificationListenerService() {

    private val TAG = "NotificationListener"
    private lateinit var dbHelper: NotificationDBHelper

    override fun onCreate() {
        super.onCreate()
        dbHelper = NotificationDBHelper(this)
        Log.d(TAG, "NotificationListener service created")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListener connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "NotificationListener disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)

        sbn?.let { notification ->
            try {
                val packageName = notification.packageName
                val title = notification.notification.extras.getString("android.title") ?: ""
                val content = notification.notification.extras.getString("android.text") ?: ""

                Log.d(TAG, "Notification received from: $packageName")
                Log.d(TAG, "Title: $title")
                Log.d(TAG, "Content: $content")

                val notText = isFinancialNotification(title, content)
                if (notText != null) {
                    Log.d(TAG, "Financial notification detected!")
                    val appName = getAppNameFromPackage(packageName)
                    processAndSaveNotification(appName, notText)
                } else {
                    Log.d(TAG, "Not a financial notification, ignoring")
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error processing notification", e)
            }
        }
    }

    private fun isFinancialNotification(title: String, content: String): String? {
        val keywords = listOf("€", "eur", "$", "usd", "cop")
        val fullText = "$title - $content".lowercase()
        val isFinancial = keywords.any { fullText.contains(it.lowercase()) }
        return if (isFinancial) fullText else null
    }

    private fun processAndSaveNotification(appName: String, content: String) {
        val splittedContent = content.split(" - ", limit = 2)
        val name = if (splittedContent.isNotEmpty()) splittedContent[0] else appName
        val amount = if (splittedContent.size > 1) getAmount(splittedContent[1]) else ""
        saveToSharedPreferences("$name - $amount")
    }

    private fun saveToSharedPreferences(content: String) {
        val sharedPreferences = applicationContext.getSharedPreferences("APP_PREFS", Context.MODE_PRIVATE)
        val existingNotifications = sharedPreferences.getString("NOTIFICATIONS", "")
        val updatedNotifications = if (existingNotifications.isNullOrEmpty()) {
            "$content |"
        } else {
            existingNotifications + content + " |"
        }
        sharedPreferences.edit().putString("NOTIFICATIONS", updatedNotifications).apply()
    }

    private fun getAmount(content: String): String {
        val regex = Regex("""(?:[€$]\s*([\d.,]+)|([\d.,]+)\s*[€$])""")
        val match = regex.find(content)
        val numberStr = match?.groups?.get(1)?.value ?: match?.groups?.get(2)?.value
        return numberStr ?: ""
    }

    private fun getAppNameFromPackage(packageName: String): String {
        return try {
            val packageManager = applicationContext.packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }
}