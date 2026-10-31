#include "playback_capture.h"

#include <godot_cpp/core/class_db.hpp>

#include <cstring>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <audioclient.h>
#include <ksmedia.h>
#include <mmdeviceapi.h>
#undef ERROR
#undef OK
#undef FAILED
#undef SUCCEEDED
#undef interface
static bool hr_failed(HRESULT value) {
	return value < 0;
}
static bool hr_ok(HRESULT value) {
	return value >= 0;
}
#endif

using namespace godot;

PlaybackCapture *PlaybackCapture::singleton = nullptr;

void PlaybackCapture::_bind_methods() {
	ClassDB::bind_method(D_METHOD("is_supported"), &PlaybackCapture::is_supported);
	ClassDB::bind_method(D_METHOD("start"), &PlaybackCapture::start);
	ClassDB::bind_method(D_METHOD("stop"), &PlaybackCapture::stop);
	ClassDB::bind_method(D_METHOD("get_sample_rate"), &PlaybackCapture::get_sample_rate);
	ClassDB::bind_method(D_METHOD("poll_frames"), &PlaybackCapture::poll_frames);
	ClassDB::bind_method(D_METHOD("get_status"), &PlaybackCapture::get_status);
	ADD_SIGNAL(MethodInfo("capture_started"));
	ADD_SIGNAL(MethodInfo("capture_failed", PropertyInfo(Variant::STRING, "reason")));
}

PlaybackCapture *PlaybackCapture::get_singleton() {
	return singleton;
}

PlaybackCapture::PlaybackCapture() {
	singleton = this;
}

PlaybackCapture::~PlaybackCapture() {
	stop();
	if (singleton == this) {
		singleton = nullptr;
	}
}

bool PlaybackCapture::is_supported() const {
#ifdef _WIN32
	return true;
#else
	return false;
#endif
}

void PlaybackCapture::set_status(const std::string &text) {
	std::lock_guard<std::mutex> lock(mutex);
	status_text = text;
}

String PlaybackCapture::get_status() const {
	std::lock_guard<std::mutex> lock(mutex);
	return String(status_text.c_str());
}

int PlaybackCapture::get_sample_rate() const {
	std::lock_guard<std::mutex> lock(mutex);
	return sample_rate;
}

void PlaybackCapture::pump_events() {
	const int event = pending_event.exchange(0);
	if (event == 1) {
		emit_signal("capture_started");
	} else if (event == 2) {
		emit_signal("capture_failed", get_status());
	}
}

PackedFloat32Array PlaybackCapture::poll_frames() {
	pump_events();
	std::lock_guard<std::mutex> lock(mutex);
	PackedFloat32Array out;
	if (pending.empty()) {
		return out;
	}
	out.resize((int64_t)pending.size());
	std::memcpy(out.ptrw(), pending.data(), pending.size() * sizeof(float));
	pending.clear();
	return out;
}

void PlaybackCapture::start() {
	stop();
#ifdef _WIN32
	set_status("Waiting for capture");
	running.store(true);
	worker = std::thread(&PlaybackCapture::thread_main, this);
#else
	set_status("Playback unavailable");
#endif
}

void PlaybackCapture::stop() {
	running.store(false);
	if (worker.joinable()) {
		worker.join();
	}
	pending_event.store(0);
	std::lock_guard<std::mutex> lock(mutex);
	pending.clear();
	sample_rate = 0;
	status_text = "Audio off";
}

#ifdef _WIN32

