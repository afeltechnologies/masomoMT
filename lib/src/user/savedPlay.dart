import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './savedVideos.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen/screen.dart';

import 'package:video_player/video_player.dart';

class ChewieListItem extends StatefulWidget {
  final list;
  final videoWeek;
  final user;

  const ChewieListItem(this.list, this.videoWeek, this.user);

  // This will contain the URL/asset path which we want to play
  @override
  _ChewieListItemState createState() =>
      new _ChewieListItemState(this.list, this.videoWeek, this.user);
}

class _ChewieListItemState extends State<ChewieListItem> {
  ChewieController _chewieController2;
  VideoPlayerController _controller;
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

  @override
  void initState() {
    currentList = list;
    super.initState();
    _changeVideo(currentList);
  }

  void dispose() {
    _controller.dispose();
    Screen.keepOn(false);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
            AspectRatio(
              aspectRatio: _controller.value.initialized
                  ? _controller.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  ClosedCaption(text: _controller.value.caption.text),
                  _PlayPauseOverlay(controller: _controller),
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'UKUBWA: ' + currentList['size'],
                    textAlign: TextAlign.center,
                  ),
                  OutlineButton(
                    borderSide:
                        BorderSide(color: Color(0xFFB3590A), width: 2.0),
                    splashColor: const Color(0xFFB3590A),
                    onPressed: () {
                      deleteConfirm(currentList['url']);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      child: Text('Futa Video'),
                    ),
                  )
                ],
              ),
            ),
            Text(currentList['title']),
            SizedBox(
              height: 10,
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
                  color: (currentList['url'] == videoWeek[index]['url'])
                      ? Colors.red[100]
                      : Colors.white,
                  child: ListTile(
                    leading: Image.asset(
                      "assets/resource/play.png",
                      width: 50,
                      height: 40,
                      fit: BoxFit.fill,
                    ),
                    title: Text(videoWeek[index]['title']),
                    subtitle: Text(videoWeek[index]['size']),
                    trailing: Icon(Icons.play_arrow_outlined),
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    onTap: () {
                      // Change video controller and play
                      if (currentList['url'] != videoWeek[index]['url']) {
                        _changeVideo(widget.videoWeek[index]);
                      }
                    },
                  ),
                );
              },
            ),
          );
  }

  void _changeVideo(dataVideo) async {
    if (_controller != null) {
      if (_controller.value.isPlaying) {
        _controller.pause();
      }
    }
    var fullPath = dataVideo['url'];
    _controller = VideoPlayerController.file(fullPath);
    setState(() {});

    _controller.addListener(() {
      setState(() {
        currentList = dataVideo;
      });
    });
    _controller.setLooping(false);
    _controller.initialize().then((value) => null);
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

class _PlayPauseOverlay extends StatelessWidget {
  const _PlayPauseOverlay({Key key, this.controller}) : super(key: key);

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: Duration(milliseconds: 50),
          reverseDuration: Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? controller.value.isBuffering
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFB3590A)),
                      ),
                    )
                  : SizedBox.shrink()
              : Container(
                  color: Colors.grey.withOpacity(0.6),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 100.0,
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
      ],
    );
  }
}
