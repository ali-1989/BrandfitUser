import 'package:flutter/material.dart';

import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/database/models/notifierModelDb.dart';
import '/screens/alertPart/alertScreenCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appThemes.dart';
import '/tools/dateTools.dart';
import '/views/messageViews/mustLoginView.dart';
import '/views/messageViews/notDataFoundView.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

class AlertScreen extends StatefulWidget {
  static const screenName = '/AlertScreen';

  AlertScreen({Key? key}) :super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AlertScreenState();
  }
}
///====================================================================================================
class AlertScreenState extends StateBase<AlertScreen> with TickerProviderStateMixin {
  StateXController stateController = StateXController();
  AlertScreenCtr controller = AlertScreenCtr();

  AlertScreenState();

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
    return StateX(
      isMain: true,
        controller: stateController,
        builder: (ctx, ctr, data) {
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
        });
  }

  Widget getBody() {
    return StateX(
      controller: stateController,
      isSubMain: true,
      builder: (context, ctr, data) {
        if(controller.notifierManager!.notifyList.isEmpty) {
          return NotDataFoundView();
        }

        return ListView.builder(
          itemCount: controller.notifierManager!.notifyList.length,
            itemBuilder: (ctx, idx){
              return genListItem(idx);
            },
        );
      }
    );
  }
  ///==========================================================================================================
  Widget genListItem(int idx){
    final notify = controller.notifierManager!.notifyList[idx];

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 0,
      color: AppThemes.currentTheme.primaryColor.withAlpha(100),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(notify.title).boldFont()
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(notify.registerDate != null? DateTools.dateAndHmRelative(notify.registerDate): ''),

                    SizedBox(width: 5,),
                    Icon(IconList.dotsVer,
                      size: 14,).wrapMaterial(
                      onTapDelay: (){
                        controller.showItemMenu(notify);
                      },
                      materialColor: Colors.grey.withAlpha(50),
                    ),
                  ],
                ),
              ],
            ),

            genInfoByType(notify),
          ],
        ),
      ),
    );
  }

  Widget genInfoByType(NotifierModelDb notify){
    if(notify.batch == NotifiersBatch.courseAnswer.name){
      return genForRequestAnswer(notify);
    }

    else if(notify.batch == NotifiersBatch.programs.name){
      return genForPrograms(notify);
    }

    return SizedBox();
  }

  Widget genForRequestAnswer(NotifierModelDb notify){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 5,),
        Row(
          children: [
            Flexible(
                child: Text('[${notify.descriptionJs!['trainer_name']}]')
                    .boldFont()
                    .subAlpha()
                    .oneLineOverflow$Start()
            ),

            SizedBox(width: 14,),
            Flexible(
                child: Text('${notify.descriptionJs!['course_name']}')
                    .boldFont().subAlpha().oneLineOverflow$Start()
            ),
          ],
        ),

        SizedBox(height: 5,),
        Visibility(
          visible: notify.descriptionJs!.containsKey('cause'),
            child: Row(
              children: [
                Flexible(
                  child: Text('${notify.descriptionJs!['cause']}')
                      .subAlpha(),
                ),
              ],
            )
        ),

        Builder(
          builder: (ctx){
            if(notify.descriptionJs!.containsKey('days')) {
              final days = notify.descriptionJs!['days'];
              final sendDate = notify.descriptionJs!['send_date'];

              var res = ctx.tInMap('alertPage', 'yourProgramSendDays')!;
              res = res.replaceFirst('#', '$days');
              res = res + ' (${DateTools.dateOnlyRelative$String(sendDate)})';

              return Row(
                children: [
                  Flexible(child: Text(res)
                      .subAlpha()),
                ],
              );
            }

            return SizedBox();
          },
        )
      ],
    );
  }

  Widget genForPrograms(NotifierModelDb notify){
    var exeTime = tInMap('alertPage', 'youMustExecuteInTime')!;

    if(notify.descriptionJs!.containsKey('active_days')){
      exeTime = exeTime.replaceFirst('#', DateTools.dateOnlyRelative(notify.registerDate));
      exeTime = exeTime.replaceFirst('x', '${notify.descriptionJs!['active_days']}');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 5,),
        Row(
          children: [
            Flexible(
                child: Text('[${notify.descriptionJs!['trainer_name']}]')
                    .boldFont()
                    .subAlpha()
                    .oneLineOverflow$Start()
            ),

            SizedBox(width: 14,),
            Flexible(
                child: Text('${notify.descriptionJs!['course_name']}')
                    .boldFont().subAlpha().oneLineOverflow$Start()
            ),
          ],
        ),

        SizedBox(height: 5,),
        Visibility(
            visible: notify.descriptionJs!.containsKey('active_days'),
            child: Row(
              children: [
                Flexible(
                    child: Text(exeTime).subAlpha()
                ),
              ],
            )
        ),
      ],
    );
  }
}
