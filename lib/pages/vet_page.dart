import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class VetPage extends StatefulWidget {
  const VetPage({super.key});

  @override
  State<VetPage> createState() => _VetPageState();
}

class _VetPageState extends State<VetPage> {
  Position? _position;
  bool _loadingLocation = false;
  String _locationStatus = 'Tap "Use GPS" to find nearest clinics';

  static const List<Map<String, dynamic>> _clinics = [
    {
      'name': 'Cebu Northside Veterinary Clinic',
      'address': 'Door 4, Brgy, Bogo MGF Franz Bldg, Gairan, Bogo City, 6010 Cebu',
      'phone': '09674592737',
      'hours': 'Mon-Fri: 8AM - 5PM',
      'type': 'Private',
      'color': Color(0xFFFF9E89),
      'lat': 11.0509,
      'lng': 124.0054,
    },
    {
      'name': 'David Shepherd Veterinary Services',
      'address': 'A.Mansueto St, Lourdes, Bogo City, 6010 Cebu',
      'phone': '09661456014',
      'hours': 'Mon-Sat: 9AM - 6PM',
      'type': 'Private',
      'color': Color(0xFFFFBFA3),
      'lat': 11.0515,
      'lng': 124.0060,
    },
    {
      'name': 'Bogo Claws and Paws Animal Clinic',
      'address': '3225+M7X, Bogo City, Cebu',
      'phone': '(032) 406 0505',
      'hours': 'Daily: 8AM - 8PM',
      'type': 'Private',
      'color': Color(0xFFFFD4A8),
      'lat': 11.0520,
      'lng': 124.0048,
    },
    {
      'name': 'Happy Paws Vet Clinic',
      'address': 'Carbon Market Area, Bogo City, Cebu',
      'phone': '0935-789-0123',
      'hours': 'Mon-Sat: 8AM - 7PM',
      'type': 'Private',
      'color': Color(0xFFFFEFC4),
      'lat': 11.0500,
      'lng': 124.0065,
    },
  ];

  Future<void> _getLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationStatus = 'Getting your location...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permission denied';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Enable location in phone settings';
          _loadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _position = position;
        _locationStatus = 'Showing nearest clinics first';
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Could not get location';
        _loadingLocation = false;
      });
    }
  }

  double _getDistance(Map<String, dynamic> clinic) {
    if (_position == null) return 0;
    return Geolocator.distanceBetween(
          _position!.latitude,
          _position!.longitude,
          clinic['lat'] as double,
          clinic['lng'] as double,
        ) /
        1000;
  }

  List<Map<String, dynamic>> get _sortedClinics {
    if (_position == null) return _clinics;
    final sorted = List<Map<String, dynamic>>.from(_clinics);
    sorted.sort((a, b) => _getDistance(a).compareTo(_getDistance(b)));
    return sorted;
  }

  void _openMaps(Map<String, dynamic> clinic) async {
    final lat = clinic['lat'] as double;
    final lng = clinic['lng'] as double;
    final name = Uri.encodeComponent(clinic['name'] as String);
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$name&center=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _callClinic(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinics = _sortedClinics;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9E89),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Vet Clinics',
          style: TextStyle(
            color: Color(0xFF5B3A29),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          // GPS Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF9E89),
                  Color(0xFFFFBFA3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _position != null
                      ? Icons.location_on
                      : Icons.location_searching,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationStatus,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _loadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : TextButton(
                        onPressed: _getLocation,
                        child: Text(
                          _position != null ? 'Refresh' : 'Use GPS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ],
            ),
          ),

          // Clinics List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: clinics.length,
              itemBuilder: (context, index) {
                final clinic = clinics[index];
                final distance =
                    _position != null ? _getDistance(clinic) : null;
                final color = clinic['color'] as Color;
                final phone = clinic['phone'] as String;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.local_hospital,
                                  color: color.darken(0.15), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clinic['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Color(0xFF5B3A29),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          clinic['type'] as String,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color.darken(0.2),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (distance != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFEFC4),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${distance.toStringAsFixed(1)} km',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF5B3A29),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.brown[400]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                clinic['address'] as String,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.brown[600]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Phone
                        if (phone.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.phone,
                                  size: 16, color: Colors.brown[400]),
                              const SizedBox(width: 6),
                              Text(
                                phone,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.brown[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Hours
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 16, color: Colors.brown[400]),
                            const SizedBox(width: 6),
                            Text(
                              clinic['hours'] as String,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.brown[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Buttons
                        Row(
                          children: [
                            if (phone.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _callClinic(phone),
                                  icon: Icon(Icons.phone,
                                      size: 16, color: color.darken(0.2)),
                                  label: Text(
                                    'Call',
                                    style:
                                        TextStyle(color: color.darken(0.2)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: color.darken(0.1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            if (phone.isNotEmpty) const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _openMaps(clinic),
                                icon: const Icon(Icons.directions, size: 16),
                                label: const Text('Directions'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: color.darken(0.05),
                                  foregroundColor: const Color(0xFF5B3A29),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}