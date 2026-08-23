import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class BrowseProfilesScreen extends StatefulWidget {
  const BrowseProfilesScreen({super.key});
  @override
  State<BrowseProfilesScreen> createState() => _BrowseProfilesScreenState();
}

class _BrowseProfilesScreenState extends State<BrowseProfilesScreen> {
String? selectedReligion, selectedState, selectedGender;
final minAgeController = TextEditingController(text: '18');
final maxAgeController = TextEditingController(text: '60');
List<DocumentSnapshot> results = [];
bool loading = false;

final religions = ['All','Hindu','Muslim','Sikh','Christian','Jain','Buddhist','Other'];
final states = ['All','Rajasthan','Maharashtra','Uttar Pradesh','Madhya Pradesh','Gujarat','Delhi','Bihar','Punjab','Haryana'];
final genders = ['All','Male','Female'];

int calcAgeAny(dynamic dobData){
try{
DateTime? dt;
if(dobData is Timestamp) {
  dt = dobData.toDate();
} else if(dobData is DateTime) dt = dobData;
else if(dobData is String && dobData.isNotEmpty){
final c = dobData.replaceAll('-','/').split('/');
if(c.length==3) dt = DateTime(int.parse(c[2]), int.parse(c[1]), int.parse(c[0]));
}
if(dt==null) return 0;
final now = DateTime.now();
int a = now.year - dt.year;
if(now.month < dt.month || (now.month==dt.month && now.day < dt.day)) a--;
return a;
}catch(_){return 0;}
}
Future<void> searchProfiles() async {
  setState(()=>loading=true);
  try{
    Query query = FirebaseFirestore.instance.collection('users');
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if(selectedReligion!= 'All' && selectedReligion!=null) query = query.where('religion', isEqualTo: selectedReligion);
    if(selectedState!= 'All' && selectedState!=null) query = query.where('state', isEqualTo: selectedState);
    if(selectedGender!= 'All' && selectedGender!=null) query = query.where('gender', isEqualTo: selectedGender);
    int minAge = int.tryParse(minAgeController.text.trim())??18;
    int maxAge = int.tryParse(maxAgeController.text.trim())??60;
    final snap = await query.limit(100).get();
    final filtered = snap.docs.where((d){
      if(d.id == currentUid) return false;
      var data = d.data() as Map<String, dynamic>;
      int userAge = calcAgeAny(data['dob']);
      if(userAge==0) userAge = (data['age'] is int)? data['age'] : int.tryParse(data['age'].toString())??0;
      if(userAge==0) return true;
      return userAge >= minAge && userAge <= maxAge;
    }).toList();
    setState((){results = filtered; loading = false;});
  }catch(e){ setState(()=>loading=false); }
}

void openProfile(Map<String,dynamic> data, String otherUid){
  Navigator.push(context, MaterialPageRoute(builder: (_) => FullProfileScreen(data: data, otherUid: otherUid, calcAgeAny: calcAgeAny)));
}

Widget drop(String label, List<String> items, String? val, Function(String?) onChanged){
  return DropdownButtonFormField<String>(initialValue: val, decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), items: items.map((e)=> DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged);
}
@override
Widget build(BuildContext context){
  return Scaffold(
    backgroundColor: const Color(0xFFFFF5FB),
    appBar: AppBar(backgroundColor: const Color(0xFF8E24AA), title: const Text('Search Profiles', style: TextStyle(color: Colors.white))),
    body: Column(children: [
      Container(padding: const EdgeInsets.all(12), color: Colors.white, child: Column(children: [
        Row(children: [Expanded(child: drop('Dharm', religions, selectedReligion, (v)=> setState(()=>selectedReligion=v))), const SizedBox(width: 8), Expanded(child: drop('Rajya', states, selectedState, (v)=> setState(()=>selectedState=v)))]),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: drop('Gender', genders, selectedGender, (v)=> setState(()=>selectedGender=v))), const SizedBox(width: 8), Expanded(child: TextField(controller: minAgeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Age', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: maxAgeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Age', border: OutlineInputBorder())))]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: searchProfiles, icon: const Icon(Icons.search, color: Colors.white), label: const Text('Search', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA))))
      ])),
      if(loading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
      if(!loading) Expanded(child: ListView.builder(itemCount: results.length, itemBuilder: (ctx,i){
        final data = results[i].data() as Map<String,dynamic>; final otherUid = results[i].id; final displayAge = calcAgeAny(data['dob'])!=0? calcAgeAny(data['dob']) : (data['age']??0);
        return Card(child: ListTile(leading: CircleAvatar(backgroundImage: (data['profileImageUrl']??'').toString().isNotEmpty? NetworkImage(data['profileImageUrl']) : null), title: Text(data['name']??'No Name'), subtitle: Text('${data['religion']??'-'} • ${data['state']??'-'} • $displayAge'), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: ()=> openProfile(data, otherUid)));
      }))
    ]),
  );
}
}
class FullProfileScreen extends StatelessWidget {
final Map<String,dynamic> data;
final String otherUid;
final int Function(dynamic) calcAgeAny;
const FullProfileScreen({super.key, required this.data, required this.otherUid, required this.calcAgeAny});
Widget infoRow(String t,String v)=> Padding(padding:const EdgeInsets.symmetric(vertical:4), child:Row(children:[Text('$t: ', style:const TextStyle(fontWeight:FontWeight.bold, color:Color(0xFF8E24AA))), Expanded(child:Text(v.isEmpty?'-':v))]));
@override
Widget build(BuildContext context) {
int displayAge = calcAgeAny(data['dob'])!=0? calcAgeAny(data['dob']) : (data['age'] is int? data['age'] : int.tryParse('${data['age']??0}')??0);
String dobText = data['dob'] is Timestamp? "${(data['dob'] as Timestamp).toDate().day}/${(data['dob'] as Timestamp).toDate().month}/${(data['dob'] as Timestamp).toDate().year}" : (data['dob']??data['dobText']??'');
return Scaffold(
backgroundColor: const Color(0xFFFFF5FB),
appBar: AppBar(backgroundColor: const Color(0xFF8E24AA), title: Text(data['name']??'Profile', style: const TextStyle(color: Colors.white))),
body: SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: Column(children: [
Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8E24AA), width: 3)), child: ClipOval(child: SizedBox(width: 120, height: 120, child: (data['profileImageUrl']??'').toString().isNotEmpty? Image.network(data['profileImageUrl'], fit: BoxFit.cover) : Container(color: const Color(0xFF8E24AA), child: Center(child: Text((data['name']??'U')[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.white))))))),
const SizedBox(height: 10),
Text(data['name']??'', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
Text(data['state']??'', style: TextStyle(color: Colors.grey[600])),
Text('Age: $displayAge saal', style: const TextStyle(color: Color(0xFF8E24AA), fontWeight: FontWeight.bold)),
const SizedBox(height: 16),
Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
const Text('Personal Details', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8E24AA))), const Divider(),
infoRow('DOB', dobText), infoRow('Age', '$displayAge saal'), infoRow('Gender', data['gender']??''), infoRow('Marital', data['maritalStatus']??''), infoRow('Religion', data['religion']??''), infoRow('Income', data['income']??''), infoRow('Mobile', data['mobile']??''), infoRow('Father', data['fatherName']??''),
  infoRow('Education', data['education']??''), infoRow('Work', data['work']??''),
  const SizedBox(height: 8), const Text('About', style: TextStyle(fontWeight: FontWeight.bold)), Text(data['description']??data['about']??'-'),
])),
  const SizedBox(height: 16),
  Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Biodata Document', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8E24AA))), const Divider(),
    if((data['biodataUrl']??'')=='') const Text('Biodata upload nahi hai')
    else ListTile(
      leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF8E24AA), size: 40),
      title: Text(data['biodataFileName']??'Biodata'),
      subtitle: const Text('Original file'),
      trailing: const Icon(Icons.download),
      onTap: () async { await launchUrl(Uri.parse(data['biodataUrl']), mode: LaunchMode.externalApplication); },
    ),
    if((data['biodataUrl']??'')!='') SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.download, color: Colors.white), label: const Text('Original Download', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA)), onPressed: () async { await launchUrl(Uri.parse(data['biodataUrl']), mode: LaunchMode.externalApplication); }))
  ])),
]),
),
);
}
}