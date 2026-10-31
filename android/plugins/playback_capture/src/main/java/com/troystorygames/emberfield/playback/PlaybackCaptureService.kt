package com.troystorygames.emberfield.playback

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log

class PlaybackCaptureService : Service() {
    private var projection: MediaProjection? = null
    private var recorder: AudioRecord? = null
    private var reader: Thread? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()
        try {
            if (Build.VERSION.SDK_INT >= 29) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (error: Exception) {
            fail("Permission needed")
            stopSelf()
            return START_NOT_STICKY
        }

        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, 0) ?: 0
        val data = if (Build.VERSION.SDK_INT >= 33) {
            intent?.getParcelableExtra(EXTRA_DATA, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent?.getParcelableExtra(EXTRA_DATA)
        }
        if (resultCode == 0 || data == null) {
            fail("Permission needed")
            stopSelf()
            return START_NOT_STICKY
        }

        val manager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val mediaProjection = try {
            manager.getMediaProjection(resultCode, data)
        } catch (error: Exception) {
            Log.w(TAG, "getMediaProjection failed", error)
            null
        }
        if (mediaProjection == null) {
            fail("Capture blocked")
            stopSelf()
            return START_NOT_STICKY
        }
        projection = mediaProjection
        mediaProjection.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                stopCapture()
            }
        }, Handler(Looper.getMainLooper()))

        if (!startRecording(mediaProjection)) {
            fail("Capture blocked")
            stopSelf()
            return START_NOT_STICKY
        }
        CaptureBridge.status = "Capturing"
        emitStarted()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopCapture()
        super.onDestroy()
    }

    private fun startRecording(mediaProjection: MediaProjection): Boolean {
        if (Build.VERSION.SDK_INT < 29) {
            return false
        }
        return startPlaybackRecord(mediaProjection)
    }

    @android.annotation.TargetApi(29)
    private fun startPlaybackRecord(mediaProjection: MediaProjection): Boolean {
        val rate = 48000
        val channel = AudioFormat.CHANNEL_IN_STEREO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        val minBuffer = AudioRecord.getMinBufferSize(rate, channel, encoding)
        if (minBuffer <= 0) {
            return false
        }
        val config = AudioPlaybackCaptureConfiguration.Builder(mediaProjection)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
            .build()
        val format = AudioFormat.Builder()
            .setEncoding(encoding)
            .setSampleRate(rate)
            .setChannelMask(channel)
            .build()
        val record = try {
            AudioRecord.Builder()
                .setAudioPlaybackCaptureConfig(config)
                .setAudioFormat(format)
                .setBufferSizeInBytes(minBuffer * 2)
                .build()
        } catch (error: SecurityException) {
            Log.w(TAG, "playback capture blocked", error)
            return false
        } catch (error: UnsupportedOperationException) {
            Log.w(TAG, "playback capture unsupported", error)
            return false
        }
        if (record.state != AudioRecord.STATE_INITIALIZED) {
            record.release()
            return false
        }
        recorder = record
        CaptureBridge.sampleRate = rate
        CaptureBridge.running = true
        record.startRecording()
        val thread = Thread {
            val shorts = ShortArray(minBuffer)
            val floats = FloatArray(minBuffer)
            while (CaptureBridge.running) {
                val count = record.read(shorts, 0, shorts.size)
                if (count > 0) {
                    for (i in 0 until count) {
                        floats[i] = shorts[i] / 32768.0f
                    }
                    CaptureBridge.append(floats, count)
                } else if (count < 0) {
                    break
                }
            }
        }
        thread.name = "PlaybackCapture"
        reader = thread
        thread.start()
        return true
    }

    private fun stopCapture() {
        CaptureBridge.running = false
        val thread = reader
        reader = null
        try {
            thread?.join(500)
        } catch (_: InterruptedException) {
        }
        try {
            recorder?.stop()
        } catch (_: IllegalStateException) {
        }
        recorder?.release()
        recorder = null
        projection?.stop()
        projection = null
        if (CaptureBridge.status == "Capturing") {
            CaptureBridge.status = "Audio off"
        }
    }

    private fun fail(reason: String) {
        CaptureBridge.status = reason
        emitFailed(reason)
    }

    private fun emitStarted() {
        Handler(Looper.getMainLooper()).post {
            CaptureBridge.plugin?.notifyCaptureStarted()
        }
    }

    private fun emitFailed(reason: String) {
        Handler(Looper.getMainLooper()).post {
            CaptureBridge.plugin?.notifyCaptureFailed(reason)
        }
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel(CHANNEL_ID, "Playback capture", NotificationManager.IMPORTANCE_LOW)
            channel.setSound(null, null)
            manager.createNotificationChannel(channel)
        }
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("Visualizing playback")
            .setContentText("Emberfield is visualizing audio from other apps")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .build()
    }

    companion object {
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_DATA = "result_data"
        private const val CHANNEL_ID = "playback_capture"
        private const val NOTIFICATION_ID = 5150
        private const val TAG = "PlaybackCapture"
    }
}
