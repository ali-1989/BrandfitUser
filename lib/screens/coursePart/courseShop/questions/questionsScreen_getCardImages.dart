import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:iris_pic_editor/pic_editor.dart';
import 'package:iris_tools/api/helpers/fileHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/models/dataModels/photoDataModel.dart';
import '/system/enums.dart';
import '/system/extensions.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/directoriesCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/permissionTools.dart';
import '/tools/widgetTools.dart';
import '/views/brokenImageView.dart';

class QuestionsScreenGetCardImage extends StatefulWidget {
  static const screenName = 'QuestionsScreenGetCardImage';
  final CourseQuestionModel courseQuestionModel;

  QuestionsScreenGetCardImage({
    Key? key,
    required this.courseQuestionModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return QuestionsScreenGetCardImageState();
  }
}
///=====================================================================================
class QuestionsScreenGetCardImageState extends StateBase<QuestionsScreenGetCardImage> {
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
        Text('${tInMap('courseBuyQuestionPage', 'imageOfCard')}:')
            .bold().fs(16).alpha(alpha: 150),

        SizedBox(height: AppSizes.fwSize(5),),
        Text('${tInMap('courseBuyQuestionPage', 'canUploadLater')}:')
            .subFont().fs(16).alpha(alpha: 150),

        SizedBox(height: AppSizes.fwSize(10),),
        FractionallySizedBox(
          widthFactor: 0.8,
          alignment: Alignment.center,
          child: AspectRatio(
            aspectRatio: 16/10,
            child: GestureDetector(
              onTap: (){
                if(courseQuestionModel.cardPhoto != null) {
                  openGallery([courseQuestionModel.cardPhoto!], 0);
                }
              },
              onLongPress: (){
                if(courseQuestionModel.cardPhoto != null) {
                  deleteDialog();
                }
              },
              child: IrisImageView(
                imagePath: courseQuestionModel.cardPhoto?.getPath(),
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
    );
  }
  ///========================================================================================================
  void addPhoto(){
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

                      editImage(value.path);
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

                      editImage(value.path);
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
    final ph = PhotoDataModel();

    ph.localPath = path;
    ph.utcDate = DateHelper.getNowToUtc();
    courseQuestionModel.cardPhoto = ph;

    stateController.updateMain();
  }

  void deletePhoto() {
    courseQuestionModel.cardPhoto?.localPath = '';
    courseQuestionModel.cardPhoto = null;

    stateController.updateMain();
  }
}
