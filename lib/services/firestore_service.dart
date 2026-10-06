import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_user.dart';
import '../models/content.dart';

/// Thin wrapper around Cloud Firestore / Storage. Firestore's offline
/// persistence is on by default on mobile, so reads and queued writes keep
/// working without a connection and sync when the network returns.
class FirestoreService {
  FirestoreService([FirebaseFirestore? db, FirebaseStorage? storage])
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  // ---- Users -------------------------------------------------------------

  Stream<AppUser?> watchUser(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(
            (s) => s.exists ? AppUser.fromMap(s.id, s.data()!) : null,
          );

  /// New accounts are always created as students; an admin promotes them.
  Future<void> createProfile({
    required String uid,
    required String name,
    required String department,
    required int year,
  }) =>
      _db.collection('users').doc(uid).set({
        'name': name,
        'department': department,
        'year': year,
        'role': UserRole.student.value,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<AppUser>> watchUsers({String? department}) {
    Query<Map<String, dynamic>> q = _db.collection('users');
    if (department != null) q = q.where('department', isEqualTo: department);
    return q.snapshots().map((s) {
      final users = s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return users;
    });
  }

  Future<void> setRole(String uid, UserRole role) =>
      _db.collection('users').doc(uid).update({'role': role.value});

  // ---- E-library ---------------------------------------------------------

  Stream<List<Book>> watchBooks(AppUser user) {
    Query<Map<String, dynamic>> q = _db.collection('books');
    if (!user.role.seesAllDepartments) {
      q = q.where('department', whereIn: [user.department, 'ALL']);
    }
    return q.snapshots().map((s) {
      final books = s.docs.map((d) => Book.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return books;
    });
  }

  Future<void> addBook({
    required AppUser uploader,
    required String title,
    required String author,
    required String department,
    required String fileUrl,
  }) =>
      _db.collection('books').add({
        'title': title,
        'author': author,
        'department': department,
        'fileUrl': fileUrl,
        'uploadedBy': uploader.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<String> uploadBookFile(String fileName, List<int> bytes) async {
    final ref = _storage
        .ref('books/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'application/pdf'),
    );
    return ref.getDownloadURL();
  }

  Future<void> deleteBook(String id) => _db.collection('books').doc(id).delete();

  // ---- Tech news ---------------------------------------------------------

  Stream<List<NewsItem>> watchNews(AppUser user) {
    Query<Map<String, dynamic>> q = _db.collection('news');
    if (!user.role.seesAllDepartments) {
      q = q.where('department', isEqualTo: user.department);
    }
    return q.snapshots().map((s) {
      final items = s.docs.map((d) => NewsItem.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
      return items;
    });
  }

  Future<void> postNews({
    required AppUser author,
    required String title,
    required String body,
    required String department,
  }) =>
      _db.collection('news').add({
        'title': title,
        'body': body,
        'department': department,
        'authorId': author.uid,
        'authorName': author.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteNews(String id) => _db.collection('news').doc(id).delete();

  // ---- Chat --------------------------------------------------------------

  Stream<List<ChatMessage>> watchMessages(String chatId) => _db
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());

  Future<void> sendMessage(String chatId, AppUser sender, String text) => _db
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .add({
        'senderId': sender.uid,
        'senderName': sender.name,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ---- Bus tracking ------------------------------------------------------

  Stream<List<BusLocation>> watchBuses() =>
      _db.collection('bus_locations').snapshots().map((s) =>
          s.docs.map((d) => BusLocation.fromMap(d.id, d.data())).toList());

  Future<void> updateBus({
    required String busId,
    required double lat,
    required double lng,
    required double speedKmh,
    required String driverName,
  }) =>
      _db.collection('bus_locations').doc(busId).set({
        'lat': lat,
        'lng': lng,
        'speedKmh': speedKmh,
        'driverName': driverName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> removeBus(String busId) =>
      _db.collection('bus_locations').doc(busId).delete();
}
