import 'package:flutter/material.dart';
// import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class Translator extends StatefulWidget {
  final userId;
  Translator(this.userId);
  _TranslatorState createState() => _TranslatorState(userId);
}

enum TtsState { playing, stopped, paused, continued }

class _TranslatorState extends State<Translator> {
  final userId;

  final _input1 = TextEditingController();
  final _input2 = TextEditingController();
  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  String text1 = "Kiswahili";
  String text2 = "English";
  String label = "ENG - SWA";
  bool isLoading = false;

  TtsState ttsState = TtsState.stopped;

  _TranslatorState(this.userId);

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;

  get isPaused => ttsState == TtsState.paused;

  get isContinued => ttsState == TtsState.continued;

  @override
  initState() {
    super.initState();
    initTts();
  }

  initTts() {
    flutterTts = new FlutterTts();

    _getLanguages();

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        _getEngines();
      }
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    if (kIsWeb || Platform.isIOS) {
      flutterTts.setPauseHandler(() {
        setState(() {
          print("Paused");
          ttsState = TtsState.paused;
        });
      });

      flutterTts.setContinueHandler(() {
        setState(() {
          print("Continued");
          ttsState = TtsState.continued;
        });
      });
    }

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
    setState(() {
      language = 'en-US';
    });
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);
  }

  Future _getEngines() async {
    var engines = await flutterTts.getEngines;
    if (engines != null) {
      for (dynamic engine in engines) {
        print(engine);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  Future _speak(String _newVoiceText, String language) async {
    flutterTts = new FlutterTts();
    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        await flutterTts.setVolume(volume);
        await flutterTts.setSpeechRate(rate);
        await flutterTts.setPitch(1.0);
        await flutterTts.setLanguage(language);
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(_newVoiceText);
      }
    }
  }

  changeLanguage() {
    if (text1 == 'Kiswahili') {
      setState(() {
        text1 = "English";
        text2 = "Kiswahili";
        label = "ENG - SWA";
      });
    } else {
      setState(() {
        text1 = "Kiswahili";
        text2 = "English";
        label = "SWA - ENG";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.all(5.0),
        height: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text(
              'Tafsiri',
              style: TextStyle(fontSize: 25, color: Colors.black),
            ),
            Text(
              'Andika neno au sentensi kisha bonyeza Tafsiri au nisomee kusikiliza sauti.',
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text('$text1'),
                Spacer(),
                Row(
                  children: [
                    RaisedButton(
                      color: const Color(0xFFB3590A),
                      child: Text(
                        'Nisomee',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        if (_input1.text != null) {
                          if (text1 == 'Kiswahili') {
                            _speak(_input1.text, 'sw');
                            sendTranslate('nisomee', _input1.text);
                          } else {
                            _speak(_input1.text, 'en-US');
                            sendTranslate('nisomee', _input1.text);
                          }
                        }
                      },
                    ),
                    // new IconButton(
                    //   icon: new Icon(Icons.multitrack_audio),
                    //   tooltip: text1 == 'Kiswahili' ? 'Soma' : 'Read',
                    //   onPressed: () {
                    //     if (_input1.text != null) {
                    //       if (text1 == 'Kiswahili') {
                    //         _speak(_input1.text, 'sw');
                    //       } else {
                    //         _speak(_input1.text, 'en-US');
                    //       }
                    //     }
                    //   },
                    // ),
                  ],
                ),
              ],
            ),
            Card(
              color: Colors.white,
              child: TextField(
                controller: _input1,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.greenAccent, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: const Color(0xFFB3590A), width: 2.0),
                    ),
                    hintText: "$text1"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: Row(
                children: <Widget>[
                  FlatButton.icon(
                    onPressed: () => changeLanguage(),
                    icon: Icon(Icons.switch_right),
                    label: Text('$label'),
                    color: Colors.green,
                    textColor: Colors.white,
                  ),
                  Spacer(),
                  FlatButton(
                    child: Text('Tafsiri'),
                    onPressed: () => translating(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: Colors.green,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text('$text2'),
                Spacer(),
                RaisedButton(
                  color: const Color(0xFFB3590A),
                  child: Text(
                    'Nisomee',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    if (_input2.text != null) {
                      if (text2 == 'Kiswahili') {
                        _speak(_input2.text, 'sw');
                        sendTranslate('nisomee', _input2.text);
                      } else {
                        _speak(_input2.text, 'en-US');
                        sendTranslate('nisomee', _input2.text);
                      }
                    }
                  },
                ),
              ],
            ),
            isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Card(
                    color: Colors.white,
                    child: TextField(
                      enabled: true,
                      controller: _input2,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.greenAccent, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color(0xFFB3590A), width: 2.0),
                          ),
                          hintText: "$text2"),
                    ),
                  ),
            Spacer(
              flex: 2,
            ),
          ],
        ),
      ),
    );
  }

  String _parseHtmlString(String htmlString) {
    var text = html.Element.span()..appendHtml(htmlString);
    return text.innerText;
  }

  translating() async {
    setState(() {
      isLoading = true;
    });
    final input = _input1.text;
    var _to;
    if (text1 == 'Kiswahili') {
      _to = 'en';
    } else {
      _to = 'sw';
    }
    var translated = await sendTranslate('tafsiri', input, _to);
    _input2.text = _parseHtmlString(translated);

    setState(() {
      isLoading = false;
    });
  }

  Future<String> sendTranslate(String action, String trans, [to]) async {
    try {
      var resposnse = await http.put(
        'https://masomo.co.tz/translate/index_v3',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'id': userId,
          'action': '$action',
          'text': trans,
          'translation': _input2.text,
          'to': to,
        }),
      );
      return resposnse.body;
    } catch (e) {
      //print(e);
      return null;
    }
  }
}
