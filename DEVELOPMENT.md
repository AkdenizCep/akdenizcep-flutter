# Akdeniz Cep — Development Guide

> Bu dosya, AI agent'ların ve geliştiricilerin proje bağlamını hızlıca kavraması için hazırlanmıştır.
> Yeni bir özellik yazmadan veya mevcut kodu değiştirmeden önce bu dosyayı oku.

---

## Proje Özeti

**Akdeniz Cep**, Akdeniz Üniversitesi öğrencileri için geliştirilmiş bir mobil uygulamadır.
Dağınık hâlde bulunan kampüs servislerini (OBS, yemekhane, ring saatleri, kulüp etkinlikleri) tek bir platformda birleştirir.

**Tech stack:** Flutter · Firebase (Firestore, Auth, Realtime DB, Storage) · Riverpod

---

## Kurulum: Google Maps API anahtarı

Harita ekranları (kampüs haritası, ring durakları) bir Google Maps API anahtarı
ister. Anahtar **kaynak kontrolünde tutulmaz** — depo public olduğu için her iki
platformda da git'in görmediği bir dosyadan okunur. Anahtar olmadan uygulama
derlenir ve çalışır, yalnızca haritalar boş/gri çizilir.

**Android** — `android/local.properties` dosyasına ekle (dosya zaten
gitignore'da):

```properties
MAPS_API_KEY=buraya_anahtarini_yaz
```

`android/app/build.gradle.kts` bunu okuyup `AndroidManifest.xml` içindeki
`${MAPS_API_KEY}` yer tutucusuna enjekte eder. CI'da `MAPS_API_KEY` ortam
değişkeni de kullanılabilir.

**iOS** — örnek dosyayı kopyala ve doldur:

```bash
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
```

`Debug.xcconfig` ve `Release.xcconfig` bu dosyayı `#include?` ile alır (dosya
yoksa build kırılmaz), değer `Info.plist` içindeki `MapsApiKey` anahtarına
işlenir ve `AppDelegate.swift` oradan okur.

**Web / Chrome** — örnek dosyayı kopyala ve anahtarı doldur:

```bash
cp web/maps_config.example.js web/maps_config.js
```

`web/maps_config.js` gitignore'dadır. `index.html`, dosya mevcutsa Google Maps
JavaScript API'yi bu değerle yükler; dosya veya anahtar yoksa uygulama açılır
ancak harita boş kalır. Web anahtarı tarayıcıdan görülebileceği için Google
Cloud Console'da HTTP referrer kısıtlaması zorunludur.

> Anahtarı Google Cloud Console'da mutlaka kısıtla: Android için paket adı +
> SHA-1, iOS için bundle id, web için izin verilen HTTP referrer'lar. İstemci
> anahtarları dağıtılan uygulamadan tamamen gizlenemez; temel koruma platform
> ve kullanım kısıtlamalarıdır.

---

## Mimari: Model / Service / Provider / Pages

Proje **4 katmanlı pragmatic architecture** kullanır. Clean Architecture **kullanılmaz** — UseCase sınıfları, Repository interface/implementation ayrımı veya DTO/Entity çifti yoktur.

```
Firestore ──► Service ──► Provider ──► Page
```

### Katmanlar ve Sorumlulukları

#### 1. `models/`
- Saf Dart sınıfları. Flutter veya Firebase import etmez.
- Her model `fromJson`, `toJson`, `copyWith` içerir.
- Firestore dökümanından direkt map edilir — ayrı bir DTO modeli **yoktur**.

```dart
// features/community/models/club.dart
class Club {
  final String id;
  final String name;
  final String logoUrl;
  final String category;
  final int followerCount;

  Club({required this.id, required this.name, ...});

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: json['id'],
    name: json['name'],
    ...
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, ...};

  Club copyWith({String? name, ...}) => Club(name: name ?? this.name, ...);
}
```

#### 2. `services/`
- Tüm Firebase çağrıları burada yapılır. Başka hiçbir yerde `FirebaseFirestore.instance` çağrılmaz.
- `Stream<T>` veya `Future<T>` döner — widget veya `ref` bilgisi içermez.
- Hata yönetimi (`try/catch`) burada yapılır; üst katmanlara anlamlı exception fırlatılır.

```dart
// features/community/services/community_service.dart
class CommunityService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Club>> getClubs() {
    return _db.collection('clubs').snapshots().map(
      (snap) => snap.docs.map((d) => Club.fromJson(d.data()..['id'] = d.id)).toList(),
    );
  }

  Future<void> followClub(String uid, String clubId) async {
    await _db.collection('users').doc(uid).update({
      'followedClubs': FieldValue.arrayUnion([clubId]),
    });
  }
}
```

#### 3. `providers/`
- Riverpod provider'ları. Service'i çağırır, state'i UI'a sunar.
- `ref` ve Riverpod API'si yalnızca bu katmanda kullanılır.
- İş mantığı içerebilir (filtreleme, sıralama, birden fazla service çağrısını birleştirme).

```dart
// features/community/providers/community_provider.dart
final communityServiceProvider = Provider((_) => CommunityService());

final clubsProvider = StreamProvider<List<Club>>((ref) {
  return ref.watch(communityServiceProvider).getClubs();
});
```

#### 4. `pages/`
- Yalnızca UI kodu. İş mantığı veya Firebase çağrısı içermez.
- `ConsumerWidget` kullanır, `ref.watch` ile provider'ı dinler.
- Her sayfa klasörü: `page.dart` + `components/` alt klasörü (sayfaya özel widget'lar).

```dart
// features/community/pages/community_page.dart
class CommunityPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsProvider);
    return clubsAsync.when(
      data: (clubs) => ClubListView(clubs: clubs),
      loading: () => const LoadingOverlay(),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}
```

---

## Klasör Yapısı

```
lib/
├── main.dart
├── app/
│   ├── router.dart
│   └── theme.dart
│
├── features/
│   ├── auth/
│   │   ├── models/
│   │   │   └── app_user.dart
│   │   ├── services/
│   │   │   └── auth_service.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── pages/
│   │       ├── login_page.dart
│   │       ├── register_page.dart
│   │       └── components/
│   │
│   ├── community/
│   │   ├── models/
│   │   │   ├── club.dart
│   │   │   └── club_event.dart
│   │   ├── services/
│   │   │   └── community_service.dart
│   │   ├── providers/
│   │   │   └── community_provider.dart
│   │   └── pages/
│   │       ├── community_page.dart
│   │       ├── club_detail_page.dart
│   │       ├── event_detail_page.dart
│   │       └── components/
│   │
│   ├── student_events/
│   │   ├── models/
│   │   │   └── student_event.dart
│   │   ├── services/
│   │   │   └── student_events_service.dart
│   │   ├── providers/
│   │   │   └── student_events_provider.dart
│   │   └── pages/
│   │       ├── student_events_page.dart
│   │       ├── create_event_page.dart
│   │       ├── student_event_detail_page.dart
│   │       └── components/
│   │
│   ├── cafeteria/
│   │   ├── models/
│   │   │   ├── menu_item.dart
│   │   │   └── meal_rating.dart
│   │   ├── services/
│   │   │   └── cafeteria_service.dart
│   │   ├── providers/
│   │   │   └── cafeteria_provider.dart
│   │   └── pages/
│   │       ├── cafeteria_page.dart
│   │       └── components/
│   │
│   ├── ring/
│   │   ├── models/
│   │   │   ├── ring_schedule.dart
│   │   │   ├── ring_stop.dart
│   │   │   └── ring_departures.dart    # saf hesaplama, Firebase'e bağlı değil
│   │   ├── services/
│   │   │   └── ring_service.dart
│   │   ├── providers/
│   │   │   └── ring_provider.dart
│   │   └── pages/
│   │       ├── ring_page.dart
│   │       ├── ring_stops_page.dart
│   │       └── components/
│   │
│   ├── board/
│   │   ├── models/
│   │   │   └── board_item.dart
│   │   ├── services/
│   │   │   └── board_service.dart
│   │   ├── providers/
│   │   │   └── board_provider.dart
│   │   └── pages/
│   │       ├── board_page.dart
│   │       └── components/
│   │
│   ├── map/
│   │   └── pages/
│   │       ├── map_page.dart
│   │       └── components/
│   │
│   └── home/
│       └── pages/
│           ├── home_page.dart
│           └── components/
│
└── shared/
    ├── components/
    │   ├── app_card.dart
    │   ├── loading_overlay.dart
    │   └── error_view.dart
    ├── services/
    │   └── storage_service.dart
    └── providers/
        └── user_provider.dart
```

---

## Firebase Veri Modeli

### Firestore Koleksiyonları

```
users/{uid}
  name: string
  email: string
  studentId: string
  followedClubs: string[]
  createdAt: timestamp

clubs/{clubId}
  name: string
  logoUrl: string
  category: string
  followerCount: number
  adminUid: string
  createdAt: timestamp

  club-events/{ceventId}
    title: string
    date: timestamp
    imageUrl: string
    location: string
    locationLatitude: number
    locationLongitude: number
    description: string
    qrAttendance: boolean         # true ise QR ile katılımcı kaydı açık
    createdAt: timestamp

    attendance/{uid}              # QR ile kapıda alınan yoklama (RSVP'den ayrı)
      uid: string
      name: string                # kayıt anındaki ad soyad, denormalize
      studentId: string
      recordedBy: string          # okutan yöneticinin uid'i
      checkedInAt: timestamp

announcements/{announcementId}
  imageUrl: string
  title: string
  context: string
  createdAt: timestamp

student-events/{seventId}
  title: string
  authorUid: string
  date: timestamp
  location: string
  locationLatitude: number
  locationLongitude: number
  description: string
  createdAt: timestamp

cafeteria_ratings/{date}                # döküman kimliği tarihin kendisi: "2026-08-04"
  date: string                          # "YYYY-MM-DD"
  avgRating: number                     # client transaction ile güncellenir
  ratingCount: number                   # client transaction ile güncellenir

  ratings/{uid}                         # alt koleksiyon — kullanıcı başına 1 döküman
    rating: number                      # 1–5
    comment: string                     # opsiyonel, boş string olabilir
    authorName: string                  # yazma anında AppUser.name'den denormalize edilir
    votes: map<uid, number>             # yorum başına faydalı(1)/faydasız(-1) oyları
    createdAt: timestamp
```

> **Öğün ayrımı yoktur.** Puanlama gün bazlıdır — bir öğrenci bir güne yalnızca
> bir kez oy verebilir. Döküman kimliği doğrudan tarihtir; `users/{uid}.ratedMealIds`
> de bu tarihleri tutar.

### Realtime Database

```json
{
  "cafeteria_menu": {
    "2026-08-04": [
      "Düğün Çorbası - 210 kcal",
      "Fırında Makarna - 480 kcal",
      "Zeytinyağlı Taze Fasulye",
      "Kemalpaşa Tatlısı"
    ]
  },
  "ring_stops": {
    "rektorluk": { "name": "Rektörlük", "lat": 36.8969, "lng": 30.6364 },
    "ziraat": { "name": "Ziraat Fakültesi", "lat": 36.8981, "lng": 30.6402 },
    "meltem": { "name": "Meltem Kapısı", "lat": 36.8925, "lng": 30.6488 }
  },
  "ring_schedule": {
    "au102_gidis": {
      "weekday": ["07:30", "08:00", "08:30"],
      "weekend": ["09:00", "11:00", "14:00"],
      "stops": ["rektorluk", "ziraat", "meltem"]
    },
    "au102_donus": {
      "weekday": ["07:45", "08:15"],
      "weekend": ["09:30"],
      "stops": ["meltem", "ziraat", "rektorluk"]
    }
  }
}
```

#### Yemekhane veri kuralları

- `cafeteria_menu/{tarih}` **düz bir dizidir**, öğün alt düğümü yoktur.
  Üniversite gün başına tek bir liste yayınlar.
- Kalori isteğe bağlıdır ve satırın sonuna `- 450 kcal` biçiminde yazılır.
  Girilmeyen satırlar kalori sütununda boş kalır; hiçbiri girilmemişse toplam
  satırı hiç gösterilmez.
- `DailyMenu.fromRtdb` eski `{"lunch": [...], "dinner": [...]}` biçimini de
  okur ama **yalnızca ilk öğünü** alır (kahvaltı < öğle < akşam sırasıyla).
  İkisini birleştirmek günün menüsünü iki katına çıkarıp yanıltıcı oluyordu.
  Bu yalnızca veri düz diziye taşınana kadar geçerli bir ara çözümdür; taşıma
  bittiğinde geriye dönük destek kaldırılabilir.

#### Ring veri kuralları

- **Hat anahtarı `<hatKodu>_<yön>` biçimindedir** — `au102_gidis`, `au102_donus`.
  Hat listesi bu anahtarlardan türetilir; uygulamada sabit hat listesi tutulmaz.
- `ring_stops` ortak bir durak havuzudur; hatlar `stops` dizisiyle **sıralı**
  referans verir (kalkış noktasından varış noktasına). Bir durak birden çok
  hatta geçebilir; "bu duraktan hangi hatlar geçiyor" bu referanslardan
  hesaplanır.
- `stops` alanı **opsiyoneldir**. Girilmediğinde uygulama yön seçicide gerçek
  durak adları yerine "Gidiş / Dönüş"e düşer ve "Yakındaki Duraklar" girişini
  hiç göstermez — uydurma durak adı gösterilmez.
- **Durak bazlı saat yayınlanmaz.** `weekday` / `weekend` dizileri yalnızca
  hattın *kalkış noktasından* ayrılma saatleridir. Bu yüzden arayüzde hiçbir
  yerde durağa "varış" süresi gösterilmez; dil her zaman "kalkış"tır.

---

## Kimlik Doğrulama

- Yalnızca `@ogr.akdeniz.edu.tr` uzantılı e-posta adresleriyle kayıt ve giriş yapılabilir.
- Giriş yöntemi **e-posta + şifre**'dir. Google Sign-In **kullanılmaz**.
- Kayıt sırasında e-posta domain'i `AuthService` içinde kontrol edilir; uygun olmayan adresler reddedilir.
- Firebase e-posta doğrulama (email verification) kaydın ardından gönderilir; doğrulanmamış hesaplar uyarı alır.
- `AuthProvider` oturum durumunu uygulama genelinde yönetir.
- Firestore Security Rules, `request.auth.token.email` ile domain'i sunucu tarafında da doğrular.

---

## Yapılması Gerekenler ✅

- Her model `fromJson`, `toJson`, `copyWith` metodlarına sahip olmalı.
- Tüm Firebase çağrıları yalnızca ilgili feature'ın `services/` klasöründe yapılmalı.
- `ref` ve Riverpod API'si yalnızca `providers/` klasöründe kullanılmalı.
- `pages/` içinde yalnızca UI kodu bulunmalı; iş mantığı provider'lara taşınmalı.
- Sayfaya özel widget'lar ilgili sayfanın `components/` alt klasörüne konulmalı.
- Birden fazla feature'da kullanılan widget'lar `shared/components/` altına alınmalı.
- Birden fazla feature'da kullanılan servisler `shared/services/` altına alınmalı.
- Hata yönetimi `services/` katmanında `try/catch` ile yapılmalı.
- Tüm Firestore stream'leri provider'larda `StreamProvider` ile sarılmalı.
- Navigasyon yalnızca `app/router.dart` üzerinden `go_router` ile yapılmalı.
- Yemek rating'i gönderilirken Firestore transaction kullanılmalı — `avgRating` ve `ratingCount` atomik güncellenmelidir.

---

## Kaçınılması Gerekenler 🚫

- `pages/` veya `providers/` içinde `FirebaseFirestore.instance` çağrısı yapma.
- `services/` içinde `ref`, `context` veya herhangi bir widget kullanma.
- Aynı Firebase koleksiyonu için birden fazla servis dosyası oluşturma.
- `BuildContext`'i provider veya service'e parametre olarak geçirme.
- Model sınıflarına Flutter import'u ekleme (`import 'package:flutter/...'`).
- `StatefulWidget` kullanarak UI state'ini `setState` ile yönetme — bunun yerine Riverpod kullan.
- Doğrudan `FirebaseAuth.instance.currentUser` kontrolü page'lerde yapma — `authProvider`'ı kullan.
- Realtime DB yerine Firestore'u sık güncellenen veriler (ring, menü) için kullanma — maliyet artar.
- `pages/` içinde iç içe `Consumer` widget'ları oluşturma — provider'ları üst seviyede izle.
- Yorum veya etkinlik verisi için Realtime DB kullanma — bunlar Firestore'a aittir.
- Bir feature'ın `services/` veya `providers/` dosyasını başka bir feature doğrudan import etme — paylaşılan mantık `shared/` altına taşınmalı.
- Google Sign-In kullanma — auth yöntemi yalnızca e-posta + şifredir.
- Kullanıcının aynı güne ait ikinci rating girişine izin verme — `ratings/{uid}` dökümanı zaten varsa işlemi reddet.
- `avgRating` ve `ratingCount` alanlarını client'tan direkt yazma — bunlar yalnızca Cloud Function veya transaction ile güncellenmeli.

---

## Bağımlılıklar (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.x
  go_router: ^13.x
  cloud_firestore: ^4.x
  firebase_auth: ^4.x
  firebase_database: ^10.x
  firebase_storage: ^11.x
  cached_network_image: ^3.x
  flutter_local_notifications: ^17.x
  google_maps_flutter: ^2.x
  intl: ^0.19.x
```

---

## Önemli Notlar

- OBS sayfası `WebView` ile açılır — native entegrasyon yoktur.
- Kampüs haritası Google Maps üzerinde statik marker'larla gösterilir.
- Yemekhane menüsü ve ring saatleri üniversite tarafından manuel olarak Realtime DB'ye girilir.
- Kulüp etkinliği oluşturma yetkisi yalnızca `adminUid` eşleşen kullanıcılara Firestore Security Rules ile korunur.
- Öğrenci etkinlikleri (`student-events`) tüm giriş yapmış öğrenciler tarafından oluşturulabilir; silme ve düzenleme yalnızca `authorUid` eşleşen kullanıcıya açıktır.
- Yemek rating'leri Firestore'da tutulur (`cafeteria_ratings`). Her öğrenci bir yemeğe günde yalnızca 1 kez oy verebilir; bu kural `ratings/{uid}` dökümanının varlığı kontrol edilerek `cafeteria_service.dart` içinde uygulanır. `avgRating` ve `ratingCount` Firestore transaction ile atomik güncellenir. Puanla birlikte isteğe bağlı bir yorum (`comment`) ve yazarın o anki adı (`authorName`, `AppUser.name`'den denormalize) kaydedilir; diğer öğrenciler bu yorumları yemek kartının altında görebilir.
