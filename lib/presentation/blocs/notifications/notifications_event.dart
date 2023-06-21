part of 'notifications_bloc.dart';

abstract class NotificationsEvent {
  const NotificationsEvent();

}

class NotificationsStatusChanged extends NotificationsEvent {
  final AuthorizationStatus status;

  NotificationsStatusChanged( this.status );
}

class NotificationReceived extends NotificationsEvent {
  final PushMessage notification;

  NotificationReceived( this.notification );
}
