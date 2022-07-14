import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:animate_do/animate_do.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/api/helpers/pathHelper.dart';
import 'package:iris_tools/widgets/optionsRow/radioRow.dart';
import 'package:iris_tools/modules/stateManagers/refresh.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/managers/pupilCourseManager.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/models/dataModels/usersModels/healthConditionModel.dart';
import '/models/dataModels/usersModels/jobActivityModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/coursePart/courseShop/courseShopScreen.dart';
import '/screens/coursePart/courseShop/questions/questionsScreen.dart';
import '/system/extensions.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appManager.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';

class QuestionsScreenCtr implements ViewController {
  late QuestionsScreenState state;
  late Requester commonRequester;
  late UserModel user;
  late CourseQuestionModel questionsModel;


  @override
  void onInitState<E extends State>(E state){
    this.state = state as QuestionsScreenState;

    commonRequester = Requester();

    user = Session.getLastLoginUser()!;
    questionsModel = CourseQuestionModel.fromUser(user);
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
    if(state is QuestionsScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  void onStepsComplete(){
    final kv = state.tAsMap('goalOfBuyCourse');
    final vController = RefreshController();
    var gv = '';
    late AnimationController animController;

    Widget mapFn(MapEntry<String, dynamic> me){
      return RadioRow(
          description: Text('${me.value}'),
          groupValue: gv,
          value: me.key,
          onChanged: (v){
            gv = v;
            vController.update();
          }
      );
    }

    final view = Padding(padding: EdgeInsets.all(5),
      child: Refresh(
        controller: vController,
        builder: (ctx, ctr){
          return Flash(
            animate: false,
            manualTrigger: false,
            controller: (AnimationController c){
              animController = c;
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${state.tInMap('courseBuyQuestionPage', 'whatYourGoalOfBuy')}').bold(),
                ...kv!.entries.map(mapFn).toList(),
              ],
            ),
          );
        },
      ),);

    void yesFn(){
      if(gv.isEmpty){
        animController.reset();
        animController.forward();
        return;
      }

      questionsModel.goalOfBuy = gv;
      AppNavigator.pop(state.context);
      requestBuyCourse();
    }

    void noFn(){
      AppNavigator.pop(state.context);
    }

    DialogCenter().showYesNoDialog(state.context,
      descView: view,
      yesFn: yesFn,
      noFn: noFn,
      dismissOnButtons: false,
      yesText: state.t('buy'),
      noText: state.t('back'));
  }

  void requestBuyCourse() async {
    FocusHelper.hideKeyboardByUnFocusRoot();
    final cm = state.widget.courseModel;

    final js = <String, dynamic>{};
    js[Keys.request] = 'BuyACourse';
    js[Keys.requesterId] = user.userId;
    js[Keys.forUserId] = user.userId;
    js['course_id'] = cm.id;
    js['trainer_id'] = cm.creatorUserId;
    js['question_js'] = questionsModel.toMap();

    final partNames = <String>[];

    for(var p in questionsModel.experimentPhotos) {
      partNames.add(p.id);
      commonRequester.httpItem.addBodyFile(p.id, PathHelper.getFileName(p.localPath!), File(p.localPath!));
    }

    for(var p in questionsModel.bodyPhotos) {
      partNames.add(p.id);
      commonRequester.httpItem.addBodyFile(p.id, PathHelper.getFileName(p.localPath!), File(p.localPath!));
    }

    for(var p in questionsModel.bodyAnalysisPhotos) {
      partNames.add(p.id);
      commonRequester.httpItem.addBodyFile(p.id, PathHelper.getFileName(p.localPath!), File(p.localPath!));
    }

    if(questionsModel.cardPhoto != null){
      final p = questionsModel.cardPhoto!;
      partNames.add(p.id);
      commonRequester.httpItem.addBodyFile(p.id, PathHelper.getFileName(p.localPath!), File(p.localPath!));
    }

    js['part_names'] = partNames;
    AppManager.addAppInfo(js);
    commonRequester.httpItem.addBodyField(Keys.jsonHttpPart, JsonHelper.mapToJson(js));
    commonRequester.requestPath = RequestPath.SetData;

    commonRequester.httpRequestEvents.onFailState = (req) async {
      await state.hideLoading();
      await SheetCenter.showSheet$OperationFailed(state.context);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
     await state.hideLoading();

      user.jobActivityModel.matchBy(JobActivityModel.fromMap(js['question_js']));
      user.healthConditionModel.matchBy(HealthConditionModel.fromMap(js['question_js']));
      user.sportEquipmentModel.gymTools = js['question_js']['gym_tools_description'];
      user.sportEquipmentModel.homeTools = js['question_js']['home_tools_description'];
      user.birthDate = questionsModel.birthdate;
      user.sex = questionsModel.sex;
      user.fitnessDataModel.setHeight(questionsModel.height);
      user.fitnessDataModel.setWeight(questionsModel.weight);

      // ignore: unawaited_futures
      Session.sinkUserInfo(user);

      void yesFn(){
        final cm = PupilCourseManager.managerFor(user.userId);
        //cm.addItem(state.widget.courseModel);
        cm.addRequestedId(state.widget.courseModel.id);

        //close dialog
        AppNavigator.pop(state.context);
        // todo must a notifie call for restart
        AppNavigator.popRoutesUntilPageName(state.context, CourseShopScreen.screenName);
      }

      final view = Padding(padding: EdgeInsets.all(5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${state.tInMap('courseBuyQuestionPage', 'yourRequestRegisterWaitFor')}').bold(),
          ],
        ),
      );

      await DialogCenter().showDialog(
          state.context,
          descView: view,
          yesFn: yesFn,
          dismissOnButtons: false,
          title: '${state.tInMap('courseBuyQuestionPage', 'dearUser')}',
          yesText: state.t('ok'));
    };

    state.showLoading();
    commonRequester.request(state.context);
  }
}
