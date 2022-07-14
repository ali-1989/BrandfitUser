import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/colorHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as pull;

import '/abstracts/stateBase.dart';
import '/screens/supportPart/listChildTicket.dart';
import '/screens/supportPart/supportScreenCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appThemes.dart';
import '/views/messageViews/mustLoginView.dart';
import '/views/preWidgets.dart';

class SupportScreen extends StatefulWidget {
  static const screenName = 'SupportScreen';

  SupportScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SupportScreenState();
  }
}
///=======================================================================================================
class SupportScreenState extends StateBase<SupportScreen> with SingleTickerProviderStateMixin {
  var stateController = StateXController();
  var controller = SupportScreenCtr();

  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();
    controller.onBuild();

    return getScaffold();
  }

  @override
  void dispose() {
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  Widget getScaffold() {
    return WillPopScope(
      onWillPop: () => onWillBack(this),
      child: StateX(
          isMain: true,
          controller: stateController,
          builder: (context, ctr, data) {
            return Scaffold(
              key: scaffoldKey,
              appBar: getAppbar(),
              body: SafeArea(
                child: getMainBuilder(),
              ),
            );
        }
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
                  if(controller.ticketManager?.allTicketList.isEmpty?? true){
                    return SizedBox();
                  }

                  return IconButton(
                    onPressed: (){
                      controller.openNewTicket();
                    },
                    //label: Text('${tInMap('supportPage', 'newTicket')}'),
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
    if(controller.ticketManager!.allTicketList.isEmpty){
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
              child: Text('${tInMap('supportPage', 'firstDialog')}',
                textAlign: TextAlign.center,).bold().fsR(2).color(Colors.white),
            ),
          ),
        ),
        SizedBox(height: 12,),
        TextButton(onPressed: (){
          controller.openNewTicket();
        },
            child: Text('${t('start')}').bold().fsR(4).color(Colors.blue)
        ),
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
            itemCount: controller.ticketManager!.allTicketList.length,
            itemBuilder: (ctx, idx) {
              var itm = controller.ticketManager!.allTicketList[idx];
              return ListChildTicket(ticketModel: itm, key: ValueKey(itm.id),);
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
