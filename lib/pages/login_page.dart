import 'dart:ui';
import 'package:appsocial/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';



const kHeadingText = "Connect with your friends and chat in real-time";
const kBodyText =
    "Stay connected with your loved ones wherever you are. Share messages, photos, and more, all in one place.";

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


  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.height*0.3,
                    child: Lottie.asset('animations/welcome.json'),
                  ),
                ),
              ),


              Text(
                kHeadingText,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Text(
                  kBodyText,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(
                height: 40,
              ),
              FilledButton.tonalIcon(
                onPressed: controlSignIn,
                icon: const Icon(IconlyLight.login),
                label: const Text("Continue with Google"),
              ),
            ],
          ),
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
        showSuccessAnimation(context);
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
void showSuccessAnimation(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black
        .withOpacity(0.5), // Set the barrier color to a semi-transparent black
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Set the blur radius
          child: ColorFiltered(
            colorFilter:
            ColorFilter.mode(Colors.transparent, BlendMode.srcATop),
            child: Lottie.asset(
              'animations/login_successfully.json',
              width: 200,
              height: 200,
            ),
          ),
        ),
      );
    },
  );
}