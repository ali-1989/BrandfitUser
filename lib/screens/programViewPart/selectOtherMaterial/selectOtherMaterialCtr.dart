import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/managers/foodMaterialManager.dart';
import '/models/dataModels/foodModels/materialModel.dart';
import '/models/dataModels/foodModels/materialWithValueModel.dart';
import '/models/dataModels/programModels/foodSuggestion.dart';
import '/screens/commons/topInputFieldScreen.dart';
import '/screens/programViewPart/selectOtherMaterial/selectOtherMaterialScreen.dart';
import '/system/keys.dart';
import '/system/queryFiltering.dart';
import '/system/requester.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/httpCenter.dart';

class SelectOtherMaterialCtr implements ViewController {
  late SelectOtherMaterialScreenState state;
  late Requester commonRequester;
  late TextEditingController searchEditController;
  List<MaterialModel> foodMaterialList = [];
  bool showProgress = false;
  late FilterRequest filterRequest;
  late FoodSuggestion foodSuggestion;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as SelectOtherMaterialScreenState;

    filterRequest = FilterRequest();
    filterRequest.limit = 100;

    commonRequester = Requester();
    foodSuggestion = state.widget.foodSuggestion;

    //searchBarCtr = FloatingSearchBarController();

    prepareFilterOptions();
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }

  void prepareFilterOptions(){
    filterRequest.addSearchView(SearchKeys.titleKey);
  }
  ///========================================================================================================
  void onClickOnMaterial(MaterialModel material){
    FocusHelper.hideKeyboardByService();

    for(final mat in foodSuggestion.usedMaterialList) {
      if (mat.materialId == material.id) {
        StateXController.globalUpdate(Keys.toast, stateData: '${state.t('thisItemExistInBasket')}');
        return;
      }
    }

    final des = state.t('enterValueOfThisMaterial')?.replaceFirst(RegExp('#'), material.matchTitle?? material.orgTitle);

    AppNavigator.pushNextTransparentPage(
        state.context,
        TopInputFieldScreen(
          description: des,
          textInputType: TextInputType.number,),
        name: TopInputFieldScreen.screenName).then((value) {
          int val = MathHelper.clearToInt(value);

          if(val > 0){
            foodMaterialList.clear();
            //searchBarCtr.close();

            addMaterialToSuggestion(material, val);
            FoodMaterialManager.addItem(material);
            FoodMaterialManager.sinkItems([material]);
          }
        });
  }

  void addMaterialToSuggestion(MaterialModel material, int val){
    final mw = MaterialWithValueModel();
    mw.material = material;
    mw.materialValue = val;
    mw.unit = material.measure.unit;

    foodSuggestion.usedMaterialList.add(mw);
    AppNavigator.pop(state.context);
  }

  void showEditMaterialValuePrompt(MaterialWithValueModel material){
    final des = state.t('enterValueOfThisMaterial')?.replaceFirst(RegExp('#'),
        material.material!.matchTitle?? material.material!.orgTitle);

    AppNavigator.pushNextTransparentPage(
        state.context,
        TopInputFieldScreen(
          description: des,
          textInputType: TextInputType.number,
          hint: '${material.materialValue}',
        ),
        name: TopInputFieldScreen.screenName
    )
        .then((value) {
          int val = MathHelper.clearToInt(value);

          if(val > 0){
            material.materialValue = val;

          }
    });
  }

  void resetRequest(){
    foodMaterialList.clear();

    requestSearchFood();
  }

  void requestSearchFood() {
    final searchText = filterRequest.getSearchSelectedForce().text?? '';

    if(searchText.length < 2){
      showProgress = false;
      state.stateController.updateMain();
      return;
    }

    //filterRequest.setTextToSelectedSearch(searchText);

    final js = <String, dynamic>{};
    js[Keys.request] = 'SearchOnFoodMaterial';
    js[Keys.filtering] = filterRequest.toMap();

    commonRequester.requestPath = RequestPath.GetData;
    commonRequester.bodyJson = js;

    commonRequester.httpRequestEvents.onFailState = (req) async {
      state.stateController.updateMain();
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      showProgress = false;

      List? list = data[Keys.resultList];
      //String? domain = data[Keys.domain];

      if(list != null) {
        for (final row in list) {
          final r = MaterialModel.fromMap(row);

          foodMaterialList.add(r);
        }
      }

      state.stateController.updateMain();
    };

    commonRequester.request(state.context);
  }
}
