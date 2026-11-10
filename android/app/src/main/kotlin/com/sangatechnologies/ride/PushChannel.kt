package com.sangatechnologies.ride

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

object PushChannel {
    const val ID = "sanga_default"

    fun ensure(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val name = context.applicationInfo.loadLabel(context.packageManager)
        manager.createNotificationChannel(NotificationChannel(ID, name, NotificationManager.IMPORTANCE_HIGH))
    }
}
