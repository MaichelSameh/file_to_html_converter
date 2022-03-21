import 'dart:io';

import 'package:path_provider/path_provider.dart' as path_provider;

class Splits {
  ///this function will split the given file into pages
  ///it supports all the office document to html files
  ///the pdf to html files
  Future<List<File>> splitIntoPages(String filePath) async {
    //reading the file data line by line
    List<String> initialData = File(filePath).readAsLinesSync();
    //the page count for file naming
    int pageCount = 1;
    //the final result
    List<File> result = [];
    //extracting the header from the file
    List<String> header = initialData
        .getRange(0,
            initialData.indexWhere((element) => element.contains("<body")) + 1)
        .toList();
    //removing the header from the file
    initialData.removeRange(
        0, initialData.indexWhere((element) => element.contains("<body")) + 1);
    //extracting the footer/end of the file
    List<String> footer = initialData
        .getRange(
            initialData.indexWhere((element) => element.contains("</body")) - 1,
            initialData.length)
        .toList();
    //removing the footer/end of the file
    initialData.removeRange(
        initialData.indexWhere((element) => element.contains("</body")) - 1,
        initialData.length);
    //checking if it's a pdf file
    if (header[1].contains("pdf")) {
      //removing the loading indicator
      initialData.removeRange(
          initialData
              .indexWhere((element) => element.contains("loading-indicator")),
          initialData.indexWhere(
                  (element) => element.contains("loading-indicator")) +
              2);
      //adding the page the page-container opening div to the header
      header.add(initialData.first);
      //removing the page the page-container div
      initialData.removeAt(0);
      //adding the page the page-container closing div to the footer
      footer.add(initialData.last);
      //removing the page the page-container closing div
      initialData.removeLast();
      //this variable will control the do while loop
      bool repeat = false;
      do {
        //reassigning the value of false to the variable repeat
        //so it will stop the loop if the condition is not satisfied
        repeat = false;
        //checking if there are any pages in the file
        if (initialData.any((element) => element.contains("pf$pageCount"))) {
          repeat = true;
        }
        //getting the index of the end of the page
        int index = initialData
            .indexWhere((element) => element.contains("pf${pageCount + 1}"));
        //extracting the page
        String page = initialData
            .getRange(0, (index <= 0 ? initialData.length : index))
            .join("\n");
        //removing the extracted page from the file
        initialData.removeRange(0, (index < 0 ? initialData.length : index));
        //getting a temporary directory
        Directory dir = await path_provider.getTemporaryDirectory();
        //writing the page in a new file
        result.add(await File(dir.path + "page$pageCount.html")
            .writeAsString(header.join("\n") + page + footer.join("\n")));
      } while (repeat);
    } else {
      do {
        //checking the end of the page
        int index = initialData.indexWhere(
                (element) => element.contains("page-break-before: always")) -
            1;
        //if the file contains no pages, then it has only one page
        index = index <= 0 ? initialData.length : index;
        //extracting the page
        String page = initialData.getRange(0, index).join("\n");
        //removing the extracted page
        initialData.removeRange(0, index);
        //checking if the file contains other data or not
        if (initialData.isNotEmpty) {
          //removing the page break statement from the file
          initialData.first =
              initialData.first.replaceFirst("page-break-before: always", "");
        }
        //generating a temporary directory
        Directory dir = await path_provider.getTemporaryDirectory();
        //writing the page in a new file
        result.add(await File(dir.path + "page$pageCount.html")
            .writeAsString(header.join("\n") + page + footer.join("\n")));
      }
      //this loop will stop when the file is empty only
      while (initialData.isNotEmpty);
    }

    return result;
  }

  ///this function will split the html to extract only the paragraph text
  List<String> splitTextFromHtml(List<String> htmlContent) {
    //the result of the function
    List<String> result = [];
    //this regex detect all the html tags
    RegExp htmlTagsPattern = RegExp("<[^>]*>");
    //creating a variable to store all teh file lines with the new format
    List<String> tempList = [];
    for (int index = 0; index < htmlContent.length; index++) {
      String temp = htmlContent[index].replaceAll("<", "\n<");
      tempList.addAll(temp.split("\n"));
    }
    //reassigning the html content
    htmlContent = tempList;
    do {
      //detecting the begin of the text
      int startAt = htmlContent.indexWhere((element) => element.contains("<p"));
      //detecting the end of the text
      int endAt =
          htmlContent.indexWhere((element) => element.contains("</p")) + 1;
      //adjusting the end index
      endAt = endAt <= 0
          ? htmlContent.length
          : endAt > htmlContent.length
              ? htmlContent.length
              : endAt;
      //checking if the file contains any other paragraphs or not
      if (startAt < 0) {
        //if wes, then we will break the loop
        break;
      }
      //adding the paragraph content
      result.add(htmlContent.getRange(startAt, endAt).join("\n"));
      // removing the added paragraph
      htmlContent.removeRange(startAt, endAt);
    } while (htmlContent.any((element) => element.contains("<p")));
    //removing all the html tags and the empty lines from the result
    for (int index = 0; index < result.length; index++) {
      result[index] =
          result[index].replaceAll(htmlTagsPattern, "").replaceAll("\n", "");
    }
    //removing the empty values in the array
    result.removeWhere((element) => element.trim().isEmpty);
    return result;
  }
}
