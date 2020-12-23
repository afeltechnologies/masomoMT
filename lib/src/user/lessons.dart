import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';

class Lessons extends StatefulWidget {
  final zoeziList;
  final weekNumber;
  Lessons(this.zoeziList, this.weekNumber);

  @override
  _LessonsState createState() => _LessonsState(zoeziList, weekNumber);
}

class _LessonsState extends State<Lessons> {
  final zoeziList;
  final weekNumber;
  var weekLessons = [];
  bool isFetching = true;
  bool hasSuccess = false;
  FlutterTts flutterTts;
  bool isCorrect = false;
  bool isStarted = false;

  bool isAvailable = false;
  bool isListening = false;
  String resultText = "";
  final SpeechToText speech = SpeechToText();
  double minSoundLevel = 5000;
  double maxSoundLevel = -5000;
  double level = 0.5;

  AudioCache audioCache = AudioCache();
  AudioPlayer advancedPlayer = AudioPlayer();

  @override
  initState() {
    super.initState();
    _lessons();
    _initSpeechRecogniser();
  }

  Future<void> _initSpeechRecogniser() async {
    bool hasSpeech = await speech.initialize(
        onStatus: statusListener, onError: errorListener);
    if (!mounted) return;

    setState(() {
      isAvailable = hasSpeech;
    });
  }

  void statusListener(String status) {
    if (status == 'listening') {
      setState(() => isListening = true);
    } else {
      setState(() => isListening = false);
    }
  }

  void resultListener(SpeechRecognitionResult result) {
    String string = weekLessons[lessonIndex]['english'];
    if (result.finalResult) {
      setState(() {
        resultText = result.recognizedWords
            .toLowerCase()
            .replaceAll(RegExp(r"[^\s\w]"), '');
        isListening = false;
        isCorrect = resultText
            .contains(string.toLowerCase().replaceAll(RegExp(r"[^\s\w]"), ''));
        isStarted = true;
      });
      print("$resultText : ${weekLessons[lessonIndex]['english']}");
      print("IsCorrect: $isCorrect");
    }
  }

