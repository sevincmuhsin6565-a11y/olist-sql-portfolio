# Olist E-Ticaret SQL Analizi

🇬🇧 [English version](README.md)

Brezilyalı e-ticaret pazar yeri Olist'e ait ~100 bin siparişin (2016–2018) PostgreSQL ile yapılmış
SQL analizi. Proje; satış trendleri, ürün kategorileri, teslimat operasyonu, müşteri yorumları,
satıcı performansı ve tekrar alışverişi kapsıyor. Her soru bir metrik tanımıyla başlıyor,
bir doğrulama adımı ve temkinli bir yorumla bitiyor.

**Araçlar:** PostgreSQL · DataGrip · Git/GitHub
**Veri seti:** [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

## Proje hakkında

Bu, Udemy'de Nafiz Altay'ın sektör odaklı SQL kursunu tamamladıktan sonra hazırladığım ilk SQL
portföy projem. Amacım SQL'i gerçek bir veri setinde uygulamak ve sorguların sadece çalıştığından
değil, sonuçların doğru olduğundan emin olmaktı. Endüstri Mühendisliği öğrencisi olarak teslimat
ve satıcı sonuçlarını operasyonel bir bakışla da okudum (tedarik süresi, hizmet seviyesi,
önceliklendirme).

---

## Yaklaşım

**İş sorusu → Metrik tanımı → Gerekli tablolar → SQL → Doğrulama → Yorum**

### Sonuçlar nasıl kontrol edildi?

| Uygulama | Projeden örnek |
|---|---|
| **Grain kontrolü** | Her tablo için `COUNT(*)` ile `COUNT(DISTINCT key)` karşılaştırıldı ([`schema/03`](schema/03_grain_checks.sql)). `order_reviews` tablosunun sipariş başına benzersiz olmadığı bulundu (551 siparişin birden fazla yorumu var). |
| **Metrik tanımı** | Her analiz dosyasının başında yazılı. Kalemlerle join sonrası siparişler `COUNT(DISTINCT order_id)` ile, müşteriler `customer_unique_id` ile sayıldı (`customer_id` kullanılsaydı tekrar alışveriş oranı %0 çıkardı). |
| **Fan-out'u önleme** | Yorumlar join'den önce sipariş seviyesine indirildi (S4). Satıcı metrikleri (satıcı, sipariş) seviyesinde hesaplandı; böylece bir gecikme veya yorum sipariş başına bir kez sayıldı (S5). |
| **Doğrulama / mutabakat** | S1: aylık sorgudaki teslim edilmiş sipariş = 96.478 (`orders` ile aynı). S2: kategori gelirlerinin toplamı = toplam teslim edilmiş gelir (13.221.498,11). S4: yorumlu 95.824 sipariş = 96.470 teslim edilmiş sipariş − yorumsuz 646. S5: 97.811 satıcı-sipariş satırı = benzersiz (satıcı, sipariş) çifti. S7: ABC sınıfları toplamı 74 kategori ve gelirin %100'ü. |
| **NULL yönetimi** | Teslim tarihi olmayan 8 teslim edilmiş sipariş açıkça çıkarıldı (`CASE` ile yapılan zamanında teslim bayrağı onları "geç" sayardı). `LEFT JOIN` + `COALESCE` ile kategorisi ya da çevirisi olmayan 623 ürün korundu. Tahmini teslim tarihleri 00:00 olarak kayıtlı olduğu için tarihler `DATE` tipine çevrildi. |
| **Korelasyon ≠ nedensellik** | Zamanında teslim oranı Kasım 2017'de (hacim zirvesi) düştü; ancak Ocak 2018'de benzer hacimde oran %94,3'tü → düşüşler tek başına hacimle açıklanamıyor. |
| **Performans** | Index eklemeden önce ve sonra `EXPLAIN ANALYZE`; index'in hangi sorgulara yardım edip hangilerine etmediği belgelendi. |

---

## Ana bulgular

| Alan | Sonuç |
|---|---|
| **Satış** | Teslim edilmiş siparişler 2017 boyunca arttı (zirve: Kasım 2017'de 7.288), 2018'de yatay ya da hafif düşük seyretti (Ocak'ta 7.069 → Ağustos'ta 6.351). Ortalama sepet ~125–150 bandında kaldı; yani gelir artışı büyük ölçüde sepet tutarıyla değil, sipariş hacmiyle açıklanıyor. |
| **Ürün kategorileri** | 74 kategoriden 17'si (%23) gelirin %79,7'sini oluşturuyor; ilk 10 kategori %62. `bed_bath_table` en çok ürünü düşük ortalama fiyatla (~93) satıyor; `watches_gifts` bunun yaklaşık yarısı kadar ürünü ~199 ortalama fiyatla satıyor. |
| **Teslimat** | Aylık ortalama teslim süresi ~11–17 gün, söz verilen süre ~23–28 gün. Zamanında teslim oranı çoğu ayda %93–97; en düşük değer Mart 2018'de %81 — o ay yavaşlayan teslimatlar, dönemin en kısa teslim sözüyle aynı zamana denk geldi. |
| **Yorumlar** | Geç siparişler: ortalama puan 2,27, düşük puan (1–2) oranı %62,5. Zamanında siparişler: 4,29 ve %9,3. Güçlü bir ilişki; başka faktörler (satıcı, bölge) her ikisini de etkileyebilir. |
| **Satıcılar** | Gelire göre ilk 10 satıcının 5'inin gecikme oranı, platform ortalamasının (%6,77) üstünde (en yüksek: %10,5). |
| **Tekrar alışveriş** | 93.358 müşteriden 2.801'inin (%3,0) 2 veya daha fazla teslim edilmiş siparişi var; sipariş tabanına tek seferlik alıcılar hâkim. |
| **Sorgu performansı** | `order_items.seller_id` üzerine eklenen index, tek satıcılık bir sorguyu tam tablo taraması yerine index taraması kullandırarak 70,5 ms'den 41,3 ms'ye indirdi (~%41). |

---

## Operasyonel bakış açısı

- **Bir süreç olarak teslimat:** Teslimat iki KPI ile ölçüldü: tedarik süresi (hız) ve
  zamanında teslim oranı (hizmet seviyesi). Çünkü biri iyileşirken diğeri kötüleşebilir.
  Söz verilen ve gerçekleşen teslim arasındaki ~10–12 günlük fark, yüksek zamanında teslim
  oranıyla tutarlı. Daha kısa söz vermenin satışları artırıp artırmayacağı bu veriyle ölçülemiyor.
- **ABC sınıflandırması:** Stok önceliklendirmede kullanılan standart yöntem kategorilere
  uygulandı. Yönetim dikkatinin nerede daha önemli olduğunu gösteriyor; hangi kategorilerin
  kapatılacağını göstermiyor.
- **Satıcı karnesi:** Satıcılar sadece gelirle değil; hacim, gecikme oranı ve yorum puanı
  birlikte, bir platform referans değerine göre karşılaştırıldı.
- **Ölç → değiştir → tekrar ölç:** Index çalışması bu döngüyü izledi. `order_items` taraması
  kaldırılınca, plandaki en büyük kalan maliyet `orders` taraması oldu.

---

## Proje yapısı

```
├── schema/
│   ├── 01_create_tables.sql          # tablo tanımları
│   ├── 02_row_counts.sql             # import kontrolü (Kaggle kaynağıyla karşılaştırma)
│   └── 03_grain_checks.sql           # bir satır neyi temsil ediyor?
├── diagrams/
│   └── erd.md                        # varlık-ilişki diyagramı (Mermaid)
├── analysis/
│   ├── 01_data_quality_checks.sql
│   ├── 02_monthly_sales_trend.sql
│   ├── 03_top_categories_by_revenue.sql
│   ├── 04_delivery_performance.sql
│   ├── 05_late_delivery_vs_reviews.sql
│   ├── 06_seller_performance.sql
│   ├── 07_repeat_customers.sql
│   └── 08_category_pareto_abc.sql    # window function'lar
├── optimization/
│   └── 01_seller_lookup_index.sql    # EXPLAIN ANALYZE önce/sonra
└── documentation/
    └── assumptions.md                # veri kararları ve metrik kuralları
```

---

## Veri kalitesi ve temel kararlar

Ham veri hiçbir zaman değiştirilmedi; sorunlar sorgulardaki filtrelerle ele alındı.
Tam liste: [`documentation/assumptions.md`](documentation/assumptions.md)

- `customer_id` her sipariş için üretiliyor → gerçek müşteriler `customer_unique_id` ile sayıldı.
- `order_reviews` sipariş başına benzersiz değil → yorumlar join'den önce sipariş seviyesine
  indirildi; birden fazla yorumu olan siparişlerde en düşük puan kullanıldı.
- Teslim edilmiş 8 siparişin teslim tarihi yok → teslimat metriklerinden çıkarıldı.
- 610 ürünün kategorisi, 13 ürünün İngilizce çevirisi yok → `LEFT JOIN` + yedek etiket;
  böylece hiçbir gelir düşmedi.
- Gelir = teslim edilmiş siparişlerde `SUM(order_items.price)` (kargo hariç).

---

## Kullanılan SQL teknikleri

- Dört tabloya kadar `INNER JOIN` ve `LEFT JOIN`
- Çok adımlı CTE zincirleri dahil CTE'ler
- Window function'lar: `RANK()`, `SUM() OVER ()`,
  `SUM() OVER (ORDER BY ... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` ile birikimli toplam
- Aggregation: `COUNT(DISTINCT ...)` (bileşik anahtarlar dahil), `SUM`, `AVG`, `MIN` / `MAX`,
  `COUNT(*) FILTER (WHERE ...)`
- Bayrak, oran ve sınıflandırma için `CASE WHEN`
- Tarihler: `DATE_TRUNC`, `TO_CHAR`, `::date` dönüşümü ve tarih farkı
- Yedek etiket için `COALESCE`
- `UNION ALL` (import satır sayısı kontrolü)
- `EXPLAIN ANALYZE`, `CREATE INDEX`, `ANALYZE`

---

## Kısıtlar

- **Gözlemsel veri:** Tüm ilişkiler (örneğin geç teslimat ve düşük puan) birlikteliktir,
  kanıtlanmış nedenler değil.
- **Eksik 2016 verisi:** 2016-09 ve 2016-12'de birer sipariş var, 2016-11'de hiç yok.
- **2018 sonu kesintisi:** Eylül–Ekim 2018 siparişlerinin çoğu, veri toplandığında henüz teslim
  edilmemişti; bu yüzden teslim edilmiş filtresinin dışında kalıyorlar. Trendler 2017-01 ile
  2018-08 arası için okunuyor.
- **Çok satıcılı siparişler:** Teslim tarihi ve yorumlar sipariş seviyesinde; bu yüzden birden
  fazla satıcılı siparişlerde bir gecikme ya da yorum siparişteki her satıcıya atfediliyor.
- **Tekrar alışveriş oranındaki yanlılık:** İlk siparişini 2018 sonunda veren müşterilerin
  geri dönmek için az zamanı oldu; bu yüzden %3,0'lık oran muhtemelen gerçek oranın altında.

---

## Nasıl yeniden üretilir?

1. Veri setini Kaggle'dan indir (CSV dosyaları bu repoda yok).
2. `schema/01_create_tables.sql` ile tabloları oluştur ve CSV'leri import et.
3. Import'u doğrulamak için `schema/02_row_counts.sql` dosyasını çalıştır.
4. `analysis/` klasöründeki dosyaları sırayla çalıştır.

---

## Yapay zekâ kullanımı

Bu projede yapay zekâ araçları bir öğretmen ve inceleyici olarak kullanıldı. Claude, sorular ve
ipuçlarıyla çalışma akışını yönlendirdi; sorgularımı mantık hataları açısından inceledi (grain,
JOIN'ler, NULL yönetimi, metrik tanımları) ve dosyaların formatlanmasına ve dokümantasyon
taslağına yardım etti. Window function analizi dahil bazı sorularda yapay zekânın önerdiği
çözümleri (Claude, Gemini) inceledim ve kullanmadan önce mantığını adım adım çözdüm.

Tüm sorgular DataGrip'te çalıştırıldı ve sonuçlar, yukarıda anlatıldığı gibi bağımsız toplamlarla
kontrol edildi. Bu repodaki her sorgunun mantığını açıklayabilirim.

---

**Hazırlayan:** Muhsin Sevinç — Endüstri Mühendisliği öğrencisi