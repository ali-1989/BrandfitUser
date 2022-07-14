import 'package:flutter/material.dart';

import '/abstracts/viewController.dart';
import '/managers/foodProgramManager.dart';
import '/models/dataModels/courseModels/pupilCourseModel.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/programViewPart/programViewScreen.dart';
import '/screens/programViewPart/treeScreen/treeScreen.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/httpCenter.dart';

class ProgramViewCtr implements ViewController {
  late ProgramViewScreenState state;
  late PupilCourseModel pupilCourseModel;
  late UserModel user;
  late Requester commonRequester;
  late FoodProgramManager foodManager;
  late List<FoodProgramModel> programList = [];

  @override
  void onInitState<E extends State>(E state){
    this.state = state as ProgramViewScreenState;

    user = Session.getLastLoginUser()!;
    commonRequester = Requester();
    pupilCourseModel = state.widget.pupilCourseModel;

    foodManager = FoodProgramManager.managerFor(user.userId);
    programList = foodManager.allModelList.where((element) => element.requestId == pupilCourseModel.requestId).toList();
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

  void gotoTreeView(FoodProgramModel program){
    AppNavigator.pushNextPage(
        state.context,
        TreeFoodProgramScreen(
          pupilCourseModel: state.widget.pupilCourseModel,
          pupilUser: user,
          programModel: program,
        ),
        name: TreeFoodProgramScreen.screenName
    );
  }
}
