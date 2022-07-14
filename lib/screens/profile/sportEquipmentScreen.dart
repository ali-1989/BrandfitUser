import 'package:flutter/material.dart';

import 'package:community_material_icon/community_material_icon.dart';
import 'package:dio/dio.dart';
import 'package:iris_pic_editor/picEditor/switchRefresh.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/api/keyboard/keyboardEvent.dart';
import 'package:iris_tools/models/dataModels/colorTheme.dart';
import 'package:iris_tools/widgets/text/autoDirection.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/system/extensions.dart';
import '/system/httpProcess.dart';
import '/system/keys.dart';
import '/system/session.dart';
import '/tools/app/appManager.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/centers/snackCenter.dart';
import '/views/loadingScreen.dart';

class SportEquipmentScreen extends StatefulWidget {
  SportEquipmentScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SportEquipmentScreenState();
  }
}
///========================================================================================================
class SportEquipmentScreenState extends StateBase<SportEquipmentScreen> with SingleTickerProviderStateMixin {
  UserModel user = Session.getLastLoginUser()!;
  TextEditingController clobCtr = TextEditingController();
  TextEditingController homeCtr = TextEditingController();
  SwitchController collapseCtr = SwitchController('Description');
  HttpRequester? requestObj;
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(vsync: this, length: 2);
    clobCtr.text = user.sportEquipmentModel.gymTools?? '';
    homeCtr.text = user.sportEquipmentModel.homeTools?? '';
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    return getScaffold(this);
  }

  @override
  void dispose() {
    clobCtr.dispose();
    homeCtr.dispose();
    HttpCenter.cancelAndClose(requestObj);

    super.dispose();
  }
}
///========================================================================================================
Widget getScaffold(SportEquipmentScreenState state) {
  return WillPopScope(
    onWillPop: () => state.onWillBack(state),
    child: Scaffold(
      key: state.scaffoldKey,
      appBar: getAppbar(state),
      body: getScaffoldBody(state),
    ),
  );
}
///========================================================================================================
PreferredSizeWidget getAppbar(SportEquipmentScreenState state) {
  return AppBar(
    title: Text(state.tC('sportsEquipment')!),
  );
}
///========================================================================================================
Widget getScaffoldBody(SportEquipmentScreenState state) {
  final inputParentDecoration = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    border: Border.all(
      color: AppThemes.currentTheme.fabBackColor.withAlpha(200),
      style: BorderStyle.solid,
      width: 0.8,
    ),
  );

  return SizedBox(
    //constraints: BoxConstraints.expand(),
    height: AppSizes.getScreenHeight(state.context),

    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          KeyboardStateListener(
            builder: (BuildContext context, Widget? child, bool isKeyboardOpen) {
              if(isKeyboardOpen) {
                return SizedBox();
              } else {
                return Card(
                  color: Colors.transparent,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: AppThemes.currentTheme.fabBackColor.withAlpha(150),
                      width: 0.8,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text('${state.tJoin('sportsEquipmentDescription')}',
                      textAlign: TextAlign.start,).fsR(2, max: 20),
                  ),
                );
              }
            },
          ),
          //SizedBox(height: 12,),

          Expanded(
              child: Column(
                children: [
                  TabBar(
                    controller: state.tabController,
                    isScrollable: false,
                    mouseCursor: SystemMouseCursors.noDrop,
                    labelColor: AppThemes.currentTheme.infoTextColor,
                    unselectedLabelColor: AppThemes.currentTheme.infoTextColor,
                    tabs: [
                      Tab(
                        text: state.tC('gym'),
                        icon: Icon(CommunityMaterialIcons.dumbbell).alpha(alpha: 120),
                      ),

                      Tab(
                        text: state.tC('home'),
                        icon: Icon(CommunityMaterialIcons.home).alpha(alpha: 120),
                      ),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      physics: NeverScrollableScrollPhysics(),
                      controller: state.tabController,
                      children: [
                        DecoratedBox(
                          decoration: inputParentDecoration,
                          child: AutoDirection(
                            builder: (BuildContext context, AutoDirectionController controller) {
                              return TextField(
                                controller: state.clobCtr,
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                textDirection: controller.getTextDirection(state.clobCtr.text),
                                minLines: null,
                                maxLines: null,
                                expands: true,
                                style: AppThemes.baseTextStyle(),
                                decoration: ColorTheme.noneBordersInputDecoration.copyWith(
                                  contentPadding: EdgeInsets.all(5),
                                  hintText: state.tC('clubEquipment')
                                ),
                                onChanged: (t){
                                  controller.onChangeText(t);
                                },
                              );
                            },

                          ),
                        ),



                        DecoratedBox(
                          decoration: inputParentDecoration,
                          child: AutoDirection(
                            builder: (BuildContext context, AutoDirectionController controller) {
                              return TextField(
                                controller: state.homeCtr,
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                textDirection: controller.getTextDirection(state.homeCtr.text),
                                minLines: null,
                                maxLines: null,
                                expands: true,
                                style: AppThemes.baseTextStyle(),
                                decoration: ColorTheme.noneBordersInputDecoration.copyWith(
                                  contentPadding: EdgeInsets.all(5),
                                    hintText: state.tC('homeEquipment'),
                                ),
                                onChanged: (t){
                                  controller.onChangeText(t);
                                },
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),


                ],
              )
          ),

          SizedBox(
            height: 60,
            width: double.infinity,
            child: Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 0),
                child: ActionChip(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  label: Text('${state.tC('save')}'),
                  avatar: Icon(Icons.save).chipItemColor(),
                  onPressed: (){
                    uploadList(state, state.clobCtr.text, state.homeCtr.text);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
///========================================================================================================
void uploadList(SportEquipmentScreenState state, String gym, String home) {
  FocusHelper.hideKeyboardByUnFocus(state.context);

  final js = <String, dynamic>{};
  js[Keys.request] = 'UpdateSportsEquipment';
  js[Keys.userId] = state.user.userId;
  js['sports_equipment_in_home'] = home;
  js['sports_equipment_in_gym'] = gym;

  AppManager.addAppInfo(js);

  final request = HttpItem();
  request.pathSection = '/set-data';
  request.method = 'POST';
  request.setResponseIsPlain();
  request.body = JsonHelper.mapToJson(js);

  LoadingScreen.showLoading(state.context, canBack: false);
  HttpCenter.cancelAndClose(state.requestObj);
  final response = HttpCenter.send(request);
  state.requestObj = response;

  response.responseFuture.catchError((e){
    if (e is DioError){
      if(e.message == 'my') {
        return response.emptyError;
      }
    }

    LoadingScreen.hideLoading(state.context);
    SnackCenter.showSnack$errorCommunicatingServer(state.context);
  });

  response.responseFuture.then((val) {

    if(!response.isOk){
      LoadingScreen.hideLoading(state.context);
      SheetCenter.showSheet$ServerNotRespondProperly(state.context);
      return;
    }

    final Map? js = response.getBodyAsJson();

    if (js == null) {
      LoadingScreen.hideLoading(state.context);
      SnackCenter.showSnack$errorInServerSide(state.context);
      return;
    }

    final String result = js[Keys.result]?? Keys.error;

    if(result == Keys.ok) {
      state.user.sportEquipmentModel.gymTools = gym;
      state.user.sportEquipmentModel.homeTools = home;

      Session.sinkUserInfo(state.user).then((value) {
        LoadingScreen.hideLoading(state.context);
        SnackCenter.showSnack$successOperation(state.context);
      });
    }
    else {
      LoadingScreen.hideLoading(state.context);

      if (!HttpProcess.processCommonRequestError(state.context, js)) {
        SheetCenter.showSheet$ServerNotRespondProperly(state.context);
      }
    }
  });
}
///========================================================================================================
