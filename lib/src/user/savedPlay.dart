import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './savedVideos.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen/screen.dart';

import 'package:video_player/video_player.dart';

class ChewieListItem extends StatefulWidget {
  final url;
  final videoWeek;
  final user;

  const ChewieListItem(this.url, this.videoWeek, this.user);

  // This will contain the URL/asset path which we want to play
  @override
  _ChewieListItemState createState() =>
      new _ChewieListItemState(this.url, this.videoWeek, this.user);
}

class _ChewieListItemState extends State<ChewieListItem> {
  ChewieController _chewieController2;
  String title, size, week;
  bool changingVideo = false;
  final list;
  final videoWeek;
  final user;

  var _disposed = false;
  String titleVideo;
  String sizeVideo;
  var currentList;
  bool isVideoLoading;
  _ChewieListItemState(this.list, this.videoWeek, this.user);

  VideoPlayerController _videoPlayerController2;

  var currentUrl;
  @override
  void initState() {
    super.initState();
    _videoPlayerController2 = VideoPlayerController.file(list['url']);

    setState(() {
      currentUrl = list['url'];
      title = list['title'];
      size = list['size'];
      week = list['week'];
      currentList = list;
    });
    super.initState();
    Screen.keepOn(true);
    _chewieController2 = ChewieController(
      videoPlayerController: _videoPlayerController2,
      aspectRatio: _videoPlayerController2.value.aspectRatio,
      autoInitialize: true,
      looping: false,
      autoPlay: true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  void dispose() {
    Screen.keepOn(false);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _videoPlayerController2?.pause();
    _videoPlayerController2?.dispose();
    super.dispose();
  }

  TargetPlatform _platform;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playing Saved Video',
      theme: ThemeData.light().copyWith(
        platform: _platform ?? Theme.of(context).platform,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFB3590A),
          title: Text('Saved Videos'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (_videoPlayerController2 != null) {
                _videoPlayerController2.pause();
                _chewieController2 = null;
                _videoPlayerController2 = null;
              }
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            if (_chewieController2 == null || _videoPlayerController2 == null)
              Container(
                color: Colors.black,
                child: AspectRatio(
                  aspectRatio: 16.0 / 9.0,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_videoPlayerController2.value.hasError)
              Container(
                color: Colors.black,
                child: AspectRatio(
                  aspectRatio: 16.0 / 9.0,
                  child: Center(
                    child: Text(_videoPlayerController2.value.errorDescription),
                  ),
                ),
              )
            else
              Container(
                color: Colors.black,
                child: AspectRatio(
                  aspectRatio: _videoPlayerController2.value.aspectRatio,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: Chewie(
                      controller: _chewieController2,
                    ),
                  ),
                ),
              ),
            Text(currentList['title']),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('UKUMBWA: ${currentList['size']}'),
                // FlatButton(
                //   color: Colors.red,
                //   padding: EdgeInsets.all(0),
                //   onPressed: () {
                //     deleteConfirm(currentUrl);
                //   },
                //   child: Text("Delete"),
                // ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Text('Video zingine ulizo save'),
            listVideos(),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget listVideos() {
    return (videoWeek == null || videoWeek.length == 0)
        ? Text('Hakuna video uliyo isave')
        : Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: videoWeek.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, index) {
                return Card(
                  color: currentList['url'] == videoWeek[index]['url']
                      ? Colors.red[100]
                      : Colors.white,
                  child: InkWell(
                    onTap: () {
                      if (currentList['url'] != videoWeek[index]['url']) {
                        _initializeAndPlay(
                          videoWeek[index]['url'],
                          videoWeek[index]['size'],
                          videoWeek[index]['title'],
                          videoWeek[index],
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Image.asset(
                              "assets/resource/play.png",
                              width: 70,
                              height: 50,
                              fit: BoxFit.fill,
                            ),
                          ),
                          Expanded(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    videoWeek[index]['title'],
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Padding(
                                    child: Text(
                                        videoWeek[index]['week'] +
                                            ': Ukubwa ' +
                                            videoWeek[index]['size'],
                                        style:
                                            TextStyle(color: Colors.grey[500])),
                                    padding: EdgeInsets.only(top: 3),
                                  )
                                ]),
                          ),
                          Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.play_arrow)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }

  fileDelete(url) async {
    // Deleting a file
    Directory appDocDirectory = await getApplicationSupportDirectory();
    var path = appDocDirectory.path + '/.saved/';

    var filename = url.path.split("/");
    String name = filename[filename.length - 1];

    final fullPath = path + name;
    try {
      if (await File(fullPath).delete() != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SavedVideos(user),
          ),
        );
      }
    } catch (e) {
      return 0;
    }
  }

  deleteConfirm(url) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(
              'Unataka kufuta somo hili kwenye simu? Hautaweza kuplay bila bando muda mwingine.'),
          actions: <Widget>[
            FlatButton(
              child: Text('Acha'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text('Futa'),
              onPressed: () {
                fileDelete(url);
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _initializeAndPlay(url, size, title, data) async {
    _chewieController2 = null;
    setState(
      () {
        titleVideo = title;
        sizeVideo = size;
        currentList = data;
        isVideoLoading = true;
      },
    );

    VideoPlayerController controller = VideoPlayerController.file(url);

    final old = _videoPlayerController2;
    _videoPlayerController2 = controller;
    if (old != null) {
      old.removeListener(_onControllerUpdated);
      await old.pause();
    }

    _videoPlayerController2
      ..initialize().then((_) {
        _videoPlayerController2.play();
        old?.dispose();

        _videoPlayerController2.addListener(_onControllerUpdated);

        _chewieController2 = ChewieController(
          videoPlayerController: controller,
          aspectRatio: controller.value.aspectRatio,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          allowedScreenSleep: false,
          autoInitialize: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFFB3590A),
            handleColor: Colors.blue,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.lightGreen,
          ),
          placeholder: Container(
            color: Colors.grey,
          ),
        );
      });

    setState(() {
      isVideoLoading = false;
    });
    if (_videoPlayerController2.value.isPlaying) {
      setState(() {});
    }
  }

  Future<void> _onControllerUpdated() async {
    if (_disposed) return;
    final controller = _videoPlayerController2;
    if (controller == null) return;
    if (!controller.value.initialized) return;
    final position = await controller.position;
    final duration = controller.value.duration;
    if (position == null || duration == null) return;

    final playing = controller.value.isPlaying;

    // blocking too many updation
    if (playing) {
      // handle progress indicator
      if (_disposed) return;
      setState(() {});
    }
  }
}
