package com.N3k0chan.cashly

import android.content.ContentValues
import android.database.sqlite.SQLiteDatabase
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.regex.Pattern

class TransactionNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "TxnNotifListener"
        private const val DB_NAME = "cashly_database.db"

        // Matches: €12.50, 12,50€, $100, 100$, € 12.50, 12.50 €, etc.
        private val CURRENCY_REGEX = Pattern.compile(
            """(?:[$€]\s?)(\d+(?:[.,]\d{1,2})?)|(\d+(?:[.,]\d{1,2})?)\s?(?:[$€])"""
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        try {
            val extras = sbn.notification.extras
            val title = extras?.getCharSequence("android.title")?.toString() ?: ""
            val text = extras?.getCharSequence("android.text")?.toString() ?: ""
            val fullText = "$title $text".trim()
            val packageName = sbn.packageName ?: "Unknown"

            // Skip own notifications
            if (packageName == applicationContext.packageName) return

            Log.d(TAG, "Notification from $packageName: $fullText")

            // Check for currency symbols
            if (!fullText.contains("€") && !fullText.contains("$")) return

            val amount = extractAmount(fullText) ?: return
            if (amount <= 0) return

            Log.d(TAG, "Extracted amount: $amount from $packageName")

            insertPendingMovement(fullText, packageName, amount)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Not needed
    }

    private fun extractAmount(text: String): Double? {
        val matcher = CURRENCY_REGEX.matcher(text)
        while (matcher.find()) {
            val value = matcher.group(1) ?: matcher.group(2) ?: continue
            val normalized = value.replace(",", ".")
            val parsed = normalized.toDoubleOrNull()
            if (parsed != null && parsed > 0) return parsed
        }
        return null
    }

    private fun insertPendingMovement(text: String, appName: String, amount: Double) {
        var db: SQLiteDatabase? = null
        try {
            val dbPath = applicationContext.getDatabasePath(DB_NAME)

            // Don't try to insert if the database doesn't exist yet (app never opened)
            if (!dbPath.exists()) {
                Log.w(TAG, "Database does not exist yet, skipping")
                return
            }

            db = SQLiteDatabase.openDatabase(
                dbPath.absolutePath,
                null,
                SQLiteDatabase.OPEN_READWRITE
            )

            // Check for duplicates in the last 60 seconds
            val now = Date()
            val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
            val nowStr = isoFormat.format(now)
            val oneMinuteAgo = isoFormat.format(Date(now.time - 60_000))

            val cursor = db.rawQuery(
                "SELECT COUNT(*) FROM PendingNotificationMovement WHERE notificationText = ? AND appName = ? AND timestamp > ?",
                arrayOf(text, appName, oneMinuteAgo)
            )
            cursor.moveToFirst()
            val count = cursor.getInt(0)
            cursor.close()

            if (count > 0) {
                Log.d(TAG, "Duplicate notification, skipping")
                return
            }

            val values = ContentValues().apply {
                put("notificationText", text)
                put("appName", appName)
                put("extractedAmount", amount)
                put("timestamp", nowStr)
            }

            db.insert("PendingNotificationMovement", null, values)
            Log.d(TAG, "Saved pending movement: $amount from $appName")
        } catch (e: Exception) {
            Log.e(TAG, "Error inserting pending movement", e)
        } finally {
            db?.close()
        }
    }
}
