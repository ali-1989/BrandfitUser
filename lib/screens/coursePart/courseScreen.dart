import 'package:flutter/material.dart';

import 'package:iris_tools/widgets/icon/circularIcon.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/screens/coursePart/courseScreenCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/views/messageViews/mustLoginView.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

class CourseScreen extends StatefulWidget {
  static const screenName = 'CourseScreen';

  CourseScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CourseScreenState();
  }
}
///=========================================================================================================
class CourseScreenState extends StateBase<CourseScreen> {
  var stateController = StateXController();
  var controller = CourseScreenCtr();

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

  getPage() {
    return SizedBox(
      width: AppSizes.getScreenWidth(context),
      height: AppSizes.getScreenHeight(context),

      child: StateX(
        isMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
          return Stack(
              fit: StackFit.expand,
              children: [
                Builder(
                  builder: (ctx){
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
                ),

                if(controller.courseManager.myRequestedList.isNotEmpty)
                Positioned(
                  bottom: 16,
                  right: 12,
                  child: CircularIcon(
                    backColor: AppThemes.currentTheme.fabBackColor,
                    itemColor: AppThemes.currentTheme.fabItemColor,
                    icon: Icons.add,
                    size: 40,
                    padding: 10,
                  ).wrapMaterial(
                      onTapDelay: (){
                        controller.gotoShopScreen();
                      }
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  getBody() {
    return StateX(
      isSubMain: true,
      controller: stateController,
      builder: (context, ctr, data) {
        if(controller.isInRequestState) {
          return PreWidgets.flutterLoadingWidget$Center();
        }

        if(controller.courseManager.myRequestedList.isEmpty) {
          return showCourseShop();
        }

        return ListView.builder(
          itemCount: controller.courseManager.myRequestedList.length,
            itemBuilder: (ctx, idx){
              return genListItem(idx);
            }
        );
      },
    );
  }
  ///==========================================================================================================
  Widget genListItem(int idx){
    var course = controller.courseManager.myRequestedList[idx];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: (){
          controller.gotoFullInfo(course);
        },
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(IconList.apps2, color: AppThemes.currentTheme.primaryColor,),
                  SizedBox(width: 8,),
                  Text(course.title).bold().fsR(3),
                ],
              ),

              SizedBox(height: 12,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${t('status')} : ${course.getStatusText(context)}')
                      .bold().color(course.getStatusColor()),

                  Visibility(
                    visible: course.isSendProgram,
                    child: ElevatedButton(
                        onPressed: (){
                          controller.gotoPrograms(course);
                        },
                        child: Text('${tInMap('coursePage', 'programs')}')
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget showCourseShop(){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${tJoin('thereIsNoCoursePleaseBuy')}',
            textAlign: TextAlign.center,).bold().fsR(3).alpha(alpha: 140),

          SizedBox(height: 22,),

          ElevatedButton(
            child: Text("${tInMap('coursePage', 'ourCourses')}"),
            style: ButtonStyle(
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 60))
            ),
            onPressed: (){
              controller.gotoShopScreen();
            },
          ),
        ],
      ),
    );
  }
}
