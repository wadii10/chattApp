import 'dart:io';
import 'dart:async';
import 'package:appsocial/widgets/FullImageWidget.dart';
import 'package:appsocial/widgets/progress_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chat extends StatelessWidget {
  final String recieverId;
  final String recieverAvatar;
  final String recieverName;

  const Chat({
    super.key, required this.recieverId, required this.recieverAvatar, required this.recieverName
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              backgroundImage: CachedNetworkImageProvider(recieverAvatar),
            ),
          ),
        ],
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.black,
        title: Text(
          recieverName,
          style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
      ),
      body: ChatScreen(recieverId: recieverId, recieverAvatar: recieverAvatar),
    );
  }
}

class ChatScreen extends StatefulWidget {

  final String? recieverId;
  final String? recieverAvatar;

  const ChatScreen({super.key, required this.recieverId, required this.recieverAvatar});

  @override
  State<ChatScreen> createState() => _ChatScreenState(recieverId: recieverId, recieverAvatar: recieverAvatar);
}

class _ChatScreenState extends State<ChatScreen> {
  final String? recieverId;
  final String? recieverAvatar;

  _ChatScreenState({required this.recieverId, required this.recieverAvatar});

  final TextEditingController textEditingController = TextEditingController();
  var listMessage;
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  bool ?isDisplaySticker;
  bool ?isLoading;

  File ?imageFile;
  String ?imageUrl;

  String? chatId;
  SharedPreferences? preferences;
  String? id;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    focusNode.addListener(onFocusChange);
    isDisplaySticker = false;
    isLoading = false;

