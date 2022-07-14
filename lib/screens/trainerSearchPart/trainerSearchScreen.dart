import 'package:brandfit_user/screens/trainerSearchPart/trainerSearchCtr.dart';
import 'package:brandfit_user/system/icons.dart';
import 'package:brandfit_user/views/messageViews/notDataFoundView.dart';
import 'package:flutter/material.dart';
import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/widgets/searchBar.dart';

import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/system/extensions.dart';
import '/tools/app/appThemes.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

class TrainerSearchScreen extends StatefulWidget {
  static const screenName = '/TrainerSearchScreen';

  TrainerSearchScreen({Key? key}) :super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TrainerSearchScreenState();
  }
}
///====================================================================================================
class TrainerSearchScreenState extends StateBase<TrainerSearchScreen> with TickerProviderStateMixin {
  StateXController stateController = StateXController();
  TrainerSearchCtr controller = TrainerSearchCtr();

  TrainerSearchScreenState();

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
    return Scaffold(
      appBar: AppBar(
        title: Text('${tInMap('trainerSearchPage', 'pageTitle')}'),
      ),
      body: StateX(
        isMain: true,
          controller: stateController,
          builder: (ctx, ctr, data) {
            /*if(controller.user == null) {
              return MustLoginView(this, loginFn: controller.tryLogin,);
            }*/

            switch(ctr.mainState){
              case StateXController.state$loading:
                return PreWidgets.flutterLoadingWidget$Center();
              case StateXController.state$serverNotResponse:
              case StateXController.state$netDisconnect:
                return ServerResponseWrongView(this, tryAgain: controller.tryAgain);
              default:
                return getBody();
            }
          }),
    );
  }

  Widget getBody() {
    return StateX(
      controller: stateController,
      isSubMain: true,
      builder: (context, ctr, data) {
        return Column(
          children: [
            genSearchBar(),

            Expanded(
              child: getListview(),
            )
          ],
        );
      }
    );
  }
  ///==========================================================================================================
  Widget genSearchBar(){
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
    if(controller.trainerList.isEmpty) {
      if(controller.searchEditController?.text.isEmpty?? true){
        return NotDataFoundView(
          message: tInMap('coursePage', 'enterTrainerUserName'),
        );
      }

      return NotDataFoundView(
        message: tInMap('coursePage', 'notFoundTrainer'),
      );
    }

    return ListView.builder(
      itemCount: controller.trainerList.length,
      padding: EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (ctx, idx){
        return genListItem(idx);
      },
    );
  }

  Widget genListItem(int idx){
    final trainer = controller.trainerList[idx];

    return SizedBox(
      height: 130,
      child: Card(
        key: ValueKey(trainer.userId),
        color: Colors.grey.shade300,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: (){
            //controller.gotoFullInfo(trainer);
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
                        minWidth: 80,
                        maxWidth: 100,
                        minHeight: 80,
                        maxHeight: 100,
                      ),
                      child: AspectRatio(
                        aspectRatio: 10/10,
                        child: IrisImageView(
                          //imagePath: trainer.imagePath,
                          url: trainer.profileUri,
                          beforeLoadWidget: CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: FittedBox(
                                child: Icon(IconList.accountCircleM, size: 120, color: Colors.white,),
                                fit: BoxFit.fill
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: 8,),

                Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(trainer.userName).boldFont().fsR(2),
                            Text(trainer.nameFamily).subFont().fsR(2),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${tInMap('trainerSearchPage', 'courseCount')}: ${trainer.courseCount}')
                                .fsR(1).bold().alpha(),

                            TextButton(
                                onPressed: (){
                                  controller.gotoBioScreen(trainer);
                                },
                                child: Text('${tInMap('trainerSearchPage', 'biography')}')
                            ),
                          ],
                        ),
                      ],
                    )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
