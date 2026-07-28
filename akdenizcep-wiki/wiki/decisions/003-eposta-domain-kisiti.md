---
title: 003 — E-posta domain kısıtı
type: decision
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/firestore-rules]]"
  - "[[wiki/sources/kod-tabani]]"
code_refs:
  - path: lib/features/auth/services/auth_service.dart
    sha: 089b8e8
---

# 003 — E-posta domain kısıtı

## Bağlam

Uygulama Akdeniz Üniversitesi öğrencilerine özel. Bir kimlik doğrulama yöntemi seçilmesi ve öğrenciliğin nasıl kanıtlanacağının belirlenmesi gerekiyordu.

## Karar

- Giriş yöntemi **yalnızca e-posta + şifre**. Google Sign-In kullanılmayacak.
- Yalnızca `@ogr.akdeniz.edu.tr` uzantılı adresler kabul edilecek.
- Kısıt hem client'ta hem Firestore kurallarında uygulanacak.

## Gerekçe

Öğrencilik durumunun tek doğrulanabilir işareti üniversite e-posta adresi. Google Sign-In açık olsaydı kullanıcılar kişisel Gmail hesaplarıyla girmeye çalışırdı ve domain kısıtı ancak sağlayıcıdan dönen adrese bakılarak, yani daha kırılgan biçimde uygulanabilirdi. E-posta+şifre akışı kısıtı kayıt anında ve tek noktada uygulamayı mümkün kılıyor.

Sunucu tarafındaki regex, client'ın atlanabileceği gerçeğine karşı savunma:

```
request.auth.token.email.matches('.*@ogr[.]akdeniz[.]edu[.]tr$')
```

## Sonuçları

**Kazanılan:** Öğrenci numarası doğrulama, kart okutma, üniversite API'si entegrasyonu — hiçbiri gerekmiyor. Firebase'in kendi e-posta doğrulaması yeterli kanıtı üretiyor.

**Ödenen:**

- Akademik ve idari personel uygulamayı kullanamıyor (`@akdeniz.edu.tr` reddediliyor)
- Mezun olan öğrencinin e-postası kapanırsa hesabı erişilemez hâle gelir; veri taşıma yolu yok
- Domain kısıtı `login()` içinde de çalıştığı için (`auth_service.dart:65`), kısıt ileride gevşetilse bile eski hesaplar etkilenir
- Kural `email_verified` kontrolü yapmıyor — doğrulanmamış hesap Firestore'a doğrudan erişebilir. Ayrıntı: [[wiki/concepts/ogrenci-dogrulama]]

## Kaynak

`DEVELOPMENT.md` → "Kimlik Doğrulama" bölümü; `firestore.rules` `isAkdenizStudent()`; `auth_service.dart:8,91-98`.
