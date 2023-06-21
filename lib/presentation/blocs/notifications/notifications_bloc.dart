import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_app/config/domain/entities/push_message.dart';

import '../../../firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

// second
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  // print("Handling a background message: ${message.messageId}");
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationsBloc() : super( const NotificationsState() ) {
    on<NotificationsStatusChanged>( _notificationStatusChanged );
    on<NotificationReceived>( _onPushMessageReceived );

    // verify notification status
    _initialStatusCheck();

    // Foregorund listener notifications
    _onForegroundMessage();
  }

  static Future<void> initializeFCM() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _notificationStatusChanged( NotificationsStatusChanged event, Emitter<NotificationsState> emit ) {
    emit(
      state.copyWith(
        status: event.status
      )
    );

    _getFCMToken();
  }

  void _onPushMessageReceived( NotificationReceived event, Emitter<NotificationsState> emit ) {
    emit(
      state.copyWith(
        notifications: [ event.notification, ...state.notifications ]
      )
    );
  }

  void _initialStatusCheck() async {
    // To know current status
    final settings = await messaging.getNotificationSettings();

    add( NotificationsStatusChanged( settings.authorizationStatus ) );

    _getFCMToken();
  }

  void _getFCMToken() async {
    final settings = await messaging.getNotificationSettings();
    if ( settings.authorizationStatus != AuthorizationStatus.authorized ) return;

    final token = await messaging.getToken();
    // print( token );
  }

  void handleRemoteMessage( RemoteMessage  message ) {

    if ( message.notification == null ) return;

    final notification = PushMessage(
      messageId: message.messageId?.replaceAll(':', '').replaceAll('%', '') ?? '',
      title: message.notification!.title ?? '',
      body: message.notification!.body ?? '',
      sentDate: message.sentTime ?? DateTime.now(),
      data: message.data,
      imageUrl: Platform.isAndroid ? message.notification!.android?.imageUrl : message.notification!.apple?.imageUrl
    );

    add( NotificationReceived( notification ) );

  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen( handleRemoteMessage );
  }

  void requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    add( NotificationsStatusChanged( settings.authorizationStatus ) );
  }

  PushMessage? getMessageById( String pushMessageId ) {

    final exist = state.notifications.any((element) => element.messageId == pushMessageId );

    if ( !exist ) return null;

    return state.notifications.firstWhere((element) => element.messageId == pushMessageId );
  }
}
