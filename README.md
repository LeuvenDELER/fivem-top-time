Markdown
# PAV Top Time & Admin System

FiveM sunucuları için geliştirilmiş; en iyi tur/süre derecelerini kaydedip listeleyen ve aynı zamanda yetkili/admin işlevleri sunan bir scripttir.

---

## 🛠️ Özellikler

* **Top Time Tabela / Menüsü:** Oyuncuların en iyi sürelerini görsel grafikler ve özel fontlar (`BebasNeueBold`, `Roboto-Bold`) eşliğinde sergiler.
* **Gelişmiş Arayüz (UI):** Temiz, performanslı ve özelleştirilmiş dairesel grafikler (`circle.png`) içerir.
* **Yetkili (Admin) Komutları:** Sunucu yöneticilerinin turları, süreleri ve oyuncu verilerini anlık olarak yönetebilmesini sağlar.
* **Düşük Resmon (Performans):** İstemci (Client) ve sunucu (Server) tarafında optimize edilmiş kod yapısı.

---

## 📥 Kurulum

1. İndirdiğiniz `pav_toptime` klasörünü FiveM sunucunuzun `resources` dizinine atın.
2. `server.cfg` dosyanızı açın ve aşağıdaki satırı ekleyin:
   ```cfg
   ensure pav_toptime
Sunucunuzu başlatın veya oyun içinden refresh ardından ensure pav_toptime komutunu çalıştırın.

📂 Dosya Yapısı
Plaintext
pav_toptime/
│
├── assets/
│   ├── BebasNeueBold.otf   # Arayüz başlık fontu
│   ├── Roboto-Bold.otf      # Arayüz metin fontu
│   └── circle.png           # Arayüz dairesel görsel bileşeni
│
└── README.md                # Dokümantasyon
⚙️ Gereksinimler & Yapılandırma
SQL/Database: Eğer süreler veritabanına kaydediliyorsa, paketinizle gelen .sql dosyasını veritabanınıza içe aktarmayı (import) unutmayın.

Font Kullanımı: Arayüz (NUI) tarafında özel fontlar tanımlanmıştır. CSS dosyalarında bu fontların doğru çağrıldığından emin olun.

🤝 Destek ve İletişim
Herhangi bir hata veya öneri durumunda lütfen geliştirici ile iletişime geçin.

discord:reaeperr
