// SB-M43-172: posts the scheduled reminder on the "reminders" channel; tapping it opens the game.
package com.scrubbots.notify;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

public class ReminderReceiver extends BroadcastReceiver {
	static final int NOTIFICATION_ID = 1;
	static final String CHANNEL = "reminders";

	/** Same request code + component = the same alarm, so scheduling replaces and cancel matches. */
	static PendingIntent pending(Context c, String title, String body) {
		Intent i = new Intent(c, ReminderReceiver.class).putExtra("title", title).putExtra("body", body);
		return PendingIntent.getBroadcast(c, 0, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
	}

	@Override
	public void onReceive(Context c, Intent i) {
		NotificationManager nm = (NotificationManager) c.getSystemService(Context.NOTIFICATION_SERVICE);
		if (!nm.areNotificationsEnabled()) {
			return;
		}
		Notification.Builder b;
		if (Build.VERSION.SDK_INT >= 26) {
			nm.createNotificationChannel(new NotificationChannel(CHANNEL, "Reminders", NotificationManager.IMPORTANCE_DEFAULT));
			b = new Notification.Builder(c, CHANNEL);
		} else {
			b = new Notification.Builder(c);
		}
		Intent open = c.getPackageManager().getLaunchIntentForPackage(c.getPackageName());
		b.setSmallIcon(c.getApplicationInfo().icon)
				.setContentTitle(i.getStringExtra("title"))
				.setContentText(i.getStringExtra("body"))
				.setAutoCancel(true)
				.setContentIntent(PendingIntent.getActivity(c, 0, open, PendingIntent.FLAG_IMMUTABLE));
		nm.notify(NOTIFICATION_ID, b.build());
	}
}
