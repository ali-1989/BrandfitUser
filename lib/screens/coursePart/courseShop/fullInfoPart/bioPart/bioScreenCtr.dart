import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/models/dataModels/photoDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/coursePart/courseShop/fullInfoPart/bioPart/bioScreen.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/centers/httpCenter.dart';
import '/views/brokenImageView.dart';

class BioScreenCtr implements ViewController {
  late BioScreenState state;
  late Requester commonRequester;
  late UserModel user;
  late CourseModel courseModel;
  late quill.QuillController bioCtr;
  String? biography;
  List<PhotoDataModel> photos = [];

  @override
  void onInitState<E extends State>(E state){
    this.state = state as BioScreenState;

    user = Session.getLastLoginUser()!;

    courseModel = state.widget.courseModel;
    biography = state.widget.bio;
    photos = state.widget.images;

    bioCtr = quill.QuillController.basic();

    if(biography != null) {
      var bioList = JsonHelper.jsonToList(biography)!;

      bioCtr = quill.QuillController(
          document: quill.Document.fromJson(bioList),
          selection: TextSelection.collapsed(offset: 0)
      );
    }

    commonRequester = Requester();
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }
  ///========================================================================================================
  void openGallery(int idx){
    final pageController = PageController(initialPage: idx,);

    final Widget gallery = PhotoViewGallery.builder(
      scrollPhysics: BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      enableRotation: false,
      gaplessPlayback: true,
      reverse: false,
      //customSize: Size(AppSizes.getScreenWidth(state.context), 200),
      itemCount: photos.length,
      pageController: pageController,
      //onPageChanged: onPageChanged,
      backgroundDecoration: BoxDecoration(
        color: Colors.black,
      ),
      builder: (BuildContext context, int index) {
        final ph = photos.elementAt(index);

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
}
