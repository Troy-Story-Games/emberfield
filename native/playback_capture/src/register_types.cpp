#include "register_types.h"

#include "playback_capture.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <gdextension_interface.h>

using namespace godot;

static void initialize_playback_capture(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(PlaybackCapture);
	Engine::get_singleton()->register_singleton("PlaybackCapture", memnew(PlaybackCapture));
}

static void uninitialize_playback_capture(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	if (Engine::get_singleton()->has_singleton("PlaybackCapture")) {
		PlaybackCapture *capture = PlaybackCapture::get_singleton();
		Engine::get_singleton()->unregister_singleton("PlaybackCapture");
		memdelete(capture);
	}
}

extern "C" {

GDExtensionBool GDE_EXPORT playback_capture_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_playback_capture);
	init_obj.register_terminator(uninitialize_playback_capture);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}

}
