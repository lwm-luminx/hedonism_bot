package host.lumiere.chip.location

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import host.lumiere.chip.ChipApplication
import host.lumiere.chip.MainActivity
import host.lumiere.chip.R
import host.lumiere.chip.core.LocationSample

/**
 * Records the shoot's location while Chip is in the background, with an ongoing notification, the
 * Android counterpart of iOS background location updates. Started only from the visible app after
 * the person grants location access, so it needs no background-location permission.
 */
class LocationRecordingService : Service(), LocationListener {
    private val recorder get() = (application as ChipApplication).locationRecorder
    private var manager: LocationManager? = null

    override fun onBind(intent: Intent?): IBinder? = null

    @SuppressLint("MissingPermission")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            recorder.stop()
            stopSelf()
            return START_NOT_STICKY
        }
        ServiceCompat.startForeground(this, NOTIFICATION_ID, notification(),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION else 0)
        val locationManager = getSystemService(LocationManager::class.java)
        manager = locationManager
        try {
            for (provider in listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)) {
                if (locationManager.isProviderEnabled(provider)) {
                    locationManager.requestLocationUpdates(provider, 5_000L, 20f, this, Looper.getMainLooper())
                }
            }
            recorder.start()
        } catch (e: SecurityException) {
            recorder.setStatus("Location permission is unavailable. Enable it in Settings to record.")
            stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onLocationChanged(location: Location) {
        recorder.add(LocationSample(location.time, location.latitude, location.longitude,
            if (location.hasAccuracy()) location.accuracy.toDouble() else -1.0))
    }

    override fun onDestroy() {
        manager?.removeUpdates(this)
        recorder.stop()
        super.onDestroy()
    }

    private fun notification(): Notification {
        val channels = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            channels.createNotificationChannel(NotificationChannel(CHANNEL, getString(R.string.location_channel), NotificationManager.IMPORTANCE_LOW))
        }
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val stop = PendingIntent.getService(this, 1, Intent(this, LocationRecordingService::class.java).setAction(ACTION_STOP), PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_chip)
            .setContentTitle(getString(R.string.location_notification))
            .setContentText("Stop when your shoot ends.")
            .setOngoing(true)
            .setContentIntent(open)
            .addAction(0, "Stop", stop)
            .build()
    }

    companion object {
        private const val CHANNEL = "location"
        private const val NOTIFICATION_ID = 1
        private const val ACTION_STOP = "host.lumiere.chip.STOP_LOCATION"

        fun start(context: Context) = ContextCompat.startForegroundService(context, Intent(context, LocationRecordingService::class.java))
        fun stop(context: Context) { context.stopService(Intent(context, LocationRecordingService::class.java)) }
    }
}
