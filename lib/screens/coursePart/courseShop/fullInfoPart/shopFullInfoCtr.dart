import 'dart:io';

import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/pathHelper.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/models/dataModels/photoDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/commons/imageFullScreen.dart';
import '/screens/coursePart/courseShop/fullInfoPart/bioPart/bioScreen.dart';
import '/screens/coursePart/courseShop/fullInfoPart/shopFullInfoScreen.dart';
import '/screens/coursePart/courseShop/questions/questionsScreen.dart';
import '/system/enums.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/directoriesCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/uriTools.dart';

class CourseFullInfoCtr implements ViewController {
  late CourseFullInfoScreenState state;
  late UserModel user;
  late CourseModel courseModel;
  late Requester commonRequester;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as CourseFullInfoScreenState;

    user = Session.getLastLoginUser()!;
    commonRequester = Requester();
    courseModel = state.widget.courseModel;
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }
  ///========================================================================================================
  void tryAgain(State state){
  }

  void tryLogin(State state){
  }

  void showFullScreenImage(){
    if(courseModel.imageUri == null){
      return;
    }

    final view = ImageFullScreen(
      imageType: ImageType.File,
      heroTag: 'h${courseModel.id}',
      imageObj: File(courseModel.imagePath!),
    );

    AppNavigator.pushNextPageExtra(state.context, view, name: ImageFullScreen.screenName);
  }

  void gotoTrainerInfo(){
    final js = <String, dynamic>{};
    js[Keys.request] = 'GetTrainerInfo';
    js[Keys.requesterId] = user.userId;
    js[Keys.forUserId] = courseModel.creatorUserId;

    commonRequester.bodyJson = js;
    commonRequester.requestPath = RequestPath.GetData;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      SheetCenter.showSheet$ErrorCommunicatingServer(state.context);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      final biography = data['bio'];
      final images = data['photos'];
      final cardNumber = data['card_number'];
      final domain = data[Keys.domain];

      List<PhotoDataModel> photos = [];

      for(final k in images){
        final name = PathHelper.getFileName(k);
        final pat = DirectoriesCenter.getSavePathByPath(SavePathType.USER_PROFILE, name)!;

        final p = PhotoDataModel();
        p.uri = UriTools.correctAppUrl(k, domain: domain);
        p.localPath = pat;

        photos.add(p);
      }

      AppNavigator.pushNextPage(
        state.context,
        BioScreen(
          courseModel: courseModel,
          bio: biography,
          cardNumber: cardNumber,
          images: photos,
        ),
        name: BioScreen.screenName,
      );
    };

    state.showLoading();
    commonRequester.request(state.context);
  }

  void requestRequestCourse() async {
    FocusHelper.hideKeyboardByUnFocusRoot();

    final js = <String, dynamic>{};
    js[Keys.request] = 'GetUserCourseBuyInfo';
    js[Keys.requesterId] = user.userId;
    js[Keys.forUserId] = user.userId;
    js['course_id'] = courseModel.id;

    commonRequester.bodyJson = js;
    commonRequester.requestPath = RequestPath.GetData;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      await SheetCenter.showSheet$OperationFailed(state.context);
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      await AppNavigator.pushNextPage(
          state.context,
          QuestionsScreen(courseModel: courseModel,),
          name: QuestionsScreen.screenName
      );
    };

    state.showLoading();
    commonRequester.request(state.context);
  }
}
