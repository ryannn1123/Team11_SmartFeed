import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'home_page.dart';
import 'dart:math' as math;

// =========================
// SHARED PALETTE
// (matches servo_page.dart / schedule_page.dart / history_page.dart / vet_page.dart)
// =========================

class _Palette {
  static const Color salmon = Color(0xFFFA7268);
  static const Color peach = Color(0xFFFF9E89);
  static const Color blush = Color(0xFFFFD6C4);
  static const Color cream = Color(0xFFFFEFC4);
  static const Color brown = Color(0xFF5B3A29);
  static const Color brownSoft = Color(0xFF7A3E2A);
}

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
  late final AnimationController _pawController;
  late final AnimationController _floatController;
  late final AnimationController _sparkleController;

  // Custom color palette (aliased to the shared app palette)
  static const Color primaryOrange = _Palette.peach;
  static const Color secondaryPeach = _Palette.blush;
  static const Color tertiaryCream = _Palette.cream;
  static const Color darkBrown = _Palette.brownSoft;
  static const Color deepBlue = _Palette.brown;

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
      duration: const Duration(milliseconds: 1600),
    );

    _logoAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _pawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _logoController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pawController.dispose();
    _floatController.dispose();
    _sparkleController.dispose();
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

  Future<void> _signInWithFacebook() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'smartfeed://login-callback',
        scopes: 'public_profile,email',
      );
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _Palette.salmon,
              primaryOrange,
              secondaryPeach,
              tertiaryCream,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Animated floating circles with custom colors
            for (int i = 0; i < 6; i++)
              Positioned(
                top: [
                  size.height * 0.02,
                  size.height * 0.15,
                  size.height * 0.4,
                  size.height * 0.65,
                  size.height * 0.85,
                  size.height * 0.1
                ][i],
                left: [
                  -30.0,
                  size.width * 0.82,
                  -20.0,
                  size.width * 0.88,
                  size.width * 0.15,
                  size.width * 0.65
                ][i],
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(seconds: 5 + i * 2),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(
                        15 * math.sin(value * math.pi * 2 + i * 1.5),
                        20 * math.cos(value * math.pi * 2 + i * 1.5),
                      ),
                      child: Container(
                        width: [80.0, 120.0, 60.0, 140.0, 90.0, 70.0][i],
                        height: [80.0, 120.0, 60.0, 140.0, 90.0, 70.0][i],
                        decoration: BoxDecoration(
                          color: [
                            primaryOrange.withOpacity(0.15),
                            secondaryPeach.withOpacity(0.15),
                            tertiaryCream.withOpacity(0.2),
                            primaryOrange.withOpacity(0.1),
                            secondaryPeach.withOpacity(0.12),
                            tertiaryCream.withOpacity(0.18),
                          ][i],
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Floating paw prints
            for (int i = 0; i < 8; i++)
              Positioned(
                top: (i * 130.0 + 40) % size.height,
                left: i % 2 == 0 ? 15.0 : size.width - 45.0,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(seconds: 3 + i % 3),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: 0.15 + 0.1 * math.sin(value * math.pi * 2),
                      child: Transform.rotate(
                        angle: value * math.pi * 2 + i * 0.5,
                        child: Icon(
                          Icons.pets,
                          size: 30.0,
                          color: darkBrown.withOpacity(0.15),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Animated sparkles
            for (int i = 0; i < 5; i++)
              Positioned(
                top: [60.0, 200.0, 350.0, 500.0, 700.0][i % 5],
                left: [40.0, 300.0, 50.0, 280.0, 100.0][i % 5],
                child: RotationTransition(
                  turns: _sparkleController,
                  child: Icon(
                    Icons.star,
                    size: [12.0, 8.0, 10.0, 14.0, 9.0][i % 5],
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // 🐾 Logo with enhanced animation
                      ScaleTransition(
                        scale: _logoAnim,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 2000),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: _Palette.salmon.withOpacity(0.35),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/smartfeed_logo.png',
                                height: isSmallScreen ? 80 : 110,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 4),
                                  Text(
                                    "Premium Pet Care",
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: darkBrown,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Animated subtitle
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "🐾 Your Smart Companion For Happy Pets 🐾",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.fraunces(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: darkBrown,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // ✨ Enhanced Frosted Glass Features Card
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.8),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _Palette.brownSoft.withOpacity(0.08),
                                        blurRadius: 25,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _PetFeatureBadge(
                                              icon: Icons.schedule_rounded,
                                              title: "Smart Schedule",
                                              color: _Palette.salmon,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _PetFeatureBadge(
                                              icon: Icons.tune_rounded,
                                              title: "Feed Control",
                                              color: primaryOrange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _PetFeatureBadge(
                                              icon: Icons.smart_toy_rounded,
                                              title: "AI Assistant",
                                              color: const Color(0xFFE0A438),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _PetFeatureBadge(
                                              icon: Icons.camera_alt_rounded,
                                              title: "Watch Live",
                                              color: const Color(0xFF6FAE7C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.dmSans(color: Colors.red.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 🔐 Enhanced GOOGLE BUTTON
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1200),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _signInWithGoogle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: deepBlue,
                                    elevation: 4,
                                    shadowColor: _Palette.salmon.withOpacity(0.2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: _Palette.salmon,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://developers.google.com/identity/images/g-logo.png',
                                              width: 22,
                                              height: 22,
                                              errorBuilder: (_, __, ___) => SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CustomPaint(
                                                  painter: _GoogleLogoPainter(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Text(
                                              "Continue with Google",
                                              style: GoogleFonts.dmSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: deepBlue,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          

                                          ],
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // 🔐 Enhanced FACEBOOK BUTTON
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1400),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _signInWithFacebook,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1877F2),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: Colors.black.withOpacity(0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const FaIcon(
                                          FontAwesomeIcons.facebookF,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        "Continue with Facebook",
                                        style: GoogleFonts.dmSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Enhanced terms text with paw decoration
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1600),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite, size: 12, color: Colors.white.withOpacity(0.7)),
                                    const SizedBox(width: 6),
                                    Text(
                                      "By continuing, you agree to our pet-friendly terms",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: darkBrown.withOpacity(0.7),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.favorite, size: 12, color: Colors.white.withOpacity(0.7)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(
                                        Icons.pets,
                                        size: 14,
                                        color: [
                                          Colors.white.withOpacity(0.6),
                                          Colors.white.withOpacity(0.5),
                                          Colors.white.withOpacity(0.4),
                                        ][index],
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================
// Enhanced Pet Feature Badge Widget
// ================================================
class _PetFeatureBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _PetFeatureBadge({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _Palette.brown,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

    final rect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: (outerR + innerR) / 2,
    );

    // Red - top left arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 2.214, 2.670, false, paint);

    // Yellow - bottom left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 1.571, 0.644, false, paint);

    // Green - bottom right arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, -0.524, 2.094, false, paint);

    // Blue - right arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.524, 0, false, paint);

    // Blue top right arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.571, 1.047, false, paint);

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