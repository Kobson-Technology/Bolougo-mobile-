class Message {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String messageText;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.messageText,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      messageText: json['messageText'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
