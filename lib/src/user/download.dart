import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class Download {
  static getFile(url) async {
    var filename = url.split("/");
    String name = filename[filename.length - 1];

    Dio dio = new Dio();
    Directory dir = await getApplicationDocumentsDirectory();
    String path = dir.path;
    await dio.download(url, path + name);
  }
}
