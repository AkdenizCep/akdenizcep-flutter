import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/club_option.dart';
import '../models/event_comment.dart';
import '../models/feed_event.dart';

/// Kulüp ve öğrenci etkinliklerini tek akışta birleştiren servis.
///
/// Kulüp etkinlikleri `clubs/{clubId}/club-events` alt koleksiyonunda durduğu
/// için tümünü tek sorguda okumak `collectionGroup` gerektirir; kulüp adı/logosu
/// `clubs` koleksiyonundan eşlenir.
class EventFeedService {
  final _db = FirebaseFirestore.instance;

  static const _studentCollection = 'student-events';
  static const _clubEventsCollection = 'club-events';

  DocumentReference<Map<String, dynamic>> _docRef(EventRef ref) {
    if (ref.source == EventSource.club) {
      return _db
          .collection('clubs')
          .doc(ref.clubId)
          .collection(_clubEventsCollection)
          .doc(ref.eventId);
    }
    return _db.collection(_studentCollection).doc(ref.eventId);
  }

  Stream<List<FeedEvent>> getFeed() {
    final studentEvents = _db
        .collection(_studentCollection)
        .orderBy('date', descending: true)
        .snapshots();
    final clubEvents = _db
        .collectionGroup(_clubEventsCollection)
        .orderBy('date', descending: true)
        .snapshots();
    final clubs = _db.collection('clubs').snapshots();

    return _combineLatest3(clubs, clubEvents, studentEvents, (
      clubsSnap,
      clubEventsSnap,
      studentEventsSnap,
    ) {
      final clubsById = {for (final doc in clubsSnap.docs) doc.id: doc.data()};

      final events = <FeedEvent>[
        ...clubEventsSnap.docs.map((doc) => _clubEventFrom(doc, clubsById)),
        ...studentEventsSnap.docs.map(_studentEventFrom),
      ];
      events.sort((a, b) => b.date.compareTo(a.date));
      return events;
    });
  }

