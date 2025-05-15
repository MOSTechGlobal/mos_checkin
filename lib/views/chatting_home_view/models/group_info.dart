class GroupInfo {
  final String groupId;
  final String groupName;
  final String groupImage;
  final String lastMsg;
  final dynamic lastMsgTime;

  GroupInfo({
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    this.lastMsg = '',
    this.lastMsgTime = '',
  });
}