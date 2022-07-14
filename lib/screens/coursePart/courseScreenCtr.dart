import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/managers/foodMaterialManager.dart';
import '/managers/foodProgramManager.dart';
import '/managers/pupilCourseManager.dart';
import '/models/dataModels/courseModels/pupilCourseModel.dart';
import '/models/dataModels/foodModels/materialModel.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/coursePart/courseScreen.dart';
import '/screens/coursePart/courseShop/courseShopScreen.dart';
import '/screens/coursePart/fullInfoPart/requestFullInfoScreen.dart';
import '/screens/loginPart/loginScreen.dart';
import '/screens/programViewPart/programViewScreen.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/httpCenter.dart';

class CourseScreenCtr implements ViewController {
  late CourseScreenState state;
  late PupilCourseManager courseManager;
  late Requester commonRequester;
  UserModel? user;
  bool isInRequestState = true;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as CourseScreenState;

    Session.addLoginListener(onNewLoginLogoff);
    Session.addLogoffListener(onNewLoginLogoff);

    commonRequester = Requester();
    commonRequester.requestPath = RequestPath.GetData;

    if(Session.hasAnyLogin()){
      user = Session.getLastLoginUser();
      courseManager = PupilCourseManager.managerFor(user!.userId);

      requestRequestedCourses();
    }
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    Session.removeLoginListener(onNewLoginLogoff);
    Session.removeLogoffListener(onNewLoginLogoff);
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }

  void onNewLoginLogoff(UserModel user){
    this.user = null;
    state.stateController.updateMain();
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is CourseScreenState) {
      isInRequestState = true;
      state.stateController.mainStateAndUpdate(StateXController.state$normal);
      requestRequestedCourses();
    }
  }

  void tryLogin(State state){
    if(state is CourseScreenState) {
      AppNavigator.pushNextPage(state.context, LoginScreen(), name: LoginScreen.screenName);
    }
  }

  void gotoFullInfo(PupilCourseModel course){
    AppNavigator.pushNextPage(
      state.context,
      RequestFullInfoScreen(courseModel: course,),
      name: RequestFullInfoScreen.screenName,
    );
  }

  void gotoShopScreen(){
    AppNavigator.pushNextPage(
      state.context,
        CourseShopScreen(),
        name: CourseShopScreen.screenName,
    ).then((value) {
          if(value != null && value) {
            isInRequestState = true;
            state.stateController.updateMain();
            requestRequestedCourses();
          }
    });
  }

  void gotoPrograms(PupilCourseModel course){
    final js = <String, dynamic>{};
    js[Keys.request] = 'GetProgramsForRequest';
    js[Keys.requesterId] = user!.userId;
    js[Keys.forUserId] = user!.userId;
    js['request_id'] = course.requestId;

    commonRequester.bodyJson = js;
    commonRequester.requestPath = RequestPath.GetData;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      state.stateController.mainStateAndUpdate(StateXController.state$netDisconnect);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      final List programList = data['program_list'];
      final List materialList = data['material_list'];
      final domain = data[Keys.domain];

      for(final m in materialList){
        final mat = MaterialModel.fromMap(m, domain: domain);
        FoodMaterialManager.addItem(mat);
        FoodMaterialManager.sinkItems([mat]);
      }

      final pManager = FoodProgramManager.managerFor(user!.userId);

      for(final p in programList){
        final pro = FoodProgramModel.fromMap(p);
        pManager.addItem(pro);
        //pManager.sinkItems([pro]);
      }

      AppNavigator.pushNextPage(
        state.context,
        ProgramViewScreen(pupilCourseModel: course,),
        name: ProgramViewScreen.screenName,
      );
    };

    state.showLoading();
    commonRequester.request(state.context);
  }

  void requestRequestedCourses() async {
    FocusHelper.hideKeyboardByUnFocusRoot();

    final js = <String, dynamic>{};
    js[Keys.request] = 'GetRequestedCourses';
    js[Keys.requesterId] = user!.userId;
    js[Keys.forUserId] = user!.userId;

    commonRequester.bodyJson = js;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      isInRequestState = false;
    };

    commonRequester.httpRequestEvents.onNetworkError = (req) async {
      state.stateController.mainStateAndUpdate(StateXController.state$netDisconnect);
    };

    commonRequester.httpRequestEvents.onResponseError = (req, isOk) async {
      state.stateController.mainStateAndUpdate(StateXController.state$serverNotResponse);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      state.stateController.mainStateAndUpdate(StateXController.state$serverNotResponse);

      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      final List? list = data[Keys.resultList];
      final domain = data[Keys.domain];

      if(list != null){
        for(final m in list){
          final itm = PupilCourseModel.fromMap(m, domain: domain);
          courseManager.addItem(itm);
          courseManager.addRequestedId(itm.id);
        }
      }

      courseManager.sortList(false);
      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    };

    commonRequester.request(state.context);
  }
}
