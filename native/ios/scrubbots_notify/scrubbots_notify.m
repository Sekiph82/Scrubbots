// SB-M43-171 / SB-M43-172: iOS GDExtension "ScrubbotsNotify" (plain C GDExtension API, no
// godot-cpp, no third-party code). RefCounted class with the same methods as the Android plugin:
//   notifications_enabled() -> bool        cached UNUserNotificationCenter authorization
//   request_authorization()                the OS prompt (only after the in-game explainer)
//   schedule(title, body, seconds)         one UNTimeIntervalNotificationTrigger, fixed id (replaces)
//   cancel_all()                           pending + delivered reminders
// Built on macos-latest by .github/workflows/ios-ipa.yml (input local_notifications); the
// header comes from `godot --dump-gdextension-interface` of the same Godot version.
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "gdextension_interface.h"

typedef struct { uint8_t opaque[8]; } GDName;  // StringName / String: one pointer

static const char *REQUEST_ID = "scrubbots_reminder";
static int64_t g_status = 0;  // 0 not determined, 1 denied, 2 authorized/provisional/ephemeral
static int g_instance_tag;

static GDExtensionClassLibraryPtr g_lib;
static GDExtensionInterfaceStringNameNewWithUtf8Chars string_name_new;
static GDExtensionInterfaceStringNewWithUtf8Chars string_new;
static GDExtensionInterfaceStringToUtf8Chars string_to_utf8;
static GDExtensionInterfaceClassdbConstructObject2 construct_object;
static GDExtensionInterfaceObjectSetInstance object_set_instance;
static GDExtensionInterfaceClassdbRegisterExtensionClass4 register_class;
static GDExtensionInterfaceClassdbRegisterExtensionClassMethod register_method;
static GDExtensionInterfaceClassdbUnregisterExtensionClass unregister_class;
static GDExtensionInterfaceVariantGetType variant_get_type;
static GDExtensionVariantFromTypeConstructorFunc variant_from_bool;
static GDExtensionTypeFromVariantConstructorFunc int_from_variant;
static GDExtensionTypeFromVariantConstructorFunc string_from_variant;
static GDExtensionPtrDestructor string_destroy;

static GDName g_class, g_parent, g_empty_name;
static GDName g_empty_string;

// ------------------------------------------------------------------ native side ----

static void refresh_status(void) {
	[[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *s) {
		UNAuthorizationStatus st = s.authorizationStatus;
		g_status = st >= UNAuthorizationStatusAuthorized ? 2 : (int64_t)st;
	}];
}

static void native_request(void) {
	[[UNUserNotificationCenter currentNotificationCenter]
			requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
						  completionHandler:^(BOOL granted, NSError *error) { refresh_status(); }];
}

static void native_schedule(const char *title, const char *body, int64_t seconds) {
	UNMutableNotificationContent *c = [UNMutableNotificationContent new];
	c.title = [NSString stringWithUTF8String:title];
	c.body = [NSString stringWithUTF8String:body];
	c.sound = [UNNotificationSound defaultSound];
	UNTimeIntervalNotificationTrigger *t = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:(seconds < 1 ? 1 : seconds) repeats:NO];
	UNNotificationRequest *r = [UNNotificationRequest requestWithIdentifier:@(REQUEST_ID) content:c trigger:t];
	[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:r withCompletionHandler:nil];
}

static void native_cancel_all(void) {
	UNUserNotificationCenter *nc = [UNUserNotificationCenter currentNotificationCenter];
	[nc removeAllPendingNotificationRequests];
	[nc removeAllDeliveredNotifications];
}

// --------------------------------------------------------------- Godot glue ----

// A Godot String copied into a malloc'd UTF-8 buffer (caller frees).
static char *utf8_of(const void *godot_string) {
	GDExtensionInt n = string_to_utf8(godot_string, NULL, 0);
	char *s = malloc((size_t)n + 1);
	string_to_utf8(godot_string, s, n);
	s[n] = 0;
	return s;
}

static void do_schedule(const void *title, const void *body, int64_t seconds) {
	char *t = utf8_of(title);
	char *b = utf8_of(body);
	native_schedule(t, b, seconds);
	free(t);
	free(b);
}