  Stream<List<ClubOption>> getClubs() {
    return _db
        .collection('clubs')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ClubOption.fromJson(doc.data()..['id'] = doc.id))
              .toList(),
        );
  }

  Stream<FeedEvent> getEvent(EventRef ref) {
    if (ref.source == EventSource.student) {
      return _docRef(ref).snapshots().map(_studentEventFrom);
    }

    final clubDoc = _db.collection('clubs').doc(ref.clubId).snapshots();
    return _combineLatest2(clubDoc, _docRef(ref).snapshots(), (
      clubSnap,
      eventSnap,
    ) {
      final clubsById = {
        if (clubSnap.data() != null) clubSnap.id: clubSnap.data()!,
      };
      return _clubEventFrom(eventSnap, clubsById);
    });
  }

  /// Kullanıcının başkan ya da yönetici üye olduğu kulüpler — etkinlik
  /// oluşturma formundaki "kimin adına" seçimi bunu kullanır.
  Stream<List<ClubOption>> getAdminClubs(String uid) {
    return _db
        .collection('clubs')
        .where(
          Filter.or(
            Filter('adminUid', isEqualTo: uid),
            Filter('adminUids', arrayContains: uid),
          ),
        )
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ClubOption.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  /// Kulüp adına etkinlik oluşturur. Yazma yetkisi Firestore kurallarında
  /// kulübün `adminUid` alanına bağlıdır.
  Future<void> createClubEvent({
    required String clubId,
    required String adminUid,
    required String title,
    required DateTime date,
    required String location,
    required double locationLatitude,
    required double locationLongitude,
    required String description,
    String category = '',
    String imageUrl = '',
    int? capacity,
    bool qrAttendance = false,
  }) async {
    try {
      await _db
          .collection('clubs')
          .doc(clubId)
          .collection(_clubEventsCollection)
          .add({
            'title': title,
            'date': Timestamp.fromDate(date),
            'location': location,
            'locationLatitude': locationLatitude,
            'locationLongitude': locationLongitude,
            'description': description,
            'category': category,
            'imageUrl': imageUrl,
            'capacity': capacity,
            'qrAttendance': qrAttendance,
            'attendeeIds': [adminUid],
            'attendeeCount': 1,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (e) {
      throw Exception('Topluluk etkinligi olusturulamadi: ${e.message}');
    }
  }

  /// Katıl / ayrıl. Kontenjan dolu bir etkinliğe katılım transaction içinde
  /// reddedilir, böylece iki kullanıcı son koltuğu aynı anda alamaz.
  Future<void> toggleJoin({
    required EventRef ref,
    required String uid,
    required bool join,
  }) async {
    final doc = _docRef(ref);
    try {
      await _db.runTransaction((transaction) async {
        final snap = await transaction.get(doc);
        final data = snap.data();
        if (data == null) {
          throw Exception('Etkinlik bulunamadi.');
        }

        final attendeeIds = List<String>.from(data['attendeeIds'] ?? const []);
        final alreadyJoined = attendeeIds.contains(uid);
        if (join == alreadyJoined) return;

        if (join) {
          final capacity = data['capacity'] as int?;
          final count = data['attendeeCount'] as int? ?? attendeeIds.length;
          if (capacity != null && count >= capacity) {
            throw Exception('Etkinlik kontenjani doldu.');
          }
        }

        // Sayaç increment yerine listeden hesaplanır: güvenlik kuralı
        // attendeeCount == attendeeIds.size() eşitliğini doğruluyor.
        final updatedIds = join
            ? [...attendeeIds, uid]
            : (attendeeIds..remove(uid));

        transaction.update(doc, {
          'attendeeIds': updatedIds,
          'attendeeCount': updatedIds.length,
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Katilim guncellenemedi: ${e.message}');
    }
  }

  Stream<List<EventComment>> getComments(EventRef ref) {
    return _docRef(ref)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => EventComment.fromJson(d.data()..['id'] = d.id))
              .toList(),
        );
  }

  Future<void> addComment({
    required EventRef ref,
    required String authorUid,
    required String authorName,
    required String text,
  }) async {
    try {
      await _docRef(ref).collection('comments').add({
        'authorUid': authorUid,
        'authorName': authorName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Yorum eklenemedi: ${e.message}');
    }
  }

  Future<void> deleteComment({
    required EventRef ref,
    required String commentId,
  }) async {
    try {
      await _docRef(ref).collection('comments').doc(commentId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Yorum silinemedi: ${e.message}');
    }
  }

  Future<void> toggleSaved({
    required String uid,
    required String eventId,
    required bool save,
  }) async {
    try {
      await _db.collection('users').doc(uid).update({
        'savedEventIds': save
            ? FieldValue.arrayUnion([eventId])
            : FieldValue.arrayRemove([eventId]),
      });
    } on FirebaseException catch (e) {
      throw Exception('Kaydetme guncellenemedi: ${e.message}');
    }
  }

  FeedEvent _studentEventFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    data['id'] = doc.id;
    data['source'] = 'student';
    final authorName = data['authorName'] as String? ?? '';
    data['authorName'] = authorName.isEmpty ? 'Öğrenci' : authorName;
    return FeedEvent.fromJson(data);
  }

  FeedEvent _clubEventFrom(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, Map<String, dynamic>> clubsById,
  ) {
    final clubId = doc.reference.parent.parent?.id ?? '';
    final club = clubsById[clubId];
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    data['id'] = doc.id;
    data['source'] = 'club';
    data['clubId'] = clubId;
    data['authorName'] = club?['name'] as String? ?? 'Topluluk';
    data['authorLogoUrl'] = club?['logoUrl'] as String? ?? '';
    data['authorUid'] = club?['adminUid'] as String? ?? '';
    return FeedEvent.fromJson(data);
  }
}

/// İki stream'in son değerlerini birleştirir; ikisi de en az bir değer
/// yayınlayana kadar çıktı üretmez. (rxdart bağımlılığı eklemekten kaçınmak
/// için elle yazıldı.)
Stream<R> _combineLatest2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A, B) combine,
) {
  return _combineLatest3<A, B, void, R>(
    a,
    b,
    Stream<void>.value(null),
    (x, y, _) => combine(x, y),
  );
}

Stream<R> _combineLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combine,
) {
  late StreamController<R> controller;
  final subscriptions = <StreamSubscription<dynamic>>[];

  late A latestA;
  late B latestB;
  late C latestC;
  var hasA = false;
  var hasB = false;
  var hasC = false;

  void emit() {
    if (hasA && hasB && hasC) {
      controller.add(combine(latestA, latestB, latestC));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subscriptions
        ..add(
          a.listen((value) {
            latestA = value;
            hasA = true;
            emit();
          }, onError: controller.addError),
        )
        ..add(
          b.listen((value) {
            latestB = value;
            hasB = true;
            emit();
          }, onError: controller.addError),
        )
        ..add(
          c.listen((value) {
            latestC = value;
            hasC = true;
            emit();
          }, onError: controller.addError),
        );
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      subscriptions.clear();
    },
  );

  return controller.stream;
}
