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
  bool aksamAlindi;
  TimeOfDay? sabahSaati;
  TimeOfDay? aksamSaati;
  bool sabahAlarmAktif;
  bool aksamAlarmAktif;
  String tarih; // YYYY-MM-DD

  Ilac({
    required this.id,
    required this.isim,
    this.sabahAlindi = false,
    this.aksamAlindi = false,
    this.sabahSaati,
    this.aksamSaati,
    this.sabahAlarmAktif = false,
    this.aksamAlarmAktif = false,
    required this.tarih,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isim': isim,
        'sabahAlindi': sabahAlindi,
        'aksamAlindi': aksamAlindi,
        'sabahSaatSaat': sabahSaati?.hour,
        'sabahSaatDakika': sabahSaati?.minute,
        'aksamSaatSaat': aksamSaati?.hour,
        'aksamSaatDakika': aksamSaati?.minute,
        'sabahAlarmAktif': sabahAlarmAktif,
        'aksamAlarmAktif': aksamAlarmAktif,
        'tarih': tarih,
      };

  factory Ilac.fromJson(Map<String, dynamic> json) {
    return Ilac(
      id: json['id'],
      isim: json['isim'],
      sabahAlindi: json['sabahAlindi'] ?? false,
      aksamAlindi: json['aksamAlindi'] ?? false,
      sabahSaati: json['sabahSaatSaat'] != null
          ? TimeOfDay(
              hour: json['sabahSaatSaat'], minute: json['sabahSaatDakika'])
          : null,
      aksamSaati: json['aksamSaatSaat'] != null
          ? TimeOfDay(
              hour: json['aksamSaatSaat'], minute: json['aksamSaatDakika'])
          : null,
      sabahAlarmAktif: json['sabahAlarmAktif'] ?? false,
      aksamAlarmAktif: json['aksamAlarmAktif'] ?? false,
      tarih: json['tarih'],
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
      // Önceki günden ilaç isimlerini al
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
              aksamSaati: data['aksamSaatSaat'] != null
                  ? TimeOfDay(
                      hour: data['aksamSaatSaat'],
                      minute: data['aksamSaatDakika'])
                  : null,
              sabahAlarmAktif: data['sabahAlarmAktif'] ?? false,
              aksamAlarmAktif: data['aksamAlarmAktif'] ?? false,
              tarih: bugunTarih,
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

    // İlaç isimlerini ve ayarlarını ayrıca kaydet
    final isimlerJson = jsonEncode(ilaclar
        .map((e) => {
              'id': e.id,
              'isim': e.isim,
              'sabahSaatSaat': e.sabahSaati?.hour,
              'sabahSaatDakika': e.sabahSaati?.minute,
              'aksamSaatSaat': e.aksamSaati?.hour,
              'aksamSaatDakika': e.aksamSaati?.minute,
              'sabahAlarmAktif': e.sabahAlarmAktif,
              'aksamAlarmAktif': e.aksamAlarmAktif,
            })
        .toList());
    await prefs.setString('ilac_isimleri', isimlerJson);
  }

  void _ilacEkle() {
    showDialog(
      context: context,
      builder: (context) {
        String yeniIsim = '';
        return AlertDialog(
          title: const Text('İlaç Ekle'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'İlaç adı (örn: Beloc, D vitamini)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => yeniIsim = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (yeniIsim.trim().isNotEmpty) {
                  setState(() {
                    ilaclar.add(Ilac(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      isim: yeniIsim.trim(),
                      tarih: bugunTarih,
                    ));
                  });
                  _ilaclarKaydet();
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
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

  Future<void> _alarmKur(Ilac ilac, bool sabahMi) async {
    final TimeOfDay? secilenSaat = await showTimePicker(
      context: context,
      initialTime: sabahMi
          ? (ilac.sabahSaati ?? const TimeOfDay(hour: 8, minute: 0))
          : (ilac.aksamSaati ?? const TimeOfDay(hour: 20, minute: 0)),
      helpText: sabahMi ? 'Sabah Alarm Saati' : 'Akşam Alarm Saati',
    );

    if (secilenSaat != null) {
      setState(() {
        if (sabahMi) {
          ilac.sabahSaati = secilenSaat;
          ilac.sabahAlarmAktif = true;
        } else {
          ilac.aksamSaati = secilenSaat;
          ilac.aksamAlarmAktif = true;
        }
      });
      _ilaclarKaydet();
      _bildirimKur(ilac, sabahMi, secilenSaat);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${ilac.isim} için ${sabahMi ? "sabah" : "akşam"} alarmı ${secilenSaat.format(context)} olarak ayarlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _bildirimKur(
      Ilac ilac, bool sabahMi, TimeOfDay saat) async {
    final int bildirimId =
        int.parse(ilac.id.substring(ilac.id.length - 4)) + (sabahMi ? 0 : 1000);

    await flutterLocalNotificationsPlugin.cancel(bildirimId);

    if (!(sabahMi ? ilac.sabahAlarmAktif : ilac.aksamAlarmAktif)) return;

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
      now.year,
      now.month,
      now.day,
      saat.hour,
      saat.minute,
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
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
                        style: TextStyle(fontSize: 18, color: Colors.grey),
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
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${gunler[now.weekday - 1]}, ${now.day} ${aylar[now.month]} ${now.year}';
  }

  Widget _buildIlerleme() {
    int toplam = ilaclar.length * 2;
    int alinan = ilaclar.where((e) => e.sabahAlindi).length +
        ilaclar.where((e) => e.aksamAlindi).length;
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
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildIlacKarti(Ilac ilac) {
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
                  child: Text(
                    ilac.isim,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _ilacSil(ilac),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildDozButon(
                    ilac: ilac,
                    sabahMi: true,
                    icon: Icons.wb_sunny,
                    etiket: 'Sabah',
                    alindi: ilac.sabahAlindi,
                    saat: ilac.sabahSaati,
                    alarmAktif: ilac.sabahAlarmAktif,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDozButon(
                    ilac: ilac,
                    sabahMi: false,
                    icon: Icons.nights_stay,
                    etiket: 'Akşam',
                    alindi: ilac.aksamAlindi,
                    saat: ilac.aksamSaati,
                    alarmAktif: ilac.aksamAlarmAktif,
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
    required bool sabahMi,
    required IconData icon,
    required String etiket,
    required bool alindi,
    required TimeOfDay? saat,
    required bool alarmAktif,
  }) {
    final renk = sabahMi ? Colors.orange : Colors.indigo;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (sabahMi) {
            ilac.sabahAlindi = !ilac.sabahAlindi;
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
              onTap: () => _alarmKur(ilac, sabahMi),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      color: alarmAktif ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      alarmAktif ? 'Alarm Açık' : 'Alarm Ekle',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            alarmAktif ? Colors.white : Colors.grey.shade600,
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
        int toplam = liste.length * 2;
        int alinan = liste.where((e) => e.sabahAlindi).length +
            liste.where((e) => e.aksamAlindi).length;
        sonuc.add({
          'tarih': tarih,
          'ozet': '$alinan / $toplam doz alındı',
          'tamamlandi': alinan == toplam,
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
