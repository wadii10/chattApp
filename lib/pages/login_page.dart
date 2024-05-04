import 'package:appsocial/pages/home_page.dart';
import 'package:appsocial/widgets/progress_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth fireBaseAuth = FirebaseAuth.instance;
  SharedPreferences ?preferences;

  bool isLoggedIn = false;
  bool isLoading = false;
  User ?currentUser;

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async {
    setState(() {
      isLoggedIn = true;
    });
    preferences = await SharedPreferences.getInstance();
    isLoggedIn = await googleSignIn.isSignedIn();
    if(isLoggedIn){
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(currentUserId: preferences!.getString("id")!)));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.black, Colors.grey]
          )
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Social App", style: TextStyle(fontSize: 82.0, color: Colors.white, fontFamily: "Signatra"),),
            GestureDetector(
              onTap: controlSignIn,
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 270.0,
                      height: 65.0,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/images/btn_google_signin.png"),
                          fit: BoxFit.cover,
                        )
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: isLoading ? circularProgress() : Container(),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<dynamic> controlSignIn() async {

    try {
      preferences = await SharedPreferences.getInstance();

      setState(() {
        isLoading = true;
      });

      GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth?.idToken,
          accessToken: googleAuth?.accessToken);

      User? firebaseUser = (await fireBaseAuth.signInWithCredential(credential)).user;

      //success
      if(firebaseUser != null) {
        // check user already signed in
        final QuerySnapshot resultQuery = await FirebaseFirestore.instance.collection("users").where("id", isEqualTo: firebaseUser.uid).get();
        final List<DocumentSnapshot> documentSnapshot = resultQuery.docs;

        if(documentSnapshot.isEmpty){
          FirebaseFirestore.instance.collection("users").doc(firebaseUser.uid).set({
            "nickname" : firebaseUser.displayName,
            "photoUrl" : firebaseUser.photoURL,
            "id" : firebaseUser.uid,
            "aboutMe" : "hey! I am new in Social App",
            "createdAt" : DateTime.now().toString(),
            "chattingWith" : null
          });

          // data in local
          currentUser = firebaseUser;
          await preferences?.setString("id", currentUser!.uid);
          await preferences?.setString("nickname", currentUser?.displayName ?? "default_nickname");
          await preferences?.setString("photoUrl", currentUser!.photoURL!);
        } else {
          currentUser = firebaseUser;
          await preferences?.setString("id", documentSnapshot[0]["id"]);
          await preferences?.setString("nickname", documentSnapshot[0]["nickname"]);
          await preferences?.setString("photoUrl", documentSnapshot[0]["photoUrl"]);
          await preferences?.setString("aboutMe", documentSnapshot[0]["aboutMe"]);
        }
        Fluttertoast.showToast(msg: "welcome!");
        setState(() {
          isLoading = false;
        });
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(currentUserId: firebaseUser.uid)));
        //fail
      }else {
        Fluttertoast.showToast(msg: "Sign In Failed!");
        setState(() {
          isLoading = false;
        });
      }
    } on Exception catch(e) {
      print('exception->$e');
    }

  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

}
