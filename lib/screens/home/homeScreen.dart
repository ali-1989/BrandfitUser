import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:iris_tools/api/helpers/colorHelper.dart';
import 'package:iris_tools/modules/propertyNotifier/propertyChangeConsumer.dart';
import 'package:iris_tools/widgets/drawer/stackDrawer.dart';
import 'package:iris_tools/widgets/shadow.dart';
import 'package:iris_tools/modules/stateManagers/refresh.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/constants.dart';
import '/managers/fontManager.dart';
import '/managers/settingsManager.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/alertPart/alertScreen.dart';
import '/screens/centerPagePart/centerPageScreen.dart';
import '/screens/chatPart/chatMainScreen.dart';
import '/screens/coursePart/courseScreen.dart';
import '/screens/drawerMenu.dart';
import '/screens/fitnessPart/statusScreen.dart';
import '/screens/home/homeScreenCtr.dart';
import '/screens/profile/mainProfileScreen.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/broadcastCenter.dart';
import '/tools/centers/dialogCenter.dart';

class HomeScreen extends StatefulWidget {
  static const screenName = '/home_page';

  HomeScreen({Key? key}) :super(key: key);

  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }
}
///====================================================================================================
class HomeScreenState extends StateBase<HomeScreen> with TickerProviderStateMixin {
  StateXController stateController = StateXController();
  HomeScreenCtr controller = HomeScreenCtr();
  PageController pageViewController = PageController(initialPage: SettingsManager.homePageIndex, keepPage: true);
  RefreshController navBarRefresher = RefreshController();
  late AnimationController menuButtonAnimController;
  String drawerName = 'homePage';

  HomeScreenState();

