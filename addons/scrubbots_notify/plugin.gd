@tool
extends EditorPlugin
## SB-M43-172 — hands the CI-built ScrubbotsNotify AAR (native/android/scrubbots_notify,
## build_aar.py -> addons/scrubbots_notify/android/scrubbots_notify.aar) to Android exports.
## Android plugins need the Gradle build, so the AAR is added only when the preset enables it;
## the family preset keeps it OFF (docs/RELEASE_BUILDS.md, workflow input local_notifications).
## Not enabled in project.godot: the Android workflow enables it only for that input.

var _export := ExportPlugin.new()

func _enter_tree() -> void:
	add_export_plugin(_export)

func _exit_tree() -> void:
	remove_export_plugin(_export)

class ExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return "ScrubbotsNotify"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	## Paths are relative to res://addons/.
	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if not bool(get_option("gradle_build/use_gradle_build")):
			return PackedStringArray()
		return PackedStringArray(["scrubbots_notify/android/scrubbots_notify.aar"])