static void append_samples(std::mutex &mutex, std::vector<float> &pending, const BYTE *data, UINT32 frames, bool silent, bool is_float, int channels, int bits, int block) {
	std::vector<float> chunk;
	chunk.reserve((size_t)frames * 2);
	for (UINT32 i = 0; i < frames; ++i) {
		float left = 0.0f;
		float right = 0.0f;
		if (!silent && data != nullptr) {
			const BYTE *sample = data + (size_t)i * (size_t)block;
			if (is_float) {
				const float *src = reinterpret_cast<const float *>(sample);
				left = src[0];
				right = channels > 1 ? src[1] : left;
			} else if (bits == 16) {
				const int16_t *src = reinterpret_cast<const int16_t *>(sample);
				left = src[0] / 32768.0f;
				right = channels > 1 ? src[1] / 32768.0f : left;
			} else if (bits == 32) {
				const int32_t *src = reinterpret_cast<const int32_t *>(sample);
				left = src[0] / 2147483648.0f;
				right = channels > 1 ? src[1] / 2147483648.0f : left;
			}
		}
		chunk.push_back(left);
		chunk.push_back(right);
	}
	std::lock_guard<std::mutex> lock(mutex);
	pending.insert(pending.end(), chunk.begin(), chunk.end());
	const size_t cap = 24000;
	if (pending.size() > cap) {
		pending.erase(pending.begin(), pending.end() - (std::ptrdiff_t)cap);
	}
}

static void release_all(IMMDeviceEnumerator *enumerator, IMMDevice *device, IAudioClient *client, IAudioCaptureClient *capture, WAVEFORMATEX *mix, HANDLE event) {
	if (capture != nullptr) {
		capture->Release();
	}
	if (client != nullptr) {
		client->Release();
	}
	if (device != nullptr) {
		device->Release();
	}
	if (enumerator != nullptr) {
		enumerator->Release();
	}
	if (mix != nullptr) {
		CoTaskMemFree(mix);
	}
	if (event != nullptr) {
		CloseHandle(event);
	}
}

