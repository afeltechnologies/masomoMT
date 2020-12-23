import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen/screen.dart';

class DownloadVideo extends StatefulWidget {
  final currentList;

  DownloadVideo(this.currentList);

  @override
  _DownloadVideoState createState() => _DownloadVideoState(this.currentList);
}

class _DownloadVideoState extends State<DownloadVideo> {
  final currentList;
  _DownloadVideoState(this.currentList);

  double progress = 0.0;
  String downloadMessage = "Inapakua... ";
  bool downloading = false;
  CancelToken cancelToken;
  bool started = false;
  @override
  void initState() {
    super.initState();
    Screen.keepOn(true);
  }

  createDir() async {
    Directory baseDir = await getApplicationSupportDirectory();
    String dirToBeCreated = ".saved";
    String finalDir = "$baseDir/$dirToBeCreated";
    var dir = Directory(finalDir);
    bool dirExists = await dir.exists();
    if (!dirExists) {
      dir.create();
    }
    return true;
  }

  downloadingFile() async {
    bool directory = await createDir();
    if (directory) {
      cancelToken = CancelToken();

      Directory appDocDirectory = await getApplicationSupportDirectory();
      var path = appDocDirectory.path + '/.saved/';

      var filename = currentList['url'].split("/");
      String name = filename[filename.length - 1];
      String fullPath = path + name;
      Dio dio = new Dio();

      setState(() {
        downloading = true;
        started = true;
      });

      try {
        await dio.download(
          currentList['url'],
          fullPath,
          onReceiveProgress: (rcv, total) {
            setState(() {
              progress = rcv / total * 100;
              downloadMessage = "Inapakua... ${progress.toStringAsFixed(2)} %";
            });
            if (progress >= 100) {
              downloading = false;
              if (Screen.isKeptOn != null) {
                Screen.keepOn(false);
              }
            }
          },
          deleteOnError: true,
          cancelToken: cancelToken,
        );
      } catch (e) {
        setState(() {
          downloadMessage = "Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!started) {
      downloadingFile();
    }
    return new WillPopScope(
      onWillPop: () async => cancelDownload(context),
      child: new Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFB3590A),
          title: Text('Downloading Video'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (!downloading) {
                Navigator.of(context).pop();
              } else {
                cancelDownload(context);
              }
            },
          ),
        ),
        body: Container(
          height: double.maxFinite,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                (cancelToken.isCancelled)
                    ? Text('Imesitiswa')
                    : Column(
                        children: [
                          Text(currentList['title']),
                          Text('Ukubwa:' + currentList['size']),
                        ],
                      ),
                SizedBox(
                  height: 20,
                ),
                Text('$downloadMessage'),
                SizedBox(
                  height: 10,
                ),
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[300],
                  value: (progress / 100),
                  minHeight: 10.0,
                ),
                _back()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _back() {
    if (downloading) {
      return Text('');
    } else {
      return Column(
        children: [
          SizedBox(
            height: 10,
          ),
          FlatButton(
            padding: EdgeInsets.all(8),
            color: const Color(0xFFB3590A),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Back'),
          ),
        ],
      );
    }
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
                  Navigator.of(context, rootNavigator: true).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }
}
