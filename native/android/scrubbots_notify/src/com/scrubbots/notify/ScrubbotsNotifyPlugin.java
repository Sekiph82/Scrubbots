// SB-M43-172: Godot 4 Android plugin (v2) "ScrubbotsNotify". One local reminder at a time
// (fixed id): schedule replaces it, cancel_all removes it. No push server, no network.
// AlarmManager.setAndAllowWhileIdle needs no permission (inexact by design; exact alarms are
// restricted). Alarms do not survive a reboot: the next app close schedules again, so no
// RECEIVE_BOOT_COMPLETED permission is requested.
package com.scrubbots.notify;

import android.app.AlarmManager;
import android.app.NotificationManager;
import android.content.Context;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

public class ScrubbotsNotifyPlugin extends GodotPlugin {
	public ScrubbotsNotifyPlugin(Godot godot) {
		super(godot);
	}

	@Override
	public String getPluginName() {
		return "ScrubbotsNotify";
	}

	/** True when the OS lets this app post notifications (all API levels, user settings included). */
	@UsedByGodot
	public boolean notifications_enabled() {
		return ((NotificationManager) getContext().getSystemService(Context.NOTIFICATION_SERVICE)).areNotificationsEnabled();
	}

	@UsedByGodot
	public void schedule(String title, String body, int seconds) {
		Context c = getContext();
		AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
		am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + Math.max(1, seconds) * 1000L,
				ReminderReceiver.pending(c, title, body));
	}

	@UsedByGodot
	public void cancel_all() {
		Context c = getContext();
		((AlarmManager) c.getSystemService(Context.ALARM_SERVICE)).cancel(ReminderReceiver.pending(c, "", ""));
		((NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE)).cancel(ReminderReceiver.NOTIFICATION_ID);
	}
}
