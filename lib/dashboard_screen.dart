import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'browse_profiles_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String name='',dob='',gender='',state='',mobile='',fatherName='',education='',work='',maritalStatus='',religion='',description='',income='';
  int age = 0;
  DateTime? dobDate;
  String biodataFileName='',biodataUrl='',profileImageUrl='';
  bool loading=true;

  final religionList = ['Hindu','Muslim','Sikh','Christian','Jain','Buddhist','Other'];
  final genderList = ['Male','Female'];
  final maritalList = ['Unmarried','Divorced','Widow'];

  @override
  void initState(){
    super.initState();
    loadData();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if(uid!= null){ FirebaseFirestore.instance.collection('users').doc(uid).update({'isOnline': true}).catchError((_){}); }
  }

  int calcAgeFromAny(dynamic dobData) {
    try{
      DateTime? dt;
      if(dobData is Timestamp) {
        dt = dobData.toDate();
      } else if(dobData is DateTime) dt = dobData;
      else if(dobData is String) {
        final c = dobData.replaceAll('-','/').split('/');
        if(c.length==3) dt = DateTime(int.parse(c[2]), int.parse(c[1]), int.parse(c[0]));
      }
      if(dt==null) return 0;
      dobDate = dt;
      final now = DateTime.now();
      int a = now.year - dt.year;
      if(now.month < dt.month || (now.month==dt.month && now.day < dt.day)) a--;
      return a;
    }catch(_){return 0;}
  }
  Future<void> loadData() async {
    try{
      final uid=FirebaseAuth.instance.currentUser!.uid;
      final doc=await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if(!doc.exists){ setState(()=>loading=false); return; }
      final data=doc.data()!;
      setState((){
        name=data['name']??'';
        if(data['dob'] is Timestamp) {
          dobDate = (data['dob'] as Timestamp).toDate();
          dob = "${dobDate!.day}/${dobDate!.month}/${dobDate!.year}";
          age = calcAgeFromAny(data['dob']);
        } else {
          dob=data['dob']??data['dobText']??'';
          age = calcAgeFromAny(dob);
          if(age==0 && data['age'] is int) age = data['age'];
        }
        gender=data['gender']??'';
        religion=data['religion']??'';
        state=data['state']??data['village']??'';
        mobile=data['mobile']??'';
        fatherName=data['fatherName']??'';
        education=data['education']??'';
        work=data['work']??'';
        maritalStatus=data['maritalStatus']??'';
        description=data['description']??data['about']??'';
        income=data['income']??'';
        biodataFileName=data['biodataFileName']??'';
        biodataUrl=data['biodataUrl']??'';
        profileImageUrl=data['profileImageUrl']??'';
        loading=false;
      });
    }catch(e){ setState(()=>loading=false); }
  }

  Future<void> pickProfileImage() async { const g=XTypeGroup(label:'Images', extensions:['jpg','jpeg','png']); final f=await openFile(acceptedTypeGroups:[g]); if(f==null)return; final b=await f.readAsBytes(); final uid=FirebaseAuth.instance.currentUser!.uid; final ref=FirebaseStorage.instance.ref().child('users/$uid/profile.jpg'); await ref.putData(b); final url=await ref.getDownloadURL(); await FirebaseFirestore.instance.collection('users').doc(uid).update({'profileImageUrl':url}); setState(()=>profileImageUrl=url); }
  Future<void> pickBiodata() async { const g=XTypeGroup(label:'Files', extensions:['pdf','doc','docx','jpg','jpeg','png']); final f=await openFile(acceptedTypeGroups:[g]); if(f==null)return; final b=await f.readAsBytes(); final fn=f.name; final uid=FirebaseAuth.instance.currentUser!.uid; final ref=FirebaseStorage.instance.ref().child('users/$uid/biodata/$fn'); await ref.putData(b); final url=await ref.getDownloadURL(); await FirebaseFirestore.instance.collection('users').doc(uid).update({'biodataFileName':fn,'biodataUrl':url}); setState((){biodataFileName=fn; biodataUrl=url;}); }
  Future<void> downloadBiodata() async { if(biodataUrl.isNotEmpty) await launchUrl(Uri.parse(biodataUrl), mode: LaunchMode.externalApplication);
  }
  void openEditProfile(){
    final nc=TextEditingController(text:name); final sc=TextEditingController(text:state); final mc=TextEditingController(text:mobile); final fc=TextEditingController(text:fatherName); final ec=TextEditingController(text:education); final wc=TextEditingController(text:work); final dc=TextEditingController(text:description); final ic=TextEditingController(text:income);
    String? tr=religionList.contains(religion)?religion:null, tg=genderList.contains(gender)?gender:null, tm=maritalList.contains(maritalStatus)?maritalStatus:null;
    showDialog(context:context, builder:(ctx)=> StatefulBuilder(builder:(ctx,setSt)=> AlertDialog(title:const Text('Edit Profile'), content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min, children:[
      TextField(controller:nc, decoration:const InputDecoration(labelText:'Naam')),
      Text('DOB: $dob | Age: $age saal', style: const TextStyle(color: Color(0xFF8E24AA), fontWeight: FontWeight.bold)),
      DropdownButtonFormField(initialValue:tg, decoration:const InputDecoration(labelText:'Gender'), items:genderList.map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged:(v)=>setSt(()=>tg=v)),
      DropdownButtonFormField(initialValue:tm, decoration:const InputDecoration(labelText:'Marital'), items:maritalList.map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged:(v)=>setSt(()=>tm=v)),
      DropdownButtonFormField(initialValue:tr, decoration:const InputDecoration(labelText:'Dharm'), items:religionList.map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(), onChanged:(v)=>setSt(()=>tr=v)),
      TextField(controller:ic, decoration:const InputDecoration(labelText:'Income')), TextField(controller:sc, decoration:const InputDecoration(labelText:'Rajya')), TextField(controller:mc, decoration:const InputDecoration(labelText:'Mobile')), TextField(controller:fc, decoration:const InputDecoration(labelText:'Pita')), TextField(controller:ec, decoration:const InputDecoration(labelText:'Shiksha')), TextField(controller:wc, decoration:const InputDecoration(labelText:'Kaam')), TextField(controller:dc, maxLines:3, decoration:const InputDecoration(labelText:'Description', border:OutlineInputBorder())),
    ])), actions:[TextButton(onPressed:()=>Navigator.pop(ctx), child:const Text('Cancel')), ElevatedButton(onPressed:() async { final uid=FirebaseAuth.instance.currentUser!.uid; await FirebaseFirestore.instance.collection('users').doc(uid).update({'name':nc.text,'gender':tg??gender,'maritalStatus':tm??maritalStatus,'religion':tr??religion,'income':ic.text,'state':sc.text,'village':sc.text,'mobile':mc.text,'fatherName':fc.text,'education':ec.text,'work':wc.text,'description':dc.text,'about':dc.text}); Navigator.pop(ctx); loadData();}, child:const Text('Save'))]))); }

  Widget infoRow(String t,String v)=> Padding(padding:const EdgeInsets.symmetric(vertical:4), child:Row(children:[Text('$t: ', style:const TextStyle(fontWeight:FontWeight.bold, color:Color(0xFF8E24AA))), Expanded(child:Text(v.isEmpty?'-':v))]));

  @override
  Widget build(BuildContext context){
    if(loading) return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final myUid=FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor:const Color(0xFFFFF5FB),
      appBar:AppBar(backgroundColor:const Color(0xFF8E24AA), title:const Text('Dashboard', style:TextStyle(color:Colors.white)), actions:[
// FILTER WALA SEARCH - REHNE DIYA
        IconButton(icon:const Icon(Icons.search, color:Colors.white), onPressed:(){ Navigator.push(context, MaterialPageRoute(builder:(_)=>const BrowseProfilesScreen())); }),
        IconButton(icon:const Icon(Icons.logout, color:Colors.white), onPressed:() async { await FirebaseFirestore.instance.collection('users').doc(myUid).update({'isOnline':false}); await FirebaseAuth.instance.signOut(); if(!mounted)return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:(_)=>const LoginScreen()), (r)=>false); })
      ]),
