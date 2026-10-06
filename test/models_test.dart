import 'package:e_campus/models/app_user.dart';
import 'package:e_campus/models/content.dart';
import 'package:e_campus/screens/home_screen.dart';
import 'package:e_campus/services/chat_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole RBAC', () {
    test('students have no elevated permissions', () {
      const r = UserRole.student;
      expect(r.canPostNews, isFalse);
      expect(r.canManageBooks, isFalse);
      expect(r.canShareBus, isFalse);
      expect(r.canManageUsers, isFalse);
    });

    test('class representative can post news only', () {
      const r = UserRole.classRep;
      expect(r.canPostNews, isTrue);
      expect(r.canManageBooks, isFalse);
      expect(r.canShareBus, isFalse);
      expect(r.canManageUsers, isFalse);
    });

    test('teacher can post news, manage books and share the bus', () {
      const r = UserRole.teacher;
      expect(r.canPostNews && r.canManageBooks && r.canShareBus, isTrue);
      expect(r.canManageUsers, isFalse);
    });

    test('admin can do everything', () {
      const r = UserRole.admin;
      expect(r.canPostNews && r.canManageBooks && r.canShareBus && r.canManageUsers, isTrue);
      expect(r.seesAllDepartments, isTrue);
    });

    test('unknown or missing role value falls back to student', () {
      expect(UserRole.fromValue(null), UserRole.student);
      expect(UserRole.fromValue('hacker'), UserRole.student);
      expect(UserRole.fromValue('class_rep'), UserRole.classRep);
    });
  });

  group('Drawer entries by role', () {
    List<String> titles(UserRole r) => drawerEntriesFor(r).map((e) => e.title).toList();

    test('student sees only the six core features', () {
      expect(titles(UserRole.student), [
        'Dashboard', 'E-Library', 'Bus Tracking', 'Chat', 'AI Assistant', 'Tech News',
      ]);
    });

    test('class rep additionally sees Post Tech News', () {
      expect(titles(UserRole.classRep), contains('Post Tech News'));
      expect(titles(UserRole.classRep), isNot(contains('Manage Users')));
    });

    test('teacher sees upload + bus broadcast but not user management', () {
      final t = titles(UserRole.teacher);
      expect(t, containsAll(['Upload Book', 'Broadcast Bus Location']));
      expect(t, isNot(contains('Manage Users')));
    });

    test('admin sees every entry', () {
      expect(titles(UserRole.admin), hasLength(10));
      expect(titles(UserRole.admin), contains('Manage Users'));
    });
  });

  group('AppUser', () {
    test('round-trips through map', () {
      const u = AppUser(
          uid: 'u1', name: 'Asha', department: 'MCA', role: UserRole.teacher, year: 2);
      final back = AppUser.fromMap('u1', u.toMap());
      expect(back.name, 'Asha');
      expect(back.role, UserRole.teacher);
      expect(back.year, 2);
    });

    test('tolerates missing fields', () {
      final u = AppUser.fromMap('u2', {});
      expect(u.role, UserRole.student);
      expect(u.department, '');
    });
  });

  group('Chat ids', () {
    test('direct chat id is symmetric', () {
      expect(directChatId('b', 'a'), directChatId('a', 'b'));
      expect(directChatId('b', 'a'), 'a_b');
    });

    test('department room id', () {
      expect(departmentRoomId('MCA'), 'dept-MCA');
    });
  });

  group('BusLocation.isLive', () {
    final now = DateTime(2026, 1, 1, 12);
    const stale = Duration(minutes: 2);
    BusLocation at(DateTime? t) => BusLocation(
        id: 'B', lat: 0, lng: 0, speedKmh: 0, driverName: '', updatedAt: t);

    test('recent update is live', () {
      expect(at(now.subtract(const Duration(seconds: 30))).isLive(now, stale), isTrue);
    });
    test('old update is offline', () {
      expect(at(now.subtract(const Duration(minutes: 5))).isLive(now, stale), isFalse);
    });
    test('missing timestamp is offline', () {
      expect(at(null).isLive(now, stale), isFalse);
    });
  });
}
