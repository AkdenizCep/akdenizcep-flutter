---
title: Öğrenci doğrulama
type: concept
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: lib/features/auth/services/auth_service.dart
    sha: 089b8e8
  - path: firestore.rules
    sha: 0c42d94
---

# Öğrenci doğrulama

## Tanım

Uygulamaya yalnızca Akdeniz Üniversitesi öğrencileri girebilir. Bu, üç ayrı mekanizmanın üst üste binmesiyle sağlanıyor — her biri farklı bir saldırıyı kapatıyor.

## Projede nasıl uygulanıyor

**1. Client tarafı domain kontrolü.** `AuthService._validateEmailDomain` (`auth_service.dart:91`) e-postanın `@` sonrasını `ogr.akdeniz.edu.tr` ile karşılaştırıyor. Kayıt, giriş ve şifre sıfırlamanın üçünde de çağrılıyor. Bu bir güvenlik sınırı değil, kullanıcıya erken ve Türkçe hata verme yolu.

**2. E-posta doğrulama.** Kayıttan sonra Firebase doğrulama e-postası gönderiliyor. `router.dart:52-54` doğrulanmamış kullanıcıyı `/verify-email` ekranına kilitliyor. Asıl koruma bu: e-posta adresinin gerçekten o kişiye ait olduğunu kanıtlıyor.

**3. Sunucu tarafı kural.** `isAkdenizStudent()` fonksiyonu `request.auth.token.email` üzerinde regex çalıştırıyor:

```
request.auth.token.email.matches('.*@ogr[.]akdeniz[.]edu[.]tr$')
```

Bu, Firestore'daki neredeyse **her** okuma ve yazmanın önkoşulu. Client atlanabilir, bu atlanamaz.

## Dikkat edilecek bir boşluk

Kural `email_verified` alanını **kontrol etmiyor**. Yani doğrulanmamış bir hesap, uygulamayı atlayıp doğrudan Firestore'a giderse veriye erişebilir. Doğrulama kilidi yalnızca `router.dart`'ta, yani yalnızca client'ta.

> **Açık soru (2026-07-28):** `isAkdenizStudent()` fonksiyonuna `request.auth.token.email_verified == true` eklenmeli mi? Ekleme maliyeti düşük, kapattığı boşluk gerçek. Karşı argüman: kayıt akışında doğrulama öncesi `users/{uid}` dokümanı yazılıyor (`auth_service.dart:45`) — kural sıkılaştırılırsa bu yazma reddedilir ve kayıt kırılır.

## İlgili sayfalar

[[wiki/decisions/003-eposta-domain-kisiti]] · [[wiki/features/auth]] · [[wiki/concepts/guvenlik-kurallari-ile-yetkilendirme]] · [[wiki/data/users]]