// Returns true when the default device changed and the caller should reopen.
static bool read_session(std::atomic<bool> &running, std::atomic<int> &pending_event, std::mutex &mutex, std::vector<float> &pending, int &sample_rate, std::string &status_text) {
	IMMDeviceEnumerator *enumerator = nullptr;
	HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, __uuidof(IMMDeviceEnumerator), (void **)&enumerator);
	if (hr_failed(hr) || enumerator == nullptr) {
		return false;
	}

	IMMDevice *device = nullptr;
	hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
	if (hr_failed(hr) || device == nullptr) {
		enumerator->Release();
		return false;
	}

	LPWSTR id = nullptr;
	device->GetId(&id);
	std::wstring opened_id = id != nullptr ? id : L"";
	if (id != nullptr) {
		CoTaskMemFree(id);
	}

	IAudioClient *client = nullptr;
	hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, (void **)&client);
	if (hr_failed(hr) || client == nullptr) {
		device->Release();
		enumerator->Release();
		return false;
	}

	WAVEFORMATEX *mix = nullptr;
	hr = client->GetMixFormat(&mix);
	if (hr_failed(hr) || mix == nullptr) {
		client->Release();
		device->Release();
		enumerator->Release();
		return false;
	}

	bool is_float = mix->wFormatTag == WAVE_FORMAT_IEEE_FLOAT;
	if (mix->wFormatTag == WAVE_FORMAT_EXTENSIBLE) {
		auto *ext = reinterpret_cast<WAVEFORMATEXTENSIBLE *>(mix);
		is_float = ext->SubFormat == KSDATAFORMAT_SUBTYPE_IEEE_FLOAT;
		if (!is_float && ext->SubFormat != KSDATAFORMAT_SUBTYPE_PCM) {
			release_all(enumerator, device, client, nullptr, mix, nullptr);
			return false;
		}
	} else if (mix->wFormatTag != WAVE_FORMAT_IEEE_FLOAT && mix->wFormatTag != WAVE_FORMAT_PCM) {
		release_all(enumerator, device, client, nullptr, mix, nullptr);
		return false;
	}

	HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
	DWORD stream_flags = AUDCLNT_STREAMFLAGS_LOOPBACK | AUDCLNT_STREAMFLAGS_EVENTCALLBACK;
	hr = client->Initialize(AUDCLNT_SHAREMODE_SHARED, stream_flags, 200000, 0, mix, nullptr);
	if (hr_failed(hr)) {
		// Initialize can be called once per client, so a failed loopback event mode needs a new client.
		client->Release();
		client = nullptr;
		hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, (void **)&client);
		stream_flags = AUDCLNT_STREAMFLAGS_LOOPBACK;
		if (hr_ok(hr) && client != nullptr) {
			hr = client->Initialize(AUDCLNT_SHAREMODE_SHARED, stream_flags, 200000, 0, mix, nullptr);
		}
	}
	if (hr_failed(hr)) {
		release_all(enumerator, device, client, nullptr, mix, event);
		return false;
	}
	if ((stream_flags & AUDCLNT_STREAMFLAGS_EVENTCALLBACK) != 0 && event != nullptr) {
		client->SetEventHandle(event);
	}

	IAudioCaptureClient *capture = nullptr;
	hr = client->GetService(__uuidof(IAudioCaptureClient), (void **)&capture);
	if (hr_failed(hr) || capture == nullptr) {
		release_all(enumerator, device, client, capture, mix, event);
		return false;
	}
	hr = client->Start();
	if (hr_failed(hr)) {
		release_all(enumerator, device, client, capture, mix, event);
		return false;
	}

	{
		std::lock_guard<std::mutex> lock(mutex);
		sample_rate = (int)mix->nSamplesPerSec;
		status_text = "Capturing";
	}
	pending_event.store(1);

	const int channels = mix->nChannels;
	const int bits = mix->wBitsPerSample;
	const int block = mix->nBlockAlign;
	ULONGLONG last_check = GetTickCount64();
	bool reopen = false;
	bool failed = false;

	while (running.load()) {
		if (event != nullptr && (stream_flags & AUDCLNT_STREAMFLAGS_EVENTCALLBACK) != 0) {
			WaitForSingleObject(event, 50);
		} else {
			Sleep(10);
		}

		UINT32 packet = 0;
		hr = capture->GetNextPacketSize(&packet);
		if (hr == AUDCLNT_E_DEVICE_INVALIDATED) {
			reopen = true;
			break;
		}
		if (hr_failed(hr)) {
			failed = true;
			break;
		}

		while (packet > 0 && running.load()) {
			BYTE *data = nullptr;
			UINT32 frames = 0;
			DWORD packet_flags = 0;
			hr = capture->GetBuffer(&data, &frames, &packet_flags, nullptr, nullptr);
			if (hr == AUDCLNT_E_DEVICE_INVALIDATED) {
				reopen = true;
				break;
			}
			if (hr_failed(hr)) {
				failed = true;
				break;
			}
			const bool silent = (packet_flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0;
			append_samples(mutex, pending, data, frames, silent, is_float, channels, bits, block);
			capture->ReleaseBuffer(frames);
			hr = capture->GetNextPacketSize(&packet);
			if (hr == AUDCLNT_E_DEVICE_INVALIDATED) {
				reopen = true;
				break;
			}
			if (hr_failed(hr)) {
				failed = true;
				packet = 0;
			}
		}
		if (reopen || failed) {
			break;
		}

		const ULONGLONG now = GetTickCount64();
		if (now - last_check > 1000) {
			last_check = now;
			IMMDevice *current = nullptr;
			if (hr_ok(enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &current)) && current != nullptr) {
				LPWSTR current_id = nullptr;
				current->GetId(&current_id);
				std::wstring now_id = current_id != nullptr ? current_id : L"";
				if (current_id != nullptr) {
					CoTaskMemFree(current_id);
				}
				current->Release();
				if (now_id != opened_id) {
					reopen = true;
					break;
				}
			}
		}
	}

	client->Stop();
	release_all(enumerator, device, client, capture, mix, event);
	return reopen && running.load() && !failed;
}

void PlaybackCapture::thread_main() {
	const HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
	const bool should_uninit = hr_ok(hr);
	if (hr_failed(hr) && hr != RPC_E_CHANGED_MODE) {
		set_status("Could not open the playback device");
		running.store(false);
		return;
	}

	while (running.load()) {
		const bool again = read_session(running, pending_event, mutex, pending, sample_rate, status_text);
		if (!again) {
			if (running.load()) {
				set_status("Could not open the playback device");
				pending_event.store(2);
				running.store(false);
			}
			break;
		}
	}

	if (should_uninit) {
		CoUninitialize();
	}
}

#else

void PlaybackCapture::thread_main() {
}

#endif
