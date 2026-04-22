class Comment {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final String message;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'userName': userName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
