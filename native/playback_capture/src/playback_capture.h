#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>

#include <atomic>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace godot {

class PlaybackCapture : public Object {
	GDCLASS(PlaybackCapture, Object)

	static PlaybackCapture *singleton;

protected:
	static void _bind_methods();

public:
	static PlaybackCapture *get_singleton();

	PlaybackCapture();
	~PlaybackCapture();

	bool is_supported() const;
	void start();
	void stop();
	int get_sample_rate() const;
	PackedFloat32Array poll_frames();
	String get_status() const;

private:
	void thread_main();
	void set_status(const std::string &text);

	void pump_events();

	std::thread worker;
	std::atomic<bool> running{ false };
	std::atomic<int> pending_event{ 0 };
	mutable std::mutex mutex;
	std::vector<float> pending;
	std::string status_text = "Audio off";
	int sample_rate = 0;
};

} // namespace godot
