import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;

enum AvailableExtensions { doc, docx, ppt, pptx, txt, pdf }

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
      Uri link = Uri.https(
          "v2.convertapi.com",
          "/convert/${extension.name}/to/${extension == AvailableExtensions.pdf ? "txt" : extension == AvailableExtensions.ppt || extension == AvailableExtensions.pptx ? "pdf" : "html"}",
          {
            "File": fileUrl,
            "Secret": "KbYoRiVe8L5Kq3ot",
          });
      print(link);
      var res = await http.post(link);
      await FirebaseStorage.instance.refFromURL(fileUrl).delete();
      Map<String, dynamic> data = json.decode(res.body);
      if (res.statusCode == 200) {
        List<dynamic> files = data["Files"];
        List<File> htmlFiles = <File>[];
        if (extension == AvailableExtensions.ppt ||
            extension == AvailableExtensions.pptx) {
          htmlFiles.add(
              File(filePath.substring(0, filePath.lastIndexOf(".")) + ".pdf"));
        }
        print(files.length);
        for (int i = 0; i < files.length; i++) {
          if (extension == AvailableExtensions.ppt ||
              extension == AvailableExtensions.pptx) {
            print(base64.decode(files[i]["FileData"]));
            print(utf8.encode(files[i]["FileData"]));
            htmlFiles[0] = await htmlFiles[0].writeAsBytes(
              base64.decode(files[i]["FileData"]),
              mode: FileMode.append,
            );
            print(htmlFiles[0].readAsStringSync());
          } else {
            List<String> list = filePath.split("/");
            list.last = list.last.substring(0, list.last.lastIndexOf(".")) +
                "$i." +
                (extension == AvailableExtensions.pdf ? "txt" : "html");
            Directory dir =
                await path_provider.getApplicationDocumentsDirectory();
            filePath = dir.path + list.last;
            htmlFiles.add(await File(filePath)
                .writeAsBytes(base64.decode(files[i]["FileData"])));
          }
        }
        if (extension == AvailableExtensions.ppt ||
            extension == AvailableExtensions.pptx) {
          await htmlFiles[0].create();
          print(filePath);
          return await convert(AvailableExtensions.pdf, filePath);
        } else {
          return htmlFiles;
        }
      } else {
        throw data["Message"];
      }
    } catch (error) {
      // ignore: avoid_print
      print("Error occurred while converting your file. \nerror: $error");
      rethrow;
    }
  }
}
