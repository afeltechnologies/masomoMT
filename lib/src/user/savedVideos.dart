import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import './savedPlay.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io' as io;

class SavedVideos extends StatefulWidget {
  final user;
  SavedVideos(this.user);

  @override
  _PlaySavedVideos createState() => _PlaySavedVideos(user);
}

class _PlaySavedVideos extends State<SavedVideos> {
  final user;
  bool downloading = false;
  double progress = 0;
  bool isDownloaded = false;
  bool videoDownloaded = false;
  File downloadedFile;

  var videoController = VideoPlayerController;

  _PlaySavedVideos(this.user);

  TargetPlatform _platform;

  var videoWeek = [];
  var videolist = [];
  bool isFetching = true;

  setVideos() async {
    Directory appDocDirectory = await getApplicationSupportDirectory();
    var path = appDocDirectory.path + '/.saved/';
    videoWeek = io.Directory("$path").listSync(
      followLinks: false,
      recursive: false,
    );
    if (isFetching) {
      var videos = user['videos'];
      for (int i = 0; i < videos.length; i++) {
        int week = i + 1;
        var list = videos[i]['videoWeeks'];
        for (int j = 0; j < list.length; j++) {
          String videoUrl = list[j]['url'];
          for (int k = 0; k < videoWeek.length; k++) {
            var fileUrl = videoUrl.replaceAll(
                'https://dodomastore.co.tz/template/materials/', '');
            String fileFile = videoWeek[k].path.split('/').last;

            if (fileFile == fileUrl) {
              videolist.add({
                'url': videoWeek[k],
                'title': list[j]['title'],
                'size': list[j]['size'],
                'week': 'week $week',
                'urlOriginal': list[j]['url'],
              });
            }
          }
        }
      }
      setState(() {
        isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    setVideos();
    return MaterialApp(
      title: 'Saved Videos',
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
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Chagua video ili kuitazama.',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            listVideos(),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  // static String formatBytes(int bytes, int decimals) {
  //   if (bytes <= 0) return "0 B";
  //   const suffixes = ["B", "KB", "MB", "GB"];
  //   var i = (log(bytes) / log(1024)).floor();
  //   return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) +
  //       ' ' +
  //       suffixes[i];
  // }

  Widget listVideos() {
    return (videolist == null || videolist.length == 0)
        ? Center(child: Text('Hakuna video uliyo isave'))
        : Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: videolist.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, index) {
                return Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChewieListItem(videolist[index], videolist, user),
                        ),
                      );
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
                                    videolist[index]['title'],
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Padding(
                                    child: Text(
                                        videolist[index]['week'] +
                                            ': Ukubwa ' +
                                            videolist[index]['size'],
                                        style:
                                            TextStyle(color: Colors.grey[500])),
                                    padding: EdgeInsets.only(top: 3),
                                  )
                                ]),
                          ),
                          Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_forever,
                                      size: 35,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Futa hii video',
                                    onPressed: () {
                                      deleteConfirm(videolist[index]['url']);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.play_circle_fill,
                                      size: 35,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Analia Video',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChewieListItem(
                                            videolist[index],
                                            videolist,
                                            user,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
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
              onPressed: () async {
                var deleted = await url.delete();
                if (deleted != null) {
                  setState(() {
                    isFetching = true;
                    videolist = [];
                  });
                  setVideos();
                  setState(() {});
                }
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  resumedDownload(videoData) async {
    print(videoData);
    Directory appDocDirectory = await getApplicationSupportDirectory();
    var path = appDocDirectory.path + '/.saved/';

    var filename = videoData.split("/");
    String name = filename[filename.length - 1];

    String fullPath = path + name;
    Dio dio = new Dio();
    String downloadMessage = "";
    Future.wait([
      dio.download(
        videoData,
        fullPath,
        onReceiveProgress: (rcv, total) {
          // var progress = rcv / total * 100;
        },
        deleteOnError: true,
      )
    ]);
    print(downloadMessage);
  }
}

class DownloadFile {
  DownloadFile.fileDownload(url);

  fileDownload(url) async {
    var downloadMessage = [];

    Directory appDocDirectory = await getApplicationSupportDirectory();
    var path = appDocDirectory.path + '/.saved/';

    var filename = url.split("/");
    String name = filename[filename.length - 1];

    String fullPath = path + name;
    Dio dio = new Dio();
    Future.wait([
      dio.download(
        url,
        fullPath,
        onReceiveProgress: (rcv, total) {
          var progress = rcv / total * 100;
          downloadMessage[0] = [
            {
              "text": "Downloading... ${progress.floor()} %",
              "proress": progress,
            }
          ];
        },
        deleteOnError: true,
      )
    ]);
  }
}