// CHAT WALA FLOATING BUTTON HATA DIYA
      body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(16,16,16,100), child:Column(children:[
        GestureDetector(onTap:pickProfileImage, child:Container(padding:const EdgeInsets.all(3), decoration:BoxDecoration(shape:BoxShape.circle, border:Border.all(color:const Color(0xFF8E24AA), width:3)), child:ClipOval(child:SizedBox(width:110, height:110, child:profileImageUrl.isNotEmpty?Image.network(profileImageUrl, fit:BoxFit.cover):Container(color:const Color(0xFF8E24AA), child:Center(child:Text(name.isNotEmpty?name[0].toUpperCase():"N", style:const TextStyle(fontSize:40, fontWeight:FontWeight.bold, color:Colors.white)))))))),
        const SizedBox(height:10), Text(name, style:const TextStyle(fontSize:18, fontWeight:FontWeight.bold)), Text(state, style:TextStyle(color:Colors.grey[600])),
        Text('Age: $age saal', style: const TextStyle(color: Color(0xFF8E24AA), fontWeight: FontWeight.bold)),
        const SizedBox(height:12), SizedBox(width:double.infinity, child:OutlinedButton.icon(onPressed:openEditProfile, icon:const Icon(Icons.edit,size:18), label:const Text('Edit Profile'))),
        const SizedBox(height:12),
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.pink.shade50)), padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Personal details', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8E24AA))), const Divider(), infoRow('DOB', dob), infoRow('Age', '$age saal'), infoRow('Gender', gender), infoRow('Marital', maritalStatus), infoRow('Religion', religion), infoRow('Income', income), infoRow('Mobile', mobile), infoRow('Father', fatherName), infoRow('Education', education), infoRow('Work', work), const SizedBox(height: 8), const Text('About Me', style: TextStyle(fontWeight: FontWeight.bold)), Text(description.isNotEmpty? description : '-'),])),

        const SizedBox(height: 16),
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.pink.shade50)), padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Biodata', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8E24AA))),
          const Divider(),
          if(biodataFileName.isEmpty && biodataUrl.isEmpty)
            const Text('Biodata upload nahi hai', style: TextStyle(color: Colors.grey))
          else
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF8E24AA)),
              title: Text(biodataFileName.isNotEmpty? biodataFileName : 'Biodata File'),
              subtitle: const Text('Available'),
              trailing: IconButton(icon: const Icon(Icons.download), onPressed: downloadBiodata),
            ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: pickBiodata, icon: const Icon(Icons.upload_file), label: Text(biodataUrl.isEmpty? 'Upload Biodata' : 'Change Biodata'))),
        ])),

        const SizedBox(height: 16),
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.favorite, color: Colors.red, size: 20), SizedBox(width: 6), Text('Favorites', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8E24AA)))]),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(myUid).collection('favorites').snapshots(),
            builder: (c, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              if (snap.data!.docs.isEmpty) return const Text('Koi favorite nahi', style: TextStyle(color: Colors.grey));
              return Column(children: snap.data!.docs.map((favDoc){
                var fav = favDoc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(child: Text((fav['name']??'U')[0])),
                  title: Text(fav['name']??''),
                  subtitle: Text(fav['state']??''),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { await FirebaseFirestore.instance.collection('users').doc(myUid).collection('favorites').doc(favDoc.id).delete(); }),
                );
              }).toList());
            },
          ),
        ]),),
        const SizedBox(height: 16),
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.all(8), child: Column(children: [
          ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), subtitle: Text('Account hamesha ke liye delete'), onTap: () async {
            bool? confirm = await showDialog<bool>(context: context, builder: (ctx)=> AlertDialog(title: Text('Account Delete?'), content: Text('Kya aap apna account permanently delete karna chahte ho? Ye wapas nahi ayega.'), actions: [TextButton(onPressed: ()=> Navigator.pop(ctx, false), child: Text('Cancel')), TextButton(onPressed: ()=> Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: Colors.red)))],));
            if(confirm==true){
              try{
                await FirebaseFirestore.instance.collection('users').doc(myUid).delete();
                await FirebaseAuth.instance.currentUser?.delete();
                if(!mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:(_)=>const LoginScreen()), (r)=>false);
              }catch(e){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
            }
          }),
        ]),),
      ],),),),
    );
  }
}