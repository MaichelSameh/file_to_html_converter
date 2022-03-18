import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

enum AvailableExtensions { doc, docs, ppt, pptx, txt, pdf }

class Converter {
  Future<File> convert(AvailableExtensions extension, String filePath) async {
    try {
      // if (extension == AvailableExtensions.pdf) {
      //   return convertPdf(filePath);
      // }
      TaskSnapshot ff = await FirebaseStorage.instance
          .ref('''temp/${filePath.split("/").last}''').putFile(File(filePath));
      String fileUrl = await ff.ref.getDownloadURL();

      if (extension == AvailableExtensions.pdf) {
        return convertPDF(fileUrl);
      }
      Uri link = Uri.https("v2.convertapi.com", "/convert/doc/to/html", {
        "File": fileUrl,
        "Secret": "KbYoRiVe8L5Kq3ot",
      });
      var res = await http.post(link);
      await FirebaseStorage.instance.refFromURL(fileUrl).delete();
      Map<String, dynamic> data = json.decode(res.body);
      if (res.statusCode == 200) {
        File htmlFile = await File(filePath)
            .writeAsBytes(base64.decode(data["Files"].first["FileData"]));
        return htmlFile;
      } else {
        throw data["Message"];
      }
    } catch (error) {
      // ignore: avoid_print
      print("Error occurred while converting your file. \nerror: $error");
      rethrow;
    }
  }

  Future<File> convertPDF(String fileUrl) async {
    try {
      //d4a3505f70msh6d9910bcb2c588dp101794jsnde8b7a5cb4ba
      Uri link = Uri.http("apilayer-pdflayer-v1.p.rapidapi.com", "/convert", {
        "access_key": '8c6dce4b2dfadf5c1ac1e651cc997932',
        "document_url": fileUrl,
        "document_name": 'pdflayer.pdf',
        "custom_unit": 'px',
        "accept_lang": 'en-US',
        "text_encoding": 'utf-8',
        "page_size": 'A4',
        "orientation": 'portrait',
        "viewport": '1440x900',
        "watermark_opacity": '0',
        "creator": 'pdflayer.com',
        "header_align": 'center',
        "footer_align": 'center',
        "ttl": '2592000',
        "dpi": '96'
      });
      http.Response res = await http.get(link, headers: {
        'x-rapidapi-host': 'apilayer-pdflayer-v1.p.rapidapi.com',
        'x-rapidapi-key': 'd4a3505f70msh6d9910bcb2c588dp101794jsnde8b7a5cb4ba'
      });
      print(res.statusCode);
      print(res.body);

      return File("");
    } catch (error) {
      rethrow;
    }
  }

  Future<File> convertPdf(String filePath) async {
    try {
      Uri link = Uri.https(
        "pdftables.com",
        "/api",
        {"key": "", "format": "html"},
      );
      http.MultipartRequest req = http.MultipartRequest("POST", link)
        ..files.add(await http.MultipartFile.fromPath("file", filePath));
      http.StreamedResponse res = await req.send();
      print(res.statusCode);
      http.Response resData = await http.Response.fromStream(res);
      print(resData.body);
      return File("");
    } catch (error) {
      rethrow;
    }
  }
}
