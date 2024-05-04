import 'package:appsocial/main.dart';
import 'package:appsocial/models/user.dart';
import 'package:appsocial/pages/chatting_page.dart';
import 'package:appsocial/pages/setting.dart';
import 'package:appsocial/widgets/progress_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final String currentUserId;
  const HomePage({super.key, required this.currentUserId});

  @override
  State<HomePage> createState() => _HomePageState(currentUserId: currentUserId);
}

class _HomePageState extends State<HomePage> {

  _HomePageState({required this.currentUserId});

  
  TextEditingController searchtextEditingController = TextEditingController();
  Future<QuerySnapshot> ?futureSearchResult;
  Future<QuerySnapshot>? futureAllUsers;
  final String currentUserId;

  @override
  void initState() {
    super.initState();
    getAllUsers(); // Fetch all users on initialization
  }
  displayAllUsers() {
    return FutureBuilder(
      future: futureAllUsers,
      builder: (context, dataSnapshot) {
        if (!dataSnapshot.hasData) {
          return circularProgress(); // Show loading indicator
        }

        List<UserResult> allUsers = [];
        dataSnapshot.data?.docs.forEach((doc) {
          final user = User.fromDocument(doc);
          final userResult = UserResult(user);
          allUsers.add(userResult);
        });

        return ListView(
          children: allUsers,
        );
      },
    );
  }

  Future<void> getAllUsers() async {
    // Get all users except the current user
    futureAllUsers = FirebaseFirestore.instance
        .collection("users")
        .where("id", isNotEqualTo: currentUserId)
        .get();
    setState(() {}); // Update UI to show loading indicator
  }

  HomePageHeader(){
    return AppBar(
      automaticallyImplyLeading: false,
      actions: <Widget>[
        IconButton(
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsOpt()));
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
          onSubmitted: controlSearching,
        ),
      ),
    );
  }

  controlSearching(String userName) {
    Future<QuerySnapshot> allFoundUsers = FirebaseFirestore.instance.collection("users")
        .where("nickname", isGreaterThanOrEqualTo: userName).get();

    setState(() {
      futureSearchResult = allFoundUsers;
    });
  }

  emptyText() {
    searchtextEditingController.clear();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomePageHeader(),
      body: futureAllUsers == null
          ? displayNoSearchResult() // Display loading indicator or message
          : displayAllUsers(),
    );
  }

  displaySearchResult(){
    return FutureBuilder(
        future: futureSearchResult,
        builder: (context, dataSnapshot) {

          if(!dataSnapshot.hasData){
            return circularProgress();
          }

          List<UserResult> searchUserResult = [];
          dataSnapshot.data?.docs.forEach((doc) {
            final user = User.fromDocument(doc);
            final userResult = UserResult(user);
            if (currentUserId != doc["id"]) {
              searchUserResult.add(userResult);
            }
          });

          return ListView(
            children:
            searchUserResult
          ,);
        },
    );
  }

  displayNoSearchResult() {
    final Orientation orientation = MediaQuery.of(context).orientation;

    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            Icon(Icons.group, color: Colors.grey, size: 200.0),
            Text(
              "search users",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 50.0,
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserResult extends StatelessWidget {

  final User eachUser;
  UserResult(this.eachUser);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            GestureDetector(
              onTap: () => sendUserToChatPage(context),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.black,
                  backgroundImage: CachedNetworkImageProvider(
                    eachUser.photoUrl
                  ),
                ),
                title: Text(
                  eachUser.nickname,
                  style: TextStyle(
                    color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold
                  ),
                ),
                /*subtitle: Text(
                  "joined: " + DateFormat('dd-MMM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(int.parse(eachUser.createdAt as String))),
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                      fontStyle: FontStyle.italic
                  ),
                ),*/
              ),
            )
          ],
        ),
      ),
    );
  }

  sendUserToChatPage(BuildContext context){
    Navigator.push(
      context, MaterialPageRoute( builder:
        (context) => Chat(
            recieverId: eachUser.id,
            recieverAvatar: eachUser.photoUrl,
            recieverName: eachUser.nickname
        )));
  }

}




