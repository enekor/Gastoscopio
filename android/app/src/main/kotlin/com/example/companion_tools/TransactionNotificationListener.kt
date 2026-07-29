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
import org.json.JSONArray

class TransactionNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "TxnNotifListener"
        private const val DB_NAME = "cashly_database.db"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val PREF_ALLOWED_APPS = "flutter.notification_allowed_apps"
        private const val PREF_ALLOWED_APPS_CREDIT = "flutter.notification_allowed_apps_credit"

        // Matches: €12.50, 12,50€, $100, 100$, € 12.50, 12.50 €, etc.
        private val CURRENCY_REGEX = Pattern.compile(
            """(?:[$€]\s?)(\d+(?:[.,]\d{1,2})?)|(\d+(?:[.,]\d{1,2})?)\s?(?:[$€])"""
        )
    }

    private fun getAllowedApps(prefKey: String): Set<String> {
        return try {
            val prefs = applicationContext.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            // Flutter shared_preferences stores StringList as a JSON array string, prefixed with a specific phrase
            var jsonStr = prefs.getString(prefKey, null) ?: return emptySet()
            Log.d(TAG, "Reading prefs for $prefKey: $jsonStr")
            val jsonArray = JSONArray(jsonStr)
            val result = mutableSetOf<String>()
            for (i in 0 until jsonArray.length()) {
                result.add(jsonArray.getString(i))
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Error reading allowed apps for $prefKey", e)
            emptySet()
        }
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

            // Only process notifications from user-allowed apps
            val allowedApps = getAllowedApps(PREF_ALLOWED_APPS)
            val allowedCreditApps = getAllowedApps(PREF_ALLOWED_APPS_CREDIT)

            val isInNormal = allowedApps.contains(packageName)
            val isInCredit = allowedCreditApps.contains(packageName)

            if (!isInNormal && !isInCredit) {
                Log.d(TAG, "App not in allowed lists: $packageName, skipping")
                return
            }

            Log.d(TAG, "Notification from $packageName: $fullText")

            // Check for currency symbols
            if (!fullText.contains("€") && !fullText.contains("$")) return

            val amount = extractAmount(fullText) ?: return
            if (amount <= 0) return

            Log.d(TAG, "Extracted amount: $amount from $packageName")

            if (isInNormal) {
                insertPendingMovement(fullText, packageName, amount, false)
            }
            
            if (isInCredit) {
                insertPendingMovement(fullText, packageName, amount, true)
            }
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

    private fun insertPendingMovement(text: String, appName: String, amount: Double, isCreditCard: Boolean) {
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

            // Check if isCreditCard column exists to avoid crash if migration hasn't run yet
            val hasCreditColumn = columnExists(db, "PendingNotificationMovement", "isCreditCard")

            val query = if (hasCreditColumn) {
                "SELECT COUNT(*) FROM PendingNotificationMovement WHERE notificationText = ? AND appName = ? AND isCreditCard = ? AND timestamp > ?"
            } else {
                "SELECT COUNT(*) FROM PendingNotificationMovement WHERE notificationText = ? AND appName = ? AND timestamp > ?"
            }

            val queryArgs = if (hasCreditColumn) {
                arrayOf(text, appName, if (isCreditCard) "1" else "0", oneMinuteAgo)
            } else {
                arrayOf(text, appName, oneMinuteAgo)
            }

            val cursor = db.rawQuery(query, queryArgs)
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
                if (hasCreditColumn) {
                    put("isCreditCard", if (isCreditCard) 1 else 0)
                }
            }

            db.insert("PendingNotificationMovement", null, values)
            Log.d(TAG, "Saved pending movement: $amount from $appName (credit: $isCreditCard, colExists: $hasCreditColumn)")
        } catch (e: Exception) {
            Log.e(TAG, "Error inserting pending movement", e)
        } finally {
            db?.close()
        }
    }

    private fun columnExists(db: SQLiteDatabase, tableName: String, columnName: String): Boolean {
        var cursor: android.database.Cursor? = null
        return try {
            cursor = db.rawQuery("PRAGMA table_info($tableName)", null)
            val nameIndex = cursor.getColumnIndex("name")
            var exists = false
            while (cursor.moveToNext()) {
                if (columnName == cursor.getString(nameIndex)) {
                    exists = true
                    break
                }
            }
            exists
        } catch (e: Exception) {
            false
        } finally {
            cursor?.close()
        }
    }
}
