import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;

enum AvailableExtensions { doc, docs, docx, ppt, pptx, txt, pdf }

class Converter {
  Future<List<File>> convert(
      AvailableExtensions extension, String filePath) async {
    if (extension == AvailableExtensions.txt) {
      return [File(filePath)];
    }
    try {
      TaskSnapshot ff = await FirebaseStorage.instance
          .ref('''temp/${filePath.split("/").last}''').putFile(File(filePath));
      String fileUrl = await ff.ref.getDownloadURL();
      print(fileUrl);
      print(filePath);
      Uri link = Uri.https(
          "v2.convertapi.com",
          "/convert/${extension.name}/to/${extension == AvailableExtensions.pdf ? "txt" : "html"}",
          {
            "File": fileUrl,
            "Secret": "KbYoRiVe8L5Kq3ot",
          });
      var res = await http.post(link);
      await FirebaseStorage.instance.refFromURL(fileUrl).delete();
      Map<String, dynamic> data = json.decode(res.body);
      if (res.statusCode == 200) {
        List<dynamic> files = data["Files"];
        print(files.length);
        print(filePath);
        print(filePath);
        List<File> htmlFiles = <File>[];
        for (int i = 0; i < files.length; i++) {
          List<String> list = filePath.split("/");
          list.last = list.last.substring(0, list.last.lastIndexOf(".")) +
              "$i." +
              (extension == AvailableExtensions.pdf ? "txt" : "html");
          Directory dir =
              await path_provider.getApplicationDocumentsDirectory();
          filePath = dir.path + list.last;
          print(files[i]);
          htmlFiles.add(await File(filePath)
              .writeAsBytes(base64.decode(files[i]["FileData"])));
        }
        return htmlFiles;
      } else {
        print(res.statusCode);
        throw data["Message"];
      }
    } catch (error) {
      // ignore: avoid_print
      print("Error occurred while converting your file. \nerror: $error");
      rethrow;
    }
  }
}
