package com.troystorygames.emberfield.playback

object CaptureBridge {
    @Volatile var plugin: PlaybackCapturePlugin? = null
    @Volatile var status: String = "Audio off"
    @Volatile var sampleRate: Int = 0
    @Volatile var running: Boolean = false

    // Interleaved stereo samples. Oldest samples are dropped when Godot falls behind,
    // which keeps the visualizer on the most recent audio.
    private const val CAPACITY = 24000
    private val lock = Any()
    private val ring = FloatArray(CAPACITY)
    private var head = 0
    private var size = 0

    fun append(frames: FloatArray, count: Int = frames.size) {
        synchronized(lock) {
            var start = 0
            var n = count
            if (n > CAPACITY) {
                start = n - CAPACITY
                n = CAPACITY
            }
            val overflow = size + n - CAPACITY
            if (overflow > 0) {
                head = (head + overflow) % CAPACITY
                size -= overflow
            }
            var tail = (head + size) % CAPACITY
            for (i in start until start + n) {
                ring[tail] = frames[i]
                tail = if (tail + 1 == CAPACITY) 0 else tail + 1
            }
            size += n
        }
    }

    fun drain(): FloatArray {
        synchronized(lock) {
            val out = FloatArray(size)
            val first = minOf(size, CAPACITY - head)
            System.arraycopy(ring, head, out, 0, first)
            System.arraycopy(ring, 0, out, first, size - first)
            head = 0
            size = 0
            return out
        }
    }
}
