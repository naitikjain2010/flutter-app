import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final secretCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final dobCtrl = TextEditingController(); // display ke liye
  final mobileCtrl = TextEditingController();
  final fatherNameCtrl = TextEditingController();
  final villageCtrl = TextEditingController();
  final educationCtrl = TextEditingController();
  final workCtrl = TextEditingController();
  final incomeCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();

  String? gender = 'Male';
  String? maritalStatus = 'Unmarried';
  String? selectedReligion;
  String? selectedFileName;
  XFile? selectedFile;
  bool hidePass = true;
  bool isLoading = false;

  String? selectedState;
  int? calculatedAge;
  DateTime? selectedDOB; // NAYA - asli DOB

  final List<String> stateList = [
    'Rajasthan','Uttar Pradesh','Madhya Pradesh','Gujarat','Haryana','Delhi','Bihar','Maharashtra','Punjab','Uttarakhand','Chhattisgarh','Jharkhand','West Bengal','Other'
  ];
  final List<String> religionList = ['Hindu','Muslim','Sikh','Christian','Jain','Buddhist','Other'];

  int calculateAgeFromDOB(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
    return age;
  }

  Future<void> pickBiodataFile() async {
    const XTypeGroup typeGroup = XTypeGroup(label: 'Biodata Files', extensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file!= null) {
      setState(() {
        selectedFile = file;
        selectedFileName = file.name;
      });
    }
  }

  InputDecoration inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF8E24AA)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8E24AA), width: 2)),
    );
  }

  Future<void> saveAndRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedState == null || selectedReligion == null || selectedDOB == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rajya, Dharm aur DOB select karein')));
      return;
    }
    setState(() => isLoading = true);
    try {
      String email = usernameCtrl.text.trim();
      if (!email.contains('@')) email = "$email@humsafar-khoj.com";

      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: passwordCtrl.text.trim());
      String uid = cred.user!.uid;

      String biodataUrl = '';
      if (selectedFile!= null) {
        final bytes = await selectedFile!.readAsBytes();
        final storageRef = FirebaseStorage.instance.ref().child('biodatas/$uid/${selectedFileName!}');
        await storageRef.putData(bytes);
        biodataUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'username': usernameCtrl.text.trim(),
        'email': email,
        'secretWord': secretCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'dob': Timestamp.fromDate(selectedDOB!), // FILTER KE LIYE TIMESTAMP
        'dobText': dobCtrl.text.trim(), // dikhane ke liye
        'age': calculatedAge?? 0,
        'state': selectedState?? '',
        'village': villageCtrl.text.trim(),
        'religion': selectedReligion?? '',
        'gender': gender?? '',
        'maritalStatus': maritalStatus?? '',
        'fatherName': fatherNameCtrl.text.trim(),
        'education': educationCtrl.text.trim(),
        'work': workCtrl.text.trim(),
        'income': incomeCtrl.text.trim(),
        'description': descriptionCtrl.text.trim(),
        'mobile': mobileCtrl.text.trim(),
        'biodataFileName': selectedFileName?? '',
        'biodataUrl': biodataUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', usernameCtrl.text.trim());
      await prefs.setString('name', nameCtrl.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful!')));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => DashboardScreen()), (route) => false);
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message?? 'Registration Failed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FB),
      appBar: AppBar(backgroundColor: const Color(0xFF8E24AA), title: const Text('Naya Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Colors.white), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: usernameCtrl, decoration: inputDeco('Set Username', Icons.account_circle), validator: (v) => v!.isEmpty? 'Username set karo' : null),
              const SizedBox(height: 15),
              TextFormField(controller: passwordCtrl, obscureText: hidePass, decoration: inputDeco('Set Password', Icons.lock).copyWith(suffixIcon: IconButton(icon: Icon(hidePass? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => hidePass =!hidePass))), validator: (v) => v!.length < 4? 'Min 4 character' : null),
              const SizedBox(height: 15),
              TextFormField(controller: secretCtrl, decoration: inputDeco('Secret Word (Yaad rakhna)', Icons.security), validator: (v) => v!.isEmpty? 'Secret word likho' : null),
              const SizedBox(height: 15),
              TextFormField(controller: nameCtrl, decoration: inputDeco('Pura Naam', Icons.person), validator: (v) => v!.isEmpty? 'Naam likho' : null),
              const SizedBox(height: 15),
              TextFormField(
                controller: dobCtrl,
                readOnly: true,
                decoration: inputDeco('Janm Tithi (DD/MM/YYYY)', Icons.cake),
                validator: (v) => v!.isEmpty? 'Janm tithi chunein' : null,
                onTap: () async {
                  DateTime? picked = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1970), lastDate: DateTime.now());
                  if (picked!= null) {
                    setState(() {
                      selectedDOB = picked;
                      dobCtrl.text = "${picked.day}/${picked.month}/${picked.year}";
                      calculatedAge = calculateAgeFromDOB(picked);
                    });
                  }
                },
              ),
              if (calculatedAge!= null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Age: $calculatedAge saal',style: const TextStyle(color: Color(0xFF8E24AA), fontWeight: FontWeight.bold, fontSize: 14))),
                ),
              const SizedBox(height: 15),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(value: gender, decoration: inputDeco('Ling', Icons.wc), items: ['Male','Female'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => gender = val))),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(value: maritalStatus, decoration: inputDeco('Vaivahik Sthiti', Icons.favorite), items: ['Unmarried','Divorced','Widow'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => maritalStatus = val))),
              ]),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(value: selectedReligion, decoration: inputDeco('Dharm / Religion', Icons.temple_hindu), items: religionList.map((rel) => DropdownMenuItem(value: rel, child: Text(rel))).toList(), onChanged: (val) => setState(() => selectedReligion = val), validator: (v) => v == null? 'Dharm select karo' : null),
              const SizedBox(height: 15),
              TextFormField(controller: fatherNameCtrl, decoration: inputDeco('Pita Ka Naam', Icons.family_restroom)),
              const SizedBox(height: 15),
              TextFormField(controller: villageCtrl, decoration: inputDeco('Gaon / Shahar', Icons.home)),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(value: selectedState, decoration: inputDeco('Rajya / State', Icons.location_on), items: stateList.map((state) => DropdownMenuItem(value: state, child: Text(state))).toList(), onChanged: (val) => setState(() => selectedState = val), validator: (v) => v == null? 'Rajya select karo' : null),
              const SizedBox(height: 15),
              TextFormField(controller: educationCtrl, decoration: inputDeco('Shiksha', Icons.school)),
              const SizedBox(height: 15),
              TextFormField(controller: workCtrl, decoration: inputDeco('Kaam / Job', Icons.work)),
              const SizedBox(height: 15),
              TextFormField(controller: incomeCtrl, decoration: inputDeco('Income / Salary (Manual)', Icons.currency_rupee), keyboardType: TextInputType.text),
              const SizedBox(height: 15),
              TextFormField(controller: descriptionCtrl, decoration: inputDeco('Profile Description', Icons.description), maxLines: 4, maxLength: 300),
              const SizedBox(height: 15),
              TextFormField(controller: mobileCtrl, decoration: inputDeco('Mobile Number', Icons.phone), keyboardType: TextInputType.phone, maxLength: 10),
              const SizedBox(height: 25),
              InkWell(onTap: pickBiodataFile, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFF8E24AA), width: 1.5), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.cloud_upload, color: Color(0xFF8E24AA), size: 28), const SizedBox(width: 12), Expanded(child: Text(selectedFileName?? 'Biodata File (Optional)', style: TextStyle(color: selectedFileName!= null? Colors.black : Colors.grey[600]))), const Icon(Icons.folder_open, color: Color(0xFF8E24AA))]))),
              const SizedBox(height: 35),
              SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: isLoading? null : saveAndRegister, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: isLoading? const CircularProgressIndicator(color: Colors.white) : const Text('Register Karein', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }
}