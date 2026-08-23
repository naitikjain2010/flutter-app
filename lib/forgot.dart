import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});
  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final secretCtrl = TextEditingController();
  final newUserCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> updateBoth() async {
    if (secretCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secret Word likho')));
      return;
    }
    if (newUserCtrl.text.trim().isEmpty || newPassCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naya Username aur Password dono likho')));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Firestore me Secret Word se user dhoondo
      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('secretWord', isEqualTo: secretCtrl.text.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secret Word galat hai! Register wala Secret Word yaad karo')));
        setState(() => isLoading = false);
        return;
      }

      var oldDoc = query.docs.first;
      var oldData = oldDoc.data();
      String oldUid = oldDoc.id;
      String oldEmail = oldData['email'];

      // 2. Naya Email banao
      String newEmail = newUserCtrl.text.trim();
      if (!newEmail.contains('@')) {
        newEmail = "$newEmail@humsafar-khoj.com";
      }

      // 3. Firebase Auth me naya account banao (Forgot ka simple tarika)
      // Purana Auth user delete nahi kar sakte bina login ke, to naya bana dete hain
      UserCredential newCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: newEmail,
        password: newPassCtrl.text.trim(),
      );

      String newUid = newCred.user!.uid;

      // 4. Firestore me naya data copy karo purane se + naya username
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        ...oldData,
        'username': newUserCtrl.text.trim(),
        'email': newEmail,
        'uid': newUid,
        'oldUid': oldUid,
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Purana data delete karo (optional)
      await FirebaseFirestore.instance.collection('users').doc(oldUid).delete();
      // Purana Auth account bhi delete karne ki koshish
      try {
        // Agar purane se login ho sake to delete
      } catch(_){}

      // 6. Local me bhi update
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', newUserCtrl.text.trim());
      await prefs.setString('name', oldData['name']?? '');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update Ho Gaya! Naya Username: ${newUserCtrl.text} - Ab isse Login karo')));
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ye naya username pehle se kisi ne le liya hai, dusra try karo')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FB),
      appBar: AppBar(title: const Text('Forgot Username / Password', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF8E24AA), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Secret Word se dono reset karo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8E24AA))),
            const SizedBox(height: 5),
            Text('Register karte time jo Secret Word dala tha, wahi yahan kaam aayega. Ye Firebase se check hoga.', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 25),
            TextField(
              controller: secretCtrl,
              decoration: InputDecoration(
                labelText: 'Secret Word (Register Wala)',
                prefixIcon: const Icon(Icons.security, color: Color(0xFF8E24AA)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF8E24AA), width: 2), borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 15),
            TextField(
              controller: newUserCtrl,
              decoration: InputDecoration(labelText: 'Naya Username Set Karo', prefixIcon: const Icon(Icons.account_circle), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: newPassCtrl,
              decoration: InputDecoration(labelText: 'Naya Password Set Karo', prefixIcon: const Icon(Icons.lock_reset), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading? null : updateBoth,
                icon: isLoading? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                label: Text(isLoading? 'Checking...' : 'Username & Password Update Karo', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}