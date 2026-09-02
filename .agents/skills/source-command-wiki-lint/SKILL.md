---
name: "source-command-wiki-lint"
description: "akdenizcep-wiki sağlık taraması"
---

# source-command-wiki-lint

Use this skill when the user asks to run the migrated source command `wiki-lint`.

## Command Template

`akdenizcep-wiki/AGENTS.md` şemasını oku ve ona uy. Ardından wiki'yi tara.

Kontroller:

1. **Bayatlık.** Her sayfanın `code_refs` girdileri için `git log -1 --format=%h -- <path>` çalıştır. Dosya kayıtlı `sha`'dan sonra değişmişse sayfayı listele. Kullanıcı onaylarsa `status: stale` yap.
2. **Kırık linkler.** Her `[[hedef]]` için `akdenizcep-wiki/<hedef>.md` dosyasının var olduğunu doğrula — linkler vault köküne göre tam yoldur (`[[wiki/features/ring]]`). `wiki/` öneki olmayan link kırıktır ve Obsidian'da tıklanınca vault kökünde boş dosya oluşturur.
3. **Yetim sayfalar.** Hiçbir sayfadan gelen linki olmayanlar (`index.md`'den gelen link sayılmaz).
4. **Eksik yollar.** Her `code_refs.path` diskte var mı.
5. **Çelişkiler.** Sayfalar arası tutarsızlıklar; ayrıca çözülmemiş `> **Çelişki`  bloklarını listele.
6. **Eksik sayfalar.** Birden çok sayfada geçen ama kendi sayfası olmayan kavramlar.

Bulguları başlıklar altında raporla. **Kendiliğinden toplu düzeltme yapma** — hangi düzeltmelerin uygulanacağını kullanıcı seçsin. Uygulananları `log.md`'ye `lint` tipi girdiyle yaz.
