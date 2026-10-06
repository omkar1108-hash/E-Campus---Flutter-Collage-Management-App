import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.department,
    required this.fileUrl,
    this.createdAt,
  });

  final String id;
  final String title;
  final String author;
  final String department;
  final String fileUrl;
  final DateTime? createdAt;

  factory Book.fromMap(String id, Map<String, dynamic> m) => Book(
        id: id,
        title: (m['title'] as String?) ?? '',
        author: (m['author'] as String?) ?? '',
        department: (m['department'] as String?) ?? 'ALL',
        fileUrl: (m['fileUrl'] as String?) ?? '',
        createdAt: _date(m['createdAt']),
      );
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.body,
    required this.department,
    required this.authorName,
    this.authorId = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String department;
  final String authorName;
  final String authorId;
  final DateTime? createdAt;

  factory NewsItem.fromMap(String id, Map<String, dynamic> m) => NewsItem(
        id: id,
        title: (m['title'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        department: (m['department'] as String?) ?? '',
        authorName: (m['authorName'] as String?) ?? '',
        authorId: (m['authorId'] as String?) ?? '',
        createdAt: _date(m['createdAt']),
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) => ChatMessage(
        id: id,
        senderId: (m['senderId'] as String?) ?? '',
        senderName: (m['senderName'] as String?) ?? '',
        text: (m['text'] as String?) ?? '',
        createdAt: _date(m['createdAt']),
      );
}

class BusLocation {
  const BusLocation({
    required this.id,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.driverName,
    this.updatedAt,
  });

  final String id;
  final double lat;
  final double lng;
  final double speedKmh;
  final String driverName;
  final DateTime? updatedAt;

  factory BusLocation.fromMap(String id, Map<String, dynamic> m) => BusLocation(
        id: id,
        lat: (m['lat'] as num?)?.toDouble() ?? 0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0,
        speedKmh: (m['speedKmh'] as num?)?.toDouble() ?? 0,
        driverName: (m['driverName'] as String?) ?? '',
        updatedAt: _date(m['updatedAt']),
      );

  bool isLive(DateTime now, Duration staleAfter) =>
      updatedAt != null && now.difference(updatedAt!) <= staleAfter;
}

/// A single turn in the AI chatbot conversation.
class AiTurn {
  const AiTurn(this.role, this.content);

  /// `user` or `assistant`.
  final String role;
  final String content;
}