  @override
  void initState() {
    super.initState();

    menuButtonAnimController =
        AnimationController(vsync: this, duration: Duration(milliseconds: SettingsManager.drawerMenuTimeMill));

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
    menuButtonAnimController.dispose();
    pageViewController.dispose();
    navBarRefresher.dispose();
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  /*@override no need
  void onBackButton<s extends StateBase>(s state, {dynamic result}) {
    SystemNavigator.pop();
  }*/

  @override
  Future<bool> onWillBack<s extends StateBase>(s state) {
    //old: state.scaffoldKey.currentState
    if(DrawerStacks.isOpen(drawerName)){
      //old: Navigator.of(state.context).pop();
      controller.toggleDrawer();
      return Future<bool>.value(false);
    }

    if(SettingsManager.settingsModel.confirmOnExit) {
      return DialogCenter().showDialog$wantClose(context);
    }
    else {
      return Future<bool>.value(true);
    }
    //SystemNavigator.pop();   this is close app
  }

  Widget getScaffold() {
    return WillPopScope(
        onWillPop: () => onWillBack(this),
        child: StateX(
          isMain: true,
            controller: stateController,
            builder: (ctx, ctr, data) {
              return DrawerStack(
                name: drawerName,
                factor: 220,
                gestureThreshold: 10,
                backgroundColor: Colors.grey[800],
                rtlDirection: AppThemes.isRtlDirection(),
                drawer: getDrawerView(),
                body: Scaffold(
                  key: scaffoldKey,
                  appBar: getAppBar(),
                  body: getBody(),
                  //drawer: getDrawer(state),
                  drawerEdgeDragWidth: 20.0,
                  drawerDragStartBehavior: DragStartBehavior.start,
                  bottomNavigationBar: getBottomNavigation(),
                ),

                onStartOpen: (){
                  menuButtonAnimController.forward();
                },

                onStartClose: (){
                  menuButtonAnimController.reverse();
                },
              );
            })
    );
  }

  PreferredSizeWidget getAppBar() {
    return AppBar(
      primary: true,//if false : unUse status bar height padding.
      title: Text(getPagesName(context, SettingsManager.homePageIndex)),
      automaticallyImplyLeading: false, // false: remove (backBtn or drawer menu)

      leading: RotatedBox(
        quarterTurns: AppThemes.isRtlDirection()? 2:0,
        child: IconButton(
          icon: AnimatedIcon(
            textDirection: TextDirection.ltr,
            icon: AnimatedIcons.menu_arrow,
            progress: menuButtonAnimController,
          ),
          onPressed: (){
            controller.toggleDrawer();
          },),
      ),

      actions: <Widget>[
        if(Session.hasAnyLogin())
          GestureDetector(
            onTap: (){
              AppNavigator.pushNextPage(context, UserProfileScreen(), name: UserProfileScreen.screenName);
            },
            child: SizedBox(
              width: 34, height: 34,
              child: PropertyChangeConsumer<UserModel, UserModelNotifierMode>(
                model: Session.getLastLoginUser()!,
                onAnyInstance: true,
                properties: [UserModelNotifierMode.profilePath],
                builder: (context, model, properties){
                  if(model!.profileProvider != null && Session.hasAnyLogin()) {
                    return CircleAvatar(
                      backgroundImage: model.profileProvider,
                    );
                  }

                  return IconButton(
                    onPressed: (){
                      AppNavigator.pushNextPage(context, UserProfileScreen(), name: UserProfileScreen.screenName);
                    },
                    icon: Icon(IconList.accountDoubleCircle, size: 34,),
                    iconSize: 34,
                    padding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ),

        SizedBox(
          width: 20,
        ),
      ],
      //leading:
    );
  }

  Widget getDrawerView() {
    return SizedBox(
      width: 250,
      child: DrawerMenuTool.getDrawerMenu(context, controller.onDrawerMenuClick),
    );
  }

  Widget getBody() {
    return PageView.builder(
      reverse: false,
      pageSnapping: false,
      controller: pageViewController,
      scrollDirection: Axis.horizontal,
      dragStartBehavior: DragStartBehavior.start,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (ctx, idx) {
        return generatePages(ctx, idx);
      },
    );
  }

  Widget getBottomNavigation() {
    return Refresh(
        controller: navBarRefresher,
        builder: (ctx, controller) {
          return ShadowBox(
            shadowColor: AppThemes.themeData.appBarTheme.shadowColor!,
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: AppThemes.subFont.family,
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: ConvexAppBar.badge(
                  getBadge(),
                  key: GlobalKey(),
                  initialActiveIndex: SettingsManager.homePageIndex,
                  backgroundColor: AppThemes.currentTheme.primaryColor,
                  activeColor: AppThemes.currentTheme.whiteOrBlackOnPrimary(), // is circle color
                  color: AppThemes.currentTheme.whiteOrBlackOnPrimary(), // is Text color
                  badgeColor: AppThemes.currentTheme.badgeBackColor,
                  badgeTextColor: AppThemes.currentTheme.badgeTextColor,
                  badgeMargin: EdgeInsets.zero,
                  style: TabStyle.reactCircle,
                  badgePadding: EdgeInsets.fromLTRB(4,1,4,1),
                  badgeTextStyle: TextStyle(
                      color: AppThemes.currentTheme.badgeTextColor,
                      fontSize: 16,
                    fontFamily: FontManager.instance.getEnglishFont()?.family
                  ),
                  items: getNavItems(),
                  onTap: (idx){
                    SettingsManager.homePageIndex = idx;
                    pageViewController.jumpToPage(idx);
                    stateController.updateMain();
                  },
                ),
              ),
            ),
          );
        }
    );
  }

  Map<int, dynamic> getBadge() {
    final res = <int, dynamic>{};
    // res[1] = AppThemes.currentTheme.badgeBackColor

    if((BroadcastCenter.homePageBadges[0]?? 0) > 0){
      res[0] = '${BroadcastCenter.homePageBadges[0]}';
    }

    return res;
  }

  List<TabItem> getNavItems(){
    final res = <TabItem>[];
    final iconColor = ColorHelper.getUnNearColor(AppThemes.currentTheme.whiteOrBlackOnPrimary(),
        AppThemes.currentTheme.primaryColor,
        Colors.grey[900]!);

    final setting = TabItem(
        icon: Icon(IconList.alertBell, size: 24, color: iconColor),
        activeIcon: Icon(IconList.alertBell, size: 24, color: AppThemes.currentTheme.primaryColor),
        title: getPagesName(context, 0));

    final dashboard = TabItem(
        icon: Icon(IconList.dumbbell, size: 24, color: iconColor),
        activeIcon: Icon(IconList.dumbbell, size: 24, color: AppThemes.currentTheme.primaryColor),
        title: getPagesName(context, 1));

    final home = TabItem(
        icon: Icon(IconList.home, size: 24, color: iconColor),
        activeIcon: Icon(IconList.home, size: 24, color: AppThemes.currentTheme.primaryColor),
        title: getPagesName(context, 2));

    final profile = TabItem(
        icon: Icon(IconList.heartPulse, size: 24, color: iconColor),
        activeIcon: Icon(IconList.heartCircleOutline, size: 24, color: AppThemes.currentTheme.primaryColor),
        title: getPagesName(context, 3));

    final chat = TabItem(
        icon: Icon(IconList.message, size: 24, color: iconColor),
        activeIcon: Icon(IconList.message, size: 24, color: AppThemes.currentTheme.primaryColor),
        title: getPagesName(context, 4));

    res.add(setting);
    res.add(dashboard);
    res.add(home);
    res.add(profile);
    res.add(chat);

    return res;
  }
  ///==========================================================================================================
  Widget generatePages(BuildContext ctx, int idx){
    switch(idx){
      case 0:
        return AlertScreen();
      case 1:
        return CourseScreen();
      case 2:
        return CenterPageScreen(key: BroadcastCenter.centerPageScreenKey,);
      case 3:
        return StatusScreen();
      case 4:
        return ChatMainScreen();
      default:
        return Center(child: Text('not defined'),);
    }
  }

  String getPagesName(BuildContext ctx, int idx){
    switch(idx){
      case 0:
        return ctx.tInMap('navNames', 'alert')!;
      case 1:
        return ctx.tInMap('navNames', 'myCourses')!;
      case 2:
        return ctx.tC('home')!;
      case 3:
        return ctx.tInMap('navNames', 'myStatus')!;
      case 4:
        return ctx.tC('chat')!;
      default:
        return Constants.appTitle;
    }
  }
}


