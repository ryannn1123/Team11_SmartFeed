import 'package:flutter/material.dart';
import '../main.dart';
import 'servo_page.dart';
import 'schedule_page.dart';
import 'vet_page.dart';
import 'pet_registration_page.dart';
import 'history_page.dart';
import 'login_page.dart';
import '../widgets/chatbot.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ServoPage(),
    SchedulePage(),
    HistoryPage(),
    VetPage(),
    PetRegistrationPage(),
  ];

  static const Color _coralPink = Color(0xFFFF9E89);
  static const Color _warmSand  = Color(0xFFFFD8A0);
  static const Color _inactive  = Color(0xFF8A92A3);

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.tune_rounded, 'label': 'Control'},
    {'icon': Icons.schedule_rounded, 'label': 'Schedule'},
    {'icon': Icons.history_rounded, 'label': 'History'},
    {'icon': Icons.health_and_safety_rounded, 'label': 'Vet'},
    {'icon': Icons.pets_rounded, 'label': 'Pets'},
  ];

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Pet Parent';
    final userAvatar = user?.userMetadata?['avatar_url'];

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        backgroundColor: _coralPink,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF9E89),
                    Color(0xFFFFBFA3),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _coralPink.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Smart',
                    style: TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Feed',
                    style: TextStyle(
                      color: Color(0xFFFF6F61),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            offset: const Offset(0, 48),
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _coralPink,
                backgroundImage:
                    userAvatar != null ? NetworkImage(userAvatar) : null,
                child: userAvatar == null
                    ? Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A92A3),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: _signOut,
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 18, color: Color(0xFFFF6F61)),
                    SizedBox(width: 8),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          const _PetBackground(),
          _pages[_currentIndex],
        ],
      ),

      // 🌟 REDESIGNED COMPACT FLOATING NAVIGATION BAR
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final isSelected = _currentIndex == index;
              final item = _navItems[index];

              return GestureDetector(
                onTap: () {
                  setState(() => _currentIndex = index);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _warmSand.withOpacity(0.55)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 22,
                        color: isSelected ? _coralPink : _inactive,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? _coralPink : _inactive,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),

      // PetBot now floats here on every tab, including Schedule —
      // "Add feeding time" moved to the top of SchedulePage, so this
      // spot no longer needs to be reserved for it.
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: FloatingChatbot(),
      ),
    );
  }
}

class _PetBackground extends StatelessWidget {
  const _PetBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            left: -70,
            child: _Blob(
                size: 210,
                color: const Color(0xFFFF9E89),
                opacity: 0.34),
          ),
          Positioned(
            bottom: 70,
            right: -85,
            child: _Blob(
                size: 230,
                color: const Color(0xFFFFBFA3),
                opacity: 0.28),
          ),
          Positioned(
            bottom: -65,
            left: -70,
            child: _Blob(
                size: 210,
                color: const Color(0xFFFFD8A0),
                opacity: 0.34),
          ),
          Positioned(
            top: 145,
            right: 24,
            child: Icon(
              Icons.pets_rounded,
              size: 34,
              color: const Color(0xFFFF9E89).withOpacity(0.08),
            ),
          ),
          Positioned(
            top: 250,
            left: 28,
            child: Icon(
              Icons.favorite_rounded,
              size: 24,
              color: const Color(0xFFFFBFA3).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Blob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}