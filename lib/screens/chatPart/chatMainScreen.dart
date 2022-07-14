import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/colorHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as pull;

import '/abstracts/stateBase.dart';
import '/screens/chatPart/chatMainScreenCtr.dart';
import '/screens/chatPart/listChildChat.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/views/messageViews/mustLoginView.dart';
import '/views/preWidgets.dart';

class ChatMainScreen extends StatefulWidget {
  static const screenName = 'ChatMainScreen';

  ChatMainScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChatMainScreenState();
  }
}
///=========================================================================================================
class ChatMainScreenState extends StateBase<ChatMainScreen> {
  StateXController stateController = StateXController();
  ChatMainScreenCtr controller = ChatMainScreenCtr();

  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    controller.onBuild();
    return getPage();
  }

  @override
  void dispose() {
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  Widget getPage() {
    return SizedBox(
      width: AppSizes.getScreenWidth(context),
      height: AppSizes.getScreenHeight(context),
      child: SafeArea(
          child: StateX(
              isMain: true,
              controller: stateController,
              builder: (context, ctr, data) {
              return getMainBuilder();
            }
          )
      ),
    );
  }

  Widget getMainBuilder() {
    return StateX(
        isSubMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
          return Builder(
            builder: (context) {
              if(controller.user == null){
                return MustLoginView(this);
              }

              switch(ctr.mainState){
                case StateXController.state$loading:
                  return PreWidgets.flutterLoadingWidget$Center();
              }

              return getBody();
            },
          );
        }
    );
  }

  PreferredSizeWidget getAppbar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: StateX(
          controller: stateController,
          id: 'appBar',
          chainToMain: true,
          builder: (ctx, ctr, data) {
            return AppBar(
              title: Text('${tInMap('drawerMenu', 'contactUs')}'),
              actions: [
                Builder(
                    builder: (ctx){
                      if(controller.chatManager?.allChatList.isEmpty?? true){
                        return SizedBox();
                      }

                      return IconButton(
                        onPressed: (){
                          controller.openNewChat();
                        },
                        //label: Text('${tInMap('supportPage', 'new')}'),
                        icon: Icon(IconList.add),
                      );
                    })
              ],
            );
          }
      ),
    );
  }

  getBody() {
    if(controller.chatManager!.allChatList.isEmpty){
      return welcomeFrame();
    }

    return getPull();
  }
  ///=======================================================================================================
  Widget welcomeFrame(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Card(
            color: ColorHelper.highLightMore(AppThemes.currentTheme.primaryColor),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${tInMap('chatPage', 'firstDialog')}',
                textAlign: TextAlign.center,).bold().fsR(2).color(Colors.white),
            ),
          ),
        ),
        SizedBox(height: 12,),
      ],
    );
  }

  Widget getPull() {
    return pull.RefreshConfiguration(
        headerBuilder: pullHeader,
        footerBuilder: () => pull.ClassicFooter(),
        headerTriggerDistance: 80.0,
        footerTriggerDistance: 200.0,
        maxOverScrollExtent: 100,
        maxUnderScrollExtent: 0,
        enableScrollWhenRefreshCompleted: true,
        // incompatible with PageView and TabBarView.
        enableLoadingWhenFailed: true,
        hideFooterWhenNotFull: true,
        enableBallisticLoad: false,
        enableBallisticRefresh: false,
        skipCanRefresh: true,
        child: pull.SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          controller: controller.pullLoadCtr,
          onRefresh: () => controller.onRefresh(),
          onLoading: () => controller.onLoadMore(),
          footer: pullFooter(),
          child: ListView.builder(
            itemCount: controller.chatManager!.allChatList.length,
            itemBuilder: (ctx, idx) {
              var itm = controller.chatManager!.allChatList[idx];
              return ListChildChat(chatModel: itm, key: ValueKey(itm.id),);
            },
          ),
        ));
  }

  Widget pullHeader(){
    return pull.MaterialClassicHeader(
      color: AppThemes.checkPrimaryByWB(AppThemes.currentTheme.primaryColor, AppThemes.currentTheme.differentColor),
      //refreshStyle: pull.RefreshStyle.Follow,
    );
  }

  Widget pullFooter(){
    return pull.CustomFooter(
      loadStyle: pull.LoadStyle.ShowWhenLoading,
      builder: (BuildContext context, pull.LoadStatus? state) {
        if (state == pull.LoadStatus.loading) {
          return SizedBox(
            height: 80,
            child: PreWidgets.flutterLoadingWidget$Center(),
          );
        }

        if (state == pull.LoadStatus.noMore || state == pull.LoadStatus.idle) {
          return SizedBox();
        }

        return SizedBox();
      },
    );
  }
}

