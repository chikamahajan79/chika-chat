import 'package:flutter/material.dart';
import 'services/biometric_auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChikaApp());
}

class ChikaApp extends StatelessWidget {
  const ChikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chika',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075E54), // Privacy Teal
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const BiometricLockScreen(),
    );
  }
}

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final BiometricAuthService _bioAuth = BiometricAuthService();
  bool _isUnlocked = false;
  String _status = 'Locked with Biometrics';

  @override
  void initState() {
    super.initState();
    _triggerBiometricAuth();
  }

  Future<void> _triggerBiometricAuth() async {
    setState(() => _status = 'Verifying identity...');
    final success = await _bioAuth.authenticate(
      reason: 'Scan fingerprint or face to open Chika',
    );
    if (mounted) {
      setState(() {
        _isUnlocked = success;
        _status = success ? 'Unlocked' : 'Authentication failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) {
      return const ChikaHomeScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 84, color: Color(0xFF00A884)),
              const SizedBox(height: 24),
              const Text(
                'Chika Locked',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(_status, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _triggerBiometricAuth,
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock with Biometrics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A884),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChikaHomeScreen extends StatelessWidget {
  const ChikaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202C33),
        title: const Text('Chika (E2EE)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Pair via QR Code',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: 'Lock App',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BiometricLockScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 64, color: Color(0xFF00A884)),
            const SizedBox(height: 16),
            const Text(
              'End-to-End Encrypted',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'No phone number • No server logs • Zero-Knowledge',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
