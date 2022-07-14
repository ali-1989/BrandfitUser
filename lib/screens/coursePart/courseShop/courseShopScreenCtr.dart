import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/managers/pupilCourseManager.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/coursePart/courseShop/courseShopScreen.dart';
import '/screens/coursePart/courseShop/fullInfoPart/shopFullInfoScreen.dart';
import '/screens/loginPart/loginScreen.dart';
import '/system/keys.dart';
import '/system/queryFiltering.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/httpCenter.dart';

class CourseShopScreenCtr implements ViewController {
  late CourseShopScreenState state;
  late PupilCourseManager courseManager;
  late Requester commonRequester;
  late FilterRequest filterRequest;
  TextEditingController? searchEditController;
  List<CourseModel> shopList = [];
  UserModel? user;
  int requestCountOnLunch = 0;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as CourseShopScreenState;

    commonRequester = Requester();
    filterRequest = FilterRequest();

    state.stateController.mainState = StateXController.state$loading;

    if(Session.hasAnyLogin()){
      user = Session.getLastLoginUser();
      courseManager = PupilCourseManager.managerFor(user!.userId);
      requestCountOnLunch = courseManager.myRequestedList.length;

      prepareFilterOptions();
      requestShopCourses();
    }
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }

  void prepareFilterOptions(){
    //filterRequest.addSortView(SortKeys.ageKey, isAsc: false,  isDefault: true);

    filterRequest.addSearchView(SearchKeys.userNameKey);
    filterRequest.selectedSearchKey = SearchKeys.userNameKey;
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is CourseShopScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
      requestShopCourses();
    }
  }

  void tryLogin(State state){
    if(state is CourseShopScreenState) {
      AppNavigator.pushNextPage(state.context, LoginScreen(), name: LoginScreen.screenName);
    }
  }

  void gotoFullInfo(CourseModel course) async {
    AppNavigator.pushNextPage(
        state.context,
        CourseFullInfoScreen(courseModel: course),
        name: CourseFullInfoScreen.screenName,
    ).then((value){
      // todo must a notifie call for restart no by then
      resetRequest();
    });
  }

  void resetRequest(){
    shopList.clear();

    requestShopCourses();
  }

  void requestShopCourses() async {
    FocusHelper.hideKeyboardByUnFocusRoot();

    final js = <String, dynamic>{};
    js[Keys.request] = 'GetCoursesForShop';
    js[Keys.requesterId] = user!.userId;
    js[Keys.forUserId] = user!.userId;
    js[Keys.filtering] = filterRequest.toMap();

    commonRequester.bodyJson = js;
    commonRequester.requestPath = RequestPath.GetData;

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

      if(list != null && list.isNotEmpty){
        for(final m in list){
          final c = CourseModel.fromMap(m, domain: domain);
          //courseManager.addItem(c);
          shopList.add(c);
        }
      }

      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    };

    commonRequester.request(state.context);
  }
}
