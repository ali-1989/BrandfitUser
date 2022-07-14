import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:iris_pic_editor/pic_editor.dart';
import 'package:iris_tools/api/helpers/fileHelper.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/models/dataModels/photoDataModel.dart';
import '/models/dataModels/usersModels/fitnessDataModel.dart';
import '/system/enums.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/directoriesCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/permissionTools.dart';
import '/tools/widgetTools.dart';
import '/views/brokenImageView.dart';
import '/views/preWidgets.dart';

class QuestionsScreenGetImage extends StatefulWidget {
  static const screenName = 'QuestionsScreenGetImage';
  final CourseQuestionModel courseQuestionModel;

  QuestionsScreenGetImage({
    Key? key,
    required this.courseQuestionModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return QuestionsScreenGetImageState();
  }
}
///=====================================================================================
class QuestionsScreenGetImageState extends StateBase<QuestionsScreenGetImage> {
  StateXController stateController = StateXController();
  late final CourseQuestionModel courseQuestionModel;

  @override
  void initState() {
    super.initState();

    courseQuestionModel = widget.courseQuestionModel;
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    return getMainBuilder();
  }

  @override
  void dispose() {
    stateController.dispose();

    super.dispose();
  }

  Widget getMainBuilder() {
    return StateX(
      isMain: true,
      controller: stateController,
      builder: (context, ctr, data) {
        return getBody();
      },
    );
  }

  Widget getBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${tInMap('courseBuyQuestionPage', 'imageExperiments')}:').bold().fs(16).alpha(alpha: 150),
        SizedBox(height: AppSizes.fwSize(8),),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            //shrinkWrap: true,
            itemCount: courseQuestionModel.experimentPhotos.length +1,
            itemBuilder: (ctx, idx){
              if (idx == 0) {
                return SizedBox(
                  width: 170,
                  height: 170,
                  child: Center(
                    child: IconButton(
                        iconSize: 80,
                        icon: Icon(Icons.add).siz(80),
                        onPressed: () {
                          addPhoto(NodeNames.experiment_photo);
                        }
                    ).wrapDotBorder(color: AppThemes.currentTheme.textColor),
                  ),
                );
              }

              final ph = courseQuestionModel.experimentPhotos.elementAt(idx - 1);
              return getListItem(idx, ph, courseQuestionModel.experimentPhotos, NodeNames.experiment_photo);
            },
          ),
        ),

        SizedBox(height: AppSizes.fwSize(16),),
        ///-------------------------
        Text('${tInMap('courseBuyQuestionPage', 'imageBodyAnalysis')}:').bold().fs(16).alpha(alpha: 150),
        SizedBox(height: AppSizes.fwSize(8),),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            //shrinkWrap: true,
            itemCount: courseQuestionModel.bodyAnalysisPhotos.length +1,
            itemBuilder: (ctx, idx){
              if (idx == 0) {
                return SizedBox(
                  width: 170,
                  height: 170,
                  child: Center(
                    child: IconButton(
                        iconSize: 80,
                        icon: Icon(Icons.add).siz(80),
                        onPressed: () {
                          addPhoto(NodeNames.body_analysis_photo);
                        }
                    ).wrapDotBorder(color: AppThemes.currentTheme.textColor),
                  ),
                );
              }

              final ph = courseQuestionModel.bodyAnalysisPhotos.elementAt(idx - 1);
              return getListItem(idx, ph, courseQuestionModel.bodyAnalysisPhotos, NodeNames.body_analysis_photo);
            },
          ),
        ),

        ///-------------------------
        Text('${tInMap('courseBuyQuestionPage', 'imageBody')}:').bold().fs(16).alpha(alpha: 150),
        SizedBox(height: 8,),
        Text('${tInMap('courseBuyQuestionPage', 'sendBodyImageForTrainer')}').subFont().fs(14).alpha(alpha: 200),
        SizedBox(height: AppSizes.fwSize(8),),
        Text('${tInMap('courseBuyQuestionPage', 'sendBodyImageForTrainer2')}').subFont().fs(14).alpha(alpha: 200),
        SizedBox(height: AppSizes.fwSize(8),),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            //shrinkWrap: true,
            itemCount: courseQuestionModel.bodyPhotos.length +1,
            itemBuilder: (ctx, idx){
              if (idx == 0) {
                return SizedBox(
                  width: 170,
                  height: 170,
                  child: Center(
                    child: IconButton(
                        iconSize: 80,
                        icon: Icon(Icons.add).siz(80),
                        onPressed: () {
                          addPhoto(NodeNames.body_photo);
                        }
                    ).wrapDotBorder(color: AppThemes.currentTheme.textColor),
                  ),
                );
              }

              final ph = courseQuestionModel.bodyPhotos.elementAt(idx - 1);
              return getListItem(idx, ph, courseQuestionModel.bodyPhotos, NodeNames.body_photo);
            },
          ),
        ),
      ],
    );
  }

  Widget getListItem(int idx, PhotoDataModel ph, List<PhotoDataModel> iList, NodeNames nodeName){
    return Stack(
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: Padding(
            padding: EdgeInsets.all(6.0),
            child: GestureDetector(
              onTap: () {
                openGallery(iList, idx - 1);
              },
              onLongPress: () {
                deleteDialog(ph, nodeName);
              },
              child: IrisImageView(
                beforeLoadWidget: PreWidgets.flutterLoadingWidget$Center(),
                errorWidget: BrokenImageView(),
                url: ph.uri,
                imagePath: ph.getPath(),
              ),
            ),
          ),
        ),

        Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Align(
                alignment: Alignment.topLeft,
                child: Icon(IconList.delete, color: Colors.white,).wrapMaterial(
                    materialColor: Colors.grey.withAlpha(200),
                    onTapDelay: (){
                      deleteDialog(ph, nodeName);
                    }
                )
            )
        ),
      ],
    );
  }
  ///========================================================================================================
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
                SheetCenter.closeSheetByName(context, 'ChoosePhotoSource');

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
              child: Text('${tC('camera')}')
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
                SheetCenter.closeSheetByName(context, 'ChoosePhotoSource');

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
              child: Text('${tC('gallery')}')
          ),

          SizedBox(height: 16,),
        ],
      ),
    );

    SheetCenter.showSheetCustom(context, view, routeName: 'ChoosePhotoSource');
  }

  void deleteDialog(PhotoDataModel photo, NodeNames nodeName){
    final desc = tC('wantToDeleteThisItem')!;

    void yesFn(){
      AppNavigator.pop(context);
      deletePhoto(photo, nodeName);
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

  void editImage(String imgPath, NodeNames nodeName){
    final editOptions = EditOptions.byPath(imgPath);
    editOptions.cropBoxInitSize = Size(200, 170);

    void onOk(EditOptions op) async {
      final pat = DirectoriesCenter.getSavePathByPath(SavePathType.COURSE_PHOTO, imgPath)!;

      FileHelper.createNewFileSync(pat);
      FileHelper.writeBytesSync(pat, editOptions.imageBytes!);

      insertPic(pat, nodeName);
    }

    editOptions.callOnResult = onOk;
    final ov = OverlayScreenView(content: PicEditor(editOptions), backgroundColor: Colors.black);
    OverlayDialog().show(context, ov);
  }

  void insertPic(String path, NodeNames nodeName) {
    courseQuestionModel.addPhoto(path, nodeName);
    stateController.updateMain();
  }

  void deletePhoto(PhotoDataModel photo, NodeNames nodeName) {
    courseQuestionModel.deletePhoto(photo, nodeName);
    stateController.updateMain();
  }

}
