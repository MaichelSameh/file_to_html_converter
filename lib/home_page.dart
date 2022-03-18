import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'converter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? file;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:
            // file == null ?
            Center(
                child: ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                              type: FileType.custom,
                              allowedExtensions: AvailableExtensions.values
                                  .map<String>((extension) => extension.name)
                                  .toList());
                      if (result != null) {
                        file = await Converter().convert(
                          AvailableExtensions.values.firstWhere((element) =>
                              element.name ==
                              result.files.first.path!.split(".").last),
                          result.files.first.path!,
                        );
                        setState(() {});
                      }
                    },
                    child: const Text("Select file")))
        // : WebView(
        //     onWebViewCreated: (controller) {
        //       controller.loadFile(file!.absolute.path);
        //     },
        //   ),
        );
  }
}
