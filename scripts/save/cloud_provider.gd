extends RefCounted
## CloudProvider — preload (res://scripts/save/cloud_provider.gd).
##
## SB-M43-153/156 provider-neutral cloud-save seam (owner 2026-10-22: Android Google Play Games
## Saved Games, iOS Game Center + iCloud; no own server, no separate login). This base class IS
## the shipping default (the null provider): no account service, nothing is ever read or
## written, so CloudSaveService stays signed_out and the local save is the only copy.
##
## Contract for a real provider (and test doubles). Callbacks may run synchronously or later:
##   is_available() -> bool          the platform account service exists on this device
##   is_signed_in() -> bool          the player is signed in to it
##   sign_in(deliver) -> bool        start the PLATFORM sign-in UI (never our own);
##       deliver.call({"ok": bool, "reason"})
##   read(deliver) -> bool           deliver.call({"ok": true, "data": String}) ("" = no cloud
##       copy yet) or {"ok": false, "reason": "offline" | <error>}
##   write(data, deliver) -> bool    store `data` (JSON text) as THE one cloud copy;
##       deliver.call({"ok": true} | {"ok": false, "reason": "offline" | <error>})

func is_available() -> bool:
	return false

func is_signed_in() -> bool:
	return false

func sign_in(_deliver: Callable) -> bool:
	return false

func read(_deliver: Callable) -> bool:
	return false

func write(_data: String, _deliver: Callable) -> bool:
	return false