    chatId = "";
    readLocal();
  }

  readLocal() async {
    preferences = await SharedPreferences.getInstance();
    id = preferences!.getString("id") ?? "";

    if(id.hashCode <= recieverId.hashCode){
      chatId = "$id-$recieverId";
    }else{
      chatId = "$recieverId-$id";
    }

    FirebaseFirestore.instance.collection("users").doc(id).update(
        {"chattingWith":recieverId}
    );

    setState(() {

    });
  }

  onFocusChange(){
    if(focusNode.hasFocus){
      //hide stickers when keypad is display
      setState(() {
        isDisplaySticker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        child: Stack(
          children: [
            Column(
              children: [
                createListMessages(),//list message
                (isDisplaySticker! ? createStickers() : Container()) ,// show stickers
                createInput(),//control input
              ],
            ),
            createLoading(),
          ],
        ),
      canPop: false,
      onPopInvoked: (bool _onBackPress){
          if(isDisplaySticker!){
          setState(() {
          isDisplaySticker = false;
          });
        }else {
            Navigator.pop(context);
          }
          },
    );
  }

  createLoading(){
    return Positioned(
        child: isLoading! ? circularProgress() : Container()
    );
  }

  createListMessages(){
    return Flexible(
        child: chatId == '' ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
          ),
        ) : StreamBuilder(
          stream: FirebaseFirestore.instance.collection("messages").
          doc(chatId).collection(chatId!).orderBy("timestamp", descending: true ).limit(20).snapshots(),
          builder: (context, snapshot) {
            if(!snapshot.hasData){
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                ),
              );
            }else {
              listMessage = snapshot.data!.docs;
              return ListView.builder(
                  padding: EdgeInsets.all(10.0),
                  itemBuilder:(context, index) => createItem(index, snapshot.data!.docs[index]),
                  itemCount: snapshot.data!.docs.length,
                  reverse: true,
                  controller: listScrollController,
              );
            }
        },),
    );
  }

  bool isLastMsgLeft(int index) {
    if((index>0 && listMessage!=null && listMessage[index-1]["idFrom"]==id) || index ==0){
      return true;
    }else {
      return false;
    }
  }

  bool isLastMsgRight(int index) {
    if((index>0 && listMessage!=null && listMessage[index-1]["idFrom"]!=id) || index ==0){
      return true;
    }else {
      return false;
    }
  }

  createItem(int index, DocumentSnapshot document) {
    //my messages in Right
    if(document["idFrom"] == id){
      return Row(
        children: [
          document["type"]==0
              ?Container(
            child: Text(
                document["content"],
              style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500),
            ),
            padding: EdgeInsets.fromLTRB(15.0,10.0, 15.0,10.0),
            width: 200.0,
            decoration: BoxDecoration(color: Colors.lightBlueAccent,borderRadius: 
            BorderRadius.circular(8.0)),
            margin: EdgeInsets.only(bottom: isLastMsgRight(index)?20.0:10.0,right:10.0),
          )
              :document["type"]==1
              ?Container(
            child: TextButton(
              child:Material(
                child: CachedNetworkImage(
                  placeholder: (context,url)=>Container(
                   child: CircularProgressIndicator(
                     valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                   ),
                    width: 200.0,
                    height: 200.0,
                    padding: EdgeInsets.all(70),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                  ),
                  errorWidget: (context,url,error)=>Material(
                    child: Image.asset("images/img_not_available.jpeg",width: 200.0,
                      height: 200.0,fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  imageUrl: document["content"],
                  width: 200.0,
                  height: 200.0,fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                clipBehavior: Clip.hardEdge,
              ) ,
              onPressed: (){
                Navigator.push(context,MaterialPageRoute(
                    builder: (context)=>FullPhoto(
                      url:document["content"])
                )
                );
              },
            ),
            margin: EdgeInsets.only(bottom: isLastMsgRight(index)?20.0:10.0,right:10.0),
          )
              :Container(
            child: Image.asset(
              "images/${document['content']}.gif",
              width: 100.0,
              height: 100.0,
              fit: BoxFit.cover,
            ),
            margin: EdgeInsets.only(bottom: isLastMsgRight(index)?20.0:10.0,right:10.0),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );

    }else{
      return Container(
        child: Column(
          children: [
            Row(
              children: [
                isLastMsgLeft(index)
                    ? Material(
                  child: CachedNetworkImage(
                    placeholder: (context,url)=>Container(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                      ),
                      width: 35.0,
                      height: 35.0,
                      padding: EdgeInsets.all(10.0),
                    ),
                    imageUrl: recieverAvatar!,
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                      Radius.circular(18.0)
                  ),
                  clipBehavior: Clip.hardEdge,
                )
                    : Container(
                  width: 35.0,
                ),
                document["type"]==0
                    ?Container(
                  child: Text(
                    document["content"],
                    style: TextStyle(
                        color: Colors.white,fontWeight: FontWeight.w400
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(15.0,10.0, 15.0,10.0),
                  width: 200.0,
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0)),
                  margin: EdgeInsets.only(left: 10.0),
                )
                    :document["type"]==1
                    ?Container(
                  child: TextButton(
                    child:Material(
                      child: CachedNetworkImage(
                        placeholder: (context,url)=>Container(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                          ),
                          width: 200.0,
                          height: 200.0,
                          padding: EdgeInsets.all(70),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          ),
                        ),
                        errorWidget: (context,url,error)=>Material(
                          child: Image.asset("images/img_not_available.jpeg",width: 200.0,
                            height: 200.0,fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                        imageUrl: document["content"],
                        width: 200.0,
                        height: 200.0,fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      clipBehavior: Clip.hardEdge,
                    ) ,
                    onPressed: (){
                      Navigator.push(context,MaterialPageRoute(
                          builder: (context)=>FullPhoto(
                              url:document["content"])
                      )
                      );
                    },
                  ),
                  margin: EdgeInsets.only(left: 10.0),
                )
                    :Container(
                  child: Image.asset(
                    "images/${document['content']}.gif",
                    width: 100.0,
                    height: 100.0,
                    fit: BoxFit.cover,
                  ),
                  margin: EdgeInsets.only(bottom: isLastMsgRight(index)?20.0:10.0,right:10.0),
                ),
              ],
            ),
            isLastMsgLeft(index)
                ? Container(
              child: Text(
                DateFormat("dd MMMM, yyyy - hh:mm:aa").format(
                  DateTime(int.parse(document["timestamp"]))
                ),
                style: TextStyle(color: Colors.grey, fontSize: 12.0, fontStyle: FontStyle.italic),
              ),
              margin: EdgeInsets.only(left: 50.0, top: 50.0, bottom: 5.0),
            )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  createInput(){
    return Container(
      child: Row(
        children: [
          Material(
            child: Container( //image icon
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.image),
                color: Colors.lightBlueAccent,
                onPressed: pickImageFromGallery,
              ),
            ),
            color: Colors.white,
          ),
          Material( // emoji icon
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.face),
                color: Colors.lightBlueAccent,
                onPressed: getSticker,
              ),
            ),
            color: Colors.white,
          ),
          Flexible(
              child: Container(
                child: TextField(
                  style: TextStyle(
                    color: Colors.black, fontSize: 15.0
                  ),
                  controller: textEditingController,
                  decoration: InputDecoration.collapsed(
                      hintText: "write here ... ",
                    hintStyle: TextStyle(color: Colors.grey)
                  ),
                  focusNode: focusNode,
                ),
              )
          ),
          Material( //send message icon
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                color: Colors.grey,
                onPressed: () => onSendMessage(textEditingController.text, 0),
              ),
            ),
            color: Colors.white,
          )
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.5
          ),
        ),
        color: Colors.white,
      ),
    );
  }

  createStickers(){
    return Container(
      child: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => onSendMessage("mimi1",2),
                child: Image.asset(
                  "images/mimi1.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage("mimi2",2),
                child: Image.asset(
                  "images/mimi2.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage("mimi3",2),
                child: Image.asset(
                  "images/mimi3.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => onSendMessage("mimi4",2),
                child: Image.asset(
                  "images/mimi4.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage("mimi5",2),
                child: Image.asset(
                  "images/mimi5.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage("mimi6",2),
                child: Image.asset(
                  "images/mimi6.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => onSendMessage("mimi7",2),
                child: Image.asset(
                  "images/mimi7.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage("mimi8",2),
                child: Image.asset(
                  "images/mimi8.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton(
                onPressed: () => onSendMessage("mimi9",2),
                child: Image.asset(
                  "images/mimi9.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.5
          )
        ),
        color: Colors.white
      ),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isDisplaySticker = !isDisplaySticker!;
    });
  }


  Future<XFile?> pickImageFromGallery() async {
    final imagePicker = ImagePicker();
    final XFile? imageFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if(imageFile != null){
      isLoading = true;
    }
    uploadImageFile();
  }

  Future uploadImageFile() async{
    String fileName = DateTime.now().toString();
    final storage = FirebaseStorage.instance;
    final reference = storage.ref().child('chat images/').child(fileName);

    final uploadTask = reference.putFile(imageFile!);
    try {
      final storageTaskSnapshot = await uploadTask.whenComplete(() => null);
      // Handle successful upload
      final downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl!, 1);
      });
    } on FirebaseException catch (error) {
      // Handle upload error
      print('Error uploading file: ${error.message}');
    } catch (error) {
      setState(() {
        isLoading = true;
      });
      Fluttertoast.showToast(msg: '$error');
    }
  }

  void onSendMessage(String contentMsg, int type) {
    //type = 0 its msg
    //type = 1 its image
    //type = 2 its sticker

    if(contentMsg != ""){
      textEditingController.clear();

      var docRef = FirebaseFirestore.instance.collection("messages").
      doc(chatId).collection(chatId!).doc(DateTime.now().toIso8601String());

      FirebaseFirestore.instance.runTransaction((transaction) async {
        await transaction.set(docRef, {
          "idFrom" : id,
          "idTo": recieverId,
          "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "content": contentMsg,
          "type": type
        });
      });

      listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    }else {
      Fluttertoast.showToast(msg: "empty message!");
    }
  }
}

