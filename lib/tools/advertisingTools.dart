import 'dart:io';

import 'package:flutter/material.dart';

import 'package:iris_db/iris_db.dart';
import 'package:iris_tools/api/helpers/fileHelper.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:permission_handler/permission_handler.dart';

import '/models/dataModels/advertisingModel.dart';
import '/system/downloadUpload.dart';
import '/system/enums.dart';
import '/system/keys.dart';
import '/tools/app/appManager.dart';
import '/tools/centers/broadcastCenter.dart';
import '/tools/centers/cacheCenter.dart';
import '/tools/centers/dbCenter.dart';
import '/tools/centers/directoriesCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/permissionTools.dart';
import '/tools/uriTools.dart';

class AdvertisingTools {
  AdvertisingTools._();

  static List<AdvertisingModel> carouselModelList = [];

  static Future callRequestAdvertising() async {
    if(!BroadcastCenter.isNetConnected){
      return false;
    }

    /// because this method inserted in build method and recall very
    if (!CacheCenter.timeoutCache.addTimeout(Keys.updateAdvertisingCache, Duration(minutes: 15))){
      return;
    }

    requestAdvertising();

    /*NetListener listener = NetListener(Keys.updateAdvertisingCache);

    listener.onConnected = (bool isWifi){
      requestAdvertising().then((value){
        if(BoolHelper.itemToBool(value)) {
          listener.purge();
        }
      });
    };

    listener.listenIfNot();*/
  }

  static Future<bool> requestAdvertising() async{
    Map<String, dynamic> js = {};
    js[Keys.request] = 'GetUserAdvertisingList';
    AppManager.addAppInfo(js);

    HttpItem request = HttpItem();
    request.pathSection = '/get-data';
    request.method = 'POST';
    request.body = JsonHelper.mapToJson(js);

    Future<bool> f = Future<bool>((){
      HttpRequester response = HttpCenter.send(request);

      return response.responseFuture
          .catchError((e){
        CacheCenter.timeoutCache.deleteTimeout(Keys.updateAdvertisingCache);
      })
          .then((value) async {
        if (!response.isOk) {
          CacheCenter.timeoutCache.deleteTimeout(Keys.updateAdvertisingCache);
          return false;
        }

        Map<String, dynamic>? json = response.getBodyAsJson();

        if (json == null) {
          return true;
        }
print('================ advertising ===================================');
print(json);
        String result = json[Keys.result] ?? Keys.error;

        if (result == Keys.ok) {
          List<dynamic> rList = json[Keys.resultList];
          String domain = json[Keys.domain];

          if(rList.isEmpty){
            DbCenter.db.delete(DbCenter.tbAdvertising, null);
            return true;
          }

          List<int> ids = [];

          for(var cas in rList){
            ids.add(cas['id']);
          }

          await DbCenter.db.delete(DbCenter.tbAdvertising,
              Conditions().add(Condition(ConditionType.NotIn)..key = 'id'..value = ids));


          for(var jsItem in rList){
            var url = jsItem[Keys.imageUri];
            jsItem[Keys.imageUri] = UriTools.correctAppUrl(url, domain: domain);

            await DbCenter.db.insertOrUpdate(DbCenter.tbAdvertising, jsItem,
                Conditions().add(Condition()..key = 'id'..value = jsItem['id']));
          }

          prepareCarousel();
        }

        return true; // must return true, for purge net listener
      });
    });

    return f;
  }
  ///======== fetch ============================================================================
  static List<AdvertisingModel> fetchAdvertising() {
    var res = <AdvertisingModel>[];

    List<dynamic> db = DbCenter.db.query(DbCenter.tbAdvertising, null);

    for(var map in db) {
      var m = AdvertisingModel.fromMap(map);
      res.add(m);
    }

    return res;
  }
  ///======== prepare ============================================================================
  static void prepareCarousel() async {
    // Image.asset('assets/images/a1.png'),

    List<AdvertisingModel> aList = fetchAdvertising();

    for(var itm in aList){
      String? path = itm.imagePath;

      bool existInList = false;

      for(var am in carouselModelList){
        if(am.imagePath == path){
          aList.add(am);
          existInList = true;
          break;
        }
      }

      if(existInList){
        continue;
      }

      bool existImage = false;

      if(path != null){
        File f = FileHelper.getFile(path);

        var exist = await f.exists();

        if(exist){
          Widget w = Image.file(f);

          var n = AdvertisingModel();
          n.imagePath = path;
          n.title = itm.title;
          n.clickLink = itm.clickLink;
          n.imageUri = itm.imageUri;
          n.imageWidget = w;

          aList.add(n);

          existImage = true;
        }
      }

      if(!existImage){
        String? url = itm.imageUri;

        if(url == null) {
          continue;
        }

        var result = await PermissionTools.requestStoragePermission();

        if(result == PermissionStatus.granted) {
          String savePath = DirectoriesCenter.getSavePathUri(url, SavePathType.ADVERTISING)!;
          var dItem = DownloadUpload.downloadManager.createDownloadItem(url,
              tag: Keys.genDownloadTag_advertising(itm), savePath: savePath);
          dItem.forceCreateNewFile = true;
          dItem.attach = itm.id;
          dItem.category = DownloadCategory.advertisingUser.toString();

          DownloadUpload.downloadManager.enqueue(dItem);
        }
      }
    }

    carouselModelList.clear();
    carouselModelList.addAll(aList);

    BroadcastCenter.centerPageScreenKey.currentState?.controller.reBuildCarouselView();
    BroadcastCenter.centerPageScreenKey.currentState?.carouselRefresher.update();
  }
}
