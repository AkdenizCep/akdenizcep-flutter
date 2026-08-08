---
title: 006 — Durak bazlı saat yayınlanmaz
type: decision
updated: 2026-07-28
status: current
sources:
  - "[[wiki/sources/development-md]]"
  - "[[wiki/sources/realtime-db-json]]"
code_refs:
  - path: lib/features/ring/models/ring_schedule.dart
    sha: a32558f
---

# 006 — Durak bazlı saat yayınlanmaz

## Bağlam

Üniversitenin yayınladığı ring verisi yalnızca hattın **kalkış noktasından** ayrılış saatlerini içeriyor. Ara duraklara ne zaman varılacağı bilgisi yok. Kullanıcının asıl sorduğu soru ise "benim durağıma kaçta gelecek".

Bu boşluk, kalkış saati + durak sırası + tahmini yol süresiyle doldurulabilirdi.

## Karar

**Tahmin üretilmeyecek.** Arayüzde hiçbir yerde durağa "varış" süresi gösterilmeyecek; dil her zaman "kalkış" olacak.

Aynı ilkenin ikinci uygulaması: `stops` dizisi girilmemişse yön seçicide gerçek durak adları yerine "Gidiş / Dönüş" gösterilir ve "Yakındaki Duraklar" girişi hiç açılmaz. `DEVELOPMENT.md`'nin ifadesiyle: "uydurma durak adı gösterilmez".

## Gerekçe

Yanlış bir varış tahmini, hiç tahmin olmamasından kötüdür — kullanıcı otobüsü kaçırır ve uygulamaya güvenmeyi bırakır. Trafik, yolcu yoğunluğu ve kampüs içi değişkenlik, sabit yol süresiyle yapılacak tahmini güvenilmez kılar.

Karar, veri eksikliğini gizlemek yerine görünür kılmayı seçiyor. Aynı ilke `firebase/README.md`'de de tekrarlanıyor: durak adları `__DOLDUR__` iken yüklenmemeli, "çünkü bu adlar doğrudan uygulamada görünür".

## Sonuçları

**Kazanılan:** Uygulama söylediği her şeyde doğru. Gösterilen her saat üniversitenin yayınladığı gerçek veriden geliyor.

**Ödenen:**

- Kullanıcının asıl sorusu cevapsız kalıyor
- Veri eksikse arayüzün bir kısmı bütünüyle boş kalıyor — bugün üretimde tam olarak bu yaşanıyor. [[wiki/data/ring-stops]] boş olduğu için durak listesi, harita ve en yakın durak özellikleri çalışmıyor. Bu, kararın bilinçli ve kabul edilmiş bedeli: kod doğru davranıyor, eksik olan veri.
- [[wiki/features/ring]]'in 18 bileşeninin bir kısmı bugün hiç görünmüyor

## Kaynak

`DEVELOPMENT.md` → "Ring veri kuralları"; `firebase/README.md` → "İçe aktarmadan önce".
