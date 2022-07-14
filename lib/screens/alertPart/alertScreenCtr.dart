import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/database/models/notifierModelDb.dart';
import '/managers/userNotifierManager.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/alertPart/alertScreen.dart';
import '/screens/loginPart/loginScreen.dart';
import '/system/icons.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/broadcastCenter.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/sheetCenter.dart';

class AlertScreenCtr extends ViewController {
  late AlertScreenState state;
  UserModel? user;
  UserNotifierManager? notifierManager;

  @override
  void onInitState<E extends State>(covariant E state) {
    this.state = state as AlertScreenState;

    Session.addLoginListener(onNewLogin);
    Session.addLogoffListener(onLogoff);

    if(Session.hasAnyLogin()){
      userActions(Session.getLastLoginUser()!);
    }
  }

  @override
  void onBuild() {
  }

  @override
  void onDispose() {
    Session.removeLoginListener(onNewLogin);
    Session.removeLogoffListener(onLogoff);
    BroadcastCenter.newNotifyNotifier.removeListener(onNewNotifier);
  }

  void onNewLogin(UserModel user){
    userActions(user);

    state.stateController.updateMain();
  }

  void onLogoff(UserModel user){
    this.user = null;
    notifierManager = null;
    BroadcastCenter.newNotifyNotifier.removeListener(onNewNotifier);

    state.stateController.updateMain();
  }

  void onNewNotifier(){
    notifierManager?.fetchUserNotifiers();
    notifierManager?.sortList(false);

    state.stateController.updateMain();
  }

  void userActions(UserModel user){
    this.user = user;
    notifierManager = UserNotifierManager.managerFor(user.userId);

    BroadcastCenter.newNotifyNotifier.addListener(onNewNotifier);
    notifierManager!.fetchUserNotifiers();
    notifierManager?.sortList(false);

    state.addPostOrCall(() {
      requestNotifiers();
    });
  }
  ///=============================================================================================
  void tryAgain(State state){
    if(state is AlertScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
      requestNotifiers();
    }
  }

  void tryLogin(State state){
    if(state is AlertScreenState) {
      AppNavigator.pushNextPage(state.context, LoginScreen(), name: LoginScreen.screenName);
    }
  }

  void showItemMenu(NotifierModelDb model){
    final items = <Map>[];

    items.add({
      'title': '${state.t('delete')}',
      'icon': IconList.delete,
      'fn': (){
        yesFn(){
          AppNavigator.pop(state.context);
          deleteNotifier(model);
        }

        DialogCenter().showYesNoDialog(
            state.context,
            yesFn: yesFn,
            desc: state.t('wantToDeleteThisItem'));
      }
    });


    Widget genView(elm){
      return ListTile(
        title: Text(elm['title']),
        leading: Icon(elm['icon']),
        onTap: (){
          SheetCenter.closeSheetByName(state.context, 'itemMenu');
          elm['fn']?.call();
        },
      );
    }

    SheetCenter.showSheetMenu(state.context, items.map(genView).toList(), 'itemMenu');
  }

  void deleteNotifier(NotifierModelDb model) async {
    final res = await notifierManager?.requestDeleteNotifier(model);

    if(res != null && res){
      SheetCenter.showSheet$SuccessOperation(state.context);
    }
    else {
      SheetCenter.showSheet$OperationFailed(state.context);
    }
  }

  void requestNotifiers() async {
    FocusHelper.hideKeyboardByUnFocusRoot();
    final res = await notifierManager?.requestNotifiers();

    if(res != null && res){
      notifierManager?.sortList(false);
      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    }

    await notifierManager!.seenAndSaveAllNotifiers();
    BroadcastCenter.prepareBadgesAndRefresh();
    notifierManager!.requestSyncSeen();
  }
}
