import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool _loading = false;
  String? _error;

  late final AnimationController _logoController;
  late final Animation<double> _logoAnim;

  @override
  void initState() {
    super.initState();

    supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        _onLoginSuccess();
      }
    });

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoAnim = Tween<double>(begin: 0.92, end: 1.04).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _logoController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _onLoginSuccess() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final existing = await supabase
          .from('servo')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('servo').insert({
          'user_id': userId,
          'angle': 0,
          'last_confirmed': 0,
        });
      }
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'smartfeed://login-callback',
      );
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  //fbbbbbbbbbbbbbbbbb
  Future<void> _signInWithFacebook() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'smartfeed://login-callback',
      scopes: 'public_profile,email', // explicitly request only basic scopes
    );
  } catch (e) {
    setState(() => _error = 'Error: $e');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEFC4),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF9E89),
              Color(0xFFFFBFA3),
              Color(0xFFFFEFC4),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _logoAnim,
                    child: Container(
                      width: 320,
                      height: 180,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/smartfeed_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Your smart companion for happy pets 🐾",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF172033).withOpacity(0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 38),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.86),
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        _PetFeature(Icons.schedule_rounded,
                            "Smart feeding schedule"),
                        SizedBox(height: 14),
                        _PetFeature(
                            Icons.tune_rounded, "Feed control anytime"),
                        SizedBox(height: 14),
                        _PetFeature(
                            Icons.smart_toy_rounded, "AI pet assistant"),
                        SizedBox(height: 14),
                        _PetFeature(Icons.camera_alt_rounded,
                            "Watch your pet live"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 34),

                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF172033),
                        elevation: 6,
                        shadowColor: Colors.black.withOpacity(0.16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF6F61),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Real Google Logo from official CDN
                                Image.network(
                                  'https://developers.google.com/identity/images/g-logo.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (_, __, ___) => SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CustomPaint(
                                      painter: _GoogleLogoPainter(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Continue with Google",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF172033),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

const SizedBox(height: 14),

SizedBox(
  width: double.infinity,
  height: 56,
  child: ElevatedButton(
    onPressed: _loading ? null : _signInWithFacebook,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1877F2),
      foregroundColor: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        FaIcon(
          FontAwesomeIcons.facebookF,
          color: Colors.white,
          size: 20,
        ),
        SizedBox(width: 12),
        Text(
          "Continue with Facebook",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    ),
  ),
),
                  const SizedBox(height: 18),

                  Text(
                    "By continuing, you agree to our pet-friendly terms 🐾",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF172033).withOpacity(0.48),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




// ================================================
// Real Google "G" Logo Painter
// ================================================
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final outerR = w / 2;
    final innerR = outerR * 0.6;
    final strokeW = outerR - innerR;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: (outerR + innerR) / 2);

    // Red - top left arc (~210 degrees, from ~127° to ~337°)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 2.214, 2.670, false, paint);

    // Yellow - bottom left arc (~60 degrees)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 1.571, 0.644, false, paint);

    // Green - bottom right arc (~60 degrees)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, -0.524, 2.094, false, paint);

    // Blue - right arc + horizontal bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.524, 0, false, paint);

    // Blue top right arc
    canvas.drawArc(rect, -1.571, 1.047, false, paint);

    // Blue horizontal bar (the middle dash of the G)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(cx, cy - strokeW / 2, outerR - strokeW * 0.1, strokeW),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}

// ================================================
// Feature Row Widget
// ================================================
class _PetFeature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PetFeature(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFF9E89).withOpacity(0.18),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFFFF6F61),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: const Color(0xFF172033).withOpacity(0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}