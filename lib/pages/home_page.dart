import 'package:appsocial/main.dart';
import 'package:appsocial/pages/setting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatefulWidget {
  final String currentUserId;
  const HomePage({super.key, required this.currentUserId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchtextEditingController = TextEditingController();

  HomePageHeader(){
    return AppBar(
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
            },
            icon: Icon(Icons.settings, size:30, color: Colors.white)
        )
      ],
        elevation: 0,
        backgroundColor: Colors.grey.shade900,
        title: Container(
          height: 38,
          child: TextField(
            controller: searchtextEditingController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                contentPadding: EdgeInsets.all(0),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500,),
                suffixIcon: IconButton(
                    onPressed: emptyText,
                    icon: Icon(Icons.clear_rounded, color: Colors.grey.shade500,),),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none
                ),
                hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500
                ),
                hintText: "Search users"
            ),
          ),
        ),
    );
  }
  emptyText() {
    searchtextEditingController.clear();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomePageHeader(),
      body: ElevatedButton.icon(
        onPressed: logoutUser,
        icon: const Icon(Icons.close),
        label: const Text("Log out"),
        style: ElevatedButton.styleFrom( // Optional: customize styles
          primary: Colors.red, // Set background color
          onPrimary: Colors.white, // Set text color
        ),
      ),
    );
  }

  final GoogleSignIn googleSignIn = GoogleSignIn();
  Future<void> logoutUser () async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MyApp()), (route) => false);
  }
}


