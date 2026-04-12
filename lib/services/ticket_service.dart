import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import '../models/ticket.dart'; 
import '../models/comment.dart'; 

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _generateTicketId() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('tickets')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'TK-001';
      }

      String lastId = 'TK-000';
      final data = snapshot.docs.first.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('id')) {
        lastId = data['id'].toString();
      }

      int number = 1;
      if (lastId.contains('-')) {
        number = int.parse(lastId.split('-')[1]) + 1;
      }
      return 'TK-${number.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('Erreur generateTicketId: $e');
      return 'TK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  Future<String?> uploadFile(PlatformFile file, String ticketId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      if (file.bytes != null && file.bytes!.length < 500000) {
        String base64String = base64Encode(file.bytes!);
        return 'data:image/jpeg;base64,$base64String';
      }

      return 'https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png';

    } catch (e) {
      debugPrint('Erreur upload fichier simulé : $e');
      return null;
    }
  }

  Future<String?> createTicket({
    required String title,
    required String description,
    required String priority,
    required String category,
    required String clientId,
    required String clientName,
    List<PlatformFile>? attachmentFiles,
  }) async {
    try {
      String ticketId = await _generateTicketId();

      List<String> attachmentUrls = [];
      if (attachmentFiles != null && attachmentFiles.isNotEmpty) {
        final futures = attachmentFiles.map((file) => uploadFile(file, ticketId));
        final results = await Future.wait(futures);
        
        for (var url in results) {
          if (url != null) attachmentUrls.add(url);
        }
      }

      Ticket newTicket = Ticket(
        id: ticketId,
        title: title,
        description: description,
        status: 'nouveau',
        priority: priority,
        category: category,
        clientId: clientId,
        clientName: clientName,
        attachments: attachmentUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('tickets')
          .doc(ticketId)
          .set(newTicket.toJson());

      return ticketId;
    } catch (e) {
      debugPrint('Erreur création ticket: $e');
      return null;
    }
  }

  Stream<List<Ticket>> getClientTickets(String clientId) {
    return _firestore
        .collection('tickets')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
          final tickets = snapshot.docs
              .map((doc) => Ticket.fromJson(doc.data()))
              .toList();
          tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tickets;
        });
  }

  Stream<List<Ticket>> getAllTickets() {
    return _firestore
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Ticket.fromJson(doc.data()))
              .toList();
        });
  }

  Future<Ticket?> getTicketById(String ticketId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .get();

      if (doc.exists) {
        return Ticket.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur récupération ticket: $e');
      return null;
    }
  }

  Stream<Ticket?> watchTicket(String ticketId) {
    return _firestore.collection('tickets').doc(ticketId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return Ticket.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> updateStatus(String ticketId, String newStatus) async {
    await _firestore.collection('tickets').doc(ticketId).update({
      'status': newStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updatePriority(String ticketId, String newPriority) async {
    await _firestore.collection('tickets').doc(ticketId).update({
      'priority': newPriority,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> assignTicket(
    String ticketId,
    String agentId,
    String agentName,
  ) async {
    await _firestore.collection('tickets').doc(ticketId).update({
      'assignedTo': agentId,
      'assignedToName': agentName,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addComment({
    required String ticketId,
    required String userId,
    required String userName,
    required String message,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('comments').add({
        'ticketId': ticketId,
        'userId': userId,
        'userName': userName,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _firestore.collection('tickets').doc(ticketId).update({
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await docRef.update({'id': docRef.id});
    } catch (e) {
      debugPrint('Erreur ajout commentaire: $e');
    }
  }

  Stream<List<Comment>> getComments(String ticketId) {
    return _firestore
        .collection('comments')
        .where('ticketId', isEqualTo: ticketId)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs
              .map((doc) => Comment.fromJson(doc.data()))
              .toList();
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        });
  }

  Future<Map<String, int>> getTicketCountsByStatus() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('tickets').get();

      Map<String, int> counts = {
        'nouveau': 0,
        'en_cours': 0,
        'resolu': 0,
        'ferme': 0,
      };

      for (var doc in snapshot.docs) {
        String status = doc.get('status') ?? 'nouveau';
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Erreur statistiques: $e');
      return {};
    }
  }

  Future<Map<String, int>> getTicketCountsByPriority() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('tickets').get();

      Map<String, int> counts = {'basse': 0, 'moyenne': 0, 'haute': 0};

      for (var doc in snapshot.docs) {
        String priority = doc.get('priority') ?? 'moyenne';
        counts[priority] = (counts[priority] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Erreur statistiques: $e');
      return {};
    }
  }
}
