import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'converter.dart';
import 'files_grid_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<File>? files;
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : files == null
                ? Center(
                    child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: AvailableExtensions.values
                                      .map<String>(
                                          (extension) => extension.name)
                                      .toList());
                          if (result != null) {
                            await Converter().convert(
                              AvailableExtensions.values.firstWhere((element) =>
                                  element.name ==
                                  result.files.first.path!.split(".").last),
                              result.files.first.path!,
                            );
                            isLoading = false;
                            setState(() {});
                          }
                        },
                        child: const Text("Select file")))
                : FilesGridScreen(pages: files!));
  }
}
