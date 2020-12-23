import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogflow/dialogflow_v2.dart';
import 'package:intl/intl.dart';

class ChatBot extends StatefulWidget {
  _ChatBot createState() => _ChatBot();
}

class _ChatBot extends State<ChatBot> {
  List<ChatBox> messagesList = [];
  TextEditingController sendTextController = TextEditingController();

  Future<void> getMessageFromAPI(String message) async {
    String textRes;
    AuthGoogle authGoogle =
        await AuthGoogle(fileJson: 'assets/credential.json').build();
    Dialogflow dialogflow =
        Dialogflow(authGoogle: authGoogle, language: Language.english);

    AIResponse aiResponse = await dialogflow.detectIntent(message);
    textRes = aiResponse.getMessage();
    if (textRes == null) {
      textRes = "No response";
    }
    print(textRes);
    setState(() {
      messagesList.insert(
        0,
        ChatBox(
          message: textRes,
          type: false,
          context: context,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFB3590A),
        title: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Colors.black,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Mr. Masomo',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    return Stack(
      overflow: Overflow.visible,
      children: <Widget>[
        Positioned.fill(
          child: Image(
            image: Image.asset('assets/images/masomo.png').image,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: ListView.builder(
                  reverse: true,
                  itemCount: messagesList.length,
                  itemBuilder: (context, i) {
                    return messagesList[i];
                  },
                ),
              ),
              buildTextArea(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTextArea(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: <Widget>[
          CupertinoButton(
            onPressed: () {
              // Optional Button
            },
            pressedOpacity: 0.4,
            child: Icon(Icons.add, color: Colors.black),
          ),
          Expanded(
            child: TextField(
              controller: sendTextController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                contentPadding: const EdgeInsets.all(0),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          CupertinoButton(
            onPressed: () {
              if (sendTextController.text.trim().isNotEmpty) {
                setState(() {
                  messagesList.insert(
                    0,
                    ChatBox(
                      message: sendTextController.text,
                      type: true,
                      context: context,
                    ),
                  );
                });
                getMessageFromAPI(sendTextController.text);
                sendTextController.text = '';
              }
            },
            pressedOpacity: 0.4,
            child: Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

class ChatBox extends StatelessWidget {
  final String message;
  final bool type;
  final BuildContext context;
  const ChatBox({Key key, this.message, this.type, this.context})
      : super(key: key);

  static DateTime now = DateTime.now();
  static String time = DateFormat('H:mm').format(now);

  @override
  Widget build(BuildContext context) {
    return type ? sendBox(this.message) : receiveBox(this.message);
  }

  Widget sendBox(String message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(5),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: Color(0xff2980b9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
              Text(
                time,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget receiveBox(String message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(5),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: Color(0xff34495e),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
              Text(
                time,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
