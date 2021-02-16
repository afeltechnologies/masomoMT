// import 'dart:isolate';
// import 'dart:ui';
// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class DownloadFile extends StatefulWidget {
//   final url;
//   DownloadFile(this.url);
//
//   @override
//   _DownloadFileState createState() => _DownloadFileState(this.url);
// }
//
// class _DownloadFileState extends State<DownloadFile> {
//   final _documents;
//   _DownloadFileState(this._documents);
//   bool debug = true;
//
//   List<_TaskInfo> _tasks;
//   List<_ItemHolder> _items;
//   bool _isLoading;
//   bool _permissionReady;
//   String _localPath;
//   ReceivePort _port = ReceivePort();
//
//   @override
//   void initState() {
//     super.initState();
//     _bindBackgroundIsolate();
//
//     FlutterDownloader.registerCallback(downloadCallback);
//
//     _isLoading = true;
//     _permissionReady = true;
//     _prepare();
//   }
//
//   @override
//   void dispose() {
//     _unbindBackgroundIsolate();
//     super.dispose();
//   }
//
//   void _bindBackgroundIsolate() {
//     bool isSuccess = IsolateNameServer.registerPortWithName(
//         _port.sendPort, 'downloader_send_port');
//     if (!isSuccess) {
//       _unbindBackgroundIsolate();
//       _bindBackgroundIsolate();
//       return;
//     }
//     _port.listen((dynamic data) {
//       if (debug) {
//         print('UI Isolate Callback: $data');
//       }
//       String id = data[0];
//       DownloadTaskStatus status = data[1];
//       int progress = data[2];
//
//       if (_tasks != null && _tasks.isNotEmpty) {
//         final task = _tasks.firstWhere((task) => task.taskId == id);
//         if (task != null) {
//           setState(() {
//             task.status = status;
//             task.progress = progress;
//           });
//         }
//       }
//     });
//   }
//
//   void _unbindBackgroundIsolate() {
//     IsolateNameServer.removePortNameMapping('downloader_send_port');
//   }
//
//   static void downloadCallback(
//       String id, DownloadTaskStatus status, int progress) {
//     print(
//         'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
//
//     final SendPort send =
//         IsolateNameServer.lookupPortByName('downloader_send_port');
//     send.send([id, status, progress]);
//   }
//
//   final platform = Platform();
//
//   @override
//   Widget build(BuildContext context) {
//     return new Scaffold(
//       appBar: new AppBar(
//         title: new Text('Download'),
//       ),
//       body: Builder(
//           builder: (context) => _isLoading
//               ? new Center(
//                   child: new CircularProgressIndicator(),
//                 )
//               : _permissionReady
//                   ? _buildDownloadList()
//                   : _buildNoPermissionWarning()),
//     );
//   }
//
//   Widget _buildDownloadList() => Container(
//         child: ListView(
//           padding: const EdgeInsets.symmetric(vertical: 16.0),
//           children: _items
//               .map((item) => item.task == null
//                   ? _buildListSection(item.name)
//                   : DownloadItem(
//                       data: item,
//                       onItemClick: (task) {
//                         _openDownloadedFile(task).then((success) {
//                           if (!success) {
//                             Scaffold.of(context).showSnackBar(SnackBar(
//                                 content: Text('Cannot open this file')));
//                           }
//                         });
//                       },
//                       onAtionClick: (task) {
//                         if (task.status == DownloadTaskStatus.undefined) {
//                           _requestDownload(task);
//                         } else if (task.status == DownloadTaskStatus.running) {
//                           _pauseDownload(task);
//                         } else if (task.status == DownloadTaskStatus.paused) {
//                           _resumeDownload(task);
//                         } else if (task.status == DownloadTaskStatus.complete) {
//                           _delete(task);
//                         } else if (task.status == DownloadTaskStatus.failed) {
//                           _retryDownload(task);
//                         }
//                       },
//                     ))
//               .toList(),
//         ),
//       );
//
//   Widget _buildListSection(String title) => Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//         child: Text(
//           title,
//           style: TextStyle(
//               fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18.0),
//         ),
//       );
//
//   Widget _buildNoPermissionWarning() => Container(
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                 child: Text(
//                   'Please grant accessing storage permission to continue -_-',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.blueGrey, fontSize: 18.0),
//                 ),
//               ),
//               SizedBox(
//                 height: 32.0,
//               ),
//               FlatButton(
//                   onPressed: () {
//                     _checkPermission().then((hasGranted) {
//                       setState(() {
//                         _permissionReady = hasGranted;
//                       });
//                     });
//                   },
//                   child: Text(
//                     'Retry',
//                     style: TextStyle(
//                         color: Colors.blue,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20.0),
//                   ))
//             ],
//           ),
//         ),
//       );
//
//   void _requestDownload(_TaskInfo task) async {
//     task.taskId = await FlutterDownloader.enqueue(
//         url: task.link,
//         headers: {"auth": "test_for_sql_encoding"},
//         savedDir: _localPath,
//         showNotification: true,
//         openFileFromNotification: true);
//   }
//
//   void _cancelDownload(_TaskInfo task) async {
//     await FlutterDownloader.cancel(taskId: task.taskId);
//   }
//
//   void _pauseDownload(_TaskInfo task) async {
//     await FlutterDownloader.pause(taskId: task.taskId);
//   }
//
//   void _resumeDownload(_TaskInfo task) async {
//     String newTaskId = await FlutterDownloader.resume(taskId: task.taskId);
//     task.taskId = newTaskId;
//   }
//
//   void _retryDownload(_TaskInfo task) async {
//     String newTaskId = await FlutterDownloader.retry(taskId: task.taskId);
//     task.taskId = newTaskId;
//   }
//
//   Future<bool> _openDownloadedFile(_TaskInfo task) {
//     return FlutterDownloader.open(taskId: task.taskId);
//   }
//
//   void _delete(_TaskInfo task) async {
//     await FlutterDownloader.remove(
//         taskId: task.taskId, shouldDeleteContent: true);
//     await _prepare();
//     setState(() {});
//   }
//
//   Future<bool> _checkPermission() async {
//     return true;
//   }
//
//   Future<Null> _prepare() async {
//     final tasks = await FlutterDownloader.loadTasks();
//
//     int count = 0;
//     _tasks = [];
//     _items = [];
//
//     _tasks.addAll(_documents.map((document) =>
//         _TaskInfo(name: document['title'], link: document['url'])));
//
//     _items.add(_ItemHolder(name: 'Saved Videos'));
//     for (int i = count; i < _tasks.length; i++) {
//       _items.add(_ItemHolder(name: _tasks[i].name, task: _tasks[i]));
//       count++;
//     }
//
//     tasks?.forEach((task) {
//       for (_TaskInfo info in _tasks) {
//         if (info.link == task.url) {
//           info.taskId = task.taskId;
//           info.status = task.status;
//           info.progress = task.progress;
//         }
//       }
//     });
//
//     _permissionReady = await _checkPermission();
//
//     _localPath = (await _findLocalPath()) + Platform.pathSeparator + 'Download';
//
//     final savedDir = Directory(_localPath);
//     bool hasExisted = await savedDir.exists();
//     if (!hasExisted) {
//       savedDir.create();
//     }
//
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   Future<String> _findLocalPath() async {
//     Directory appDocDirectory = await getApplicationSupportDirectory();
//     var path = appDocDirectory.path + '/.saved/';
//     return path;
//   }
// }
//
// class DownloadItem extends StatelessWidget {
//   final _ItemHolder data;
//   final Function(_TaskInfo) onItemClick;
//   final Function(_TaskInfo) onAtionClick;
//
//   DownloadItem({this.data, this.onItemClick, this.onAtionClick});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.only(left: 16.0, right: 8.0),
//       child: InkWell(
//         onTap: data.task.status == DownloadTaskStatus.complete
//             ? () {
//                 onItemClick(data.task);
//               }
//             : null,
//         child: Stack(
//           children: <Widget>[
//             Container(
//               width: double.infinity,
//               height: 64.0,
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: <Widget>[
//                   Expanded(
//                     child: Text(
//                       data.name,
//                       maxLines: 1,
//                       softWrap: true,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.only(left: 8.0),
//                     child: _buildActionForTask(data.task),
//                   ),
//                 ],
//               ),
//             ),
//             data.task.status == DownloadTaskStatus.running ||
//                     data.task.status == DownloadTaskStatus.paused
//                 ? Positioned(
//                     left: 0.0,
//                     right: 0.0,
//                     bottom: 0.0,
//                     child: LinearProgressIndicator(
//                       value: data.task.progress / 100,
//                     ),
//                   )
//                 : Container()
//           ].where((child) => child != null).toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionForTask(_TaskInfo task) {
//     if (task.status == DownloadTaskStatus.undefined) {
//       return RawMaterialButton(
//         onPressed: () {
//           onAtionClick(task);
//         },
//         child: Icon(Icons.file_download),
//         shape: CircleBorder(),
//         constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
//       );
//     } else if (task.status == DownloadTaskStatus.running) {
//       return RawMaterialButton(
//         onPressed: () {
//           onAtionClick(task);
//         },
//         child: Icon(
//           Icons.pause,
//           color: Colors.red,
//         ),
//         shape: CircleBorder(),
//         constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
//       );
//     } else if (task.status == DownloadTaskStatus.paused) {
//       return RawMaterialButton(
//         onPressed: () {
//           onAtionClick(task);
//         },
//         child: Icon(
//           Icons.play_arrow,
//           color: Colors.green,
//         ),
//         shape: CircleBorder(),
//         constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
//       );
//     } else if (task.status == DownloadTaskStatus.complete) {
//       return Row(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           Text(
//             'Ready',
//             style: TextStyle(color: Colors.green),
//           ),
//           RawMaterialButton(
//             onPressed: () {
//               onAtionClick(task);
//             },
//             child: Icon(
//               Icons.delete_forever,
//               color: Colors.red,
//             ),
//             shape: CircleBorder(),
//             constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
//           )
//         ],
//       );
//     } else if (task.status == DownloadTaskStatus.canceled) {
//       return Text('Canceled', style: TextStyle(color: Colors.red));
//     } else if (task.status == DownloadTaskStatus.failed) {
//       return Row(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           Text('Failed', style: TextStyle(color: Colors.red)),
//           RawMaterialButton(
//             onPressed: () {
//               onAtionClick(task);
//             },
//             child: Icon(
//               Icons.refresh,
//               color: Colors.green,
//             ),
//             shape: CircleBorder(),
//             constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
//           )
//         ],
//       );
//     } else if (task.status == DownloadTaskStatus.enqueued) {
//       return Text('Pending', style: TextStyle(color: Colors.orange));
//     } else {
//       return null;
//     }
//   }
// }
//
// class _TaskInfo {
//   final String name;
//   final String link;
//
//   String taskId;
//   int progress = 0;
//   DownloadTaskStatus status = DownloadTaskStatus.undefined;
//
//   _TaskInfo({this.name, this.link});
// }
//
// class _ItemHolder {
//   final String name;
//   final _TaskInfo task;
//
//   _ItemHolder({this.name, this.task});
// }

import 'dart:isolate';
import 'dart:ui';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

const debug = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: debug);

  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return new MaterialApp(
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(
        platform: platform,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget with WidgetsBindingObserver {
  final TargetPlatform platform;

  MyHomePage({Key key, this.platform}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _documents = [
    {
      'name': 'Learning Android Studio',
      'link':
          'http://barbra-coco.dyndns.org/student/learning_android_studio.pdf'
    },
  ];

  List<_TaskInfo> _tasks;
  List<_ItemHolder> _items;
  bool _isLoading;
  bool _permissionReady;
  String _localPath;
  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();

    _bindBackgroundIsolate();

    FlutterDownloader.registerCallback(downloadCallback);

    _isLoading = true;
    _permissionReady = false;

    _prepare();
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      if (debug) {
        print('UI Isolate Callback: $data');
      }
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      if (_tasks != null && _tasks.isNotEmpty) {
        final task = _tasks.firstWhere((task) => task.taskId == id);
        if (task != null) {
          setState(() {
            task.status = status;
            task.progress = progress;
          });
        }
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    if (debug) {
      print(
          'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    }
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Downloader'),
      ),
      body: Builder(
          builder: (context) => _isLoading
              ? new Center(
                  child: new CircularProgressIndicator(),
                )
              : _permissionReady
                  ? _buildDownloadList()
                  : _buildNoPermissionWarning()),
    );
  }

  Widget _buildDownloadList() => Container(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: _items
              .map((item) => item.task == null
                  ? _buildListSection(item.name)
                  : DownloadItem(
                      data: item,
                      onItemClick: (task) {
                        _openDownloadedFile(task).then((success) {
                          if (!success) {
                            Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text('Cannot open this file')));
                          }
                        });
                      },
                      onAtionClick: (task) {
                        _requestDownload(task);

                        // if (task.status == DownloadTaskStatus.undefined) {
                        //   _requestDownload(task);
                        // }
                        // else if (task.status == DownloadTaskStatus.running) {
                        //   _pauseDownload(task);
                        // } else if (task.status == DownloadTaskStatus.paused) {
                        //   _resumeDownload(task);
                        // } else if (task.status == DownloadTaskStatus.complete) {
                        //   _delete(task);
                        // } else if (task.status == DownloadTaskStatus.failed) {
                        //   _retryDownload(task);
                        // }
                      },
                    ))
              .toList(),
        ),
      );

  Widget _buildListSection(String title) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18.0),
        ),
      );

  Widget _buildNoPermissionWarning() => Container(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Please grant accessing storage permission to continue -_-',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey, fontSize: 18.0),
                ),
              ),
              SizedBox(
                height: 32.0,
              ),
              FlatButton(
                  onPressed: () {
                    _checkPermission().then((hasGranted) {
                      setState(() {
                        _permissionReady = hasGranted;
                      });
                    });
                  },
                  child: Text(
                    'Retry',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0),
                  ))
            ],
          ),
        ),
      );

  void _requestDownload(_TaskInfo task) async {
    task.taskId = await FlutterDownloader.enqueue(
        url: task.link,
        headers: {"auth": "test_for_sql_encoding"},
        savedDir: _localPath,
        showNotification: true,
        openFileFromNotification: true);
  }

  void _cancelDownload(_TaskInfo task) async {
    await FlutterDownloader.cancel(taskId: task.taskId);
  }

  void _pauseDownload(_TaskInfo task) async {
    await FlutterDownloader.pause(taskId: task.taskId);
  }

  void _resumeDownload(_TaskInfo task) async {
    String newTaskId = await FlutterDownloader.resume(taskId: task.taskId);
    task.taskId = newTaskId;
  }

  void _retryDownload(_TaskInfo task) async {
    String newTaskId = await FlutterDownloader.retry(taskId: task.taskId);
    task.taskId = newTaskId;
  }

  Future<bool> _openDownloadedFile(_TaskInfo task) {
    return FlutterDownloader.open(taskId: task.taskId);
  }

  void _delete(_TaskInfo task) async {
    await FlutterDownloader.remove(
        taskId: task.taskId, shouldDeleteContent: true);
    await _prepare();
    setState(() {});
  }

  Future<bool> _checkPermission() async {
    if (widget.platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<Null> _prepare() async {
    final tasks = await FlutterDownloader.loadTasks();

    int count = 0;
    _tasks = [];
    _items = [];

    _tasks.addAll(_documents.map((document) =>
        _TaskInfo(name: document['name'], link: document['link'])));

    _items.add(_ItemHolder(name: 'Documents'));
    for (int i = count; i < _tasks.length; i++) {
      _items.add(_ItemHolder(name: _tasks[i].name, task: _tasks[i]));
      count++;
    }

    tasks?.forEach((task) {
      for (_TaskInfo info in _tasks) {
        if (info.link == task.url) {
          info.taskId = task.taskId;
          info.status = task.status;
          info.progress = task.progress;
        }
      }
    });

    _permissionReady = await _checkPermission();

    _localPath = (await _findLocalPath()) + Platform.pathSeparator + 'Download';

    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _findLocalPath() async {
    final directory = widget.platform == TargetPlatform.android
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path;
  }
}

class DownloadItem extends StatelessWidget {
  final _ItemHolder data;
  final Function(_TaskInfo) onItemClick;
  final Function(_TaskInfo) onAtionClick;

  DownloadItem({this.data, this.onItemClick, this.onAtionClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 8.0),
      child: InkWell(
        onTap: data.task.status == DownloadTaskStatus.complete
            ? () {
                onItemClick(data.task);
              }
            : null,
        child: Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 64.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      data.name,
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildActionForTask(data.task),
                  ),
                ],
              ),
            ),
            data.task.status == DownloadTaskStatus.running ||
                    data.task.status == DownloadTaskStatus.paused
                ? Positioned(
                    left: 0.0,
                    right: 0.0,
                    bottom: 0.0,
                    child: LinearProgressIndicator(
                      value: data.task.progress / 100,
                    ),
                  )
                : Container()
          ].where((child) => child != null).toList(),
        ),
      ),
    );
  }

  Widget _buildActionForTask(_TaskInfo task) {
    if (task.status == DownloadTaskStatus.undefined) {
      return RawMaterialButton(
        onPressed: () {
          onAtionClick(task);
        },
        child: Icon(Icons.add),
        shape: CircleBorder(),
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
      );
    } else if (task.status == DownloadTaskStatus.running) {
      return RawMaterialButton(
        onPressed: () {
          onAtionClick(task);
        },
        child: Icon(
          Icons.pause,
          color: Colors.red,
        ),
        shape: CircleBorder(),
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
      );
    } else if (task.status == DownloadTaskStatus.paused) {
      return RawMaterialButton(
        onPressed: () {
          onAtionClick(task);
        },
        child: Icon(
          Icons.play_arrow,
          color: Colors.green,
        ),
        shape: CircleBorder(),
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
      );
    } else if (task.status == DownloadTaskStatus.complete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Ready',
            style: TextStyle(color: Colors.green),
          ),
          RawMaterialButton(
            onPressed: () {
              onAtionClick(task);
            },
            child: Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
            shape: CircleBorder(),
            constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
          )
        ],
      );
    } else if (task.status == DownloadTaskStatus.canceled) {
      return Text('Canceled', style: TextStyle(color: Colors.red));
    } else if (task.status == DownloadTaskStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${task.status}', style: TextStyle(color: Colors.red)),
          RawMaterialButton(
            onPressed: () {
              onAtionClick(task);
            },
            child: Icon(
              Icons.refresh,
              color: Colors.green,
            ),
            shape: CircleBorder(),
            constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
          )
        ],
      );
    } else if (task.status == DownloadTaskStatus.enqueued) {
      return Text('Pending', style: TextStyle(color: Colors.orange));
    } else {
      return null;
    }
  }
}

class _TaskInfo {
  final String name;
  final String link;

  String taskId;
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;

  _TaskInfo({this.name, this.link});
}

class _ItemHolder {
  final String name;
  final _TaskInfo task;

  _ItemHolder({this.name, this.task});
}
