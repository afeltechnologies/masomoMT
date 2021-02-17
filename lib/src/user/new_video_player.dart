import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ext_video_player/ext_video_player.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_downloader/flutter_downloader.dart';

class NewVideoPlayer extends StatefulWidget {
  final user;
  final week;
  final list;
  final videoWeek;
  NewVideoPlayer(this.user, this.list, this.week, this.videoWeek);

  @override
  _NewVideoPlayerState createState() => _NewVideoPlayerState();
}

class _NewVideoPlayerState extends State<NewVideoPlayer> {
  VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB3590A),
        title: Text('Week ${widget.week}'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            _controller = null;
            Navigator.of(context).pop();
          },
        ),
      ),
      // body: ListView(
      //   children: [
      //     // Text('USER = ${widget.user}'),
      //     // Divider(),
      //     Text('VIDEOWEEK = ${widget.videoWeek}'),
      //     Divider(),
      //     Text('LIST = ${widget.list}'),
      //     // Divider(),
      //     // Text('WEEK = ${widget.week}'),
      //   ],
      // ),
      body: _YoutubeVideo(
        user: widget.user,
        videoWeek: widget.videoWeek,
        list: widget.list,
        week: widget.week,
      ),
    );
  }
}

class _YoutubeVideo extends StatefulWidget {
  final user;
  final week;
  final list;
  final videoWeek;
  _YoutubeVideo({
    @required this.user,
    @required this.list,
    @required this.week,
    @required this.videoWeek,
  });

  @override
  _YoutubeVideoState createState() => _YoutubeVideoState();
}

class _YoutubeVideoState extends State<_YoutubeVideo> {
  VideoPlayerController _controller;
  var currentList;
  bool isDownloading = false;
  bool notSaved = true;
  File downloadedFile;

  void _changeVideo(dataVideo) async {
    if (_controller != null) {
      if (_controller.value.isPlaying) {
        _controller.pause();
      }
    }

    Directory appDocDirectory = await getApplicationSupportDirectory();
    var path = appDocDirectory.path +
        Platform.pathSeparator +
        '.saved' +
        Platform.pathSeparator;
    var filen = dataVideo['url'].split('/');
    var file = filen[filen.length - 1];
    String fullPath = path + file;

    bool value = File(fullPath).existsSync();
    if (value) {
      _controller = VideoPlayerController.file(File(fullPath));
      setState(() {
        notSaved = false;
      });
    } else {
      _controller = VideoPlayerController.network(
        '${dataVideo['url']}',
      );
      setState(() {
        notSaved = true;
      });
    }

    _controller.addListener(() {
      setState(() {
        currentList = dataVideo;
      });
    });
    _controller.setLooping(false);
    _controller.initialize().then((value) => null);
  }

  fileExists(filename) async {
    Directory appDocDirectory = await getApplicationSupportDirectory();
    var path = appDocDirectory.path + Platform.pathSeparator + '.saved';

    var filen = filename.split('/');
    var file = filen[filen.length - 1];
    String fullPath = path + file;
    try {
      await File(fullPath).exists().then((value) {
        if (value) {
          setState(() {
            downloadedFile = File(fullPath);
            notSaved = true;
          });
          return true;
        } else {
          return null;
        }
      });
    } catch (e) {}
  }

  ReceivePort _port = ReceivePort();
  var _downloadTaskId;
  //
  // void _changeVideo(dataVideo) async {
  //   if (_controller.value.isPlaying) {
  //     _controller.pause();
  //   }
  //   _controller = null;
  //
  //   Directory appDocDirectory = await getApplicationSupportDirectory();
  //   var path = appDocDirectory.path + Platform.pathSeparator + '.saved';
  //
  //   var filen = dataVideo['url'].split('/');
  //   var file = filen[filen.length - 1];
  //   String fullPath = path + file;
  //
  //   await File(fullPath).exists().then((value) {
  //     if (value) {
  //       _controller = VideoPlayerController.file(downloadedFile);
  //     } else {
  //       _controller = VideoPlayerController.network(
  //         '${dataVideo['url']}',
  //       );
  //     }
  //   });
  //
  //   _controller.addListener(() {
  //     setState(() {
  //       currentList = dataVideo;
  //     });
  //   });
  //   _controller.setLooping(false);
  //   _controller.initialize().then((value) => _controller.play());
  // }

  @override
  void initState() {
    super.initState();
    _changeVideo(widget.list);
    // _controller = VideoPlayerController.network(
    //   '${widget.list['url']}',
    // );
    // _controller.addListener(() {
    //   setState(() {
    //     currentList = widget.list;
    //   });
    // });
    // _controller.setLooping(true);
    // _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    // _unbindBackgroundIsolate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        //
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'UKUBWA: ' + currentList['size'],
                textAlign: TextAlign.center,
              ),
              notSaved
                  ? RaisedButton(
                      color: Color(0xFFB3590A),
                      onPressed: () {
                        if (!isDownloading && notSaved) {
                          saveVideo(currentList);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        child: isDownloading ? Text("Inasave") : Text('Save'),
                      ),
                    )
                  : OutlineButton(
                      borderSide:
                          BorderSide(color: Color(0xFFB3590A), width: 2.0),
                      splashColor: const Color(0xFFB3590A),
                      onPressed: () {},
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        child: Text('Imehifadhiwa'),
                      ),
                    )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${currentList['title']}',
              style: Theme.of(context).textTheme.subtitle2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
          child: Divider(
            height: 2,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: ListView.builder(
            reverse: false,
            itemCount: widget.videoWeek.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, index) {
              String titleVideo = widget.videoWeek[index]['title'];
              String videoSize = widget.videoWeek[index]['size'];
              var url = widget.videoWeek[index]['url'];

              return Card(
                color:
                    currentList['url'] == url ? Colors.red[100] : Colors.white,
                child: ListTile(
                  leading: Image.asset(
                    "assets/resource/play.png",
                    width: 50,
                    height: 40,
                    fit: BoxFit.fill,
                  ),
                  title: Text(titleVideo),
                  subtitle: Text(videoSize),
                  trailing: Icon(Icons.play_arrow_outlined),
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  onTap: () {
                    // Change video controller and play
                    if (currentList['url'] != url) {
                      _changeVideo(widget.videoWeek[index]);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void saveVideo(var data) async {
    setState(() {
      isDownloading = true;
    });
    Directory appDocDirectory = await getApplicationSupportDirectory();
    final _path = appDocDirectory.path + Platform.pathSeparator + '.saved/';

    final savedDir = Directory(_path);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
    await FlutterDownloader.enqueue(
      url: data['url'],
      headers: {"auth": "masomoMT_Downloader"},
      savedDir: savedDir.path,
      showNotification: true,
      openFileFromNotification: false,
    ).then((value) => setState(() {
          isDownloading = false;
        }));
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('masomoMT' + id);
    send.send([id, status, progress]);
  }

  Future<Null> _loadTask(_downloadTaskId) async {
    print('downloading taskss hereeee');
    final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: 'SELECT * FROM task');
    print(tasks);
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
