import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/models/dataModels/colorTheme.dart';
import 'package:iris_tools/widgets/attribute.dart';
import 'package:iris_tools/widgets/multiSelect/multiSelect.dart';
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

/// more help: https://stackoverflow.com/questions/56326005/how-to-use-expanded-in-singlechildscrollview

class HealthConditionScreen extends StatefulWidget {
  HealthConditionScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return HealthConditionScreenState();
  }
}
///=====================================================================================
class HealthConditionScreenState extends StateBase<HealthConditionScreen> {
  UserModel user = Session.getLastLoginUser()!;
  TextEditingController descriptionInputCtr = TextEditingController();
  TextEditingController medicInputCtr = TextEditingController();
  ScrollController scrollController = ScrollController();
  AttributeController viewPortAtt = AttributeController();
  AttributeController childAtt = AttributeController();
  Map<String, dynamic> allIlsMap = {};
  List<String> allIlls = [];
  List<int> selectedIlls = [];
  HttpRequester? requestObj;
  double h = 100;

  @override
  void initState() {
    super.initState();

    allIlsMap = tAsMap('illness')!;

    for(var kv in allIlsMap.entries){
      allIlls.add(kv.value);
    }

    fetch(this);

    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      final viewPort = viewPortAtt.getHeight()!;
      final cur = childAtt.getHeight()!;

      if(cur < viewPort && scrollController.position.maxScrollExtent > 0){
        h = h + (viewPort - cur);

        update();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    return getScaffold(this);
  }

  @override
  void dispose() {
    HttpCenter.cancelAndClose(requestObj);

    super.dispose();
  }

  void fetch(HealthConditionScreenState state){
    state.descriptionInputCtr.text = state.user.healthConditionModel.illDescription?? '';
    state.medicInputCtr.text = state.user.healthConditionModel.illMedications?? '';
    final userIlls = state.user.healthConditionModel.illList;

    final fixIlls = state.allIlsMap.entries;

    for(var i =0; i < state.allIlsMap.length; i++) {
      final MapEntry e = fixIlls.elementAt(i);

      if(userIlls.contains(e.key)) {
        state.selectedIlls.add(i);
      }
    }
  }
}
///========================================================================================================
Widget getScaffold(HealthConditionScreenState state) {
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
PreferredSizeWidget getAppbar(HealthConditionScreenState state) {
  return AppBar(
    title: Text(state.tC('healthCondition')!),
  );
}
///========================================================================================================
Widget getScaffoldBody(HealthConditionScreenState state) {
  //fetch(state);

  final inputParentDecoration = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    border: Border.all(
      color: AppThemes.currentTheme.fabBackColor.withAlpha(200),
      style: BorderStyle.solid,
      width: 0.8,
    ),
  );

  return Attribute(
      controller: state.viewPortAtt,
      childBuilder: (BuildContext context, AttributeController att) {
      return SizedBox(
        height: AppSizes.getScreenHeight(state.context),

        child: SingleChildScrollView( // for keyboard overflow
          child: Attribute(
              controller: state.childAtt,
              childBuilder: (BuildContext context, AttributeController controller){
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [

                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 1, vertical: 6),
                            child: Text('${state.tC('chooseYourDiseases')}',
                              textAlign: TextAlign.start,).fsR(2, max: 20),
                          ),
                        ),

                        Expanded(
                          child: Scrollbar(
                            isAlwaysShown: true,
                            controller: state.scrollController,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: 50, maxHeight: state.h),
                                child: SingleChildScrollView(
                                  controller: state.scrollController,
                                  scrollDirection: Axis.vertical,
                                  child: MultiSelect(
                                    spacing: 4,
                                    isRadio: false,
                                    borderRadius: BorderRadius.circular(30.0),
                                    buttons: [
                                      ...state.allIlls,
                                    ],
                                    selectedButtons: state.selectedIlls,
                                    onChangeState: (idx, value, isSelected){
                                      if(isSelected){
                                        if(!state.selectedIlls.contains(idx)) {
                                          state.selectedIlls.add(idx);
                                        }
                                      }
                                      else {
                                        state.selectedIlls.remove(idx);
                                      }
                                    },
                                    selectedIcon: Icon(Icons.check).rSiz(-2).textColor(),
                                    selectedColor: AppThemes.currentTheme.activeItemColor,
                                    unselectedColor: AppThemes.currentTheme.activeItemColor.withAlpha(90),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12,),
                        Text('${state.tJoin('healthConditionDescription')}',
                          textAlign: TextAlign.start,).fsR(2, max: 20),

                        SizedBox(height: 12,),
                        DecoratedBox(
                          decoration: inputParentDecoration,
                          child: AutoDirection(
                            builder: (context, controller) {
                              return TextField(
                                controller: state.descriptionInputCtr,
                                textDirection: controller.getTextDirection(state.descriptionInputCtr.text),
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                minLines: 4,
                                maxLines: 4,
                                expands: false,
                                decoration: ColorTheme.noneBordersInputDecoration,
                                onChanged: (t){
                                  controller.onChangeText(t);
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 12,),
                        SizedBox(
                          width: double.infinity,
                          child: Text('${state.tC('medications')}:',
                            textAlign: TextAlign.start,).fsR(2, max: 20),
                        ),

                        SizedBox(height: 12,),
                        DecoratedBox(
                          decoration: inputParentDecoration,
                          child: AutoDirection(
                              builder: (context, controller) {
                              return TextField(
                                controller: state.medicInputCtr,
                                textDirection: controller.getTextDirection(state.medicInputCtr.text),
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                minLines: 2,
                                maxLines: 2,
                                expands: false,
                                decoration: ColorTheme.noneBordersInputDecoration,
                                onChanged: (t){
                                  controller.onChangeText(t);
                                },
                              );
                            }
                          ),
                        ),

                        SizedBox(
                          height: 70,
                          width: double.infinity,
                          child: Align(
                            alignment: AlignmentDirectional.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(5, 10, 5, 5),
                              child: ActionChip(
                                padding: EdgeInsets.symmetric(horizontal: 50),
                                label: Text('${state.tC('save')}'),
                                avatar: Icon(Icons.save).chipItemColor(),
                                onPressed: (){
                                  final selected = <String>[];

                                  for(var i in state.selectedIlls){
                                    final k = state.allIlsMap.keys.elementAt(i);
                                    selected.add(k);
                                  }

                                  uploadList(state, selected, state.descriptionInputCtr.text, state.medicInputCtr.text);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
          ),
        ),
      );
    }
  );
}
///========================================================================================================
void uploadList(HealthConditionScreenState state, List<String> ills, String description, String medications) {
  FocusHelper.hideKeyboardByUnFocus(state.context);

  final js = <String, dynamic>{};
  js[Keys.request] = 'UpdateHealthCondition';
  js[Keys.userId] = state.user.userId;
  js['ill_list'] = ills;
  js['ill_description'] = description;
  js['ill_medications'] = medications;

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
    if(response.isDioCancelError) {
      return response.emptyError;
    }

    LoadingScreen.hideLoading(state.context).then((value){
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    });
  });

  response.responseFuture.then((val) async{

    if(!response.isOk){
      await LoadingScreen.hideLoading(state.context);
      await SheetCenter.showSheet$ServerNotRespondProperly(state.context);
      return;
    }

    final Map? js = response.getBodyAsJson();

    if (js == null) {
      await LoadingScreen.hideLoading(state.context);
      SnackCenter.showSnack$errorInServerSide(state.context);
      return;
    }

    final String result = js[Keys.result]?? Keys.error;

    if(result == Keys.ok) {
      state.user.healthConditionModel.illList = ills;
      state.user.healthConditionModel.illDescription = description;
      state.user.healthConditionModel.illMedications = medications;

      // ignore: unawaited_futures
      Session.sinkUserInfo(state.user).then((value) async{
        await LoadingScreen.hideLoading(state.context);
        SnackCenter.showSnack$successOperation(state.context);
      });
    }
    else {
      await LoadingScreen.hideLoading(state.context);

      if (!HttpProcess.processCommonRequestError(state.context, js)) {
        await SheetCenter.showSheet$ServerNotRespondProperly(state.context);
      }
    }
  });
}
///========================================================================================================

