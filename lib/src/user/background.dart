import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
abstract class Background extends StatelessWidget {
  var url;

  Background(url);

  fetchData(http.Client client) async {
    final response = await client.get(url);

    // Use the compute function to run parsePhotos in a separate isolate.
    return compute(parseData, response.body);
  }

// A function that converts a response body into a List<Photo>.
  parseData(String responseBody) {
    final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

    return parsed.map<List>(json);
  }
}
