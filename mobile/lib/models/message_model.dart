class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String? senderName;
  final String? receiverName;
  final String? propertyId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.senderName,
    this.receiverName,
    this.propertyId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'],
      senderId: json['sender']?['_id'] ?? json['sender'] ?? '',
      receiverId: json['receiver']?['_id'] ?? json['receiver'] ?? '',
      senderName: json['sender']?['name'] ?? '',
      receiverName: json['receiver']?['name'] ?? '',
      propertyId: json['property']?['_id'] ?? json['property'],
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': senderId,
      'receiver': receiverId,
      'property': propertyId,
      'content': content,
      'isRead': isRead,
    };
  }
}
