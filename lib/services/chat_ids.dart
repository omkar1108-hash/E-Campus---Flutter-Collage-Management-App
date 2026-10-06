/// Chat room identifiers. The Firestore security rules rely on these formats:
/// a direct chat id contains both participant uids, a department room is
/// `dept-<code>`.
String directChatId(String uidA, String uidB) {
  final ids = [uidA, uidB]..sort();
  return ids.join('_');
}

String departmentRoomId(String department) => 'dept-$department';
