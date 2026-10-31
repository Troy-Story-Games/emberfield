package com.troystorygames.emberfield.playback

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.view.View
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class PlaybackCapturePlugin(godot: Godot) : GodotPlugin(godot) {
    private var hostActivity: Activity? = null

    override fun onMainCreate(activity: Activity?): View? {
        hostActivity = activity
        return null
    }
    override fun getPluginName(): String = "PlaybackCapture"

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        return mutableSetOf(
            SignalInfo("capture_started"),
            SignalInfo("capture_failed", String::class.java),
        )
    }

    @UsedByGodot
    fun is_supported(): Boolean = Build.VERSION.SDK_INT >= 29

    @UsedByGodot
    fun get_sample_rate(): Int = CaptureBridge.sampleRate

    @UsedByGodot
    fun get_status(): String = CaptureBridge.status

    @UsedByGodot
    fun start() {
        val host = hostActivity ?: activity
        if (host == null) {
            fail("Could not open the capture prompt")
            return
        }
        if (Build.VERSION.SDK_INT < 29) {
            fail("Playback capture requires Android 10 or newer")
            return
        }
        CaptureBridge.plugin = this
        CaptureBridge.status = "Waiting for capture"
        // Android 13+ hides the foreground service notification without this permission.
        if (Build.VERSION.SDK_INT >= 33 &&
            host.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            host.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
            return
        }
        openCapturePrompt(host)
    }

    private fun openCapturePrompt(host: Activity) {
        val manager = host.getSystemService(Activity.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        host.startActivityForResult(manager.createScreenCaptureIntent(), REQUEST_CAPTURE)
    }

    override fun onMainRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>?,
        grantResults: IntArray?,
    ) {
        if (requestCode != REQUEST_NOTIFICATIONS) {
            return
        }
        // Continue either way; capture still works if the user declines notifications.
        val host = hostActivity ?: activity ?: return
        openCapturePrompt(host)
    }

    @UsedByGodot
    fun stop() {
        CaptureBridge.running = false
        CaptureBridge.status = "Audio off"
        val host = hostActivity ?: activity ?: return
        host.stopService(Intent(host, PlaybackCaptureService::class.java))
    }

    @UsedByGodot
    fun poll_frames(): FloatArray = CaptureBridge.drain()

    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_CAPTURE) {
            return
        }
        val host = hostActivity ?: activity
        if (host == null || resultCode != Activity.RESULT_OK || data == null) {
            fail("Permission needed")
            return
        }
        val intent = Intent(host, PlaybackCaptureService::class.java)
        intent.putExtra(PlaybackCaptureService.EXTRA_RESULT_CODE, resultCode)
        intent.putExtra(PlaybackCaptureService.EXTRA_DATA, Intent(data))
        if (Build.VERSION.SDK_INT >= 26) {
            host.startForegroundService(intent)
        } else {
            host.startService(intent)
        }
    }

    fun notifyCaptureStarted() {
        emitSignal("capture_started")
    }

    fun notifyCaptureFailed(reason: String) {
        CaptureBridge.status = reason
        emitSignal("capture_failed", reason)
    }

    private fun fail(reason: String) {
        notifyCaptureFailed(reason)
    }

    companion object {
        private const val REQUEST_CAPTURE = 0x5150
        private const val REQUEST_NOTIFICATIONS = 0x5151
    }
}
