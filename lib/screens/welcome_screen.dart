import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // GrindFit palette: Black + Gold + White + Gray
  static const Color _black = Color(0xFF050505);
  static const Color _charcoal = Color(0xFF141414);
  static const Color _gold = Color(0xFFFFC107);
  static const Color _goldLight = Color(0xFFFFD54F);
  static const Color _goldDeep = Color(0xFFE0A100);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _gray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: Column(
        children: [
          // 1. Hero image — full width sa taas, may fade papuntang black sa ibaba
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: _charcoal),
                Image.asset(
                  'assets/images/fitness_hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: _gold,
                    ),
                  ),
                ),

                // Bahagyang dark tint para mas bagay sa black theme
                const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x33000000)),
                ),

                // Top fade para mabasa ang brand text
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 130,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xB3000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),

                // Gradient fade (transparent -> black)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 200,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00050505),
                          Color(0xCC050505),
                          Color(0xFF050505),
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Brand mark sa taas
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'GRIND',
                                  style: TextStyle(color: _white),
                                ),
                                TextSpan(
                                  text: 'FIT',
                                  style: TextStyle(color: _gold),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Content section (fade + slide up pagpasok)
          SafeArea(
            top: false,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - value)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tagline
                    const Text(
                      'TRACK  •  ADAPT  •  ACHIEVE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 3,
                        color: _gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Headline
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: _white,
                          height: 1.2,
                        ),
                        children: [
                          TextSpan(text: 'Stronger Every Step\nYour '),
                          TextSpan(
                            text: 'Fitness',
                            style: TextStyle(color: _gold),
                          ),
                          TextSpan(text: ' Journey\nStarts '),
                          TextSpan(
                            text: 'Here.',
                            style: TextStyle(color: _gold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Description
                    const Text(
                      'Track your daily workouts effortlessly, unlock tailored AI-powered recommendations designed for your body, and consistently crush your fitness goals with GrindFit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _gray,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Get Started button (gold gradient)
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [_goldDeep, _gold, _goldLight],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4DFFC107),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: _black,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Already have an account? Log In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: _gray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 13,
                              color: _gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}