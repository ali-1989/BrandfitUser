import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as pull;

import '/abstracts/viewController.dart';
import '/managers/ticketManager.dart';
import '/managers/userAdvancedManager.dart';
import '/models/dataModels/ticketModels/ticketMessageModel.dart';
import '/models/dataModels/ticketModels/ticketModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/supportPart/chatPart/ticketChatScreen.dart';
import '/screens/supportPart/supportScreen.dart';
import '/system/extensions.dart';
import '/system/keys.dart';
import '/system/queryFiltering.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appNotification.dart';
import '/tools/centers/broadcastCenter.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/netListenerTools.dart';

class SupportScreenCtr implements ViewController {
  late SupportScreenState state;
  Requester? commonRequester;
  UserModel? user;
  TicketManager? ticketManager;
  late FilterRequest filterRequest;
  var pullLoadCtr = pull.RefreshController();

  @override
  void onInitState<E extends State>(E state){
    this.state = state as SupportScreenState;

    filterRequest = FilterRequest();
    filterRequest.limit = 200;

    commonRequester = Requester();

    if(Session.hasAnyLogin()){
      state.stateController.mainState = StateXController.state$loading;
      user = Session.getLastLoginUser();
      ticketManager = TicketManager.managerFor(user!.userId);

      NetListenerTools.addNetListener(onNetStatus);
      NetListenerTools.addWsListener(onWsStatus);

      BroadcastCenter.ticketUpdateNotifier.addListener(onTicketUpdate);
      BroadcastCenter.ticketMessageUpdateNotifier.addListener(onMessageUpdate);

      fetchTickets().then((value) {
        state.stateController.mainStateAndUpdate(StateXController.state$normal);

        if (BroadcastCenter.isNetConnected) {
          requestUserTopTickets();
          TicketManager.startSendFailedTimer();
        }  
      });

      AppNotification.dismissById(BroadcastCenter.newTicketNotificationId);
    }
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester?.httpRequester);
    NetListenerTools.removeNetListener(onNetStatus);
    NetListenerTools.removeWsListener(onWsStatus);
    BroadcastCenter.ticketUpdateNotifier.removeListener(onTicketUpdate);
    BroadcastCenter.ticketMessageUpdateNotifier.removeListener(onMessageUpdate);
  }

  void onNetStatus(ConnectivityResult cr){
    if(cr != ConnectivityResult.none) {
      requestUserTopTickets();
    }
  }

  void onWsStatus(bool connected){
    if(connected) {
      requestUserTopTickets();
    }
  }

  void onTicketUpdate(){
    //TicketModel? ticket = Broadcast.ticketUpdateNotifier.value;
    state.stateController.updateMain();
  }

  void onMessageUpdate(){
    state.stateController.updateMain();
  }
  ///========================================================================================================
  void tryAgain(State state){
  }

  void openNewTicket(){
    var title = '';
    final view = Text('${state.tInMap('supportPage', 'selectTitle')}')
        .boldFont().fsR(1);

    final fu = DialogCenter().showTextInputDialog(
        state.context,
        descView: view,
        yesText: state.tInMap('supportPage', 'startChat'),
        noText: state.t('cancel'),
        yesFn: (txt){
          title = txt.trim();

          if(title.isNotEmpty){
            AppNavigator.pop(state.context);
          }
        },
        noFn: (){
        AppNavigator.pop(state.context);
      },
    );

    fu.then((value) {
      if(title.isEmpty){
        return;
      }

      final ticketModel = ticketManager!.generateDraftTicket(user!, title);

      gotoChat(ticketModel);

      state.stateController.updateMain();
    });
  }

  void gotoChat(TicketModel ticketModel){
    AppNavigator.pushNextPage(
        state.context,
        TicketChatScreen(ticket: ticketModel),
        name: TicketChatScreen.screenName
    );
  }

  void onRefresh() async {
    ticketManager?.allTicketList.clear();

    fetchTickets().then((value){
      if(BroadcastCenter.isNetConnected) {
        requestUserTopTickets();
      }
      else {
        pullLoadCtr.refreshToIdle();
      }
    });
  }

  Future<void> onLoadMore() async {
    final lastCase = ticketManager!.findTicketLittleTs();

    return fetchTickets(lastTs: lastCase).then((value) {
      if(BroadcastCenter.isNetConnected){
        requestMoreTickets();
      }
      else {
        if(value < filterRequest.limit){
          pullLoadCtr.loadNoData();
        }
        else {
          pullLoadCtr.loadComplete();
        }

        state.stateController.updateMain();
      }
    });
  }

  void resetRequest(){
    ticketManager!.allTicketList.clear();
    pullLoadCtr.resetNoData();

    if(BroadcastCenter.isNetConnected){
      requestUserTopTickets();
    }
    else {
      fetchTickets().then((value) {
        if(value < filterRequest.limit){
          pullLoadCtr.loadNoData();
        }
        else {
          pullLoadCtr.loadComplete();
        }

        state.stateController.updateMain();
      });
    }
  }

  Future<int> fetchTickets({String? lastTs}) async {
    final ticketIds = await ticketManager!.fetchTickets();

    if(ticketIds.isEmpty){
      return 0;
    }

    var messageIds = await TicketManager.fetchTicketMessageByTicketIds(ticketIds);

    var mediaIds = TicketManager.takeMediaIdsByMessageIds(messageIds);
    await TicketManager.fetchMediaMessageByIds(mediaIds);

    var userIds = TicketManager.takeUserIdsByMessageIds(messageIds);
    await UserAdvancedManager.loadByIds(userIds);

    ticketManager!.sortList(false);

    return ticketIds.length;
  }

  void requestUserTopTickets() async {
    FocusHelper.hideKeyboardByUnFocusRoot();

    final res = await ticketManager!.requestUserTopTickets();

    if(res){
      BroadcastCenter.ticketMessageUpdateNotifier.value = TicketMessageModel();
    }
    else {
      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    }

    if(pullLoadCtr.isRefresh) {
      pullLoadCtr.refreshToIdle();
    }
    else {
      int l = ticketManager?.allTicketList.length?? 0;

      if(l < filterRequest.limit) {
        pullLoadCtr.loadNoData();
      }
      else {
        pullLoadCtr.loadComplete();
      }
    }
  }

  void requestMoreTickets() async {
    FocusHelper.hideKeyboardByUnFocusRoot();
    filterRequest.lastCase = ticketManager!.findTicketLittleId();//ticketManager!.findTicketLittleTs();
//todo lastCase
    Map<String, dynamic> js = {};
    js[Keys.request] = 'GetTicketsForUser';
    js[Keys.userId] = user!.userId;
    js[Keys.filtering] = filterRequest.toMap();

    commonRequester?.bodyJson = js;
    commonRequester?.requestPath = RequestPath.GetData;

    commonRequester?.httpRequestEvents.onFailState = (req) async {
      if(pullLoadCtr.isRefresh) {
        pullLoadCtr.refreshFailed();
      }
      else {
        pullLoadCtr.loadFailed();
      }
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      List? ticketMap = data['ticket_list'];
      List? messageMap = data['message_list'];
      List? mediaMap = data['media_list'];
      List? userList = data['user_list'];
      var domain = data[Keys.domain];

      if(pullLoadCtr.isRefresh) {
        pullLoadCtr.refreshToIdle();
      }
      else {
        int l = ticketMap?.length?? 0;

        if(l < filterRequest.limit) {
          pullLoadCtr.loadNoData();
        }
        else {
          pullLoadCtr.loadComplete();
        }
      }

      var uList = UserAdvancedManager.addItemsFromMap(userList, domain: domain);
      UserAdvancedManager.sinkItems(uList);

      var mediaList = TicketManager.addMediaMessagesFromMap(mediaMap);
      var msgList = TicketManager.addTicketMessagesFromMap(messageMap);
      var ticketList = ticketManager!.addItemsFromMap(ticketMap);

      ticketManager!.sortList(false);

      TicketManager.sinkTicketMedia(mediaList);
      TicketManager.sinkTicketMessages(msgList);
      TicketManager.sinkTickets(ticketList);

      state.stateController.updateMain();
    };

    state.stateController.updateMain();
    commonRequester?.request(state.context);
  }
}
