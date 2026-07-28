---
title: auth
type: feature
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/kod-tabani]]"
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/firestore-rules]]"
code_refs:
  - path: lib/features/auth/services/auth_service.dart
    sha: 089b8e8
  - path: lib/app/router.dart
    sha: 089b8e8
---

# auth

## Sorumluluk

Kayıt, giriş, şifre sıfırlama, e-posta doğrulama ve oturum durumu. Uygulamanın **kapısı** — [[wiki/decisions/003-eposta-domain-kisiti]] burada uygulanır.

## Tükettiği veri

| Yol | İşlem |
| --- | --- |
| Firebase Auth | e-posta+şifre, doğrulama e-postası, şifre sıfırlama |
| [[wiki/data/users]] | kayıtta doküman oluşturur |

## Komşu feature'lar

Doğrudan komşusu yok — çıktısı `authStateProvider` üzerinden **tüm uygulamaya** yayılır. `router.dart` bu provider'ı izleyip yönlendirme yapar; [[wiki/features/profile]] çıkış ve şifre değiştirme için kullanır.

## Kararlar

- **Yalnızca e-posta + şifre.** Google Sign-In yok. Sebep: domain kısıtı ancak kontrol edilebilen bir kayıt akışıyla zorlanabilir. Bkz. [[wiki/decisions/003-eposta-domain-kisiti]].
- **Domain kontrolü iki katmanda.** `AuthService._validateEmailDomain` client'ta (`auth_service.dart:91`), `isAkdenizStudent()` sunucuda. Bkz. [[wiki/concepts/ogrenci-dogrulama]].
- **`userChanges()` ayrı bir stream.** `authStateChanges()` `emailVerified` değişimini yaymıyor; doğrulama ekranının çalışması için `userChanges()` gerekti (`auth_service.dart:14-16`). Kod içindeki yorum bunu açıklıyor.
- **Üç aşamalı yönlendirme.** `router.dart:40-57`: giriş yok → `/login`; giriş var ama doğrulanmamış → `/verify-email`; ikisi de tamam → `/home`. Ara durum kullanıcıyı uygulamada dolaşmaktan alıkoyuyor.
- **Hata mesajları Türkçe ve eşlenmiş.** `_mapAuthError` Firebase kodlarını kullanıcıya gösterilecek Türkçe metne çeviriyor — ham Firebase hatası hiç görünmüyor.

## Açık sorular

- `login()` de domain doğrulaması yapıyor. Domain kısıtı sonradan değişirse (ör. akademik personel eklenirse) mevcut hesaplar giriş yapamaz hâle gelir.
- Şifre sıfırlama e-postası gönderilirken domain kontrolü var, ama kayıtlı olmayan bir adres için Firebase yine de sessiz kalıyor — kullanıcıya "gönderildi" denip denmediği doğrulanmadı.
