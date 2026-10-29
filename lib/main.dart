
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const double villageLat = 19.130057;
const double villageLon = 76.469843;
const String villageName = 'वाघाळा, पाथरी, परभणी';

void main() {
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
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
  int selectedTab = 0;
  bool loading = true;
  String? errorMessage;
  Map<String, dynamic>? weather;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': '$villageLat',
          'longitude': '$villageLon',
          'current':
              'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
          'hourly':
              'temperature_2m,precipitation_probability,precipitation,weather_code',
          'daily':
              'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum',
          'forecast_days': '10',
          'timezone': 'Asia/Kolkata',
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('हवामान माहिती मिळाली नाही.');
      }

      final result =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        weather = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage =
            'इंटरनेट तपासा आणि पुन्हा प्रयत्न करा.';
      });
    }
  }

  String weatherText(dynamic code) {
    final c = (code as num?)?.toInt() ?? 0;

    if (c == 0) return 'निरभ्र आकाश';
    if (c <= 3) return 'ढगाळ हवामान';
    if (c == 45 || c == 48) return 'धुके';
    if (c >= 51 && c <= 57) return 'रिमझिम पाऊस';
    if (c >= 61 && c <= 67) return 'पाऊस';
    if (c >= 71 && c <= 77) return 'बर्फवृष्टी';
    if (c >= 80 && c <= 82) return 'सरी';
    if (c >= 85 && c <= 86) return 'बर्फाच्या सरी';
    if (c >= 95) return 'मेघगर्जनेसह वादळ';
    return 'हवामान बदलते आहे';
  }

  String getAdvice(int rainChance, double temperature) {
    if (rainChance >= 70) {
      return 'पावसाची शक्यता जास्त आहे. फवारणी किंवा कापणीपूर्वी ताजा अंदाज तपासा.';
    }
    if (rainChance >= 40) {
      return 'पावसाची शक्यता मध्यम आहे. शेतातील कामाचे नियोजन काळजीपूर्वक करा.';
    }
    if (temperature >= 35) {
      return 'उष्णता जास्त आहे. पिकांची गरज पाहून पाणी द्या आणि शक्य असल्यास दुपारी फवारणी टाळा.';
    }
    return 'पेरणी, फवारणी आणि सिंचन ठरवताना स्थानिक परिस्थिती व पिकाची अवस्था पाहा.';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHome(),
      buildHourly(),
      buildMap(),
      buildFarmerAdvice(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🌦️ हवामित्र मराठी',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadWeather,
            icon: const Icon(Icons.refresh),
            tooltip: 'हवामान पुन्हा मिळवा',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 55),
                        const SizedBox(height: 12),
                        Text(errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: loadWeather,
                          child: const Text('पुन्हा प्रयत्न करा'),
                        ),
                      ],
                    ),
                  ),
                )
              : pages[selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            label: 'आज',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule),
            label: 'तासानुसार',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'नकाशा',
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture),
            label: 'शेतकरी',
          ),
        ],
      ),
    );
  }

  Widget buildHome() {
    final current = weather!['current'] as Map<String, dynamic>;
    final daily = weather!['daily'] as Map<String, dynamic>;
    final code = current['weather_code'];
    final temp = (current['temperature_2m'] as num).toDouble();
    final rainChance =
        ((daily['precipitation_probability_max'] as List).first as num)
            .toInt();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          villageName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.teal.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.cloud_queue,
                    size: 65, color: Colors.teal),
                Text(
                  '${temp.round()}°C',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weatherText(code),
                  style: const TextStyle(fontSize: 19),
                ),
                const SizedBox(height: 12),
                Text(
                  'जाणवणारे तापमान: '
                  '${(current['apparent_temperature'] as num).round()}°C',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: infoCard(
                'पावसाची शक्यता',
                '$rainChance%',
                Icons.umbrella,
              ),
            ),
            Expanded(
              child: infoCard(
                'आर्द्रता',
                '${current['relative_humidity_2m']}%',
                Icons.water_drop,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: infoCard(
                'वाऱ्याचा वेग',
                '${current['wind_speed_10m']} km/h',
                Icons.air,
              ),
            ),
            Expanded(
              child: infoCard(
                'आजचा पाऊस',
                '${(daily['precipitation_sum'] as List).first} mm',
                Icons.grain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'पुढील १० दिवसांचा अंदाज',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...buildDailyRows(),
        const SizedBox(height: 12),
        const Text(
          'माहिती Open-Meteo हवामान मॉडेलवर आधारित आहे. '
          'पावसाचा अंदाज निश्चित हमी नाही.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget infoCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal, size: 27),
            const SizedBox(height: 7),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildDailyRows() {
    final daily = weather!['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List;
    final maxTemp = daily['temperature_2m_max'] as List;
    final minTemp = daily['temperature_2m_min'] as List;
    final rain = daily['precipitation_probability_max'] as List;
    final codes = daily['weather_code'] as List;

    return List.generate(dates.length, (i) {
      final date = dates[i].toString();
      return Card(
        child: ListTile(
          leading: const Icon(Icons.calendar_month, color: Colors.teal),
          title: Text(date),
          subtitle: Text(
            '${weatherText(codes[i])} • पावसाची शक्यता ${rain[i]}%',
          ),
          trailing: Text(
            '${(maxTemp[i] as num).round()}° / '
            '${(minTemp[i] as num).round()}°',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    });
  }

  Widget buildHourly() {
    final hourly = weather!['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List;
    final temps = hourly['temperature_2m'] as List;
    final rainChance = hourly['precipitation_probability'] as List;
    final rain = hourly['precipitation'] as List;
    final codes = hourly['weather_code'] as List;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'पुढील २४ तास',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(24, (i) {
          final dateTime = DateTime.parse(times[i].toString());
          final hour = dateTime.hour.toString().padLeft(2, '0');
          return Card(
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Colors.teal),
              title: Text('$hour:00 • ${weatherText(codes[i])}'),
              subtitle: Text(
                'पावसाची शक्यता ${rainChance[i]}% • '
                'पाऊस ${rain[i]} mm',
              ),
              trailing: Text(
                '${(temps[i] as num).round()}°C',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget buildMap() {
    return Column(
      children: [
        const ListTile(
          title: Text('वाघाळा परिसराचा नकाशा'),
          subtitle: Text('नकाशा पाहण्यासाठी इंटरनेट आवश्यक आहे.'),
        ),
        Expanded(
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(villageLat, villageLon),
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hava_mitra_marathi',
              ),
              const MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(villageLat, villageLon),
                    width: 150,
                    height: 70,
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 38,
                        ),
                        Text(
                          'वाघाळा',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildFarmerAdvice() {
    final current = weather!['current'] as Map<String, dynamic>;
    final daily = weather!['daily'] as Map<String, dynamic>;
    final rainChance =
        ((daily['precipitation_probability_max'] as List).first as num)
            .toInt();
    final temp = (current['temperature_2m'] as num).toDouble();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'शेतकऱ्यांसाठी हवामान मार्गदर्शन',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.agriculture,
                  size: 42,
                  color: Colors.teal,
                ),
                const SizedBox(height: 8),
                Text(
                  getAdvice(rainChance, temp),
                  style: const TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 12),
                const Text(
                  'महत्त्वाची सूचना: फवारणीपूर्वी वाऱ्याचा वेग, '
                  'पावसाचा ताजा अंदाज, औषधाचे लेबल आणि स्थानिक '
                  'कृषी अधिकाऱ्यांचा सल्ला तपासा. ही सूचना सर्व पिकांसाठी '
                  'एकसारखी लागू होईलच असे नाही.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('अंदाजात अनिश्चितता असते'),
            subtitle: Text(
              'पेरणी, फवारणी किंवा सिंचनाचा अंतिम निर्णय '
              'फक्त ॲपच्या अंदाजावर घेऊ नका.',
            ),
          ),
        ),
      ],
    );
  }
}
