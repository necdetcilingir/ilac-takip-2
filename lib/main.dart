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

// ✅ YENİ: Gün bazlı alarm modeli
class GunAlarm {
  List<bool> gunler; // 0=Pzt, 1=Sal, 2=Car, 3=Per, 4=Cum, 5=Cmt, 6=Paz
  TimeOfDay saat;
  bool aktif;

  GunAlarm({
    required this.gunler,
    required this.saat,
    this.aktif = true,
  });

  Map<String, dynamic> toJson() => {
        'gunler': gunler,
        'saatHour': saat.hour,
        'saatMinute': saat.minute,
        'aktif': aktif,
      };

  factory GunAlarm.fromJson(Map<String, dynamic> json) {
    return GunAlarm(
      gunler: List<bool>.from(json['gunler']),
      saat: TimeOfDay(hour: json['saatHour'], minute: json['saatMinute']),
      aktif: json['aktif'] ?? true,
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

  // ✅ YENİ: Gün bazlı alarm listesi (sabah, öğle, akşam için ayrı ayrı)
  List<GunAlarm> sabahGunAlarmlar;
  List<GunAlarm> ogleGunAlarmlar;
  List<GunAlarm> aksamGunAlarmlar;

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
    List<GunAlarm>? sabahGunAlarmlar,
    List<GunAlarm>? ogleGunAlarmlar,
    List<GunAlarm>? aksamGunAlarmlar,
  })  : sabahGunAlarmlar = sabahGunAlarmlar ?? [],
        ogleGunAlarmlar = ogleGunAlarmlar ?? [],
        aksamGunAlarmlar = aksamGunAlarmlar ?? [];

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
        'sabahGunAlarmlar':
            sabahGunAlarmlar.map((e) => e.toJson()).toList(),
        'ogleGunAlarmlar':
            ogleGunAlarmlar.map((e) => e.toJson()).toList(),
        'aksamGunAlarmlar':
            aksamGunAlarmlar.map((e) => e.toJson()).toList(),
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
              hour: json['sabahSaatSaat'],
              minute: json['sabahSaatDakika'])
          : null,
      ogleSaati: json['ogleSaatSaat'] != null
          ? TimeOfDay(
              hour: json['ogleSaatSaat'],
              minute: json['ogleSaatDakika'])
          : null,
      aksamSaati: json['aksamSaatSaat'] != null
          ? TimeOfDay(
              hour: json['aksamSaatSaat'],
              minute: json['aksamSaatDakika'])
          : null,
      sabahAlarmAktif: json['sabahAlarmAktif'] ?? false,
      ogleAlarmAktif: json['ogleAlarmAktif'] ?? false,
      aksamAlarmAktif: json['aksamAlarmAktif'] ?? false,
      tarih: json['tarih'],
      haftaGunu: json['haftaGunu'],
      sabahGunAlarmlar: json['sabahGunAlarmlar'] != null
          ? (json['sabahGunAlarmlar'] as List)
              .map((e) => GunAlarm.fromJson(e))
              .toList()
          : [],
      ogleGunAlarmlar: json['ogleGunAlarmlar'] != null
          ? (json['ogleGunAlarmlar'] as List)
              .map((e) => GunAlarm.fromJson(e))
              .toList()
          : [],
      aksamGunAlarmlar: json['aksamGunAlarmlar'] != null
          ? (json['aksamGunAlarmlar'] as List)
              .map((e) => GunAlarm.fromJson(e))
              .toList()
          : [],
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

  static const List<String> _gunIsimleri = [
    'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'
  ];

  static const List<String> _gunTamIsimleri = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
  ];

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
              sabahGunAlarmlar: data['sabahGunAlarmlar'] != null
                  ? (data['sabahGunAlarmlar'] as List)
                      .map((e) => GunAlarm.fromJson(e))
                      .toList()
                  : [],
              ogleGunAlarmlar: data['ogleGunAlarmlar'] != null
                  ? (data['ogleGunAlarmlar'] as List)
                      .map((e) => GunAlarm.fromJson(e))
                      .toList()
                  : [],
              aksamGunAlarmlar: data['aksamGunAlarmlar'] != null
                  ? (data['aksamGunAlarmlar'] as List)
                      .map((e) => GunAlarm.fromJson(e))
                      .toList()
                  : [],
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

    final isimlerJson = jsonEncode(ilaclar.map((e) => e.toJson()).toList());
    await prefs.setString('ilac_isimleri', isimlerJson);
  }

  void _ilacEkle() {
    String yeniIsim = '';
    bool sabahSecili = true;
    bool ogleSecili = false;
    bool aksamSecili = true;
    bool haftadaBirSecili = false;
    String secilenGun = 'Pazartesi';
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
                    const Text(
                      'Kullanım Zamanı:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Row(children: [
                        Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Sabah'),
                      ]),
                      value: sabahSecili,
                      onChanged: haftadaBirSecili
                          ? null
                          : (v) => setDialogState(() => sabahSecili = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Row(children: [
                        Icon(Icons.light_mode, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text('Öğle'),
                      ]),
                      value: ogleSecili,
                      onChanged: haftadaBirSecili
                          ? null
                          : (v) => setDialogState(() => ogleSecili = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Row(children: [
                        Icon(Icons.nights_stay,
                            color: Colors.indigo, size: 20),
                        SizedBox(width: 8),
                        Text('Akşam'),
                      ]),
                      value: aksamSecili,
                      onChanged: haftadaBirSecili
                          ? null
                          : (v) => setDialogState(() => aksamSecili = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    const Divider(),
                    CheckboxListTile(
                      title: const Row(children: [
                        Icon(Icons.calendar_today,
                            color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Text('Haftada Bir'),
                      ]),
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
                    if (haftadaBirSecili) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: secilenGun,
                        decoration: const InputDecoration(
                          labelText: 'Hangi Gün?',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        items: _gunTamIsimleri
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => secilenGun = v!),
                      ),
                      const SizedBox(height: 12),
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
                            setDialogState(() => haftaIlacSaati = secilen);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        secondary: Icon(
                          haftaAlarmAktif
                              ? Icons.alarm_on
                              : Icons.alarm_off,
                          color: haftaAlarmAktif
                              ? Colors.teal
                              : Colors.grey,
                        ),
                        title: const Text('Alarm Kur'),
                        subtitle: Text(
                          haftaAlarmAktif
                              ? 'Alarm açık — $secilenGun günü hatırlatılacak'
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
                      sabahSaati: haftadaBirSecili ? haftaIlacSaati : null,
                      sabahAlarmAktif: haftadaBirSecili
                          ? haftaAlarmAktif
                          : sabahSecili,
                      ogleAlarmAktif:
                          haftadaBirSecili ? false : ogleSecili,
                      aksamAlarmAktif:
                          haftadaBirSecili ? false : aksamSecili,
                    );

                    setState(() => ilaclar.add(yeniIlac));
                    _ilaclarKaydet();

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
              setState(() => ilaclar.removeWhere((e) => e.id == ilac.id));
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

  // ✅ YENİ: Gün bazlı alarm yönetimi dialog'u
  Future<void> _gunAlarmYonet(Ilac ilac, String zaman) async {
    List<GunAlarm> mevcutAlarmlar;
    Color renk;
    String baslik;
    IconData icon;

    if (zaman == 'sabah') {
      mevcutAlarmlar = List.from(ilac.sabahGunAlarmlar);
      renk = Colors.orange;
      baslik = 'Sabah Alarmları';
      icon = Icons.wb_sunny;
    } else if (zaman == 'ogle') {
      mevcutAlarmlar = List.from(ilac.ogleGunAlarmlar);
      renk = Colors.amber;
      baslik = 'Öğle Alarmları';
      icon = Icons.light_mode;
    } else {
      mevcutAlarmlar = List.from(ilac.aksamGunAlarmlar);
      renk = Colors.indigo;
      baslik = 'Akşam Alarmları';
      icon = Icons.nights_stay;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(icon, color: renk),
                  const SizedBox(width: 8),
                  Text(baslik),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mevcut alarmlar listesi
                    if (mevcutAlarmlar.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Henüz alarm eklenmedi.\nAşağıdan yeni alarm ekleyin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: mevcutAlarmlar.length,
                          itemBuilder: (context, index) {
                            final alarm = mevcutAlarmlar[index];
                            return _buildAlarmSatiri(
                              alarm: alarm,
                              renk: renk,
                              onSil: () => setDialogState(
                                  () => mevcutAlarmlar.removeAt(index)),
                              onAktifDegistir: (v) => setDialogState(
                                  () => alarm.aktif = v),
                              onSaatDegistir: () async {
                                final yeniSaat = await showTimePicker(
                                  context: context,
                                  initialTime: alarm.saat,
                                  helpText: 'Alarm Saatini Seç',
                                );
                                if (yeniSaat != null) {
                                  setDialogState(() => alarm.saat = yeniSaat);
                                }
                              },
                              onGunDegistir: (gunIndex) =>
                                  setDialogState(() => alarm.gunler[gunIndex] =
                                      !alarm.gunler[gunIndex]),
                            );
                          },
                        ),
                      ),

                    const Divider(),

                    // Yeni alarm ekle butonu
                    TextButton.icon(
                      onPressed: () async {
                        final yeniSaat = await showTimePicker(
                          context: context,
                          initialTime: zaman == 'sabah'
                              ? const TimeOfDay(hour: 8, minute: 0)
                              : zaman == 'ogle'
                                  ? const TimeOfDay(hour: 12, minute: 0)
                                  : const TimeOfDay(hour: 20, minute: 0),
                          helpText: 'Yeni Alarm Saati',
                        );
                        if (yeniSaat != null) {
                          setDialogState(() {
                            mevcutAlarmlar.add(GunAlarm(
                              // Varsayılan: Pazartesi-Cuma seçili
                              gunler: [
                                true, true, true, true, true, false, false
                              ],
                              saat: yeniSaat,
                            ));
                          });
                        }
                      },
                      icon: Icon(Icons.add_alarm, color: renk),
                      label: Text('Yeni Alarm Ekle',
                          style: TextStyle(color: renk)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: renk),
                  onPressed: () {
                    setState(() {
                      if (zaman == 'sabah') {
                        ilac.sabahGunAlarmlar = mevcutAlarmlar;
                        ilac.sabahAlarmAktif = mevcutAlarmlar.isNotEmpty;
                        // Geriye dönük uyumluluk için ilk alarmın saatini sabahSaati'ne yaz
                        if (mevcutAlarmlar.isNotEmpty) {
                          ilac.sabahSaati = mevcutAlarmlar.first.saat;
                        }
                      } else if (zaman == 'ogle') {
                        ilac.ogleGunAlarmlar = mevcutAlarmlar;
                        ilac.ogleAlarmAktif = mevcutAlarmlar.isNotEmpty;
                        if (mevcutAlarmlar.isNotEmpty) {
                          ilac.ogleSaati = mevcutAlarmlar.first.saat;
                        }
                      } else {
                        ilac.aksamGunAlarmlar = mevcutAlarmlar;
                        ilac.aksamAlarmAktif = mevcutAlarmlar.isNotEmpty;
                        if (mevcutAlarmlar.isNotEmpty) {
                          ilac.aksamSaati = mevcutAlarmlar.first.saat;
                        }
                      }
                    });
                    _ilaclarKaydet();
                    // Tüm alarmları yeniden kur
                    _tumAlarmlariKur(ilac, zaman, mevcutAlarmlar);
                    Navigator.pop(context);
                  },
                  child: const Text('Kaydet',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ YENİ: Tek alarm satırı widget'ı
  Widget _buildAlarmSatiri({
    required GunAlarm alarm,
    required Color renk,
    required VoidCallback onSil,
    required Function(bool) onAktifDegistir,
    required VoidCallback onSaatDegistir,
    required Function(int) onGunDegistir,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
            color: alarm.aktif ? renk.withOpacity(0.4) : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: alarm.aktif ? renk.withOpacity(0.05) : Colors.grey.shade50,
      ),
      child: Column(
        children: [
          // Saat + aktif toggle + sil
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Saat butonu
                GestureDetector(
                  onTap: onSaatDegistir,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: alarm.aktif ? renk : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${alarm.saat.hour.toString().padLeft(2, '0')}:${alarm.saat.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Aktif toggle
                Switch(
                  value: alarm.aktif,
                  onChanged: onAktifDegistir,
                  activeColor: renk,
                ),
                // Sil butonu
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: onSil,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

// Gün seçici
Padding(
  padding: const EdgeInsets.only(left: 6, right: 6, bottom: 10),
  child: LayoutBuilder(
    builder: (context, constraints) {
      final double toplamGenislik = constraints.maxWidth;
      final double daireBoyutu = (toplamGenislik - 6 * 6) / 7;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final secili = alarm.gunler[i];
          return GestureDetector(
            onTap: () => onGunDegistir(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: daireBoyutu,
              height: daireBoyutu,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secili
                    ? (alarm.aktif ? renk : Colors.grey)
                    : Colors.transparent,
                border: Border.all(
                  color: secili
                      ? (alarm.aktif ? renk : Colors.grey)
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _gunIsimleri[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: secili ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }),
      );
    },
  ),
),
    );
  }

  // ✅ YENİ: Tüm gün alarmlarını kur
  Future<void> _tumAlarmlariKur(
      Ilac ilac, String zaman, List<GunAlarm> alarmlar) async {
    final int base = int.parse(ilac.id.substring(ilac.id.length - 4));

    // Önce bu zaman için tüm eski bildirimleri iptal et
    for (int i = 0; i < 20; i++) {
      final int offset = zaman == 'sabah'
          ? i
          : zaman == 'ogle'
              ? 500 + i
              : 1000 + i;
      await flutterLocalNotificationsPlugin.cancel(base + offset);
    }

    // Her alarm için her seçili gün ayrı bildirim kur
    for (int alarmIndex = 0;
        alarmIndex < alarmlar.length;
        alarmIndex++) {
      final alarm = alarmlar[alarmIndex];
      if (!alarm.aktif) continue;

      for (int gunIndex = 0; gunIndex < 7; gunIndex++) {
        if (!alarm.gunler[gunIndex]) continue;

        final int offset = zaman == 'sabah'
            ? alarmIndex * 7 + gunIndex
            : zaman == 'ogle'
                ? 500 + alarmIndex * 7 + gunIndex
                : 1000 + alarmIndex * 7 + gunIndex;

        final int bildirimId = base + offset;

        // Dart weekday: 1=Pzt...7=Paz, bizim index: 0=Pzt...6=Paz
        final int hedefGun = gunIndex + 1;

        await _bildirimKurGunIcin(
          bildirimId: bildirimId,
          ilacIsim: ilac.isim,
          zaman: zaman,
          saat: alarm.saat,
          hedefWeekday: hedefGun,
        );
      }
    }
  }

  Future<void> _bildirimKurGunIcin({
    required int bildirimId,
    required String ilacIsim,
    required String zaman,
    required TimeOfDay saat,
    required int hedefWeekday,
  }) async {
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
    int fark = hedefWeekday - now.weekday;
    if (fark < 0) fark += 7;
    if (fark == 0 &&
        now.hour * 60 + now.minute >= saat.hour * 60 + saat.minute) {
      fark = 7;
    }

    final scheduledDate = DateTime(
      now.year, now.month, now.day + fark, saat.hour, saat.minute,
    );

    final zamanEtiketi = zaman == 'sabah'
        ? 'Sabah'
        : zaman == 'ogle'
            ? 'Öğle'
            : 'Akşam';

    await flutterLocalNotificationsPlugin.zonedSchedule(
      bildirimId,
      '💊 İlaç Zamanı!',
      '$ilacIsim — $zamanEtiketi dozu alma vakti!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
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
    var scheduledDate =
        DateTime(now.year, now.month, now.day, saat.hour, saat.minute);

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

    int fark = hedefGun - now.weekday;
    if (fark < 0) fark += 7;
    if (fark == 0 &&
        now.hour * 60 + now.minute >= saat.hour * 60 + saat.minute) {
      fark = 7;
    }

    final scheduledDate = DateTime(
        now.year, now.month, now.day + fark, saat.hour, saat.minute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      bildirimId,
      '💊 Haftalık İlaç Zamanı!',
      '${ilac.isim} alma vakti geldi. (${ilac.haftaGunu})',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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
              Text(_bugunGoster(),
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('İlaç Takibim',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
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
                      const Text('Henüz ilaç eklenmedi',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Sağ alttaki + butonuna basın',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: ilaclar.length,
                  itemBuilder: (context, index) =>
                      _buildIlacKarti(ilaclar[index]),
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
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${gunler[now.weekday - 1]}, ${now.day} ${aylar[now.month]} ${now.year}';
  }

  Widget _buildIlerleme() {
    int toplam = 0;
    int alinan = 0;

    for (final ilac in ilaclar) {
      if (ilac.haftaGunu != null) {
        final bugunAdi = _gunTamIsimleri[DateTime.now().weekday - 1];
        if (ilac.haftaGunu == bugunAdi) {
          toplam++;
          if (ilac.sabahAlindi) alinan++;
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
        Text('$alinan / $toplam doz alındı',
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: oran,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
      final bugunAdi = _gunTamIsimleri[DateTime.now().weekday - 1];
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
            Row(
              children: [
                Icon(Icons.medication,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ilac.isim,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _ilacSil(ilac),
                ),
              ],
            ),
            const Divider(),

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
                    Text('Bu ilaç ${ilac.haftaGunu} günü alınır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600)),
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
                                color: Colors.grey.shade500, fontSize: 13),
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

  // ✅ GÜNCELLENDİ: Alarm butonuna tıklayınca artık gün bazlı alarm dialog'u açılıyor
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
    // Kaç alarm var özeti
    List<GunAlarm> gunAlarmlar = zaman == 'sabah'
        ? ilac.sabahGunAlarmlar
        : zaman == 'ogle'
            ? ilac.ogleGunAlarmlar
            : ilac.aksamGunAlarmlar;

    final int aktifAlarmSayisi =
        gunAlarmlar.where((a) => a.aktif).length;

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
              color: alindi ? renk : Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            Icon(alindi ? Icons.check_circle : icon,
                color: alindi ? renk : Colors.grey, size: 32),
            const SizedBox(height: 4),
            Text(etiket,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: alindi ? renk : Colors.grey.shade600)),
            if (saat != null)
              Text(
                '${saat.hour.toString().padLeft(2, '0')}:${saat.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 12, color: alindi ? renk : Colors.grey),
              ),
            const SizedBox(height: 6),

            // ✅ Alarm butonu — gün bazlı dialog açar
            GestureDetector(
              onTap: () => ilac.haftaGunu == null
                  ? _gunAlarmYonet(ilac, zaman)
                  : _bildirimKurHaftaIci(
                      ilac,
                      saat ?? TimeOfDay.now(),
                    ),
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
                      alarmAktif
                          ? (aktifAlarmSayisi > 0
                              ? '$aktifAlarmSayisi alarm'
                              : 'Alarm Açık')
                          : 'Alarm Ekle',
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
                  style: TextStyle(color: Colors.grey)));
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
                    gun['tamamlandi'] ? Icons.check : Icons.warning_amber,
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
        final liste =
            (jsonDecode(json) as List).map((e) => Ilac.fromJson(e)).toList();
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
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
