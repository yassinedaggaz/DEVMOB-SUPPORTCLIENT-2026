class Ticket {
  final String id;
  final String title;
  final String description;
  final String status; // 'nouveau', 'en_cours', 'resolu', 'ferme'
  final String priority; // 'basse', 'moyenne', 'haute'
  final String category;
  final String clientId;
  final String clientName;
  final String? assignedTo;
  final String? assignedToName;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.clientId,
    required this.clientName,
    this.assignedTo,
    this.assignedToName,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'nouveau',
      priority: json['priority'] ?? 'moyenne',
      category: json['category'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      assignedTo: json['assignedTo'],
      assignedToName: json['assignedToName'],
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'category': category,
      'clientId': clientId,
      'clientName': clientName,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? category,
    String? clientId,
    String? clientName,
    String? assignedTo,
    String? assignedToName,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}