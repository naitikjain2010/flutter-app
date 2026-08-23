import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'register_screen.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Humsafar Khoj',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FB),
      appBar: AppBar(
        title: const Text('Humsafar Khoj'),
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Aapka Jeevan Sathi Khojne Ka\nSecure Madhyam', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8E24AA))),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA)), child: const Text('1. Register (Naya Account Banayein)', style: TextStyle(color: Colors.white)))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF8E24AA), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('2. Login (Pehle se Account hai)', style: TextStyle(color: Color(0xFF8E24AA), fontWeight: FontWeight.bold)))),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())), icon: const Icon(Icons.support_agent, color: Colors.white), label: const Text('3. Support & Feedback', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)))),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final nameCtrl = TextEditingController();
  final feedbackCtrl = TextEditingController();
  Future<void> sendMail() async {
    if (nameCtrl.text.isEmpty || feedbackCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naam aur Feedback likho')));
      return;
    }
    final subject = 'Humsafar Khoj - Feedback from ${nameCtrl.text}';
    final body = 'Naam: ${nameCtrl.text}\n\nFeedback / Sujhav:\n${feedbackCtrl.text}';
    final Uri emailUri = Uri(scheme: 'mailto', path: 'humsafarkhoj@gmail.com', query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: const Color(0xFF00897B), leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)), title: const Text('Support & Feedback', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aapke sujhav hamare liye bahut zaroori hain!', style: TextStyle(fontSize: 18, height: 1.4)),
            const SizedBox(height: 25),
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Aapka Naam', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            TextField(controller: feedbackCtrl, maxLines: 6, decoration: const InputDecoration(hintText: 'Feedback / Sujhav...', border: OutlineInputBorder())),
            const SizedBox(height: 25),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(onPressed: sendMail, icon: const Icon(Icons.send, color: Colors.white), label: const Text('Feedback Email Se Bhejein', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))))),
          ],
        ),
      ),
    );
  }
}