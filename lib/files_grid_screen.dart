import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FilesGridScreen extends StatefulWidget {
  final List<File> pages;
  const FilesGridScreen({
    Key? key,
    required this.pages,
  }) : super(key: key);

  @override
  State<FilesGridScreen> createState() => _FilesGridScreenState();
}

class _FilesGridScreenState extends State<FilesGridScreen> {
  List<int> indexes = <int>[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        actions: <Widget>[
          InkWell(
            child: Row(),
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 5 / 6,
          crossAxisSpacing: 30,
        ),
        itemCount: widget.pages.length,
        itemBuilder: (ctx, index) => ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: AlignmentDirectional.topStart,
            children: [
              WebView(
                onWebViewCreated: (controller) {
                  controller.loadFile(widget.pages[index].absolute.path);
                },
              ),
              InkWell(
                onTap: () {
                  if (indexes.contains(index)) {
                    indexes.removeWhere((element) => element == index);
                  } else {
                    indexes.add(index);
                  }
                  setState(() {});
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Color.fromRGBO(0, 0, 0, 0.5),
                        Color.fromRGBO(0, 0, 0, 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Container(
                height: 20,
                width: 20,
                margin: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.5)),
                ),
                padding: const EdgeInsets.all(3),
                child: indexes.contains(index)
                    ? Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
