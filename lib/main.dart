import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const IlacTakipApp());
}

class IlacTakipApp extends StatelessWidget {
  const IlacTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D7DD2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AnaSayfa(),
    );
  }
}

class Ilac {
  String id;
  String isim;
  bool sabahAlindi;
  bool ogleAlindi;
  bool aksamAlindi;
  TimeOfDay? sabahSaati;
  TimeOfDay? ogleSaati;
  TimeOfDay? aksamSaati;
  bool sabahAlarmAktif;
  bool ogleAlarmAktif;
  bool aksamAlarmAktif;
  String tarih;
  String? haftaGunu;

  Ilac({
    required this.id,
    required this.isim,
    this.sabahAlindi = false,
    this.ogleAlindi = false,
    this.aksamAlindi = false,
    this.sabahSaati,
    this.ogleSaati,
    this.aksamSaati,
    this.sabahAlarmAktif = false,
    this.ogleAlarmAktif = false,
    this.aksamAlarmAktif = false,
    required this.tarih,
    this.haftaGunu,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isim': isim,
        'sabahAlindi': sabahAlindi,
        'ogleAlindi': ogleAlindi,
        'aksamAlindi': aksamAlindi,
        'sabahSaatSaat': sabahSaati?.hour,
        'sabahSaatDakika': sabahSaati?.minute,
        'ogleSaatSaat': ogleSaati?.hour,
        'ogleSaatDakika': ogleSaati?.minute,
        'aksamSaatSaat': aksamSaati?.hour,
        'aksamSaatDakika': aksamSaati?.minute,
        'sabahAlarmAktif': sabahAlarmAktif,
        'ogleAlarmAktif': ogleAlarmAktif,
        'aksamAlarmAktif': aksamAlarmAktif,
        'tarih': tarih,
        'haftaGunu': haftaGunu,
      };

  factory Ilac.fromJson(Map<String, dynamic> json) {
    return Ilac(
      id: json['id'],
      isim: json['isim'],
      sabahAlindi: json['sabahAlindi'] ?? false,
      ogleAlindi: json['ogleAlindi'] ?? false,
      aksamAlindi: json['aksamAlindi'] ?? false,
      sabahSaati: json['sabahSaatSaat'] != null
          ? TimeOfDay(
              hour: json['sabahSaatSaat'], minute: json['sabahSaatDakika'])
          : null,
      ogleSaati: json['ogleSaatSaat'] != null
          ? TimeOfDay(
              hour: json['ogleSaatSaat'], minute: json['ogleSaatDakika'])
          : null,
      aksamSaati: json['aksamSaatSaat'] != null
          ? TimeOfDay(
              hour: json['aksamSaatSaat'], minute: json['aksamSaatDakika'])
          : null,
      sabahAlarmAktif: json['sabahAlarmAktif'] ?? false,
      ogleAlarmAktif: json['ogleAlarmAktif'] ?? false,
      aksamAlarmAktif: json['aksamAlarmAktif'] ?? false,
      tarih: json['tarih'],
      haftaGunu: json['haftaGunu'],
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<Ilac> ilaclar = [];
  int _selectedIndex = 0;
  late String bugunTarih;

  @override
  void initState() {
    super.initState();
    bugunTarih = _bugunTarih();
    _ilaclarYukle();
  }

  String _bugunTarih() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _ilaclarYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ilaclarJson = prefs.getString('ilaclar_$bugunTarih');

    if (ilaclarJson != null) {
      final List<dynamic> liste = jsonDecode(ilaclarJson);
      setState(() {
        ilaclar = liste.map((e) => Ilac.fromJson(e)).toList();
      });
    } else {
      final String? ilacIsimleriJson = prefs.getString('ilac_isimleri');
      if (ilacIsimleriJson != null) {
        final List<dynamic> isimler = jsonDecode(ilacIsimleriJson);
        setState(() {
          ilaclar = isimler.map((e) {
            final Map<String, dynamic> data = e as Map<String, dynamic>;
            return Ilac(
              id: data['id'],
              isim: data['isim'],
              sabahSaati: data['sabahSaatSaat'] != null
                  ? TimeOfDay(
                      hour: data['sabahSaatSaat'],
                      minute: data['sabahSaatDakika'])
                  : null,
              ogleSaati: data['ogleSaatSaat'] != null
                  ? TimeOfDay(
                      hour: data['ogleSaatSaat'],
                      minute: data['ogleSaatDakika'])
                  : null,
              aksamSaati: data['aksamSaatSaat'] != null
                  ? TimeOfDay(
                      hour: data['aksamSaatSaat'],
                      minute: data['aksamSaatDakika'])
                  : null,
              sabahAlarmAktif: data['sabahAlarmAktif'] ?? false,
              ogleAlarmAktif: data['ogleAlarmAktif'] ?? false,
              aksamAlarmAktif: data['aksamAlarmAktif'] ?? false,
              tarih: bugunTarih,
              haftaGunu: data['haftaGunu'],
            );
          }).toList();
        });
      }
    }
  }

  Future<void> _ilaclarKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    final String ilaclarJson =
        jsonEncode(ilaclar.map((e) => e.toJson()).toList());
    await prefs.setString('ilaclar_$bugunTarih', ilaclarJson);

    final isimlerJson = jsonEncode(ilaclar
        .map((e) => {
              'id': e.id,
              'isim': e.isim,
              'sabahSaatSaat': e.sabahSaati?.hour,
              'sabahSaatDakika': e.sabahSaati?.minute,
              'ogleSaatSaat': e.ogleSaati?.hour,
              'ogleSaatDakika': e.ogleSaati?.minute,
              'aksamSaatSaat': e.aksamSaati?.hour,
              'aksamSaatDakika': e.aksamSaati?.minute,
              'sabahAlarmAktif': e.sabahAlarmAktif,
              'ogleAlarmAktif': e.ogleAlarmAktif,
              'aksamAlarmAktif': e.aksamAlarmAktif,
              'haftaGunu': e.haftaGunu,
            })
        .toList());
    await prefs.setString('ilac_isimleri', isimlerJson);
  }

  void _ilacEkle() {
    String yeniIsim = '';
    bool sabahSecili = true;
    bool ogleSecili = false;
    bool aksamSecili = true;
    bool haftadaBirSecili = false;
    String secilenGun = 'Pazartesi';

    // ✅ Haftalık ilaç için saat — dialog içinde seçilecek
    TimeOfDay haftaIlacSaati = const TimeOfDay(hour: 8, minute: 0);
    bool haftaAlarmAktif = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('İlaç Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İlaç adı
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'İlaç adı (örn: Beloc, D vitamini)',
                        border: OutlineInputBorder(),
                        labelText: 'İlaç Adı',
                      ),
                      onChanged: (value) => yeniIsim = value,
                    ),
                    const SizedBox(height: 16),

                    // Kullanım zamanı başlığı
                    const Text(
                      'Kullanım Zamanı:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Sabah checkbox
                    CheckboxListTile(
                      title: const Row(
                        children: [
                          Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Sabah'),
                        ],
                      ),
                      value: sabahSecili,
                      onChanged: haftadaBirSecili
                          ? null
                          : (v) => setDialogState(() => sabahSecili = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),

                    // Öğle checkbox
                    CheckboxListTile(
                      title: const Row(
                        children: [
                          Icon(Icons.light_mode, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text('Öğle'),
                        ],
                      ),
                      value: ogleSecili,
                      onChanged: haftadaBirSecili
                          ? null
                          : (v) => setDialogState(() => ogleSecili = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),

                    // Akşam checkbox
                    CheckboxListTile(
                      title: const Row(
                        children: [
                          Icon(Icons.nights_stay,
                              color: Colors.indigo, size: 20),
                          SizedBox(width: 8),
                          Text('Akşam'),
                        ],
                      ),
                      value: aksamSecili,
                      onChanged: haftadaBirSecili
                          ? null
                          : (v) => setDialogState(() => aksamSecili = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),

                    const Divider(),

                    // Haftada bir checkbox
                    CheckboxListTile(
                      title: const Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.teal, size: 20),
                          SizedBox(width: 8),
                          Text('Haftada Bir'),
                        ],
                      ),
                      value: haftadaBirSecili,
                      onChanged: (v) => setDialogState(() {
                        haftadaBirSecili = v!;
                        if (haftadaBirSecili) {
                          sabahSecili = false;
                          ogleSecili = false;
                          aksamSecili = false;
                        }
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),

                    // ✅ Haftada bir seçiliyse: gün + saat + alarm
                    if (haftadaBirSecili) ...[
                      const SizedBox(height: 8),

                      // Gün seçimi
                      DropdownButtonFormField<String>(
                        value: secilenGun,
                        decoration: const InputDecoration(
                          labelText: 'Hangi Gün?',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        items: [
                          'Pazartesi',
                          'Salı',
                          'Çarşamba',
                          'Perşembe',
                          'Cuma',
                          'Cumartesi',
                          'Pazar',
                        ]
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => secilenGun = v!),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Saat seçimi
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        leading: const Icon(Icons.access_time,
                            color: Colors.teal),
                        title: const Text('Hatırlatma Saati'),
                        subtitle: Text(
                          '${haftaIlacSaati.hour.toString().padLeft(2, '0')}:${haftaIlacSaati.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final secilen = await showTimePicker(
                            context: context,
                            initialTime: haftaIlacSaati,
                            helpText: 'Haftalık İlaç Saati',
                          );
                          if (secilen != null) {
                            setDialogState(
                                () => haftaIlacSaati = secilen);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // ✅ Alarm açık/kapalı toggle
                      SwitchListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        secondary: Icon(
                          haftaAlarmAktif
                              ? Icons.alarm_on
                              : Icons.alarm_off,
                          color:
                              haftaAlarmAktif ? Colors.teal : Colors.grey,
                        ),
                        title: const Text('Alarm Kur'),
                        subtitle: Text(
                          haftaAlarmAktif
                              ? 'Alarm açık — ${secilenGun} günü hatırlatılacak'
                              : 'Alarm kapalı',
                        ),
                        value: haftaAlarmAktif,
                        activeColor: Colors.teal,
                        onChanged: (v) =>
                            setDialogState(() => haftaAlarmAktif = v),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (yeniIsim.trim().isEmpty) return;
                    if (!haftadaBirSecili &&
                        !sabahSecili &&
                        !ogleSecili &&
                        !aksamSecili) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Lütfen en az bir kullanım zamanı seçin!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final yeniIlac = Ilac(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      isim: yeniIsim.trim(),
                      tarih: bugunTarih,
                      haftaGunu: haftadaBirSecili ? secilenGun : null,
                      // ✅ Haftalık ilaç saatini sabahSaati alanında saklıyoruz
                      sabahSaati: haftadaBirSecili ? haftaIlacSaati : null,
                      sabahAlarmAktif:
                          haftadaBirSecili ? haftaAlarmAktif : sabahSecili,
                      ogleAlarmAktif: haftadaBirSecili ? false : ogleSecili,
                      aksamAlarmAktif:
                          haftadaBirSecili ? false : aksamSecili,
                    );

                    setState(() => ilaclar.add(yeniIlac));
                    _ilaclarKaydet();

                    // ✅ Alarm aktifse hemen bildirim kur
                    if (haftadaBirSecili && haftaAlarmAktif) {
                      _bildirimKurHaftaIci(yeniIlac, haftaIlacSaati);
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _ilacSil(Ilac ilac) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlaç Sil'),
        content: Text('${ilac.isim} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                ilaclar.removeWhere((e) => e.id == ilac.id);
              });
              _ilaclarKaydet();
              Navigator.pop(context);
            },
            child:
                const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _alarmKur(Ilac ilac, String zaman) async {
    TimeOfDay baslangic;
    String yardimMetni;

    if (zaman == 'sabah') {
      baslangic = ilac.sabahSaati ?? const TimeOfDay(hour: 8, minute: 0);
      yardimMetni = ilac.haftaGunu != null
          ? 'Haftalık Alarm Saati'
          : 'Sabah Alarm Saati';
    } else if (zaman == 'ogle') {
      baslangic = ilac.ogleSaati ?? const TimeOfDay(hour: 12, minute: 0);
      yardimMetni = 'Öğle Alarm Saati';
    } else {
      baslangic = ilac.aksamSaati ?? const TimeOfDay(hour: 20, minute: 0);
      yardimMetni = 'Akşam Alarm Saati';
    }

    final TimeOfDay? secilenSaat = await showTimePicker(
      context: context,
      initialTime: baslangic,
      helpText: yardimMetni,
    );

    if (secilenSaat != null) {
      setState(() {
        if (zaman == 'sabah') {
          ilac.sabahSaati = secilenSaat;
          ilac.sabahAlarmAktif = true;
        } else if (zaman == 'ogle') {
          ilac.ogleSaati = secilenSaat;
          ilac.ogleAlarmAktif = true;
        } else {
          ilac.aksamSaati = secilenSaat;
          ilac.aksamAlarmAktif = true;
        }
      });
      _ilaclarKaydet();

      // Haftalık ilaç için özel bildirim
      if (ilac.haftaGunu != null) {
        _bildirimKurHaftaIci(ilac, secilenSaat);
      } else {
        _bildirimKur(ilac, zaman, secilenSaat);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${ilac.isim} için alarm ${secilenSaat.format(context)} olarak ayarlandı',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _bildirimKur(
      Ilac ilac, String zaman, TimeOfDay saat) async {
    final int base = int.parse(ilac.id.substring(ilac.id.length - 4));
    final int bildirimId = zaman == 'sabah'
        ? base
        : zaman == 'ogle'
            ? base + 500
            : base + 1000;

    await flutterLocalNotificationsPlugin.cancel(bildirimId);

    bool aktif = zaman == 'sabah'
        ? ilac.sabahAlarmAktif
        : zaman == 'ogle'
            ? ilac.ogleAlarmAktif
            : ilac.aksamAlarmAktif;

    if (!aktif) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'ilac_kanal',
      'İlaç Hatırlatıcı',
      channelDescription: 'İlaç alma zamanı bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year, now.month, now.day, saat.hour, saat.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      bildirimId,
      '💊 İlaç Zamanı!',
      '${ilac.isim} alma vakti geldi.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ✅ YENİ: Haftalık ilaç için haftanın belirli gününe bildirim kur
  Future<void> _bildirimKurHaftaIci(Ilac ilac, TimeOfDay saat) async {
    final int base = int.parse(ilac.id.substring(ilac.id.length - 4));
    final int bildirimId = base + 2000;

    await flutterLocalNotificationsPlugin.cancel(bildirimId);

    if (!ilac.sabahAlarmAktif) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'ilac_kanal',
      'İlaç Hatırlatıcı',
      channelDescription: 'İlaç alma zamanı bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    // Haftanın gününü bul
    const gunSirasi = {
      'Pazartesi': DateTime.monday,
      'Salı': DateTime.tuesday,
      'Çarşamba': DateTime.wednesday,
      'Perşembe': DateTime.thursday,
      'Cuma': DateTime.friday,
      'Cumartesi': DateTime.saturday,
      'Pazar': DateTime.sunday,
    };

    final hedefGun = gunSirasi[ilac.haftaGunu] ?? DateTime.monday;
    final now = DateTime.now();

    // Bu haftanın hedef gününü hesapla
    int fark = hedefGun - now.weekday;
    if (fark < 0) fark += 7;
    if (fark == 0 &&
        now.hour * 60 + now.minute >= saat.hour * 60 + saat.minute) {
      fark = 7; // Bu günün saati geçtiyse gelecek haftaya al
    }

    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day + fark,
      saat.hour,
      saat.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      bildirimId,
      '💊 Haftalık İlaç Zamanı!',
      '${ilac.isim} alma vakti geldi. (${ilac.haftaGunu})',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // ✅ Haftada bir tekrar et
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Widget _buildAnaSayfa() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _bugunGoster(),
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'İlaç Takibim',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildIlerleme(),
            ],
          ),
        ),
        Expanded(
          child: ilaclar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined,
                          size: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz ilaç eklenmedi',
                        style:
                            TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sağ alttaki + butonuna basın',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: ilaclar.length,
                  itemBuilder: (context, index) {
                    return _buildIlacKarti(ilaclar[index]);
                  },
                ),
        ),
      ],
    );
  }

  String _bugunGoster() {
    final now = DateTime.now();
    const gunler = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
      'Cuma', 'Cumartesi', 'Pazar'
    ];
    const aylar = [
      '',
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${gunler[now.weekday - 1]}, ${now.day} ${aylar[now.month]} ${now.year}';
  }

  Widget _buildIlerleme() {
    int toplam = 0;
    int alinan = 0;

    for (final ilac in ilaclar) {
      if (ilac.haftaGunu != null) {
        final now = DateTime.now();
        const gunler = [
          'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
          'Cuma', 'Cumartesi', 'Pazar'
        ];
        final bugunAdi = gunler[now.weekday - 1];
        if (ilac.haftaGunu == bugunAdi) {
          toplam += 1;
          if (ilac.sabahAlindi) alinan += 1;
        }
      } else {
        if (ilac.sabahAlarmAktif) {
          toplam++;
          if (ilac.sabahAlindi) alinan++;
        }
        if (ilac.ogleAlarmAktif) {
          toplam++;
          if (ilac.ogleAlindi) alinan++;
        }
        if (ilac.aksamAlarmAktif) {
          toplam++;
          if (ilac.aksamAlindi) alinan++;
        }
      }
    }

    double oran = toplam > 0 ? alinan / toplam : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$alinan / $toplam doz alındı',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: oran,
            backgroundColor: Colors.white30,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildIlacKarti(Ilac ilac) {
    final bool haftadaBir = ilac.haftaGunu != null;

    bool bugunAlinabilir = true;
    if (haftadaBir) {
      final now = DateTime.now();
      const gunler = [
        'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
        'Cuma', 'Cumartesi', 'Pazar'
      ];
      final bugunAdi = gunler[now.weekday - 1];
      bugunAlinabilir = ilac.haftaGunu == bugunAdi;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlaç adı satırı
            Row(
              children: [
                Icon(Icons.medication,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ilac.isim,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (haftadaBir)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.teal.shade200),
                          ),
                          child: Text(
                            '📅 Haftada Bir — ${ilac.haftaGunu}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _ilacSil(ilac),
                ),
              ],
            ),
            const Divider(),

            // Haftada bir — bugün değil
            if (haftadaBir && !bugunAlinabilir)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Bu ilaç ${ilac.haftaGunu} günü alınır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    // ✅ Saat bilgisi göster
                    if (ilac.sabahSaati != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${ilac.sabahSaati!.hour.toString().padLeft(2, '0')}:${ilac.sabahSaati!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                          if (ilac.sabahAlarmAktif) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.alarm_on,
                                size: 14, color: Colors.teal.shade400),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              )

            // Haftada bir — bugün alınabilir
            else if (haftadaBir && bugunAlinabilir)
              _buildDozButon(
                ilac: ilac,
                zaman: 'sabah',
                icon: Icons.calendar_today,
                etiket: 'Bugün Al',
                alindi: ilac.sabahAlindi,
                saat: ilac.sabahSaati,
                alarmAktif: ilac.sabahAlarmAktif,
                renk: Colors.teal,
              )

            // Normal ilaç
            else
              Row(
                children: [
                  if (ilac.sabahAlarmAktif)
                    Expanded(
                      child: _buildDozButon(
                        ilac: ilac,
                        zaman: 'sabah',
                        icon: Icons.wb_sunny,
                        etiket: 'Sabah',
                        alindi: ilac.sabahAlindi,
                        saat: ilac.sabahSaati,
                        alarmAktif: ilac.sabahAlarmAktif,
                        renk: Colors.orange,
                      ),
                    ),
                  if (ilac.sabahAlarmAktif && ilac.ogleAlarmAktif)
                    const SizedBox(width: 8),
                  if (ilac.ogleAlarmAktif)
                    Expanded(
                      child: _buildDozButon(
                        ilac: ilac,
                        zaman: 'ogle',
                        icon: Icons.light_mode,
                        etiket: 'Öğle',
                        alindi: ilac.ogleAlindi,
                        saat: ilac.ogleSaati,
                        alarmAktif: ilac.ogleAlarmAktif,
                        renk: Colors.amber,
                      ),
                    ),
                  if (ilac.ogleAlarmAktif && ilac.aksamAlarmAktif)
                    const SizedBox(width: 8),
                  if (ilac.aksamAlarmAktif)
                    Expanded(
                      child: _buildDozButon(
                        ilac: ilac,
                        zaman: 'aksam',
                        icon: Icons.nights_stay,
                        etiket: 'Akşam',
                        alindi: ilac.aksamAlindi,
                        saat: ilac.aksamSaati,
                        alarmAktif: ilac.aksamAlarmAktif,
                        renk: Colors.indigo,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDozButon({
    required Ilac ilac,
    required String zaman,
    required IconData icon,
    required String etiket,
    required bool alindi,
    required TimeOfDay? saat,
    required bool alarmAktif,
    required Color renk,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (zaman == 'sabah') {
            ilac.sabahAlindi = !ilac.sabahAlindi;
          } else if (zaman == 'ogle') {
            ilac.ogleAlindi = !ilac.ogleAlindi;
          } else {
            ilac.aksamAlindi = !ilac.aksamAlindi;
          }
        });
        _ilaclarKaydet();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alindi ? renk.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alindi ? renk : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              alindi ? Icons.check_circle : icon,
              color: alindi ? renk : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              etiket,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: alindi ? renk : Colors.grey.shade600,
              ),
            ),
            if (saat != null)
              Text(
                '${saat.hour.toString().padLeft(2, '0')}:${saat.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: alindi ? renk : Colors.grey,
                ),
              ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _alarmKur(ilac, zaman),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: alarmAktif ? renk : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      alarmAktif ? Icons.alarm_on : Icons.alarm_add,
                      size: 14,
                      color: alarmAktif
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      alarmAktif ? 'Alarm Açık' : 'Alarm Ekle',
                      style: TextStyle(
                        fontSize: 11,
                        color: alarmAktif
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGecmisSayfa() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _gecmisYukle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final liste = snapshot.data!;
        if (liste.isEmpty) {
          return const Center(
            child: Text('Henüz geçmiş kayıt yok',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: liste.length,
          itemBuilder: (context, index) {
            final gun = liste[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      gun['tamamlandi'] ? Colors.green : Colors.orange,
                  child: Icon(
                    gun['tamamlandi']
                        ? Icons.check
                        : Icons.warning_amber,
                    color: Colors.white,
                  ),
                ),
                title: Text(gun['tarih']),
                subtitle: Text(gun['ozet']),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _gecmisYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> sonuc = [];
    final keys = prefs.getKeys().where((k) => k.startsWith('ilaclar_'));

    final sortedKeys = keys.toList()..sort();
    for (final key in sortedKeys.reversed.take(30)) {
      final tarih = key.replaceFirst('ilaclar_', '');
      final String? json = prefs.getString(key);
      if (json != null) {
        final liste = (jsonDecode(json) as List)
            .map((e) => Ilac.fromJson(e))
            .toList();
        int toplam = 0;
        int alinan = 0;
        for (final ilac in liste) {
          if (ilac.sabahAlarmAktif) {
            toplam++;
            if (ilac.sabahAlindi) alinan++;
          }
          if (ilac.ogleAlarmAktif) {
            toplam++;
            if (ilac.ogleAlindi) alinan++;
          }
          if (ilac.aksamAlarmAktif) {
            toplam++;
            if (ilac.aksamAlindi) alinan++;
          }
        }
        sonuc.add({
          'tarih': tarih,
          'ozet': '$alinan / $toplam doz alındı',
          'tamamlandi': alinan == toplam && toplam > 0,
        });
      }
    }
    return sonuc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💊 İlaç Takip'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _selectedIndex == 0 ? _buildAnaSayfa() : _buildGecmisSayfa(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _ilacEkle,
              icon: const Icon(Icons.add),
              label: const Text('İlaç Ekle'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
        ],
      ),
    );
  }
}
