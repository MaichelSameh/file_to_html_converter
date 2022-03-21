import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;

import 'api_keys.dart';
import 'splits.dart';

///this enum is contiening all the extensions to be picked from the device
enum AvailableExtensions { doc, docx, ppt, pptx, txt, pdf }

///this enum is contiening all the extensions that the api can convert to the picked file
enum ConvertToExtensions { html }

class Converter {
  ///this function is responsalble to convert any selected file by the extension
  ///to one of [ConvertToExtensions]
  Future<List<File>> convert(
    AvailableExtensions extension,
    String filePath,
  ) async {
    //the extension that the file will be converted to
    ConvertToExtensions convertTo = ConvertToExtensions.html;
    try {
      //the result that will be returned from the function
      List<File> result = [];
      //the file name without the path
      String fileName = filePath.split("/").last;
      //in this command we are uploading the given file to the firebase cloud
      TaskSnapshot task = await FirebaseStorage.instance
          .ref("temp/$fileName")
          .putFile(File(filePath));
      //getting the file download link
      String fileLink = await task.ref.getDownloadURL();
      //the cloud convert url
      Uri link = Uri.parse("https://api.sandbox.cloudconvert.com/v2/jobs");
      //this function will contains all the required parameters for the url
      //without the required engine
      Map<String, dynamic> headerParameters = {};
      //the engine that will be used to convert th file
      Map<String, dynamic> engine = {};
      //in this switch statment we are generating the header by extension
      //as each extension can have a diffrent parameters or diffrent engin
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
            //how may pages to be returned in the html file
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
      //sending the task request
      http.Response res = await http.post(
        link,
        headers: {
          //declaring the request body encoding
          "Content-Type": "application/json",
          //declaring the response body encoding
          "Accept": "application/json",
          //the authorization key
          "Authorization": "Bearer ${ApiKeys.sand_bo_key}",
        },
        body: json.encode({
          "tasks": {
            //this task will import the file to cloud convert
            "import-1": {
              "operation": "import/url",
              "url": fileLink,
              "filename": fileName
            },
            //the conversion operation
            "task-1": {
              "operation": "convert",
              "input_format": extension.name,
              "output_format": convertTo.name,
              ...engine,
              "input": ["import-1"],
              ...headerParameters,
            },
            //the export operation
            //generating a link to download the file
            "export-1": {
              "operation": "export/url",
              "input": ["task-1"]
            }
          },
          "tag": "jobbuilder"
        }),
      );
      //deleting the file from the cloud
      await FirebaseStorage.instance.refFromURL(fileLink).delete();
      //decoding the response body
      Map<String, dynamic> resData = json.decode(res.body);
      //checking if the request had completed successfully
      if (res.statusCode == 200 || res.statusCode == 201) {
        //getting the export task link
        link = Uri.parse(
            (resData["data"]["tasks"] as List<dynamic>).last["links"]["self"]);
        //getting the export task response
        resData = await getExportedFile(link, ApiKeys.sand_bo_key);
        //checking if the export operation has reult(completed successflly)
        if (resData["data"]["result"] != null) {
          //getting the download link from the response
          String fileUrl = (resData["data"]["result"]["files"] as List<dynamic>)
                  .firstWhere((element) =>
                      (element["filename"] as String?)
                          ?.endsWith(convertTo.name) ==
                      true)["url"] ??
              "";
          //changing the file extension
          fileName = fileName.substring(0, fileName.lastIndexOf(".")) +
              "." +
              convertTo.name;
          //downloading the exported file
          File file = await downloadFile(fileUrl, fileName);
          //splitting the downloaded file into pages
          result = await Splits().splitIntoPages(file.path);
          //returning the exported file pages
          return result;
        }
      }
      return result;
    } catch (error) {
      // ignore: avoid_print
      print("Error occurred while converting your file. \nerror: $error");
      rethrow;
    }
  }

  //this function can also be a recursive function
  ///getting the export operation response
  Future<Map<String, dynamic>> getExportedFile(
    //the download uri
    Uri link,
    //the cloud convert auth token
    String cloudConvertToken,
  ) async {
    //waiting for some time so the caonversion operation is completed
    await Future.delayed(const Duration(milliseconds: 300));
    //sending a check request to get the export response
    http.Response res = await http.get(
      link,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $cloudConvertToken",
      },
    );
    //decodeing the response body
    Map<String, dynamic> resData = json.decode(res.body);
    //checking if the process isn't finished yet
    if (resData["data"]["status"] == "waiting" ||
        resData["data"]["status"] == "processing") {
      //recalling the same function to send a new request
      return await getExportedFile(link, cloudConvertToken);
    }
    return resData;
  }

  ///this function will doenload the files in a temporary directory from
  ///the given [fileLink] and will store it with the name [fileName]
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
