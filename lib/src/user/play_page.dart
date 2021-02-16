import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';
import 'dart:io' as io;

class PlayPage extends StatefulWidget {
  final user;
  final week;
  final list;
  final videoWeek;
  PlayPage(this.user, this.list, this.week, this.videoWeek);

  @override
  _PlayPageState createState() =>
      new _PlayPageState(user, list, week, videoWeek);
}

class _PlayPageState extends State<PlayPage> {
  var week;
  var user;
  final list;
  final videoWeek;
  _PlayPageState(this.user, this.list, this.week, this.videoWeek);

  bool downloading = false;
  double progress = 0;
  String downloadMessage = "Inapakua...0.0";
  bool isDownloaded = false;
  bool videoDownloaded = false;
  File downloadedFile;
  bool isLoading = false;
  bool isVideoLoading = true;
  bool theVideoCheckedIfSaved = false;
  var currentList;
  CancelToken cancelToken;

  String titleVideo;
  String sizeVideo;

  fileExists(filename) async {
    Directory appDocDirectory = await getApplicationSupportDirectory();
    var path = appDocDirectory.path + '/.saved/';

    var filen = filename.split('/');
    var file = filen[filen.length - 1];
    String fullPath = path + file;
    try {
      await io.File(fullPath).exists().then((value) {
        if (value) {
          setState(() {
            downloadedFile = File(fullPath);
            videoDownloaded = true;
          });
          return downloadedFile;
        } else {
          return null;
        }
      });
    } catch (e) {}
  }

  var videoController = VideoPlayerController;

  downloadingFile(url) async {
    setState(() {
      downloading = true;
    });

    Directory appDocDirectory = await getApplicationSupportDirectory();
    var path = appDocDirectory.path + '/.saved/';

    var filename = url.split("/");
    String name = filename[filename.length - 1];

    String fullPath = path + name;
    Dio dio = new Dio();

    cancelToken = CancelToken();
    await dio.download(
      url,
      fullPath,
      options: Options(headers: {HttpHeaders.acceptEncodingHeader: "*"}),
      onReceiveProgress: (rcv, total) {
        setState(() {
          progress = double.parse((rcv / total * 100).toStringAsFixed(2));
          downloadMessage = "Inapakua... ${progress.toStringAsFixed(2)} %";
        });
        if (progress >= 100) {
          setState(() {
            isDownloaded = true;
            downloading = false;
            videoDownloaded = true;
          });
        }
      },
      deleteOnError: true,
      cancelToken: cancelToken,
    ).then((_) {});
  }

