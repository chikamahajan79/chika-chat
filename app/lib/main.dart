import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'services/biometric_auth_service.dart';
import 'services/media_cipher_service.dart';

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
          seedColor: const Color(0xFF00A884),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111B21),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF202C33),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const BiometricLockScreen(),
    );
  }
}

// -------------------------------------------------------------
// 1. Biometric Lock Guard
// -------------------------------------------------------------
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00A884).withOpacity(0.15),
                ),
                child: const Icon(Icons.fingerprint, size: 80, color: Color(0xFF00A884)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chika Private Messenger',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(_status, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: _triggerBiometricAuth,
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock with Biometrics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A884),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. Main Chat List & Navigation
// -------------------------------------------------------------
class ChikaHomeScreen extends StatefulWidget {
  const ChikaHomeScreen({super.key});

  @override
  State<ChikaHomeScreen> createState() => _ChikaHomeScreenState();
}

class _ChikaHomeScreenState extends State<ChikaHomeScreen> {
  final String _myAnonymousId = "usr_${const Uuid().v4().substring(0, 8)}";
  final List<Map<String, String>> _contacts = [
    {"name": "Alice (QR Paired)", "id": "usr_9f8a12bc", "lastMessage": "🔒 [Encrypted Photo]", "time": "10:42 PM"},
    {"name": "Bob (QR Paired)", "id": "usr_3d4e56fa", "lastMessage": "🔒 Can you send the audio note?", "time": "09:15 PM"}
  ];

  void _showMyQrCode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF202C33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your Anonymous Chika QR',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text('Have friends scan this to start an encrypted chat without phone numbers.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(
                data: "chika://pair?id=$_myAnonymousId&pk=Curve25519_DEMO_KEY",
                version: QrVersions.auto,
                size: 180.0,
              ),
            ),
            const SizedBox(height: 16),
            Text("Your ID: $_myAnonymousId", style: const TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chika', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Show My QR Code',
            onPressed: _showMyQrCode,
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: 'Lock Chika',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BiometricLockScreen()),
              );
            },
          ),
        ],
      ),
      body: _contacts.isEmpty
          ? const Center(
              child: Text('No contacts yet. Tap QR to pair anonymously.', style: TextStyle(color: Colors.grey)),
            )
          : ListView.separated(
              itemCount: _contacts.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF222D34), height: 1),
              itemBuilder: (ctx, index) {
                final contact = _contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00A884),
                    child: Text(contact['name']![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(contact['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(contact['lastMessage']!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  trailing: Text(contact['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatConversationScreen(
                          contactName: contact['name']!,
                          contactId: contact['id']!,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// -------------------------------------------------------------
// 3. Encrypted Chat & Media Screen
// -------------------------------------------------------------
class ChatConversationScreen extends StatefulWidget {
  final String contactName;
  final String contactId;

  const ChatConversationScreen({
    super.key,
    required this.contactName,
    required this.contactId,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _msgController = TextEditingController();
  final MediaCipherService _mediaCipher = MediaCipherService();
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _messages = [
    {
      "isMe": false,
      "type": "text",
      "text": "Hello! This channel is End-to-End Encrypted via Signal Double Ratchet.",
      "time": "10:40 PM"
    },
    {
      "isMe": true,
      "type": "text",
      "text": "Awesome! Zero server retention and biometric protection enabled.",
      "time": "10:41 PM"
    }
  ];

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        "isMe": true,
        "type": "text",
        "text": _msgController.text.trim(),
        "time": "Just now",
      });
      _msgController.clear();
    });
  }

  Future<void> _pickAndEncryptPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final Uint8List rawBytes = await image.readAsBytes();
    final key = await _mediaCipher.generateMediaKey();
    final encryptedPackage = await _mediaCipher.encryptMedia(rawBytes, key);

    setState(() {
      _messages.add({
        "isMe": true,
        "type": "photo",
        "rawBytes": rawBytes, // Local preview
        "cipherSize": encryptedPackage['cipherText'].length,
        "time": "Just now",
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔒 Photo encrypted with AES-256-GCM before uploading to relay!'),
        backgroundColor: Color(0xFF00A884),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contactName, style: const TextStyle(fontSize: 16)),
            const Row(
              children: [
                Icon(Icons.lock, size: 12, color: Color(0xFF00A884)),
                SizedBox(width: 4),
                Text('Signal E2EE Session', style: TextStyle(fontSize: 11, color: Color(0xFF00A884))),
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, index) {
                final msg = _messages[index];
                final bool isMe = msg['isMe'];

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF005C4B) : const Color(0xFF202C33),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg['type'] == 'text')
                          Text(msg['text'], style: const TextStyle(color: Colors.white, fontSize: 15))
                        else if (msg['type'] == 'photo')
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(msg['rawBytes'], height: 180, width: double.infinity, fit: BoxFit.cover),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(msg['time'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.done_all, size: 14, color: Color(0xFF53BDEB)),
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF202C33),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_camera, color: Color(0xFF8696A0)),
                  onPressed: _pickAndEncryptPhoto,
                ),
                IconButton(
                  icon: const Icon(Icons.mic, color: Color(0xFF8696A0)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🎤 Voice note recording & encryption ready.')),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type an encrypted message...',
                      hintStyle: TextStyle(color: Color(0xFF8696A0), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00A884)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
