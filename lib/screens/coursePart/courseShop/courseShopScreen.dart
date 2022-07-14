import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/widgets/searchBar.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/screens/coursePart/courseShop/courseShopScreenCtr.dart';
import '/system/extensions.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/currencyTools.dart';
import '/views/messageViews/mustLoginView.dart';
import '/views/messageViews/notDataFoundView.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

class CourseShopScreen extends StatefulWidget {
  static const screenName = 'CourseShopScreen';

  CourseShopScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CourseShopScreenState();
  }
}
///=====================================================================================
class CourseShopScreenState extends StateBase<CourseShopScreen> {
  StateXController stateController = StateXController();
  CourseShopScreenCtr controller = CourseShopScreenCtr();

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

  @override
  Future<bool> onWillBack<S extends StateBase>(S state){
    if(controller.requestCountOnLunch != controller.courseManager.myRequestedList.length){
      AppNavigator.pop(context, result: true);
      return Future.value(false);
    }

    return Future.value(true);
  }

  Widget getScaffold() {
    return WillPopScope(
      onWillPop: () => onWillBack(this),
      child: SizedBox(
        width: AppSizes.getScreenWidth(context),
        height: AppSizes.getScreenHeight(context),
        child: Scaffold(
          key: scaffoldKey,
          appBar: getAppbar(),
          body: getMainBuilder(),
        ),
      ),
    );
  }

  PreferredSizeWidget getAppbar() {
    return AppBar(
      title: Text(tInMap('coursePage', 'ourCourses')!),
    );
  }

  Widget getMainBuilder() {
    return StateX(
      isMain: true,
      controller: stateController,
      builder: (context, ctr, data) {
        if(controller.user == null) {
          return MustLoginView(this, loginFn: controller.tryLogin,);
        }

        switch(ctr.mainState){
          case StateXController.state$loading:
            return PreWidgets.flutterLoadingWidget$Center();
          case StateXController.state$serverNotResponse:
          case StateXController.state$netDisconnect:
            return ServerResponseWrongView(this, tryAgain: controller.tryAgain);
          default:
            return getBody();
        }
      },
    );
  }

  Widget getBody() {
    return StateX(
      isSubMain: true,
      controller: stateController,
      builder: (context, ctr, data) {
        return Column(
          children: [
            gerSearchBar(),

            Expanded(
              child: getListview(),
            )
          ],
        );
      }
    );
  }
  ///========================================================================================================
  Widget gerSearchBar(){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: SearchBar(
        iconColor: AppThemes.checkPrimaryByWB(AppThemes.currentTheme.primaryColor, AppThemes.currentTheme.textColor),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        hint: tInMap('optionsKeys', controller.filterRequest.getSearchSelectedForce().key)?? '',
        shareTextController: (c){
          controller.searchEditController = c;
        },
        searchEvent: (text){
          if(controller.filterRequest.setTextToSelectedSearch(text)) {
            controller.resetRequest();
          }
        },
        onClearEvent: (){
          if(controller.filterRequest.setTextToSelectedSearch(null)) {
            controller.resetRequest();
          }
        },
      ),
    );
  }

  Widget getListview(){
    //if(controller.courseManager.courseShopList.isEmpty) {
    if(controller.shopList.isEmpty) {
      if(controller.searchEditController?.text.isEmpty?? true){
        return NotDataFoundView(
          message: tInMap('coursePage', 'enterTrainerUserName'),
        );
      }

      return NotDataFoundView();
    }

    return ListView.builder(
      itemCount: controller.shopList.length,
      itemBuilder: (ctx, idx){
        return genListItem(idx);
      },
    );
  }

  Widget genListItem(int idx){
    //final course = controller.courseManager.courseShopList[idx];
    final course = controller.shopList[idx];

    return Card(
      key: ValueKey(course.id),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: (){
          controller.gotoFullInfo(course);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 120,
                        maxWidth: 150,
                        minHeight: 120,
                        maxHeight: 200,
                      ),
                    child: AspectRatio(
                      aspectRatio: 16/10,
                      child: IrisImageView(
                        imagePath: course.imagePath,
                        url: course.imageUri,
                        beforeLoadWidget: Image.asset('assets/images/placeHolder.png'),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(width: 8,),

              Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title).boldFont().fsR(2),

                      SizedBox(height: 12,),
                      Text('${t('trainer')}: ${course.creatorUserName}')
                          .fsR(1).bold().alpha(),

                      SizedBox(height: 2,),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(CurrencyTools.formatCurrency(MathHelper.clearToInt(course.price)))
                              .alpha(),

                          SizedBox(width: 8,),
                          Text('${course.currencyModel.currencySymbol}')
                              .alpha(),
                        ],
                      ),

                      SizedBox(height: 2,),
                      Text('${course.durationDay} ${t('days')}')
                          .fsR(1).alpha(),
                    ],
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
