import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController logoController;
  late AnimationController textController;
  late AnimationController bgController;

  late Animation<double> logoAnim;
  late Animation<Offset> textAnim;

  double progress = 0;
  bool showButton = false;

  @override
  void initState() {
    super.initState();

    // 🔷 LOGO
    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    logoAnim = CurvedAnimation(
      parent: logoController,
      curve: Curves.elasticOut,
    );

    logoController.forward();

    // 🔷 TEXT
    textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    textAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: textController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      textController.forward();
    });

    // 🔷 BACKGROUND ANIMATION
    bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // 🔷 LOADING
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        progress += 0.02;

        if (progress >= 1) {
          timer.cancel();
          showButton = true;
        }
      });
    });
  }

  @override
  void dispose() {
    logoController.dispose();
    textController.dispose();
    bgController.dispose();
    super.dispose();
  }

  void goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [

          // 🔥 GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A1F44),
                  Color(0xFF163A70),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔥 SHAPES ANIMÉS
          ...List.generate(8, (i) {
            return AnimatedBuilder(
              animation: bgController,
              builder: (_, __) {
                double offset = sin(bgController.value * 2 * pi + i) * 30;

                return Positioned(
                  top: 100 + offset + i * 40,
                  left: 30 + i * 35,
                  child: shape(i),
                );
              },
            );
          }),

          // 🔷 CONTENU
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // 🔷 LOGO
                ScaleTransition(
                  scale: logoAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.school,
                        size: 70, color: Color(0xFF0A1F44)),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔷 TITRE
                SlideTransition(
                  position: textAnim,
                  child: const Text(
                    "StageConnect",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 🔷 SOUS TITRE
                const Text(
                  "Suivi de stages intelligent",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 10),

                // 🔷 DESCRIPTION
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Plateforme unifiée pour gérer, suivre et valider vos stages en temps réel.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 🔷 PROGRESS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: Colors.blueAccent,
                  ),
                ),

                const SizedBox(height: 30),

                // 🔷 BUTTON GLASS
                if (showButton)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: goToLogin,
                    child: const Text("Commencer"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔷 SHAPES MIX
  Widget shape(int i) {
    if (i % 4 == 0) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
      );
    } else if (i % 4 == 1) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
      );
    } else if (i % 4 == 2) {
      return CustomPaint(
        size: const Size(60, 60),
        painter: TrianglePainter(),
      );
    } else {
      return CustomPaint(
        size: const Size(80, 60),
        painter: BlobPainter(),
      );
    }
  }
}

// 🔺 TRIANGLE
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05);

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// 🌊 BLOB
class BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05);

    final path = Path();

    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.3, size.height * 0.1,
        size.width * 0.6, size.height * 0.5);

    path.quadraticBezierTo(
        size.width * 0.9, size.height * 0.9,
        size.width, size.height * 0.5);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}