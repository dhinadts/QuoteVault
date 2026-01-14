import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      (ref) => NotificationSettingsNotifier(),
    );

class NotificationSettings {
  final bool enabled;
  final TimeOfDay notificationTime;

  NotificationSettings({required this.enabled, required this.notificationTime});

  NotificationSettings copyWith({bool? enabled, TimeOfDay? notificationTime}) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier()
    : super(
        NotificationSettings(
          enabled: true,
          notificationTime: const TimeOfDay(hour: 9, minute: 0),
        ),
      );

  void setEnabled(bool enabled) {
    state = state.copyWith(enabled: enabled);
  }

  void setNotificationTime(TimeOfDay time) {
    state = state.copyWith(notificationTime: time);
  }
}
