import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:iris_pic_editor/pic_editor.dart';
import 'package:iris_tools/api/helpers/fileHelper.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/courseModels/pupilCourseModel.dart';
import '/models/dataModels/photoDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/system/enums.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appManager.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/directoriesCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/permissionTools.dart';
import '/views/brokenImageView.dart';

class PayInfoScreen extends StatefulWidget {
  static const screenName = 'PayInfoScreen';
  final PupilCourseModel courseModel;
  final PhotoDataModel? photoDataModel;

  PayInfoScreen({
    Key? key,
    required this.courseModel,
    this.photoDataModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PayInfoScreenState();
  }
}
///=====================================================================================
class PayInfoScreenState extends StateBase<PayInfoScreen> {
  StateXController stateController = StateXController();
  late final PupilCourseModel courseModel;
  PhotoDataModel? photoModel;
  late UserModel user;
  late Requester commonRequester;

  @override
  void initState() {
    super.initState();

    courseModel = widget.courseModel;
    photoModel = widget.photoDataModel;
    user = Session.getLastLoginUser()!;
    commonRequester = Requester();
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    return getScaffold();
  }

  @override
  void dispose() {
    stateController.dispose();
    HttpCenter.cancelAndClose(commonRequester.httpRequester);

    super.dispose();
  }

  Widget getScaffold() {
    return StateX(
        isMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
        return SizedBox(
          width: AppSizes.getScreenHeight(context),
          child: Scaffold(
            appBar: getAppBar(),
            body: SafeArea(
                child: getBody()
            ),
          ),
        );
      }
    );
  }

  PreferredSizeWidget getAppBar(){
    return AppBar(
      actions: [
        IconButton(
            onPressed: requestUpdatePayPhoto,
          icon: Icon(IconList.tickM),
        )
      ],
    );
  }

  Widget getBody() {
    return SizedBox(
      width: double.maxFinite,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.fwSize(10),),
            Text('${tInMap('courseBuyQuestionPage', 'imageOfCard')}:')
                .bold().fs(16).alpha(alpha: 150),

            SizedBox(height: AppSizes.fwSize(10),),
            FractionallySizedBox(
              widthFactor: 0.8,
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: photoModel != null? 10/16 : 10/5,
                child: GestureDetector(
                  onTap: (){
                    if(photoModel != null) {
                      openGallery([photoModel!], 0);
                    }
                  },
                  onLongPress: (){
                    if(photoModel != null) {
                      deleteDialog();
                    }
                  },
                  child: IrisImageView(
                    imagePath: photoModel?.getPath(),
                    url: photoModel?.uri,
                    beforeLoadWidget: Align(
                      child: IconButton(
                          iconSize: 80,
                          icon: Icon(Icons.add).siz(80),
                          onPressed: () {
                            addPhoto();
                          }
                      ).wrapDotBorder(color: AppThemes.currentTheme.textColor),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  ///========================================================================================================
  void addPhoto(){
    final items = <Map>[];

    items.add({
      'title': '${t('camera')}',
      'icon': IconList.camera,
      'fn': (){
        PermissionTools.requestCameraStoragePermissions().then((value) {
          if(value == PermissionStatus.granted){
            ImagePicker().pickImage(source: ImageSource.camera).then((value) {
              if(value == null) {
                return;
              }

              editImage(value.path);
            });
          }
        });
      }
    });

    items.add({
      'title': '${t('gallery')}',
      'icon': IconList.gallery,
      'fn': (){
        PermissionTools.requestStoragePermission().then((value) {
          if(value == PermissionStatus.granted){
            ImagePicker().pickImage(source: ImageSource.gallery).then((value) {
              if(value == null) {
                return;
              }

              editImage(value.path);
            });
          }
        });
      }
    });


    Widget genView(elm){
      return ListTile(
        title: Text(elm['title']),
        leading: Icon(elm['icon']),
        onTap: (){
          SheetCenter.closeSheetByName(context, 'EditMenu');
          elm['fn']?.call();
        },
      );
    }

    SheetCenter.showSheetMenu(
        context,
        items.map(genView).toList(),
        'EditMenu',
    );
  }

  void deleteDialog(){
    final desc = tC('wantToDeleteThisItem')!;

    void yesFn(){
      AppNavigator.pop(context);
      deletePhoto();
    }

    DialogCenter().showYesNoDialog(context, desc: desc, yesFn: yesFn,);
  }

  void openGallery(List<PhotoDataModel> list, int idx){
    final pageController = PageController(initialPage: idx,);

    final Widget gallery = PhotoViewGallery.builder(
      scrollPhysics: BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      enableRotation: false,
      gaplessPlayback: true,
      reverse: false,
      //customSize: Size(AppSizes.getScreenWidth(context), 200),
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

    OverlayDialog().show(context, osv);
  }

  void editImage(String imgPath){
    final editOptions = EditOptions.byPath(imgPath);
    editOptions.cropBoxInitSize = Size(200, 170);

    void onOk(EditOptions op) async {
      final pat = DirectoriesCenter.getSavePathByPath(SavePathType.COURSE_PHOTO, imgPath)!;

      FileHelper.createNewFileSync(pat);
      FileHelper.writeBytesSync(pat, editOptions.imageBytes!);

      insertPic(pat);
    }

    editOptions.callOnResult = onOk;
    final ov = OverlayScreenView(content: PicEditor(editOptions), backgroundColor: Colors.black);
    OverlayDialog().show(context, ov);
  }

  void insertPic(String path) {
    photoModel = PhotoDataModel();

    photoModel!.localPath = path;
    photoModel!.utcDate = DateHelper.getNowToUtc();

    stateController.updateMain();
  }

  void deletePhoto() {
    photoModel = null;

    stateController.updateMain();
  }

  void requestUpdatePayPhoto() async {
    //FocusHelper.hideKeyboardByUnFocusRoot();

    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdatePayPhoto';
    js[Keys.requesterId] = user.userId;
    js[Keys.forUserId] = user.userId;
    js['course_id'] = courseModel.id;

    if(photoModel != null){
      commonRequester.httpItem.addBodyFile(photoModel!.id, photoModel!.id, File(photoModel!.localPath!));

      js['photo_data'] = photoModel!.toMap();
      js[Keys.partName] = photoModel!.id;
    }
    else {
      js[Keys.partName] = 'delete';
    }


    AppManager.addAppInfo(js);
    commonRequester.httpItem.addBodyField(Keys.jsonHttpPart, JsonHelper.mapToJson(js));
    commonRequester.requestPath = RequestPath.SetData;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      await SheetCenter.showSheet$OperationFailed(context);
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      SheetCenter.showSheet$SuccessOperation(context);
    };

    showLoading();
    commonRequester.request(context);
  }
}
