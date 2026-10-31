@tool
extends EditorExportPlugin

const PLUGIN_DIR := "res://android/plugins/playback_capture"
const AAR_PATH := "res://android/plugins/playback_capture/bin/playback_capture.aar"


func _get_name() -> String:
	return "PlaybackCaptureAar"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid


func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	if not FileAccess.file_exists(AAR_PATH):
		_build_aar()
	if not FileAccess.file_exists(AAR_PATH):
		return PackedStringArray()
	return PackedStringArray([AAR_PATH])


func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
	return '<meta-data tools:node="replace" android:name="org.godotengine.plugin.v2.PlaybackCapture" android:value="com.troystorygames.emberfield.playback.PlaybackCapturePlugin" />'


func _export_file(path: String, _type: String, features: PackedStringArray) -> void:
	if features.has("android") and path.begins_with("res://native/playback_capture/"):
		skip()


func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	if not features.has("android"):
		return
	if FileAccess.file_exists(AAR_PATH):
		return
	if _build_aar() != OK:
		push_error("Playback capture AAR is missing, so Android export will not include playback capture.")


func _build_aar() -> Error:
	var root := ProjectSettings.globalize_path(PLUGIN_DIR)
	if not _apply_android_env():
		return ERR_UNCONFIGURED
	var gradlew := root.path_join("gradlew.bat" if OS.get_name() == "Windows" else "gradlew")
	if not FileAccess.file_exists(gradlew):
		push_error("Missing Gradle wrapper at %s" % gradlew)
		return ERR_FILE_NOT_FOUND
	print("Building playback capture AAR...")
	var output: Array = []
	var code := -1
	if OS.get_name() == "Windows":
		code = OS.execute("cmd", ["/d", "/c", "cd /d \"%s\" && gradlew.bat assembleRelease" % root], output, true, false)
	else:
		code = OS.execute("sh", ["-c", "cd \"%s\" && ./gradlew assembleRelease" % root], output, true, false)
	for line in output:
		print(line)
	if code != 0 or not FileAccess.file_exists(AAR_PATH):
		push_error("gradle assembleRelease failed (exit %s)." % code)
		return FAILED
	print("Playback capture AAR ready.")
	return OK


func _apply_android_env() -> bool:
	var settings := EditorInterface.get_editor_settings()
	var sdk := str(settings.get_setting("export/android/android_sdk_path")).strip_edges()
	var java := str(settings.get_setting("export/android/java_sdk_path")).strip_edges()
	if sdk.is_empty():
		sdk = OS.get_environment("ANDROID_HOME")
	if sdk.is_empty():
		push_error("Set Editor Settings → Export → Android → Android SDK Path before exporting.")
		return false
	if java.is_empty():
		java = OS.get_environment("JAVA_HOME")
	if not java.is_empty():
		OS.set_environment("JAVA_HOME", java)
	OS.set_environment("ANDROID_HOME", sdk)
	OS.set_environment("ANDROID_SDK_ROOT", sdk)
	return true
