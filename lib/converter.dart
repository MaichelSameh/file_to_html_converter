import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

enum AvailableExtensions { doc, docx, ppt, pptx, txt, pdf }

class Converter {
  Future<List<String>> convert(
      AvailableExtensions extension, String filePath) async {
    try {
      String cloudConvertToken = "";
      String fileName = filePath.split("/").last;
      TaskSnapshot task = await FirebaseStorage.instance
          .ref("temp/$fileName")
          .putFile(File(filePath));
      String fileLink = await task.ref.getDownloadURL();
      Uri link = Uri.parse("https://api.cloudconvert.com/v2/jobs");
      Map<String, dynamic> headerParameters = {};
      switch (extension) {
        case AvailableExtensions.doc:
          headerParameters = {
            "engine": "office",
          };
          break;
        case AvailableExtensions.docx:
          headerParameters = {
            "engine": "office",
          };
          break;
        case AvailableExtensions.ppt:
          headerParameters = {
            "engine": "libreoffice",
            "embed_images": false,
          };
          break;
        case AvailableExtensions.pptx:
          headerParameters = {
            "engine": "libreoffice",
            "embed_images": false,
          };
          break;
        case AvailableExtensions.txt:
          headerParameters = {
            "engine": "libreoffice",
            "embed_images": false,
          };
          break;
        case AvailableExtensions.pdf:
          headerParameters = {
            "outline": false,
            "zoom": 1.5,
            "embed_css": true,
            "embed_javascript": true,
            "embed_images": true,
            "embed_fonts": true,
            "split_pages": true,
            "bg_format": "png",
            "engine": "pdf2htmlex",
          };
          break;
      }
      http.Response res = await http.post(
        link,
        headers: {
          "Content-Type": "application/json",
          // "Accept": "application/json",
          "Authorization": "Bearer $cloudConvertToken",
          // "Connection": "keep-alive",
          // "Accept-Encoding": "gzip, deflate, br",
        },
        body: json.encode({
          "tasks": {
            "file": {
              "operation": "import/url",
              "url": fileLink,
              "filename": fileName,
            },
            "task-1": {
              "operation": "convert",
              "input_format": extension.name,
              "output_format": "html",
              "input": ["file"],
              ...headerParameters
            }
          },
          "export-1": {
            "operation": "export/url",
            "input": ["task-1"]
          },
          "tag": "Converter",
        }),
      );
      await FirebaseStorage.instance.refFromURL(fileLink).delete();
      Map<String, dynamic> resData = json.decode(res.body);
      print(resData);
      print(res.statusCode);
      if (res.statusCode == 200 || res.statusCode == 201) {
        link = Uri.parse(
            (resData["data"]["tasks"] as List<dynamic>).last["links"]["self"]);
        resData = await getEcportedFile(link, cloudConvertToken);
        print(resData);
        if (resData["data"]["result"] != null) {
          String fileUrl = (resData["data"]["result"]["files"] as List<dynamic>)
                  .first["url"] ??
              "";
          print(fileUrl);
        }
      }
      return [" "];
    } catch (error) {
      // ignore: avoid_print
      print("Error occurred while converting your file. \nerror: $error");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEcportedFile(
    Uri link,
    String cloudConvertToken,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    http.Response res = await http.get(
      link,
      headers: {
        "Content-Type": "application/json",
        // "Accept": "application/json",
        "Authorization": "Bearer $cloudConvertToken",
      },
    );
    Map<String, dynamic> resData = json.decode(res.body);
    if (resData["data"]["status"] == "waiting" ||
        resData["data"]["status"] == "processing") {
      return await getEcportedFile(link, cloudConvertToken);
    }
    return resData;
  }
}
