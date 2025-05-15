import 'package:cloud_firestore/cloud_firestore.dart';

enum Type { text, image, video, document, audio, location }
enum LocationType { static, live }

class Message {
  final String msg;
  final String? toId;
  final String read;
  final Type type;
  final LocationType? locationType;
  final int? duration;
  final String fromId;
  final Timestamp sent;

  Message({
    required this.msg,
    this.toId,
    required this.read,
    required this.type,
    this.locationType,
    this.duration,
    required this.fromId,
    required this.sent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      msg: json['msg'] ?? '',
      toId: json['toId'],
      read: json['read'] ?? '',
      type: switch (json['type']) {
        'image' => Type.image,
        'video' => Type.video,
        'document' => Type.document,
        'audio' => Type.audio,
        'location' => Type.location,
        _ => Type.text,
      },
      locationType: json['locationType'] != null
          ? (json['locationType'] == 'live' ? LocationType.live : LocationType.static)
          : null,
      duration: json['duration'],
      fromId: json['fromId'] ?? '',
      sent: json['sent'] != null
          ? json['sent'] as Timestamp
          : Timestamp.fromDate(DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
    'msg': msg,
    if (toId != null) 'toId': toId,
    'read': read,
    'type': type.name,
    'locationType': locationType?.name,
    'duration': duration,
    'fromId': fromId,
    'sent': sent,
  };
}