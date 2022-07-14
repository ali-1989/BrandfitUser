import 'package:flutter/material.dart';

import 'package:animate_do/animate_do.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/api/helpers/textHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/widgets/buttons/outsideButton.dart';
import 'package:iris_tools/widgets/horizontalPicker.dart';
import 'package:iris_tools/widgets/icon/circularIcon.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/chartModels/nodeDataModel.dart';
import '/models/dataModels/usersModels/fitnessDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/system/extensions.dart';
import '/system/httpProcess.dart';
import '/system/keys.dart';
import '/system/session.dart';
import '/tools/app/appManager.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/centers/snackCenter.dart';
import '/tools/dateTools.dart';
import '/tools/measureTools.dart';
import '/views/loadingScreen.dart';

class AddChartItem extends StatefulWidget {
  final NodeNames nodeName;

  AddChartItem({
    Key? key,
    required this.nodeName,
    }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AddChartItemState();
  }
}
///=========================================================================================================
class AddChartItemState extends StateBase<AddChartItem> {
  late UserModel user;
  late List<NodeDataModel> nodeDataList;
  late String measure;
  HttpRequester? requestObj;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();

    user = Session.getLastLoginUser()!;
    measure = MeasureTools.getMeasureUnitFor(widget.nodeName);

    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      isLoaded = true;
      update();
    });
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: AppSizes.getScreenWidth(context),
        height: AppSizes.getScreenHeight(context),
        child: Scaffold(
          appBar: AppBar(
            title: Text('${tDynamicOrFirst('bodyStatusTypes', widget.nodeName.name)}'),
          ),
          body: getScaffoldBody(),
          floatingActionButton: GestureDetector(
            onTap: (){
              addNewItem();
            },
            child: CircularIcon(
              backColor: AppThemes.currentTheme.fabBackColor,
              icon: Icons.add,
              size: 44,
              itemColor: AppThemes.currentTheme.fabItemColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    HttpCenter.cancelAndClose(requestObj);

    super.dispose();
  }

  Widget getScaffoldBody(){
    nodeDataList = user.fitnessDataModel.getNodes(widget.nodeName)!;

    return ListView.separated(
      itemCount: isLoaded? nodeDataList.length : 0,
      padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
      itemBuilder: (ctx, index){
        final dot = nodeDataList.elementAt(index);

        return FadeInLeft(
          delay: Duration(milliseconds: 200),
          duration: Duration(milliseconds: 500),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${dot.value} $measure').bold(),
                    SizedBox(height: 8,),
                    Text(DateTools.dateRelativeByAppFormat(dot.utcDate)).infoColor(),
                  ],
                ),

                if(canDelete(dot))
                  IconButton(
                    icon: Icon(Icons.delete_forever).btnBackColor(),
                    onPressed: (){
                      final desc = tC('deleteThisChartRecord')!;
                      final Widget icon = Icon(Icons.warning,color: Colors.red,).rSiz(7);

                      void fn(){
                        deleteData(widget.nodeName, dot);
                      }

                      DialogCenter().showYesNoDialog(context,desc: desc, yesFn: fn, icon: icon);
                    },
                  ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(indent: 20, endIndent: 20,);
      },
    );
  }
  ///==========================================================================================================
  void addNewItem(){
    var selectedValue = FitnessDataModel.getMinValueForKey(widget.nodeName)+1;

    final Widget view = SizedBox(
        width: AppSizes.getScreenWidth(context),
        child: OutsideButton(
          onCloseTap: (){AppNavigator.pop(context);},
          splashColor: AppThemes.currentTheme.differentColor,
          backColor: AppThemes.currentTheme.backgroundColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 2),
            child: FlipInX(
              delay: Duration(milliseconds: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Text(' ${getAddTitle()}:').bold().fs(16)
                  ),
                  SizedBox(height: AppSizes.fwSize(16),),
                  HorizontalPicker(
                    //controller: hBmiController,
                    minValue: FitnessDataModel.getMinValueForKey(widget.nodeName),
                    maxValue: FitnessDataModel.getMaxValueForKey(widget.nodeName),
                    suffix: ' $measure',
                    showCursor: true,
                    cursorValue: selectedValue,
                    cellWidth: 70,
                    height: 70,
                    backgroundColor: AppThemes.currentTheme.backgroundColor,
                    itemBackgroundColor: AppThemes.currentTheme.backgroundColor,
                    selectedStyle: AppThemes.baseTextStyle().copyWith(
                        color: AppThemes.currentTheme.activeItemColor),
                    cursorColor: AppThemes.currentTheme.activeItemColor.withAlpha(150),
                    onChanged: (value) {
                      selectedValue = value as double;
                    },
                  ),
                ],
              ),
            ),
          ),
        )
    );

    SheetCenter.showSheetCustom(
      context,
      view,
      positiveButton: ElevatedButton(
        child: Text('${tC('add')}'),
        onPressed: (){
          uploadData(widget.nodeName, selectedValue);
        },
      ),
      routeName: 'AddNewItemSheet',
      contentColor: Colors.transparent,
      buttonBarColor: AppThemes.currentTheme.backgroundColor,
    ).then((value){
      update();
    });
  }

  bool canDelete(NodeDataModel dot){
    if(widget.nodeName == NodeNames.height_node || widget.nodeName == NodeNames.weight_node){
      return nodeDataList.length > 1;
    }

    return true;
  }

  String getAddTitle(){
    final String word = tDynamicOrFirst('bodyStatusTypes', widget.nodeName.name)!;

    return TextHelper.replace(tC('newValueFor')!, '#1', word);
  }

  void uploadData(NodeNames nodeName, dynamic value) {
    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdateFitnessStatus';
    js[Keys.userId] = user.userId;
    js['node_name'] = nodeName.name;
    js[Keys.value] = value;

    AppManager.addAppInfo(js);

    final request = HttpItem();
    request.pathSection = '/set-data';
    request.method = 'POST';
    request.setResponseIsPlain();
    request.setBody(JsonHelper.mapToJson(js));

    LoadingScreen.showLoading(context, canBack: false);
    HttpCenter.cancelAndClose(requestObj);
    final response = HttpCenter.send(request);
    requestObj = response;

    var f = response.responseFuture.catchError((e){
      if (response.isDioCancelError){
        return response.emptyError;
      }

      LoadingScreen.hideLoading(context);
      SnackCenter.showSnack$errorCommunicatingServer(context);
    });

    f.then((val) async{
      if(!response.isOk){
        await LoadingScreen.hideLoading(context);
        await SheetCenter.showSheet$ServerNotRespondProperly(context);
        return;
      }

      final Map? js = response.getBodyAsJson();

      if (js == null) {
        await LoadingScreen.hideLoading(context);
        SnackCenter.showSnack$errorInServerSide(context);
        return;
      }

      final String result = js[Keys.result]?? Keys.error;

      if(result == Keys.ok){
        final fitnessJs = js['fitness_status_js'];

        if(fitnessJs != null) {
          user.fitnessDataModel.matchBy(FitnessDataModel.fromMap(fitnessJs));
        }

        await Session.sinkUserInfo(user).then((value) async {
          await LoadingScreen.hideLoading(context);

          if(!AppNavigator.popByRouteName(context, 'AddNewItemSheet')) {
            update();
          }
        });
      }
      else {
        await LoadingScreen.hideLoading(context);

        if (!HttpProcess.processCommonRequestError(context, js)) {
          await SheetCenter.showSheet$ServerNotRespondProperly(context);
        }
      }
    });
  }

  void deleteData(NodeNames nodeName, NodeDataModel nod) {
    final js = <String, dynamic>{};
    js[Keys.request] = 'DeleteFitnessStatus';
    js[Keys.userId] = user.userId;
    js['node_name'] = nodeName.name;
    js[Keys.value] = nod.value;
    js[Keys.date] = DateHelper.toTimestamp(nod.utcDate!);

    AppManager.addAppInfo(js);

    final request = HttpItem();
    request.pathSection = '/set-data';
    request.method = 'POST';
    request.setResponseIsPlain();
    request.setBody(JsonHelper.mapToJson(js));

    LoadingScreen.showLoading(context, canBack: false);
    HttpCenter.cancelAndClose(requestObj);
    final response = HttpCenter.send(request);
    requestObj = response;

    response.responseFuture.catchError((e){
      if(response.isDioCancelError){
        return response.emptyError;
      }

      LoadingScreen.hideLoading(context);
      SnackCenter.showSnack$errorCommunicatingServer(context);
    });

    response.responseFuture.then((val) async {

      if(!response.isOk){
        await LoadingScreen.hideLoading(context);
        await SheetCenter.showSheet$ServerNotRespondProperly(context);
        return;
      }

      final Map? js = response.getBodyAsJson();

      if (js == null) {
        await LoadingScreen.hideLoading(context);
        SnackCenter.showSnack$errorInServerSide(context);
        return;
      }

      final String result = js[Keys.result]?? Keys.error;

      if(result == Keys.ok){
        final fitnessJs = js['fitness_status_js'];

        if(fitnessJs != null) {
          user.fitnessDataModel.matchBy(FitnessDataModel.fromMap(fitnessJs));
        }

        await Session.sinkUserInfo(user).then((value) async {
          await LoadingScreen.hideLoading(context);
          update();
        });
      }
      else {
        await LoadingScreen.hideLoading(context);

        if (!HttpProcess.processCommonRequestError(context, js)) {
          await SheetCenter.showSheet$ServerNotRespondProperly(context);
        }
      }
    });
  }
}

