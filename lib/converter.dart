import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;

enum AvailableExtensions { doc, docx, ppt, pptx, txt, pdf }

enum ConvertToExtensions { html }

class Converter {
  Future<File> convert(
    AvailableExtensions extension,
    String filePath,
  ) async {
    ConvertToExtensions convertTo = ConvertToExtensions.html;
    try {
      File result;
      String cloudConvertToken = "";
      String fileName = filePath.split("/").last;
      TaskSnapshot task = await FirebaseStorage.instance
          .ref("temp/$fileName")
          .putFile(File(filePath));
      String fileLink = await task.ref.getDownloadURL();
      Uri link = Uri.parse("https://api.sandbox.cloudconvert.com/v2/jobs");
      Map<String, dynamic> headerParameters = {};
      Map<String, dynamic> engine = {};
      switch (extension) {
        case AvailableExtensions.doc:
          headerParameters = {
            "engine": "libreoffice",
          };
          headerParameters = {"embed_images": true};
          break;
        case AvailableExtensions.docx:
          engine = {
            "engine": "libreoffice",
          };
          headerParameters = {"embed_images": true};
          break;
        case AvailableExtensions.ppt:
          engine = {
            "engine": "libreoffice",
          };
          headerParameters = {"embed_images": true};
          break;
        case AvailableExtensions.pptx:
          engine = {
            "engine": "libreoffice",
          };
          headerParameters = {"embed_images": true};
          break;
        case AvailableExtensions.txt:
          engine = {
            "engine": "libreoffice",
          };
          headerParameters = {"embed_images": true};
          break;
        case AvailableExtensions.pdf:
          engine = {
            "engine": "pdf2htmlex",
          };
          headerParameters = {
            "pages": "1",
            "outline": false,
            "zoom": 1.5,
            "embed_css": true,
            "embed_javascript": true,
            "embed_images": true,
            "embed_fonts": true,
            "split_pages": false,
            "bg_format": "png"
          };
          break;
      }
      http.Response res = await http.post(
        link,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $cloudConvertToken",
        },
        body: json.encode({
          "tasks": {
            "import-1": {
              "operation": "import/url",
              "url": fileLink,
              "filename": fileName
            },
            "task-1": {
              "operation": "convert",
              "input_format": extension.name,
              "output_format": convertTo.name,
              ...engine,
              "input": ["import-1"],
              ...headerParameters,
            },
            "export-1": {
              "operation": "export/url",
              "input": ["task-1"]
            }
          },
          "tag": "jobbuilder"
        }),
      );
      Map<String, dynamic> resData = json.decode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        link = Uri.parse(
            (resData["data"]["tasks"] as List<dynamic>).last["links"]["self"]);
        resData = await getEcportedFile(link, cloudConvertToken);
        if (resData["data"]["result"] != null) {
          for (var child
              in (resData["data"]["result"]["files"] as List<dynamic>)) {
            print(child);
          }
          String fileUrl = (resData["data"]["result"]["files"] as List<dynamic>)
                  .firstWhere((element) =>
                      (element["filename"] as String?)
                          ?.endsWith(convertTo.name) ==
                      true)["url"] ??
              "";
          await FirebaseStorage.instance.refFromURL(fileLink).delete();
          fileName = fileName.substring(0, fileName.lastIndexOf(".")) +
              "." +
              convertTo.name;
          result = await downloadFile(fileUrl, fileName);
          return result;
        }
      }
      return File("");
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
        "Accept": "application/json",
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

  Future<File> downloadFile(String fileLink, String fileName) async {
    //fetching the image from the internet
    http.Response res = await http.get(Uri.parse(fileLink));
    //getting the app directory to store the image in
    Directory documentDirectory = await path_provider.getTemporaryDirectory();
    //getting the file directory
    final String filePath = documentDirectory.path + "/files";
    //creating the file directory
    await Directory(filePath).create(recursive: true);
    //creating the file
    File file = File(filePath + "/" + fileName);
    //writing the file cointent
    file.writeAsBytesSync(res.bodyBytes);
    return file;
  }
}
