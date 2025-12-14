/// Example: How to add GrievBot navigation to CitizenScreen
/// 
/// This is a helper widget that can be used in any screen to navigate to GrievBot

import 'package:flutter/material.dart';
import 'grievbot_screen.dart';

class GrievBotNavigationButton extends StatelessWidget {
  final String citizenPhone;
  final String citizenName;

  const GrievBotNavigationButton({
    super.key,
    required this.citizenPhone,
    required this.citizenName,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GrievBotScreen(
              citizenPhone: citizenPhone,
              citizenName: citizenName,
            ),
          ),
        );
      },
      icon: const Icon(Icons.smart_toy, size: 32),
      label: const Text(
        '🤖 File Complaint with AI',
        style: TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Example usage in CitizenScreen:
/// 
/// GrievBotNavigationButton(
///   citizenPhone: '9876543210',
///   citizenName: 'Rajesh Kumar',
/// )