typedef enum { M_ENABLED, M_REQUEST, M_SCHEDULE, M_CANCEL } MethodId;

static void method_call(void *ud, GDExtensionClassInstancePtr inst, const GDExtensionConstVariantPtr *args,
		GDExtensionInt argc, GDExtensionVariantPtr ret, GDExtensionCallError *err) {
	MethodId m = (MethodId)(intptr_t)ud;
	GDExtensionInt want = m == M_SCHEDULE ? 3 : 0;
	err->error = GDEXTENSION_CALL_OK;
	if (argc != want) {
		err->error = argc < want ? GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS : GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;
		err->expected = (int32_t)want;
		return;
	}
	switch (m) {
		case M_ENABLED: {
			GDExtensionBool b = g_status == 2;
			refresh_status();
			variant_from_bool(ret, &b);
			break;
		}
		case M_REQUEST:
			native_request();
			break;
		case M_SCHEDULE: {
			const GDExtensionVariantType types[3] = { GDEXTENSION_VARIANT_TYPE_STRING, GDEXTENSION_VARIANT_TYPE_STRING, GDEXTENSION_VARIANT_TYPE_INT };
			for (int i = 0; i < 3; i++) {
				if (variant_get_type(args[i]) != types[i]) {
					err->error = GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;
					err->argument = i;
					err->expected = types[i];
					return;
				}
			}
			GDName title, body;
			int64_t seconds;
			string_from_variant(&title, (GDExtensionVariantPtr)args[0]);
			string_from_variant(&body, (GDExtensionVariantPtr)args[1]);
			int_from_variant(&seconds, (GDExtensionVariantPtr)args[2]);
			do_schedule(&title, &body, seconds);
			string_destroy(&title);
			string_destroy(&body);
			break;
		}
		case M_CANCEL:
			native_cancel_all();
			break;
	}
}

static void method_ptrcall(void *ud, GDExtensionClassInstancePtr inst, const GDExtensionConstTypePtr *args, GDExtensionTypePtr ret) {
	switch ((MethodId)(intptr_t)ud) {
		case M_ENABLED:
			*(GDExtensionBool *)ret = g_status == 2;
			refresh_status();
			break;
		case M_REQUEST:
			native_request();
			break;
		case M_SCHEDULE:
			do_schedule(args[0], args[1], *(const int64_t *)args[2]);
			break;
		case M_CANCEL:
			native_cancel_all();
			break;
	}
}

static GDExtensionObjectPtr create_instance(void *class_ud, GDExtensionBool notify_postinitialize) {
	GDExtensionObjectPtr o = construct_object(&g_parent);
	object_set_instance(o, &g_class, &g_instance_tag);
	return o;
}

static void free_instance(void *class_ud, GDExtensionClassInstancePtr inst) {}

static GDExtensionPropertyInfo prop(GDExtensionVariantType type, GDName *name) {
	GDExtensionPropertyInfo p = { type, name, &g_empty_name, 0, &g_empty_string, 6 /* PROPERTY_USAGE_DEFAULT */ };
	return p;
}

static void add_method(const char *name, MethodId id, GDExtensionBool returns_bool, uint32_t argc,
		GDExtensionPropertyInfo *args, GDExtensionClassMethodArgumentMetadata *meta) {
	static GDName names[4];
	string_name_new(&names[id], name);
	GDExtensionPropertyInfo ret = prop(GDEXTENSION_VARIANT_TYPE_BOOL, &g_empty_name);
	GDExtensionClassMethodInfo info;
	memset(&info, 0, sizeof(info));
	info.name = &names[id];
	info.method_userdata = (void *)(intptr_t)id;
	info.call_func = method_call;
	info.ptrcall_func = method_ptrcall;
	info.method_flags = GDEXTENSION_METHOD_FLAGS_DEFAULT;
	info.has_return_value = returns_bool;
	info.return_value_info = returns_bool ? &ret : NULL;
	info.argument_count = argc;
	info.arguments_info = args;
	info.arguments_metadata = meta;
	register_method(g_lib, &g_class, &info);
}

