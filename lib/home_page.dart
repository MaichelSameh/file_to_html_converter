import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> supportedFileFormats = <String>[
    "docx",
    "doc",
    "xlsx",
    "xls",
    "pptx",
    "ppt",
    "pdf",
    "txt",
  ];

  String? filePath = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: filePath == null || filePath?.isEmpty == true
          ? Center(
              child: ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: supportedFileFormats);
                    if (result != null) {
                      filePath = result.files.first.path;
                      setState(() {});
                    }
                  },
                  child: const Text("Select file")))
          : const SizedBox(),
    );
  }
}
