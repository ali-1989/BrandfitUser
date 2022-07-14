import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:iris_pic_editor/pic_editor.dart';
import 'package:iris_tools/api/helpers/fileHelper.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/api/helpers/pathHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/photoDataModel.dart';
import '/models/dataModels/usersModels/fitnessDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/fitnessPart/photosScreen.dart';
import '/system/enums.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appManager.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/directoriesCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/centers/snackCenter.dart';
import '/tools/permissionTools.dart';
import '/tools/widgetTools.dart';
import '/views/brokenImageView.dart';
import '/views/loadingScreen.dart';

class PhotosScreenCtr implements ViewController {
  late PhotoScreenState state;
  Requester? commonRequester;
  late UserModel user;
  late List<PhotoDataModel> frontPhotos;
  late List<PhotoDataModel> backPhotos;
  late List<PhotoDataModel> sidePhotos;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as PhotoScreenState;

    commonRequester = Requester();
    commonRequester!.requestPath = RequestPath.SetData;

    user = Session.getLastLoginUser()!;

    updatePhotos();
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester?.httpRequester);
  }

  void updatePhotos(){
    frontPhotos = user.fitnessDataModel.frontPhotoNodes;
    backPhotos = user.fitnessDataModel.backPhotoNodes;
    sidePhotos = user.fitnessDataModel.sidePhotoNodes;
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is PhotoScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  void addPhoto(NodeNames nodeName){
    final Widget view = SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20,),

          ElevatedButton(
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all(Size(200, 50)),
                shape: MaterialStateProperty.all(ShapeList.stadiumBorder$Outlined),
                foregroundColor: MaterialStateProperty.all(AppThemes.currentTheme.buttonTextColorOnPrimary),
                backgroundColor: MaterialStateProperty.all(AppThemes.currentTheme.buttonBackColorOnPrimary),
              ),
              onPressed: (){
                SheetCenter.closeSheetByName(state.context, 'ChoosePhotoSource');

                PermissionTools.requestCameraStoragePermissions().then((value) {
                  if(value == PermissionStatus.granted){
                    ImagePicker().pickImage(source: ImageSource.camera).then((value) {
                      if(value == null) {
                        return;
                      }

                      editImage(value.path, nodeName);
                    });
                  }
                });
              },
              child: Text('${state.tC('camera')}')
          ),

          SizedBox(height: 16,),
          ElevatedButton(
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all(Size(200, 50)),
                shape: MaterialStateProperty.all(ShapeList.stadiumBorder$Outlined),
                foregroundColor: MaterialStateProperty.all(AppThemes.currentTheme.buttonTextColorOnPrimary),
                backgroundColor: MaterialStateProperty.all(AppThemes.currentTheme.buttonBackColorOnPrimary),
              ),
              onPressed: (){
                SheetCenter.closeSheetByName(state.context, 'ChoosePhotoSource');

                PermissionTools.requestStoragePermission().then((value) {
                  if(value == PermissionStatus.granted){
                    ImagePicker().pickImage(source: ImageSource.gallery).then((value) {
                      if(value == null) {
                        return;
                      }

                      editImage(value.path, nodeName);
                    });
                  }
                });
              },
              child: Text('${state.tC('gallery')}')
          ),

          SizedBox(height: 16,),
        ],
      ),
    );

    SheetCenter.showSheetCustom(state.context, view, routeName: 'ChoosePhotoSource');
  }

  void deleteDialog(PhotoDataModel photo, NodeNames nodeName){
    final desc = state.tC('wantToDeleteThisItem')!;

    void yesFn(){
      deletePhoto(photo, nodeName);
    }

    DialogCenter().showYesNoDialog(state.context, desc: desc, yesFn: yesFn,);
  }

  void openGallery(List<PhotoDataModel> list, int idx){
    final pageController = PageController(initialPage: idx,);

    final Widget gallery = PhotoViewGallery.builder(
      scrollPhysics: BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      enableRotation: false,
      gaplessPlayback: true,
      reverse: false,
      //customSize: Size(AppSizes.getScreenWidth(state.context), 200),
      itemCount: list.length,
      pageController: pageController,
      //onPageChanged: onPageChanged,
      backgroundDecoration: BoxDecoration(
        color: Colors.black,
      ),
      builder: (BuildContext context, int index) {
        final ph = list.elementAt(index);

        return PhotoViewGalleryPageOptions(
            imageProvider: FileImage(File(ph.getPath()?? ''),),// NetworkImage(ph.uri),
            heroAttributes: PhotoViewHeroAttributes(tag: 'photo$idx'),
            basePosition: Alignment.center,
            gestureDetectorBehavior: HitTestBehavior.translucent,
            maxScale: 2.0,
            //minScale: 0.5,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, Object error, StackTrace? stackTrace){
              return BrokenImageView();
            }
        );
      },

      loadingBuilder: (context, progress) => Center(
        child: SizedBox(
          width: 70.0,
          height: 70.0,
          child: (progress == null || progress.expectedTotalBytes == null)

              ? CircularProgressIndicator()
              : CircularProgressIndicator(value: progress.cumulativeBytesLoaded / progress.expectedTotalBytes!,),
        ),
      ),
    );

    final osv = OverlayScreenView(
      content: gallery,
      routingName: 'Gallery',
    );

    OverlayDialog().show(state.context, osv);
  }

  void afterUpload(String filePath, Map map, NodeNames nodeName){
    final String uri = map[Keys.fileUri]?? '';
    final fitnessJs = map['fitness_status_js'];

    final newName = PathHelper.getFileName(uri);
    final newFileAddress = PathHelper.getParentDirPath(filePath) + PathHelper.getSeparator() + newName;

    final f = FileHelper.renameSyncSafe(filePath, newFileAddress);

    if(fitnessJs != null) {
      user.fitnessDataModel.matchBy(FitnessDataModel.fromMap(fitnessJs));
    }

    PhotoDataModel? find;

    if(nodeName == NodeNames.front_photo) {
      find = user.fitnessDataModel.findFrontPhotoByUri(uri);
    }
    else if(nodeName == NodeNames.back_photo){
      find = user.fitnessDataModel.findBackPhotoByUri(uri);
    }
    else {
      find = user.fitnessDataModel.findSidePhotoByUri(uri);
    }

    if(find != null){
      find.localPath = f.path;
    }

    Session.sinkUserInfo(user).then((value){
      state.hideLoading();

      updatePhotos();
      state.stateController.updateMain();
    });

    //after load image called: OverlayCenter().hideLoading(state.context);
    SnackCenter.showSnack$successOperation(state.context);
  }

  void editImage(String imgPath, NodeNames nodeName){
    final editOptions = EditOptions.byPath(imgPath);
    editOptions.cropBoxInitSize = Size(200, 170);

    void onOk(EditOptions op) async {
      final pat = DirectoriesCenter.getSavePathByPath(SavePathType.BODY_PHOTO, imgPath)!;

      FileHelper.createNewFileSync(pat);
      FileHelper.writeBytesSync(pat, editOptions.imageBytes!);

      uploadPhoto(pat, afterUpload, nodeName);
    }

    editOptions.callOnResult = onOk;
    final ov = OverlayScreenView(content: PicEditor(editOptions), backgroundColor: Colors.black);
    OverlayDialog().show(state.context, ov);
  }

  void uploadPhoto(String filePath, Function onSuccess, NodeNames nodeName) {
    final partName = nodeName.name;
    final fileName = PathHelper.getFileName(filePath);

    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdateBodyPhoto';
    js[Keys.userId] = user.userId;
    js[Keys.fileName] = fileName;
    js[Keys.partName] = partName;

    AppManager.addAppInfo(js);

    commonRequester!.httpItem.addBodyField(Keys.jsonHttpPart, JsonHelper.mapToJson(js));
    commonRequester!.httpItem.addBodyFile(partName, fileName, FileHelper.getFile(filePath));


    commonRequester?.httpRequestEvents.onNetworkError = (req) async {
      await LoadingScreen.hideLoading(state.context);
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester?.httpRequestEvents.onResponseError = (req, isOk) async {
      await LoadingScreen.hideLoading(state.context);

      if(isOk){
        SnackCenter.showSnack$errorInServerSide(state.context);
      } else {
        SnackCenter.showSnack$serverNotRespondProperly(state.context);
      }
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      await LoadingScreen.hideLoading(state.context);
      SnackCenter.showSnack$errorInServerSide(state.context);

      return true;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      onSuccess(filePath, data, nodeName);
    };

    LoadingScreen.showLoading(state.context, canBack: false);
    commonRequester?.request(state.context);
  }

  void deletePhoto(PhotoDataModel photo, NodeNames nodeName) {
    final js = <String, dynamic>{};
    js[Keys.request] = 'DeleteBodyPhoto';
    js[Keys.userId] = user.userId;
    js[Keys.nodeName] = nodeName.name;
    js[Keys.imageUri] = photo.uri;
    js[Keys.date] = DateHelper.toTimestamp(photo.utcDate!);

    commonRequester?.bodyJson = js;

    commonRequester?.httpRequestEvents.onNetworkError = (req) async {
      await LoadingScreen.hideLoading(state.context);
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester?.httpRequestEvents.onResponseError = (req, isOk) async {
      await LoadingScreen.hideLoading(state.context);

      if(isOk){
        SnackCenter.showSnack$errorInServerSide(state.context);
      } else {
        SnackCenter.showSnack$serverNotRespondProperly(state.context);
      }
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      await LoadingScreen.hideLoading(state.context);
      SnackCenter.showSnack$errorInServerSide(state.context);

      return true;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      final fitnessJs = data['fitness_status_js'];

      if(fitnessJs != null) {
        user.fitnessDataModel.matchBy(FitnessDataModel.fromMap(fitnessJs));
      }

      // ignore: unawaited_futures
      Session.sinkUserInfo(user).then((value) async {
        await LoadingScreen.hideLoading(state.context);

        updatePhotos();
        state.stateController.updateMain();
      });
    };

    LoadingScreen.showLoading(state.context, canBack: false);
    commonRequester?.request(state.context);
  }
}
