import 'package:brandfit_user/models/dataModels/courseModels/courseModel.dart';
import 'package:brandfit_user/models/dataModels/photoDataModel.dart';
import 'package:brandfit_user/models/dataModels/trainerBioModel.dart';
import 'package:brandfit_user/screens/coursePart/courseShop/fullInfoPart/bioPart/bioScreen.dart';
import 'package:brandfit_user/screens/trainerSearchPart/trainerSearchScreen.dart';
import 'package:brandfit_user/system/enums.dart';
import 'package:brandfit_user/system/keys.dart';
import 'package:brandfit_user/system/queryFiltering.dart';
import 'package:brandfit_user/system/requester.dart';
import 'package:brandfit_user/tools/centers/directoriesCenter.dart';
import 'package:brandfit_user/tools/uriTools.dart';
import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/pathHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/loginPart/loginScreen.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';

class TrainerSearchCtr extends ViewController {
  late TrainerSearchScreenState state;
  UserModel? user;
  late FilterRequest filterRequest;
  late Requester commonRequester;
  TextEditingController? searchEditController;
  List<TrainerBioModel> trainerList = [];

  @override
  void onInitState<E extends State>(covariant E state) {
    this.state = state as TrainerSearchScreenState;

    commonRequester = Requester();
    filterRequest = FilterRequest();
    prepareFilterOptions();

    if(Session.hasAnyLogin()){
      userActions(Session.getLastLoginUser()!);
    }
  }

  @override
  void onBuild() {
  }

  @override
  void onDispose() {
  }

  void userActions(UserModel user){
    this.user = user;
  }

  void prepareFilterOptions(){
    filterRequest.addSearchView(SearchKeys.userNameKey);
    filterRequest.selectedSearchKey = SearchKeys.userNameKey;
  }
  ///=============================================================================================
  void tryAgain(State state){
    if(state is TrainerSearchScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
      resetRequest();
    }
  }

  void tryLogin(State state){
    if(state is TrainerSearchScreenState) {
      AppNavigator.pushNextPage(state.context, LoginScreen(), name: LoginScreen.screenName);
    }
  }

  void gotoBioScreen(TrainerBioModel tModel){
    final courseModel = CourseModel();
    courseModel.creatorUserName = tModel.userName;

    List<PhotoDataModel> photos = [];

    for(final k in tModel.bioImages){
      final name = PathHelper.getFileName(k);
      final pat = DirectoriesCenter.getSavePathByPath(SavePathType.USER_PROFILE, name)!;

      final p = PhotoDataModel();
      p.uri = UriTools.correctAppUrl(k);
      p.localPath = pat;

      photos.add(p);
    }

    AppNavigator.pushNextPage(
      state.context,
      BioScreen(
        courseModel: courseModel,
        bio: tModel.biography,
        cardNumber: '',
        images: photos,
      ),
      name: BioScreen.screenName,
    );
  }

  void resetRequest(){
    trainerList.clear();

    requestTrainerInfo();
  }

  void requestTrainerInfo() async {
    FocusHelper.hideKeyboardByUnFocusRoot();

    final js = <String, dynamic>{};
    js[Keys.request] = 'SearchTrainerForUser';
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
          final c = TrainerBioModel.fromMap(m, domain: domain);
          trainerList.add(c);
        }
      }

      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    };

    state.stateController.mainStateAndUpdate(StateXController.state$normal);
    commonRequester.request(state.context);
  }
}
