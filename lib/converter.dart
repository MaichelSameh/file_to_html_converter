import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

enum AvailableExtensions { doc, docs, ppt, pptx, txt }

class Converter {
  Future<File> convert(AvailableExtensions extension, String filePath) async {
    try {
      TaskSnapshot ff = await FirebaseStorage.instance
          .ref('''temp/${filePath.split("/").last}''').putFile(File(filePath));
      String fileUtl = await ff.ref.getDownloadURL();
      Uri link = Uri.https("v2.convertapi.com", "/convert/doc/to/html", {
        "File": fileUtl,
        "Secret": "KbYoRiVe8L5Kq3ot",
      });
      var res = await http.post(link);
      await FirebaseStorage.instance.refFromURL(fileUtl).delete();
      Map<String, dynamic> data = json.decode(res.body);
      if (res.statusCode == 200) {
        File htmlFile = await File(filePath)
            .writeAsBytes(base64.decode(data["Files"].first["FileData"]));
        return htmlFile;
      } else {
        throw data["Message"];
      }
    } catch (error) {
      print("Error occurred while converting your file. \nerror: $error");
      rethrow;
    }
  }
}
