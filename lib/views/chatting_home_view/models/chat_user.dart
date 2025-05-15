class ChatUser {
  final String id;
  final String name;
  final String email;
  final String about;
  final String image;
  final bool isOnline;
  final String pushToken;
  final String lastActive;
  final String lastMessage;
  final int unreadCount;
  final String? rmId;
  final String? tlId;
  final List<String> type;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    required this.about,
    required this.image,
    required this.isOnline,
    required this.pushToken,
    required this.lastActive,
    this.lastMessage = 'Tab to start chats',
    this.unreadCount = 0,
    this.rmId,
    this.tlId,
    this.type = const [],
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      about: json['about'] ?? '',
      image: json['image'] ?? '',
      isOnline: json['isOnline'] ?? false,
      pushToken: json['pushToken'] ?? '',
      lastActive: json['lastActive'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      rmId: json['rmId'],
      tlId: json['tlId'],
      type: List<String>.from(json['type'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'about': about,
      'image': image,
      'isOnline': isOnline,
      'pushToken': pushToken,
      'lastActive': lastActive,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'rmId': rmId,
      'tlId': tlId,
      'type': type,
    };
  }
}