  cancelDownload(context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text('Bado haijamaliza kupakua video.'),
          actions: <Widget>[
            FlatButton(
              child: Text('Endelea'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text('Sitisha'),
              onPressed: () {
                if (!cancelToken.isCancelled) {
                  cancelToken.cancel();
                }
                setState(() {
                  downloading = false;
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  VideoPlayerController _videoPlayerController1;
  ChewieController _chewieController;

  var _disposed = false;

  @override
  initState() {
    setState(() {
      titleVideo = list['title'];
      sizeVideo = list['size'];
      currentList = list;
      isVideoLoading = true;
    });
    Screen.keepOn(true);
    fileExists(list['url']);
    if (videoDownloaded) {
      _videoPlayerController1 = new VideoPlayerController.file(downloadedFile)
        ..initialize().then((_) {
          setState(() {});
        });
    } else {
      _videoPlayerController1 = new VideoPlayerController.network(list['url'])
        ..initialize().then((_) {
          setState(() {});
        });
    }
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1,
      aspectRatio: _videoPlayerController1.value.aspectRatio,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      allowedScreenSleep: false,
      autoInitialize: true,
      showControlsOnInitialize: true,
    );
    _videoPlayerController1
      ..setVolume(1.0)
      ..initialize()
      ..play();

    setState(() {
      isVideoLoading = false;
    });
    if (_videoPlayerController1.value.isPlaying) {
      setState(() {});
    }
    super.initState();
  }

  @override
  void dispose() {
    _disposed = true;
    Screen.keepOn(false);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _videoPlayerController1?.pause(); // mute instantly
    _videoPlayerController1?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: new Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFB3590A),
          title: Text('Week $week : $titleVideo'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (_videoPlayerController1 != null && !downloading) {
                _videoPlayerController1.pause();
                _chewieController = null;
                _videoPlayerController1 = null;
              } else {
                cancelDownload(context);
              }
              if (downloading) {
                cancelDownload(context);
              } else {
                Navigator.of(context).pop();
              }
              _videoPlayerController1?.pause();
              _chewieController = null;
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 1.0),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              if (_chewieController == null || _videoPlayerController1 == null)
                Container(
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: 16.0 / 9.0,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_videoPlayerController1.value.hasError)
                // Text('An error occurred ${_videoPlayerController1.value.errorDescription}')
                Container(
                  // color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: 16.0 / 9.0,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_outlined),
                          Text('Mtandao umekosekana'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                _videoPlayerController1.value.initialized
                    ? Text('success initialize')
                    // Container(
                    //         color: Colors.black,
                    //         child: AspectRatio(
                    //           aspectRatio:
                    //               _videoPlayerController1.value.aspectRatio,
                    //           child: FittedBox(
                    //             fit: BoxFit.fill,
                    //             child: Chewie(
                    //               controller: _chewieController,
                    //             ),
                    //           ),
                    //         ),
                    //       )
                    : Text('failed to initialize here'),
              // Container(
              //         color: Colors.black,
              //         child: AspectRatio(
              //           aspectRatio: 16.0 / 9.0,
              //           child: Center(
              //             child: CircularProgressIndicator(),
              //           ),
              //         ),
              //       ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 8,
                    child: downloading
                        ? Column(
                            children: [
                              Text(
                                'Ina save... $progress%',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text('Subiri imalize kusave'),
                            ],
                          )
                        : Text(
                            ' UKUBWA: ' + sizeVideo,
                            textAlign: TextAlign.center,
                          ),
                  ),
                  Expanded(
                    flex: 4,
                    child: _videoPlayerController1.value.initialized &&
                            !downloading
                        ? FlatButton(
                            color: videoDownloaded
                                ? Colors.red
                                : const Color(0xFFB3590A),
                            padding: EdgeInsets.all(0),
                            onPressed: () {
                              if (!videoDownloaded) {
                                downloadingFile(currentList['url']);
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 5.0),
                              child: videoDownloaded
                                  ? Text("Saved")
                                  : Text("Save"),
                            ),
                          )
                        : Text('Subiri...'),
                  ),
                ],
              ),
              // SizedBox(
              //   height: 10,
              // ),
              Divider(color: Colors.black),
              Text(
                'Video nyingine za wiki hii',
                textAlign: TextAlign.left,
              ),
              SizedBox(
                height: 10,
              ),
              // Expanded(
              //   child: ListView.builder(
              //     reverse: false,
              //     itemCount: widget.videoWeek.length,
              //     shrinkWrap: true,
              //     itemBuilder: (BuildContext context, index) {
              //       String titleVideo = widget.videoWeek[index]['title'];
              //       String videoSize = widget.videoWeek[index]['size'];
              //       var url = widget.videoWeek[index]['url'];
              //
              //       return Card(
              //         color: currentList['url'] == url
              //             ? Colors.red[100]
              //             : Colors.white,
              //         child: InkWell(
              //           onTap: () {
              //             // Change video controller and play
              //             if (currentList['url'] != url) {
              //               _initializeAndPlay(
              //                   url, videoSize, titleVideo, videoWeek[index]);
              //             }
              //           },
              //           child: Container(
              //             padding: EdgeInsets.all(4),
              //             child: Row(
              //               mainAxisSize: MainAxisSize.max,
              //               crossAxisAlignment: CrossAxisAlignment.center,
              //               children: <Widget>[
              //                 Padding(
              //                   padding: EdgeInsets.only(right: 8),
              //                   child: Image.asset(
              //                     "assets/resource/play.png",
              //                     width: 70,
              //                     height: 50,
              //                     fit: BoxFit.fill,
              //                   ),
              //                 ),
              //                 Expanded(
              //                   child: Column(
              //                       mainAxisSize: MainAxisSize.min,
              //                       mainAxisAlignment: MainAxisAlignment.center,
              //                       crossAxisAlignment: CrossAxisAlignment.start,
              //                       children: <Widget>[
              //                         Text(titleVideo,
              //                             style: TextStyle(
              //                                 fontSize: 12,
              //                                 fontWeight: FontWeight.bold)),
              //                         Padding(
              //                           child: Text(videoSize,
              //                               style: TextStyle(
              //                                   color: Colors.grey[500])),
              //                           padding: EdgeInsets.only(top: 3),
              //                         )
              //                       ]),
              //                 ),
              //                 Padding(
              //                     padding: EdgeInsets.all(8.0),
              //                     child: Icon(Icons.play_arrow)),
              //               ],
              //             ),
              //           ),
              //         ),
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  void _initializeAndPlay(url, size, title, data) async {
    _chewieController = null;

    setState(
      () {
        titleVideo = title;
        sizeVideo = size;
        currentList = data;
        isVideoLoading = true;
      },
    );

    VideoPlayerController controller;
    File file = await fileExists(url);
    if (file != null) {
      controller = VideoPlayerController.file(file);
    } else {
      controller = VideoPlayerController.network(url);
    }

    final old = _videoPlayerController1;
    _videoPlayerController1 = controller;
    if (old != null) {
      old.removeListener(_onControllerUpdated);
      await old.pause();
    }

    _videoPlayerController1
      ..initialize().then((_) {
        _videoPlayerController1.play();
        old?.dispose();
        _videoPlayerController1.addListener(_onControllerUpdated);

        _chewieController = ChewieController(
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

        setState(() {
          isVideoLoading = false;
        });
      });
  }

  Future<void> _onControllerUpdated() async {
    if (_disposed) return;
    final controller = _videoPlayerController1;
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
