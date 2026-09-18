import 'package:flutter/material.dart';

class GrindFitLogo extends StatelessWidget {
  const GrindFitLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Image.asset(
        'assets/grindfit_logom.png',
        height: 52, // Pinalaki natin para mas madaling makita at malinaw ang detalye
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.fitness_center, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'GrindFit',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}