# 💊 İlaç Takip Uygulaması

Sabah/akşam ilaçlarını takip eden, alarm kurabilen Android uygulaması.

## Özellikler

- ✅ 2-3 ilaç ekleyip isimlendirebilirsin
- ☀️ Sabah dozu işaretleme
- 🌙 Akşam dozu işaretleme
- ⏰ Her ilaç için sabah/akşam alarm saati
- 🔔 Bildirim ile hatırlatma
- 📅 Son 30 günlük geçmiş
- 📊 Günlük ilerleme çubuğu

---

## APK Nasıl Alınır? (Ücretsiz, Kurulum Yok)

### Yöntem 1: Codemagic.io (En Kolay)

1. **https://codemagic.io** adresine git
2. GitHub/GitLab ile giriş yap (ücretsiz)
3. Bu klasörü GitHub'a yükle (ZIP olarak da kabul eder)
4. "Flutter App" seç
5. "Start your first build" tıkla
6. Build tamamlanınca APK indir (~10 dakika)

### Yöntem 2: FlutterLab.dev (Direkt Upload)

1. **https://flutterlab.dev** adresine git
2. Projeyi ZIP olarak yükle
3. Build al

### Yöntem 3: Kendi Bilgisayarında

Flutter kuruluysa:
```bash
cd ilac_takip
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

---

## Projeyi ZIP Olarak GitHub'a Yükleme

1. https://github.com adresine git
2. "New repository" → isim ver → Create
3. "uploading an existing file" linkine tıkla
4. Tüm dosyaları sürükle bırak
5. "Commit changes" tıkla

---

## Uygulama Kullanımı

1. **İlaç Ekle** butonuna bas → ilaç adını yaz
2. İlaç kartında **Sabah** veya **Akşam** kutusuna tıkla → ilaç alındı işaretlenir
3. **Alarm Ekle** butonuna bas → saat seç → otomatik bildirim kurulur
4. **Geçmiş** sekmesinden eski günleri gör

---

## Teknik Bilgi

- Flutter 3.x
- Bildirimler: flutter_local_notifications
- Veri saklama: shared_preferences (telefonda yerel)
- Min Android: 5.0 (API 21)