  void startListening() {
    setState(() {
      isListening = true;
      isCorrect = isStarted = false;
      resultText = "";
    });

    speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: 5),
      cancelOnError: true,
      onDevice: true,
      partialResults: true,
      listenMode: ListenMode.confirmation,
      localeId: "en-US",
      onSoundLevelChange: soundLevelLister,
    );
  }

  void stopListening() {
    speech.stop();
    setState(() => isListening = false);
  }

  void soundLevelLister(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = min(maxSoundLevel, level);
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError errorNotification) {
    print(errorNotification);
  }

  void dispose() {
    super.dispose();
    flutterTts?.stop();
    speech?.stop();
  }

  Future<void> _lessons() async {
    try {
      var resposnse = await http.post(
        'https://masomo.co.tz/mazoezi/cat1',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
          <String, String>{'week': '$weekNumber', 'zoezi': zoeziList},
        ),
      );
      setState(() {
        var less = jsonDecode(resposnse.body);
        weekLessons = less;
        if (weekLessons != null && weekLessons.length > 0) {
          _speak(weekLessons[0]['english']);
          isFetching = false;
          hasSuccess = true;
        } else {
          isFetching = false;
          hasSuccess = false;
        }
      });
    } catch (e) {
      print(e);
      setState(() {
        isFetching = false;
        hasSuccess = false;
      });
    }
  }

  int lessonIndex = 0;
  nextLesson() {
    if (weekLessons.length > lessonIndex + 1) {
      setState(() {
        lessonIndex++;
        isCorrect = isStarted = false;
        resultText = "";
        _speak(weekLessons[lessonIndex]['english']);
      });
    }
  }

  _LessonsState(this.zoeziList, this.weekNumber);
  @override
  Widget build(BuildContext context) {
    var data;
    if (!isFetching && weekLessons.isNotEmpty) {
      data = weekLessons[lessonIndex];
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        leading: Row(
          children: [
            IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.black,
                ),
                onPressed: () {
                  speech?.stop();
                  Navigator.of(context).pop();
                })
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: isFetching
            ? Center(
                child: CircularProgressIndicator(),
              )
            : !hasSuccess
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text('Hakuna masomo kwa sasa!'),
                      )
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '${data['instruction']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB3590A),
                            ),
                          ),
                          SizedBox(height: 5),
                          Container(
                            height: 140.0,
                            decoration: new BoxDecoration(
                              image: new DecorationImage(
                                image:
                                    new AssetImage('assets/resource/bg1.jpg'),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(height: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        child: Text(
                                          '${data['english']}',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      Container(
                                        child: Text(
                                          '${data['kiswahili']}',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Spacer(
                                    flex: 10,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.volume_up,
                                      size: 40,
                                      color: const Color(0xFFB3590A),
                                    ),
                                    onPressed: () => _speak(data['english']),
                                  ),
                                  Spacer(flex: 2),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Divider(
                              color: Colors.black, height: 10, thickness: 5),
                          SizedBox(height: 10),
                          data['example'].length > 0
                              ? Text(
                                  'Mifano:-',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(''),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            children: [
                              Text(
                                '${data['example']}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.volume_up,
                                  size: 20,
                                ),
                                onPressed: () {
                                  var spk = data['example'];
                                  if (spk != null && spk.length > 0) {
                                    _speak(spk);
                                  }
                                },
                              )
                            ],
                          ),
                          Text(
                            '${data['example_answer']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AvatarGlow(
                                animate: isListening,
                                endRadius: 75.0,
                                glowColor: const Color(0xFFB3590A),
                                duration: const Duration(milliseconds: 1000),
                                repeatPauseDuration:
                                    const Duration(milliseconds: 100),
                                repeat: true,
                                child: FloatingActionButton(
                                  child: Icon(
                                    Icons.mic,
                                    color:
                                        isListening ? Colors.red : Colors.white,
                                  ),
                                  onPressed: () {
                                    if (isAvailable && !isListening) {
                                      startListening();
                                    } else {
                                      stopListening();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: Container(
                              alignment: Alignment.center,
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Text(resultText),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent[100],
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 12.0,
                              ),
                            ),
                          ),
                          started(),
                          isCorrect
                              ? FlatButton(
                                  height: 50.0,
                                  color: const Color(0xFFB3590A),
                                  onPressed: () {
                                    nextLesson();
                                  },
                                  child: Text(
                                    'Endelea',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  minWidth: double.maxFinite,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                        color: const Color(0xFFB3590A),
                                        width: 1,
                                        style: BorderStyle.solid),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                )
                              : Text(''),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget started() {
    var list = [
      'Safi sana',
      'Amaizing, you killed it!',
      'Uko vizuri mno',
      'Hongera, mambo mazuri!',
      'Umefanya vizuri sana',
      'Excellent',
      'Very nice',
      'Wonderful'
    ];
    final _random = new Random();
    var element = list[_random.nextInt(list.length)];
    if (isStarted == true) {
      if (isCorrect) {
        playAudio();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$element',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                    ),
                  ),
                  Text(' '),
                  Icon(
                    Icons.check_box,
                    color: Colors.green,
                    size: 40,
                  ),
                ],
              ),
            ),
          ],
        );
      } else {
        playAudioFail();
        return Center(
          child: Text(
            'Jaribu Tena',
            style: TextStyle(
              fontSize: 25,
              color: Colors.redAccent,
            ),
          ),
        );
      }
    } else {
      return Text('');
    }
  }

  Future _speak(String _newVoiceText) async {
    flutterTts = new FlutterTts();
    if (_newVoiceText != null) {
      if (_newVoiceText.isNotEmpty) {
        await flutterTts.setVolume(1);
        await flutterTts.setSpeechRate(0.5);
        await flutterTts.setPitch(0.9);
        await flutterTts.setLanguage('en-US');
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(_newVoiceText);
      }
    }
  }

  Future<void> playAudio() async {
    await audioCache.play('resource/preview.mp3');
  }

  Future<void> playAudioFail() async {
    await audioCache.play('resource/windows_10_notify.mp3');
  }
}
