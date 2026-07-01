import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';

class ServoPage extends StatefulWidget {
  const ServoPage({super.key});

  @override
  State<ServoPage> createState() => _ServoPageState();
}

class _ServoPageState extends State<ServoPage> with TickerProviderStateMixin {
  double _angle = 0;
  double _displayAngle = 0;
  String _status = 'Ready';

  late AnimationController _pawController;
  late Animation<double> _pawAnimation;

  final List<Map<String, dynamic>> _presets = [
    {'label': '🐾 Nap', 'angle': 0, 'icon': Icons.bedtime},
    {'label': '🐕 45°', 'angle': 45, 'icon': Icons.pets},
    {'label': '🎾 Half', 'angle': 90, 'icon': Icons.circle},
    {'label': '🐩 120°', 'angle': 120, 'icon': Icons.face_4},
    {'label': '🐕‍🦺 Play', 'angle': 180, 'icon': Icons.celebration},
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentAngle();

    _pawController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pawAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pawController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _pawController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentAngle() async {
    try {
      final res = await supabase
          .from('servo')
          .select('angle, last_confirmed')
          .eq('id', 1)
          .single();

      setState(() {
        _angle = (res['angle'] as int).toDouble();
        _displayAngle = _angle;
        _status = 'Ready';
      });
      _pawController.forward(from: 0);
    } catch (e) {
      setState(() => _status = '🐾 Failed to fetch data');
    }
  }

  // Helper: convert angle to portion label
  String _portionLabel(int angle) {
    if (angle == 0) return 'Closed';
    if (angle <= 45) return 'Small';
    if (angle <= 90) return 'Medium';
    if (angle <= 135) return 'Large';
    return 'Full';
  }

  Future<void> _sendAngle() async {
    final angleInt = _angle.round();
    try {
      // Update servo angle
      await supabase
          .from('servo')
          .update({'angle': angleInt})
          .eq('id', 1);

      // Log feeding to history
      await supabase.from('feeding_logs').insert({
        'angle': angleInt,
        'portion_label': _portionLabel(angleInt),
        'trigger_type': 'manual',
        'fed_at': DateTime.now().toUtc().toIso8601String(),
      });

      setState(() => _status = '✓ Updated $angleInt°');
      _pawController.forward(from: 0);
    } catch (e) {
      setState(() => _status = '❌ Oops: $e');
    }
  }
//ari pud diri
  void _updateAngle(double val) {
  setState(() {
    _angle = val.roundToDouble();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF9E89),
              Color(0xFFFFBFA3),
              Color(0xFFFFD8A0),
              Color(0xFFFFEFC4),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with paw animation
                AnimatedBuilder(
                  animation: _pawAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1 + _pawAnimation.value * 0.1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.pets, size: 28, color: Color(0xFFFA7268)),
                          SizedBox(width: 8),
                          Text(
                            'Food Controller',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7A3E2A),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.pets, size: 28, color: Color(0xFFFA7268)),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Realtime pet servo control 🐶',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7A3E2A),
                  ),
                ),
                const SizedBox(height: 24),

                // Servo Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                            begin: _displayAngle, end: _angle),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          _displayAngle = value;
                          return SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: PetServoPainter(
                                angle: _displayAngle,
                                color: const Color(0xFFFA7268),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD6C4),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          '${_angle.round()}°',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7A3E2A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Slider
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20),
                    activeTrackColor: const Color(0xFFFA7268),
                    inactiveTrackColor: const Color(0xFFFFD6C4),
                    thumbColor: Colors.white,
                    overlayColor:
                        const Color(0xFFFA7268).withOpacity(0.2),
                  ),
                  //ari diri
                  child: Slider(
  value: _angle,
  min: 0,
  max: 180,
  divisions: 180,
  label: '${_angle.round()}°',

  onChanged: (value) {
    setState(() {
      _angle = value.roundToDouble();
    });
  },

  onChangeEnd: (value) async {
    await _sendAngle();
  },
)
                ),
                const SizedBox(height: 28),

                // Presets
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _presets.map((p) {
                    final isSelected =
                        _angle.toInt() == (p['angle'] as int);
                    return GestureDetector(
                      onTap: () => _updateAngle(
                          (p['angle'] as int).toDouble()),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFA7268)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFA7268)
                                : const Color(0xFFFFD6C4),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p['label'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF7A3E2A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              p['icon'] as IconData,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFFA7268),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // Status
                Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7A3E2A),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Refresh
                TextButton.icon(
                  onPressed: _fetchCurrentAngle,
                  icon: const Icon(Icons.refresh,
                      color: Color(0xFFFA7268)),
                  label: const Text('Refresh',
                      style: TextStyle(color: Color(0xFFFA7268))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PetServoPainter extends CustomPainter {
  final double angle;
  final Color color;

  const PetServoPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.7;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, cy + 12), width: 68, height: 42),
      const Radius.circular(20),
    );

    final bodyPaint = Paint()..color = color.withOpacity(0.15);
    final borderPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, borderPaint);

    final rad = (angle - 90) * pi / 180;
    final armEnd =
        Offset(cx + 50 * sin(rad), cy - 50 * cos(rad));

    canvas.drawLine(
      Offset(cx, cy),
      armEnd,
      Paint()
        ..color = color
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
        armEnd, 7, Paint()..color = color.withOpacity(0.85));
    canvas.drawCircle(armEnd, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(PetServoPainter old) => old.angle != angle;
}