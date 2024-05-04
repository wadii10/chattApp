import 'dart:io';
import 'package:appsocial/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appsocial/widgets/progress_widget.dart';

class SettingsOpt extends StatelessWidget {
  const SettingsOpt({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color:Colors.white,
        ),
        backgroundColor: Colors.black,
        title: Text("Account Settings",
          style:TextStyle(
              color: Colors.white,
              fontWeight:FontWeight.bold) ,
        ),
        centerTitle:true ,

      ),
      body: SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController nickNameController = TextEditingController();
  TextEditingController aboutMeController = TextEditingController();

  SharedPreferences ?preferences;
  String id = "";
  String nickname = "";
  String photoUrl = "";
  String aboutMe = "";
  File ?imageAvatar;
  bool isLoading = false;
  final FocusNode nicknameFocusNode= FocusNode();
  final FocusNode aboutMeFocusNode= FocusNode();



  @override
  void initState() {
    super.initState();
    // TODO: implement initState
    readDataFromLocal();
  }


  void readDataFromLocal() async {
    preferences = await SharedPreferences.getInstance();
    id = preferences!.getString("id")!;
    nickname = preferences!.getString("nickname")!;
    photoUrl = preferences!.getString("photoUrl")!;
    aboutMe = preferences!.getString("aboutMe")!;

    nickNameController = TextEditingController(text: nickname);
    aboutMeController = TextEditingController(text: aboutMe);

    setState(() {

    });
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker(); // Création d'une instance de ImagePicker

    // Sélectionner une image depuis la galerie
    File pickedFile = (await imagePicker.pickImage(
        source: ImageSource.gallery)) as File;
    setState(() {
      this.imageAvatar = pickedFile as File?;
      isLoading = true;
    });
      //upload image to firestore
    uploadImage();

  }

  Future<void> uploadImage() async {
    // 1. Validate image
    if (imageAvatar == null) {
      Fluttertoast.showToast(msg: "Please select an image to upload.");
      return; // Early exit if no image is selected
    }

    // 2. Generate a unique filename (optional)
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg'; // Example format

    // 3. Create a reference to the upload location
    final reference = FirebaseStorage.instance.ref().child('user_images/$fileName');

    // 4. Upload the image
    try {
      final uploadTask = reference.putFile(imageAvatar!);
      final snapshot = await uploadTask.whenComplete(() => null); // Wait for completion

      // 5. Get the download URL
      final photoUrl = await snapshot.ref.getDownloadURL();

      // 6. Update user data
      await FirebaseFirestore.instance.collection("users").doc(id).update({
        "photoUrl": photoUrl,
        "aboutMe": aboutMe,
        "nickname": nickname,
      });

      // 7. Update local storage (optional)
      await preferences?.setString("photoUrl", photoUrl);

      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Updated successfully!");
    } on FirebaseException catch (error) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Error uploading image: ${error.message}");
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "An unexpected error occurred: ${error.toString()}");
    }
  }

  updateData() async {
    nicknameFocusNode.unfocus();
    aboutMeFocusNode.unfocus();

    setState(() {
      isLoading = false;
    });

    await FirebaseFirestore.instance.collection("users").doc(id).update({
      "photoUrl": photoUrl,
      "aboutMe": aboutMe,
      "nickname": nickname,
    });

    // 7. Update local storage (optional)
    await preferences?.setString("photoUrl", photoUrl);
    await preferences?.setString("aboutMe", aboutMe);
    await preferences?.setString("nickname", nickname);

    setState(() {
      isLoading = false;
    });
    Fluttertoast.showToast(msg: "Updated successfully!");

  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              // Profile Image - Avatar
              Container(
                child: Center(
                  child: Stack(
                    children: [
                      // Profile Image - Avatar
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(300),
                          child: (imageAvatar == null)
                              ? (photoUrl != "")
                              ? CachedNetworkImage(
                            placeholder: (context, url) =>
                                Container(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.lightBlueAccent),
                                  ),
                                  width: 100.0,
                                  height: 100.0,
                                  padding: EdgeInsets.all(20.0),
                                ),
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                          )
                              : Icon(
                            Icons.account_circle, size: 90.0, color: Colors.grey,)
                              : Image.file(imageAvatar!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Camera IconButton
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.white, // replace with your primary color
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 20,
                            ),
                            onPressed: getImage,
                          ),
                        ),
                      ),
                    ],
                  ),

                ),
                width: double.infinity,
                margin: EdgeInsets.all(20.0),
              ),
              Column(
                children: [
                  Padding(padding: EdgeInsets.all(1.0),child:
                  isLoading?circularProgress():Container(),
                  ),
                  Container(
                    child: Text("Profile Name",
                      style: TextStyle(fontStyle: FontStyle.italic,fontWeight: FontWeight.bold,color: Colors.lightBlueAccent),
                    ),
                    margin: EdgeInsets.only(left: 10.0,bottom: 5.0,top: 10.0),
                  ),
                  Container(
                    child: Theme(
                      data:Theme.of(context).copyWith(primaryColor:Colors.lightBlueAccent),
                      child: TextField(
                        decoration: InputDecoration(
                            hintText: "e.g Wadii Driss",
                            contentPadding:EdgeInsets.all(5.0),
                            hintStyle:TextStyle(color: Colors.grey)
                        ),
                        controller: nickNameController,
                        onChanged: (value){
                          nickname=value;
                        },
                        focusNode: nicknameFocusNode,
                      ),
                    ),
                    margin:EdgeInsets.only(left: 30.0,right: 30.0) ,
                  ),
                  Container(
                    child: Text("About Me ",
                      style: TextStyle(fontStyle: FontStyle.italic,fontWeight: FontWeight.bold,color: Colors.lightBlueAccent),
                    ),
                    margin: EdgeInsets.only(left: 10.0,bottom: 5.0,top: 30.0),
                  ),
                  Container(
                    child: Theme(
                      data:Theme.of(context).copyWith(primaryColor:Colors.lightBlueAccent),
                      child: TextField(
                        decoration: InputDecoration(
                            hintText: "Bio ..",
                            contentPadding:EdgeInsets.all(5.0),
                            hintStyle:TextStyle(color: Colors.grey)
                        ),
                        controller: aboutMeController,
                        onChanged: (value){
                          aboutMe=value;
                        },
                        focusNode: aboutMeFocusNode,
                      ),
                    ),
                    margin:EdgeInsets.only(left: 30.0,right: 30.0) ,
                  )
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              Container(
                child: TextButton(
                  child: Text(
                    "Update",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent, disabledForegroundColor: Colors.white.withOpacity(0.38),
                    padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                  ),
                  onPressed: updateData,
                ),
                margin: EdgeInsets.only(top: 50.0, bottom: 1.0),
              ),
              Padding(
                padding: EdgeInsets.only(left: 50.0, right: 50.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red, // background color
                  ),
                  onPressed: logoutUser,
                  child: Text(
                    "Logout",
                    style: TextStyle(fontSize: 14.0),
                  ),
                ),
              )



            ],
          ),
          padding: EdgeInsets.only(left: 15.0,right: 15.0),
        ),
      ],
    );
  }



  final GoogleSignIn googleSignIn = GoogleSignIn();
  Future<void> logoutUser () async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>const MyApp()), (route) => false);
  }
}





