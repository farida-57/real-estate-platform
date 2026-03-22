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
    // sender can be a populated Map or a plain ID string
    String senderId = '';
    String? senderName;
    if (json['sender'] is Map<String, dynamic>) {
      senderId = json['sender']['_id']?.toString() ?? '';
      senderName = json['sender']['name']?.toString();
    } else if (json['sender'] != null) {
      senderId = json['sender'].toString();
    }

    // receiver can be a populated Map or a plain ID string
    String receiverId = '';
    String? receiverName;
    if (json['receiver'] is Map<String, dynamic>) {
      receiverId = json['receiver']['_id']?.toString() ?? '';
      receiverName = json['receiver']['name']?.toString();
    } else if (json['receiver'] != null) {
      receiverId = json['receiver'].toString();
    }

    // property can be populated or a plain ID
    String? propertyId;
    if (json['property'] is Map<String, dynamic>) {
      propertyId = json['property']['_id']?.toString();
    } else if (json['property'] != null) {
      propertyId = json['property'].toString();
    }

    return MessageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: senderId,
      receiverId: receiverId,
      senderName: senderName,
      receiverName: receiverName,
      propertyId: propertyId,
      content: json['content']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': senderId,
      'receiver': receiverId,
      'property': propertyId,
      'content': content,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
