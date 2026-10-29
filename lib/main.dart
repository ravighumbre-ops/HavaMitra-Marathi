
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const double defaultLat = 19.130057;
const double defaultLon = 76.469843;
const String defaultPlace = 'वाघाळा, पाथरी, परभणी';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HavaMitraApp());
}

class HavaMitraApp extends StatelessWidget {
  const HavaMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'हवामित्र मराठी',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const WeatherHome(),
    );
  }
}

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  int tab = 0;
  double lat = defaultLat;
  double lon = defaultLon;
  String place = defaultPlace;
  bool loading = true;
  String? error;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$lat',
        'longitude': '$lon',
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
        'hourly':
            'temperature_2m,precipitation_probability,precipitation,weather_code',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum',
        'forecast_days': '10',
        'timezone': 'Asia/Kolkata',
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('हवामान सर्व्हरने माहिती दिली नाही.');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        data = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'हवामान मिळाले नाही. इंटरनेट तपासून पुन्हा प्रयत्न करा.';
      });
    }
  }

  Future<void> useGps() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        showMessage('मोबाईलचे Location/GPS सुरू करा.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showMessage('Settings मध्ये Location permission द्या.');
        return;
      }

      showMessage('तुमचे स्थान शोधत आहे...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;
      setState(() {
        lat = position.latitude;
        lon = position.longitude;
        place = 'तुमचे सध्याचे GPS स्थान';
      });
      await loadWeather();
    } catch (_) {
      showMessage('GPS स्थान मिळाले नाही. पुन्हा प्रयत्न करा.');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String weatherText(dynamic code) {
    final c = (code as num?)?.toInt() ?? 0;
    if (c == 0) return 'निरभ्र आकाश';
    if (c <= 3) return 'ढगाळ हवामान';
    if (c == 45 || c == 48) return 'धुके';
    if (c >= 51 && c <= 57) return 'रिमझिम पाऊस';
    if (c >= 61 && c <= 67) return 'पाऊस';
    if (c >= 71 && c <= 77) return 'बर्फवृष्टी';
    if (c >= 80 && c <= 82) return 'पावसाच्या सरी';
    if (c >= 95) return 'मेघगर्जना किंवा वादळ';
    return 'बदलते हवामान';
  }

  Map<String, dynamic> get current =>
      data!['current'] as Map<String, dynamic>;
  Map<String, dynamic> get hourly =>
      data!['hourly'] as Map<String, dynamic>;
  Map<String, dynamic> get daily =>
      data!['daily'] as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildToday(),
      buildHourly(),
      buildMap(),
      buildFarmer(),
      buildTradition(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌦️ हवामित्र मराठी'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'GPS स्थान',
            onPressed: useGps,
            icon: const Icon(Icons.my_location),
          ),
          IconButton(
            tooltip: 'हवामान पुन्हा तपासा',
            onPressed: loadWeather,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 60),
                        const SizedBox(height: 12),
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: loadWeather,
                          child: const Text('पुन्हा प्रयत्न करा'),
                        ),
                      ],
                    ),
                  ),
                )
              : pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined), label: 'आज'),
          NavigationDestination(
            icon: Icon(Icons.schedule), label: 'तासानुसार'),
          NavigationDestination(
            icon: Icon(Icons.map_outlined), label: 'नकाशा'),
          NavigationDestination(
            icon: Icon(Icons.agriculture), label: 'शेतकरी'),
          NavigationDestination(
            icon: Icon(Icons.nights_stay_outlined), label: 'पारंपरिक'),
        ],
      ),
    );
  }

  Widget infoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Colors.teal, size: 28),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center),
              const SizedBox(height: 5),
              Text(value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildToday() {
    final temp = (current['temperature_2m'] as num).round();
    final apparent = (current['apparent_temperature'] as num).round();
    final humidity = current['relative_humidity_2m'];
    final wind = current['wind_speed_10m'];
    final rainChance =
        (daily['precipitation_probability_max'] as List).first;
    final todayRain = (daily['precipitation_sum'] as List).first;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(place,
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          color: Colors.teal.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.cloud, size: 65, color: Colors.teal),
                Text('$temp°C',
                    style: const TextStyle(
                        fontSize: 46, fontWeight: FontWeight.bold)),
                Text(weatherText(current['weather_code']),
                    style: const TextStyle(fontSize: 20)),
                Text('जाणवणारे तापमान: $apparent°C'),
              ],
            ),
          ),
        ),
        Row(children: [
          infoCard('पावसाची शक्यता', '$rainChance%', Icons.umbrella),
          infoCard('आर्द्रता', '$humidity%', Icons.water_drop),
        ]),
        Row(children: [
          infoCard('वारा', '$wind km/h', Icons.air),
          infoCard('आजचा अंदाजित पाऊस', '$todayRain mm', Icons.grain),
        ]),
        const SizedBox(height: 12),
        const Text('पुढील १० दिवस',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ...dailyRows(),
        const Text(
          'हा मॉडेलवर आधारित अंदाज आहे; प्रत्यक्ष पावसाची हमी नाही.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  List<Widget> dailyRows() {
    final dates = daily['time'] as List;
    final max = daily['temperature_2m_max'] as List;
    final min = daily['temperature_2m_min'] as List;
    final rain = daily['precipitation_probability_max'] as List;
    final codes = daily['weather_code'] as List;
    final amount = daily['precipitation_sum'] as List;

    return List.generate(dates.length, (i) => Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month, color: Colors.teal),
        title: Text('${dates[i]}'),
        subtitle: Text(
          '${weatherText(codes[i])} • पावसाची शक्यता ${rain[i]}% • '
          'पाऊस ${amount[i]} mm',
        ),
        trailing: Text(
          '${(max[i] as num).round()}° / ${(min[i] as num).round()}°',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ));
  }

  Widget buildHourly() {
    final times = hourly['time'] as List;
    final temps = hourly['temperature_2m'] as List;
    final chances = hourly['precipitation_probability'] as List;
    final amounts = hourly['precipitation'] as List;
    final codes = hourly['weather_code'] as List;
    final now = DateTime.now();

    int start = times.indexWhere((value) {
      return !DateTime.parse(value.toString()).isBefore(now);
    });
    if (start < 0) start = 0;
    final end = (start + 24 < times.length) ? start + 24 : times.length;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('पुढील २४ तासांचा अंदाज',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ...List.generate(end - start, (n) {
          final i = start + n;
          final dt = DateTime.parse(times[i].toString());
          final hour = dt.hour.toString().padLeft(2, '0');
          return Card(
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Colors.teal),
              title: Text('$hour:00 • ${weatherText(codes[i])}'),
              subtitle: Text(
                'पावसाची शक्यता ${chances[i]}% • पाऊस ${amounts[i]} mm',
              ),
              trailing: Text('${(temps[i] as num).round()}°C'),
            ),
          );
        }),
      ],
    );
  }

  Widget buildMap() {
    return Column(
      children: [
        ListTile(
          title: const Text('हवामित्र नकाशा'),
          subtitle: Text(place),
          trailing: IconButton(
            onPressed: useGps,
            icon: const Icon(Icons.my_location),
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lon),
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.havamitra.marathi',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: LatLng(lat, lon),
                  width: 130,
                  height: 70,
                  child: const Column(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 38),
                      Text('तुमचे स्थान',
                          style: TextStyle(
                              backgroundColor: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ]),
              RichAttributionWidget(attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  String farmerAdvice() {
    final chance =
        ((daily['precipitation_probability_max'] as List).first as num)
            .toInt();
    final temp = (current['temperature_2m'] as num).toDouble();

    if (chance >= 70) {
      return 'पावसाची शक्यता जास्त आहे. कापणी, फवारणी आणि शेतातील कामाचे नियोजन करण्यापूर्वी ताजा अंदाज तपासा.';
    }
    if (chance >= 40) {
      return 'पावसाची शक्यता मध्यम आहे. शेतातील कामे ठरवताना पिकाची अवस्था आणि स्थानिक परिस्थिती पाहा.';
    }
    if (temp >= 35) {
      return 'उष्णता जास्त आहे. पिकाची गरज आणि मातीतील ओलावा पाहून सिंचनाचे नियोजन करा.';
    }
    return 'सध्याच्या अंदाजानुसार शेतातील कामांचे नियोजन करा. फवारणीपूर्वी वारा आणि पावसाची शक्यता तपासा.';
  }

  Widget buildFarmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('शेतकऱ्यांसाठी मार्गदर्शन',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(farmerAdvice(),
                style: const TextStyle(fontSize: 18)),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('महत्त्वाची सूचना'),
            subtitle: Text(
              'ही सामान्य हवामानाधारित सूचना आहे. पीक, औषधाचे लेबल आणि कृषी अधिकाऱ्यांचा सल्ला लक्षात घ्या. '
              'फक्त ॲपवरून फवारणी किंवा सिंचनाचा अंतिम निर्णय घेऊ नका.',
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTradition() {
    final now = DateTime.now();

    final months = [
      'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल',
      'मे', 'जून', 'जुलै', 'ऑगस्ट',
      'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'
    ];

    final observations = <Map<String, String>>[
      {
        'title': 'काळे ढग आणि वाढता वारा',
        'text': 'काळे ढग, वाऱ्यातील बदल आणि मेघगर्जना हे पावसाच्या '
            'शक्यतेचे संकेत असू शकतात.',
        'tip': 'स्थानिक निरीक्षण; पावसाची खात्री नाही.'
      },
      {
        'title': 'मुंग्या आणि कीटकांची हालचाल',
        'text': 'काही लोकपरंपरांमध्ये मुंग्या किंवा कीटकांच्या '
            'हालचालींना पावसाशी जोडले जाते.',
        'tip': 'हा विश्वासार्ह स्वतंत्र हवामान अंदाज नाही.'
      },
      {
        'title': 'आकाशातील ढगांचे स्वरूप',
        'text': 'ढगांची उंची, घनता आणि हालचाल पाहून वातावरणातील '
            'बदलांचा अंदाज लावण्याचा प्रयत्न केला जातो.',
        'tip': 'अचूक अंदाजासाठी अधिकृत हवामान माहिती तपासा.'
      },
    ];

    final sayings = <Map<String, String>>[
      {
        'title': 'सहदेव-भाडळी परंपरा',
        'text': 'सहदेव-भाडळीच्या लोकपरंपरेत नक्षत्र, वारा, '
            'ढग आणि निसर्गातील बदल यांवर आधारित पावसाच्या '
            'म्हणी सांगितल्या जातात.',
        'tip': 'येथे विशिष्ट मूळ म्हणीचा प्रमाणित संग्रह जोडलेला नाही.'
      },
      {
        'title': 'नक्षत्र आणि पाऊस',
        'text': 'पारंपरिक पावसाच्या अंदाजात मृग, आर्द्रा, '
            'पुनर्वसू, पुष्य आणि इतर नक्षत्रांचा उल्लेख आढळतो.',
        'tip': 'नक्षत्रावरून पावसाची हमी देता येत नाही.'
      },
    ];

    Widget sectionTitle(String title, IconData icon) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget informationCard(Map<String, String> item) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title']!,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['text']!,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'टीप: ${item['tip']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          '🌙 पारंपरिक पावसाचे संकेत',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'आजची तारीख: ${now.day} ${months[now.month - 1]} ${now.year}',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 8),
        const Card(
          color: Color(0xFFE0F2F1),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'महत्त्वाचे: या विभागात आजचे खगोलशास्त्रीय नक्षत्र '
              'स्वयंचलितपणे मोजले जात नाही. खालील माहिती '
              'लोकपरंपरा आणि निसर्गनिरीक्षणासाठी आहे.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        sectionTitle('सहदेव-भाडळी आणि नक्षत्र परंपरा',
            Icons.menu_book),
        ...sayings.map(informationCard),
        sectionTitle('निसर्गातील पारंपरिक संकेत',
            Icons.cloud_outlined),
        ...observations.map(informationCard),
        sectionTitle('वैज्ञानिक हवामान अंदाज',
            Icons.wb_sunny_outlined),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'हवामित्रच्या इतर विभागांतून तपासा:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• आज: तापमान आणि पावसाची शक्यता\n'
                  '• तासानुसार: पुढील २४ तासांचा अंदाज\n'
                  '• नकाशा: तुमचे स्थान\n'
                  '• शेतकरी: हवामानाधारित सामान्य सूचना',
                ),
                const SizedBox(height: 8),
                const Text(
                  'लोकपरंपरेतील संकेत आणि आधुनिक अंदाज वेगळे ठेवा. '
                  'पाऊस, फवारणी किंवा सिंचनाचा निर्णय घेताना '
                  'अद्ययावत हवामान माहिती व स्थानिक परिस्थिती तपासा.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
