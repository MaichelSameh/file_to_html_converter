import 'dart:convert';

import 'package:http/http.dart' as http;

enum AvailableExtensions { doc, docs, ppt, pptx, txt }

class Converter {
  Future<void> convert(AvailableExtensions extension, String filePath) async {
    try {
      http.Response res = await http.post(
          Uri.https(
            "v2.convertapi.com",
            "/convert/${extension.name}/to/htm",
            {
              "Secret": "KbYoRiVe8L5Kq3ot",
              "StoreFile": false,
            },
          ),
          body: {
            "File": filePath,
          });
      if (res.statusCode == 200) {
        print(json.decode(res.body));
      }
    } catch (error) {
      print("Error occurred while converting you file. \nerror: $error");
    }
  }
}
