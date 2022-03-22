import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ViewScreen extends StatefulWidget {
  final List<File> pages;
  const ViewScreen({
    Key? key,
    required this.pages,
  }) : super(key: key);

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  final PageController pageController = PageController();
  int currentPage = 0;
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
      body: Stack(
        children: <Widget>[
          PageView.builder(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            itemBuilder: (ctx, index) => WebView(
              onWebViewCreated: (controller) {
                controller.loadFile(widget.pages[index].absolute.path);
              },
            ),
            itemCount: widget.pages.length,
          ),
          Column(
            children: <Widget>[
              Flexible(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Visibility(
                        visible: currentPage < widget.pages.length - 1,
                        child: InkWell(
                          onTap: () {
                            pageController.animateToPage(currentPage + 1,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                            setState(() {
                              ++currentPage;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius:
                                  const BorderRadiusDirectional.horizontal(
                                      start: Radius.circular(50)),
                            ),
                            child: const Icon(Icons.arrow_back_ios,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: currentPage > 0,
                        child: InkWell(
                          onTap: () {
                            pageController.animateToPage(currentPage - 1,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                            setState(() {
                              --currentPage;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius:
                                  const BorderRadiusDirectional.horizontal(
                                      end: Radius.circular(50)),
                            ),
                            child: const Icon(Icons.arrow_back_ios,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: SizedBox(
                      height: 250,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemBuilder: (ctx, index) => InkWell(
                          onTap: () {
                            pageController.animateToPage(index,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                            setState(() {
                              currentPage = index;
                            });
                          },
                          child: SizedBox(
                            height: 200,
                            width: 150,
                            child: WebView(
                              onWebViewCreated: (controller) {
                                controller.loadFile(
                                    widget.pages[index].absolute.path);
                              },
                            ),
                          ),
                        ),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemCount: widget.pages.length,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
