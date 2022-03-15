library get_better_resolution;

/*
NanoBanco Mobile App - CryptoMarket

File edited by: Álvaro Agüero - 4/2/2022
File edited by: Álvaro Agüero - 7/3/2022 - Improve performance
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'multi_width_height_image.dart';
import 'package:flutter/foundation.dart';

class GetBetterResolution {

  static Map<String, MultiWidthHeightImage> imagesMap = {};
  static late String folderInitRoute;

  /*
  * Method to initialize the library and map the different assets
  * */
  Future<void> initialize({
    required String folderInitRoute
  }) async {
    if (kDebugMode) {
      print('<< GetBetterResolution ---- initialize() >>');
      print(folderInitRoute);
    }

    imagesMap = {};
    GetBetterResolution.folderInitRoute = folderInitRoute;

    final _manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> _manifestMap = json.decode(_manifestContent);

    final _imagePaths = _manifestMap.keys
        .where((String key) => key.contains(folderInitRoute))
        .where((String key) => key.contains('.png'))
        .toList();

    for (var originalElement in _imagePaths) {

      final _originalImageNameArray = originalElement.split('/');
      final _originalImageName = _originalImageNameArray[_originalImageNameArray.length-1];

      final _originalImageNameDataArray = _originalImageName.split('.');
      final _originalImageNameExtracted = _originalImageNameDataArray[1];//home_icon_inactive

      if(imagesMap.containsKey(_originalImageNameExtracted)) {

        final _imageNameArray = originalElement.split('/');
        final _imageName = _imageNameArray[_imageNameArray.length-1];

        final _imageNameDataArray = _imageName.split('.');
        final imageNameExtracted = _imageNameDataArray[1];//home_icon_inactive

        if(_originalImageNameExtracted == imageNameExtracted) {
          final _imageSizeExtracted = _imageNameDataArray[0];
          final _sizeImageExtractedArray = _imageSizeExtracted.split('x');
          final _width = int.tryParse(_sizeImageExtractedArray[0]) ?? 100;
          final _height = int.tryParse(_sizeImageExtractedArray[1]) ?? 100;

          imagesMap[_originalImageNameExtracted]!.widths.add(_width);
          imagesMap[_originalImageNameExtracted]!.heights.add(_height);
          imagesMap[_originalImageNameExtracted]!.paths.add(originalElement);
        }
      } else {
        final _originalImageSizeExtracted = _originalImageNameDataArray[0];
        final _sizeImageExtractedArray = _originalImageSizeExtracted.split('x');
        final _originalWidth = int.tryParse(_sizeImageExtractedArray[0]) ?? 100;
        final _originalHeight = int.tryParse(_sizeImageExtractedArray[1]) ?? 100;

        imagesMap[_originalImageNameExtracted] = MultiWidthHeightImage(
            widths: [_originalWidth],
            heights: [_originalHeight],
            paths: [originalElement]
        );
      }
    }

    //Order data
    imagesMap.forEach((key, value) {
      for(int b=0; b<value.paths.length; b++) {

        final bTotalResolution = value.widths[b] + value.heights[b];

        for(int c=0; c<value.paths.length; c++) {

          final cTotalResolution = value.widths[c] + value.heights[c];

          if(cTotalResolution > bTotalResolution) {

            final String pathsAux = value.paths[b];
            final int widthAux = value.widths[b];
            final int heightAux = value.heights[b];

            value.paths[b] = value.paths[c];
            value.widths[b] = value.widths[c];
            value.heights[b] = value.heights[c];

            value.paths[c] = pathsAux;
            value.widths[c] = widthAux;
            value.heights[c] = heightAux;
          }
        }
      }
    });
  }

  /*
  * Method to get the best resolution by [referenceImageName] ex: 'home_icon_active'
  * */
  Future<String> get({
    required BuildContext context,
    required String referenceImageName,
    int? width,
    int? height
  }) async {

    /*if (kDebugMode) {
      print('===================== imagesMap get() ======================');
      imagesMap.forEach((key, value) {
        if (kDebugMode) {
          print('key $key - value $value');
        }
        for(int b=0; b<value.paths.length; b++) {
          if (kDebugMode) {
            print('heights $b - ' + value.heights[b].toString()
                + '  widths $b - ' + value.widths[b].toString()
                + '  paths $b - ' + value.paths[b].toString());
          }
        }
      });
    }*/

    if(width == null && height == null) {
      return 'Debe venir al menos un valor válido para width o height.';
    }

    if(imagesMap.containsKey(referenceImageName)) {

      final MultiWidthHeightImage multiWidthHeightImage = imagesMap[referenceImageName]!;

      //Work with [width]
      if(width != null) {

        final baseWidth = multiWidthHeightImage.widths[0];
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
        final widthCalculated = (baseWidth * devicePixelRatio * (width / baseWidth)).round();

        List<List<int>> positionAndDifferenceList = [];

        if(widthCalculated < baseWidth) {
          return multiWidthHeightImage.paths[0];
        }

        for(int b=0; b<multiWidthHeightImage.paths.length; b++) {

          if(widthCalculated == multiWidthHeightImage.widths[b]) {
            return multiWidthHeightImage.paths[b];
          }

          positionAndDifferenceList.add(
              [
                b,//[0] position
                (widthCalculated - multiWidthHeightImage.widths[b]).round().abs() //[1] difference with widthCalculated, here is rounded and positive
              ]
          );
        }

        for(int b=0; b<positionAndDifferenceList.length; b++) {
          for(int c=0; c<positionAndDifferenceList.length; c++) {
            if(positionAndDifferenceList[c][1] > positionAndDifferenceList[b][1]) {
              final positionAndDifferenceAux = positionAndDifferenceList[b];
              positionAndDifferenceList[b] = positionAndDifferenceList[c];
              positionAndDifferenceList[c] = positionAndDifferenceAux;
            }
          }
        }

        if(multiWidthHeightImage.paths.length > 1) {
          //The nearest is the last
          if(positionAndDifferenceList[0][0] == multiWidthHeightImage.paths.length-1) {
            return multiWidthHeightImage.paths[positionAndDifferenceList[0][0]];
          } else
          if(widthCalculated > multiWidthHeightImage.widths[positionAndDifferenceList[0][0]]) {
            return multiWidthHeightImage.paths[positionAndDifferenceList[1][0]];
          }
        }
        return multiWidthHeightImage.paths[positionAndDifferenceList[0][0]];
      } else { //Work with [height]

        final baseHeight = multiWidthHeightImage.heights[0];
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
        final heightCalculated = (baseHeight * devicePixelRatio * (height! / baseHeight)).round();

        List<List<int>> positionAndDifferenceList = [];

        if(heightCalculated < baseHeight) {
          return multiWidthHeightImage.paths[0];
        }

        for(int b=0; b<multiWidthHeightImage.paths.length; b++) {

          if(heightCalculated == multiWidthHeightImage.heights[b]) {
            return multiWidthHeightImage.paths[b];
          }

          positionAndDifferenceList.add(
              [
                b,//[0] position
                (heightCalculated - multiWidthHeightImage.heights[b]).round().abs() //[1] difference with heightCalculated, here is rounded and positive
              ]
          );
        }

        for(int b=0; b<positionAndDifferenceList.length; b++) {
          for(int c=0; c<positionAndDifferenceList.length; c++) {
            if(positionAndDifferenceList[c][1] > positionAndDifferenceList[b][1]) {
              final positionAndDifferenceAux = positionAndDifferenceList[b];
              positionAndDifferenceList[b] = positionAndDifferenceList[c];
              positionAndDifferenceList[c] = positionAndDifferenceAux;
            }
          }
        }

        if(multiWidthHeightImage.paths.length > 1) {
          //The nearest is the last
          if(positionAndDifferenceList[0][0] == multiWidthHeightImage.paths.length-1) {
            return multiWidthHeightImage.paths[positionAndDifferenceList[0][0]];
          } else
          if(heightCalculated > multiWidthHeightImage.heights[positionAndDifferenceList[0][0]]) {
            return multiWidthHeightImage.paths[positionAndDifferenceList[1][0]];
          }
        }
        return multiWidthHeightImage.paths[positionAndDifferenceList[0][0]];
      }
    } else {
      return 'El path no está con el formato correcto o no existe.';
    }
  }

  /*
  * Method to get a quick path by [referenceImageName] ex: 'home_icon_active'
  * */
  String getQuick({
    required String referenceImageName
  }) {
    if(imagesMap.containsKey(referenceImageName)) {
      final MultiWidthHeightImage multiWidthHeightImage = imagesMap[referenceImageName]!;
      return multiWidthHeightImage.paths[0];
    } else {
      return 'El path no está con el formato correcto o no existe.';
    }
  }

  /*
  * Method to get the best resolution by [referenceImageName] ex: 'home_icon_active'
  * */
  String getSync({
    required BuildContext context,
    required String referenceImageName,
    int? width,
    int? height
  }) {

    /*if (kDebugMode) {
      print('===================== imagesMap get() ======================');
      imagesMap.forEach((key, value) {
        if (kDebugMode) {
          print('key $key - value $value');
        }
        for(int b=0; b<value.paths.length; b++) {
          if (kDebugMode) {
            print('heights $b - ' + value.heights[b].toString()
                + '  widths $b - ' + value.widths[b].toString()
                + '  paths $b - ' + value.paths[b].toString());
          }
        }
      });
    }*/

    if(width == null && height == null) {
      return 'Debe venir al menos un valor válido para width o height.';
    }

    if(imagesMap.containsKey(referenceImageName)) {

      final MultiWidthHeightImage multiWidthHeightImage = imagesMap[referenceImageName]!;

      //Work with [width]
      if(width != null) {

        final baseWidth = multiWidthHeightImage.widths[0];
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
        final widthCalculated = (baseWidth * devicePixelRatio * (width / baseWidth)).round();

        List<List<int>> positionAndDifferenceList = [];

        if(widthCalculated < baseWidth) {
          return multiWidthHeightImage.paths[0];
        }

        for(int b=0; b<multiWidthHeightImage.paths.length; b++) {

          if(widthCalculated == multiWidthHeightImage.widths[b]) {
            return multiWidthHeightImage.paths[b];
          }

          positionAndDifferenceList.add(
              [
                b,//[0] position
                (widthCalculated - multiWidthHeightImage.widths[b]).round().abs() //[1] difference with widthCalculated, here is rounded and positive
              ]
          );
        }

        for(int b=0; b<positionAndDifferenceList.length; b++) {
          for(int c=0; c<positionAndDifferenceList.length; c++) {
            if(positionAndDifferenceList[c][1] > positionAndDifferenceList[b][1]) {
              final positionAndDifferenceAux = positionAndDifferenceList[b];
              positionAndDifferenceList[b] = positionAndDifferenceList[c];
              positionAndDifferenceList[c] = positionAndDifferenceAux;
            }
          }
        }

        if(multiWidthHeightImage.paths.length > 1) {
          //The nearest is the last
          if(positionAndDifferenceList[0][0] == multiWidthHeightImage.paths.length-1) {
            return multiWidthHeightImage.paths[positionAndDifferenceList[0][0]];
          } else
          if(widthCalculated > multiWidthHeightImage.widths[positionAndDifferenceList[0][0]]) {
            return multiWidthHeightImage.paths[positionAndDifferenceList[1][0]];
          }
        }
        return multiWidthHeightImage.paths[positionAndDifferenceList[0][0]];
      } else { //Work with [height]

        final baseHeight = multiWidthHeightImage.heights[0];
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
        final heightCalculated = (baseHeight * devicePixelRatio * (height! / baseHeight)).round();

        List<List<int>> positionAndDifferenceList = [];

        if(heightCalculated < baseHeight) {
          return multiWidthHeightImage.paths[0];
        }

        for(int b=0; b<multiWidthHeightImage.paths.length; b++) {

          if(heightCalculated == multiWidthHeightImage.heights[b]) {
            return multiWidthHeightImage.paths[b];
          }

          positionAndDifferenceList.add(
              [
                b,//[0] position
                (heightCalculated - multiWidthHeightImage.heights[b]).round().abs() //[1] difference with heightCalculated, here is rounded and positive
              ]
          );
        }

        for(int b=0; b<positionAndDifferenceList.length; b++) {
          for(int c=0; c<positionAndDifferenceList.length; c++) {
            if(positionAndDifferenceList[c][1] > positionAndDifferenceList[b][1]) {
              final positionAndDifferenceAux = positionAndDifferenceList[b];
              positionAndDifferenceList[b] = positionAndDifferenceList[c];
              positionAndDifferenceList[c] = positionAndDifferenceAux;
            }
          }
        }

        if(multiWidthHeightImage.paths.length > 1) {
          //The nearest is the last
          if(positionAndDifferenceList[0][0] == multiWidthHeightImage.paths.length-1) {
            return multiWidthHeightImage.paths[positionAndDifferenceList[0][0]];
          } else
          if(heightCalculated > multiWidthHeightImage.heights[positionAndDifferenceList[0][0]]) {
            return multiWidthHeightImage.paths[positionAndDifferenceList[1][0]];
          }
        }
        return multiWidthHeightImage.paths[positionAndDifferenceList[0][0]];
      }
    } else {
      return 'El path no está con el formato correcto o no existe.';
    }
  }
}