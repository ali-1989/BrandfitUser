import 'package:flutter/material.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as pull;

import '/abstracts/viewController.dart';
import '/managers/chatManager.dart';
import '/managers/userAdvancedManager.dart';
import '/models/dataModels/chatModels/chatMessageModel.dart';
import '/models/dataModels/chatModels/chatModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/chatPart/chatMainScreen.dart';
import '/screens/chatPart/chatScreenPart/chatScreen.dart';
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

class ChatMainScreenCtr implements ViewController {
  late ChatMainScreenState state;
  Requester? commonRequester;
  UserModel? user;
  ChatManager? chatManager;
  late FilterRequest filterRequest;
  var pullLoadCtr = pull.RefreshController();


  @override
  void onInitState<E extends State>(E state){
    this.state = state as ChatMainScreenState;

    filterRequest = FilterRequest();
    filterRequest.limit = 200;

    commonRequester = Requester();
    Session.addLoginListener(onLoginLogoff);
    Session.addLogoffListener(onLoginLogoff);

    if(Session.hasAnyLogin()){
      state.stateController.mainState = StateXController.state$loading;
      user = Session.getLastLoginUser();
      chatManager = ChatManager.managerFor(user!.userId);

      NetListenerTools.addNetListener(onNetStatus);
      NetListenerTools.addWsListener(onWsStatus);

      BroadcastCenter.chatUpdateNotifier.addListener(onChatUpdate);
      BroadcastCenter.chatMessageUpdateNotifier.addListener(onMessageUpdate);

      fetchChats().then((value) {
        state.stateController.mainStateAndUpdate(StateXController.state$normal);

        if (BroadcastCenter.isNetConnected) {
          requestUserTopChats();
          ChatManager.startSendFailedTimer();
        }
      });

      AppNotification.dismissById(BroadcastCenter.newChatNotificationId);
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
    BroadcastCenter.chatUpdateNotifier.removeListener(onChatUpdate);
    BroadcastCenter.chatMessageUpdateNotifier.removeListener(onMessageUpdate);
    Session.removeLoginListener(onLoginLogoff);
    Session.removeLogoffListener(onLoginLogoff);
  }

  void onLoginLogoff(UserModel user){
    state.stateController.updateMain();
  }

  void onNetStatus(ConnectivityResult cr){
    if(cr != ConnectivityResult.none) {
      requestUserTopChats();
    }
  }

  void onWsStatus(bool connected){
    if(connected) {
      requestUserTopChats();
    }
  }

  void onChatUpdate(){
    //ChatModel? chat = Broadcast.chatUpdateNotifier.value;
    state.stateController.updateMain();
  }

  void onMessageUpdate(){
    state.stateController.updateMain();
  }
  ///========================================================================================================
  void tryAgain(State state){
  }

  void openNewChat(){
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

      final chatModel = chatManager!.generateDraftChat(user!);

      gotoChat(chatModel);

      state.stateController.updateMain();
    });
  }

  void gotoChat(ChatModel chatModel){
    AppNavigator.pushNextPage(
        state.context,
        ChatScreen(chat: chatModel),
        name: ChatScreen.screenName
    );
  }

  void hideRefreshLoader(){
    pullLoadCtr.refreshToIdle();
  }

  void onRefresh() async {
    chatManager?.allChatList.clear();

    fetchChats().then((value){
      if(BroadcastCenter.isNetConnected) {
        requestUserTopChats();
      }
      else {
        hideRefreshLoader();
      }
    });
  }

  Future<void> onLoadMore() async {
    final lastCase = chatManager!.findChatLittleTs();

    return fetchChats(lastTs: lastCase).then((value) {
      if(BroadcastCenter.isNetConnected){
        requestMoreChats();
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
    chatManager!.allChatList.clear();
    pullLoadCtr.resetNoData();

    if(BroadcastCenter.isNetConnected){
      requestUserTopChats();
    }
    else {
      fetchChats().then((value) {
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

  Future<int> fetchChats({String? lastTs}) async {
    final chatIds = await chatManager!.fetchChats();

    if(chatIds.isEmpty){
      return 0;
    }

    var messageIds = await ChatManager.fetchMessageByChatIds(chatIds);

    var mediaIds = ChatManager.takeMediaIdsByMessageIds(messageIds);
    await ChatManager.fetchMediaMessageByIds(mediaIds);

    var userIds = ChatManager.takeUserIdsByMessageIds(messageIds);
    await UserAdvancedManager.loadByIds(userIds);

    chatManager!.sortList(false);

    return chatIds.length;
  }

  void requestUserTopChats() async {
    FocusHelper.hideKeyboardByUnFocusRoot();
    final res = await chatManager!.requestUserTopChats();

    if(res){
      BroadcastCenter.chatMessageUpdateNotifier.value = ChatMessageModel();
    }
    else {
      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    }

    if(pullLoadCtr.isRefresh) {
      hideRefreshLoader();
    }
    else {
      int l = chatManager?.allChatList.length?? 0;

      if(l < filterRequest.limit) {
        pullLoadCtr.loadNoData();
      }
      else {
        pullLoadCtr.loadComplete();
      }
    }
  }

  void requestMoreChats() async {
    FocusHelper.hideKeyboardByUnFocusRoot();

    filterRequest.lastCase = chatManager!.findChatLittleId();//ChatManager!.findChatLittleTs();

    final js = <String, dynamic>{};
    js[Keys.request] = 'GetChatsForUser';
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
      List? chatMap = data['chat_list'];
      List? messageMap = data['message_list'];
      List? mediaMap = data['media_list'];
      List? userList = data['user_list'];
      var domain = data[Keys.domain];

      if(pullLoadCtr.isRefresh) {
        hideRefreshLoader();
      }
      else {
        int l = chatMap?.length?? 0;

        if(l < filterRequest.limit) {
          pullLoadCtr.loadNoData();
        }
        else {
          pullLoadCtr.loadComplete();
        }
      }

      var uList = UserAdvancedManager.addItemsFromMap(userList, domain: domain);
      UserAdvancedManager.sinkItems(uList);

      var mediaList = ChatManager.addMediaMessagesFromMap(mediaMap);
      var msgList = ChatManager.addMessagesFromMap(messageMap);
      var chatList = chatManager!.addItemsFromMap(chatMap);

      chatManager!.sortList(false);

      ChatManager.sinkChatMedia(mediaList);
      ChatManager.sinkChatMessages(msgList);
      ChatManager.sinkChats(chatList);

      state.stateController.updateMain();
    };

    state.stateController.updateMain();
    commonRequester?.request(state.context);
  }
}
