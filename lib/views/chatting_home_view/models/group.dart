class Group {
  final String groupId;
  final String groupName;
  final String groupImage;
  final String createdAt;
  final String lastMsg;
  final String lastMsgTime;

  Group({
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.createdAt,
    required this.lastMsg,
    required this.lastMsgTime,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      groupImage: json['groupImage'] ?? '',
      createdAt: json['createdAt'] ?? '',
      lastMsg: json['last_msg'] ?? '',
      lastMsgTime: json['last_msg_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'groupId': groupId,
    'groupName': groupName,
    'groupImage': groupImage,
    'createdAt': createdAt,
    'last_msg': lastMsg,
    'last_msg_time': lastMsgTime,
  };
}