static void initialize(void *ud, GDExtensionInitializationLevel level) {
	if (level != GDEXTENSION_INITIALIZATION_SCENE) {
		return;
	}
	string_name_new(&g_class, "ScrubbotsNotify");
	string_name_new(&g_parent, "RefCounted");
	string_name_new(&g_empty_name, "");
	string_new(&g_empty_string, "");
	GDExtensionClassCreationInfo4 ci;
	memset(&ci, 0, sizeof(ci));
	ci.is_exposed = 1;
	ci.create_instance_func = create_instance;
	ci.free_instance_func = free_instance;
	register_class(g_lib, &g_class, &g_parent, &ci);

	static GDName a_title, a_body, a_seconds;
	string_name_new(&a_title, "title");
	string_name_new(&a_body, "body");
	string_name_new(&a_seconds, "seconds");
	GDExtensionPropertyInfo sargs[3] = {
		prop(GDEXTENSION_VARIANT_TYPE_STRING, &a_title),
		prop(GDEXTENSION_VARIANT_TYPE_STRING, &a_body),
		prop(GDEXTENSION_VARIANT_TYPE_INT, &a_seconds),
	};
	GDExtensionClassMethodArgumentMetadata smeta[3] = {
		GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE, GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE,
		GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT64,
	};
	add_method("notifications_enabled", M_ENABLED, 1, 0, NULL, NULL);
	add_method("request_authorization", M_REQUEST, 0, 0, NULL, NULL);
	add_method("schedule", M_SCHEDULE, 0, 3, sargs, smeta);
	add_method("cancel_all", M_CANCEL, 0, 0, NULL, NULL);
	refresh_status();
}

static void deinitialize(void *ud, GDExtensionInitializationLevel level) {
	if (level == GDEXTENSION_INITIALIZATION_SCENE) {
		unregister_class(g_lib, &g_class);
	}
}

__attribute__((visibility("default")))
GDExtensionBool scrubbots_notify_init(GDExtensionInterfaceGetProcAddress gpa, GDExtensionClassLibraryPtr lib, GDExtensionInitialization *init) {
	g_lib = lib;
	string_name_new = (GDExtensionInterfaceStringNameNewWithUtf8Chars)gpa("string_name_new_with_utf8_chars");
	string_new = (GDExtensionInterfaceStringNewWithUtf8Chars)gpa("string_new_with_utf8_chars");
	string_to_utf8 = (GDExtensionInterfaceStringToUtf8Chars)gpa("string_to_utf8_chars");
	construct_object = (GDExtensionInterfaceClassdbConstructObject2)gpa("classdb_construct_object2");
	object_set_instance = (GDExtensionInterfaceObjectSetInstance)gpa("object_set_instance");
	register_class = (GDExtensionInterfaceClassdbRegisterExtensionClass4)gpa("classdb_register_extension_class4");
	register_method = (GDExtensionInterfaceClassdbRegisterExtensionClassMethod)gpa("classdb_register_extension_class_method");
	unregister_class = (GDExtensionInterfaceClassdbUnregisterExtensionClass)gpa("classdb_unregister_extension_class");
	variant_get_type = (GDExtensionInterfaceVariantGetType)gpa("variant_get_type");
	GDExtensionInterfaceGetVariantFromTypeConstructor from_type = (GDExtensionInterfaceGetVariantFromTypeConstructor)gpa("get_variant_from_type_constructor");
	GDExtensionInterfaceGetVariantToTypeConstructor to_type = (GDExtensionInterfaceGetVariantToTypeConstructor)gpa("get_variant_to_type_constructor");
	GDExtensionInterfaceVariantGetPtrDestructor destructor = (GDExtensionInterfaceVariantGetPtrDestructor)gpa("variant_get_ptr_destructor");
	variant_from_bool = from_type(GDEXTENSION_VARIANT_TYPE_BOOL);
	int_from_variant = to_type(GDEXTENSION_VARIANT_TYPE_INT);
	string_from_variant = to_type(GDEXTENSION_VARIANT_TYPE_STRING);
	string_destroy = destructor(GDEXTENSION_VARIANT_TYPE_STRING);
	init->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
	init->initialize = initialize;
	init->deinitialize = deinitialize;
	init->userdata = NULL;
	return 1;
}
