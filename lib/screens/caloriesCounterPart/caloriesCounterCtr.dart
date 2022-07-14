import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/managers/caloriesCounterManager.dart';
import '/managers/foodMaterialManager.dart';
import '/models/dataModels/counterModels/caloriesCounterDayModel.dart';
import '/models/dataModels/counterModels/mealModel.dart';
import '/models/dataModels/foodModels/materialModel.dart';
import '/models/dataModels/foodModels/materialWithValueModel.dart';
import '/screens/caloriesCounterPart/caloriesCounterScreen.dart';
import '/screens/commons/topInputFieldScreen.dart';
import '/system/keys.dart';
import '/system/queryFiltering.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';

class CaloriesCounterCtr implements ViewController {
  late CaloriesCounterScreenState state;
  late DateTime today;
  late Requester commonRequester;
  List<MaterialModel> foodMaterialList = [];
  int selectedDayIndex = 0;
  int selectedMealIndex = 0;
  int mealCalories = 0;
  int dayCalories = 0;
  bool showSearchbar = false;
  bool showProgress = false;
  late FilterRequest filterRequest;
  late DateTime selectedDayDate;
  late CaloriesCounterManager manager;
  late CaloriesCounterDayModel dayCaloriesModel;
  late PieChartData dayChartData;
  late PieChartData mealChartData;
  late ScrollController scrollController;
  late ScrollPhysics scrollPhysics;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as CaloriesCounterScreenState;

    filterRequest = FilterRequest();
    filterRequest.limit = 100;

    state.stateController.mainState = StateXController.state$loading;
    manager = CaloriesCounterManager.managerFor(Session.getLastLoginUser()?.userId?? 0);
    commonRequester = Requester();
    today = DateTime.now();
    selectedDayDate = today;
    scrollPhysics = ClampingScrollPhysics();
    scrollController = ScrollController();
    scrollController.addListener(onScroll);

    state.stateController.addMainStateListener((sendData) {
      onRefresh();
    });

    state.addPostOrCall(() async {
      await FoodMaterialManager.loadAllRecords();
      await manager.loadItems();
      prepareDays();
      pickDay();

      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    });

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
  void onScroll(){
    if(scrollController.position.extentBefore == 0.0
        || scrollController.position.extentAfter == 0.0){
      scrollPhysics = NeverScrollableScrollPhysics();

      Future.delayed(Duration(seconds: 1), (){
        scrollPhysics = ClampingScrollPhysics();
        state.stateController.updateMain();
      });

      state.stateController.updateMain();
    }
  }

  void onRefresh(){
    calcDayChartData();
    calcMealChartData();

    final meal = currentMeal(false);

    if(meal != null) {
      mealCalories = meal.sumCalories().toInt();
    }

    dayCalories = dayCaloriesModel.meals.fold<double>(.0, (pre, element) => pre + element.sumCalories()).toInt();
  }

  void prepareDays(){
    for(int idx =0; idx< 31; idx++){
      final dt = today.subtract(Duration(days: idx));
      var dbModel = manager.findByDateOnly(DateHelper.toTimestampDate(dt));

      if(dbModel == null) {
        dbModel = CaloriesCounterDayModel();
        dbModel.userId = manager.userId;
        dbModel.date = DateHelper.toTimestampDate(dt);

        manager.addItem(dbModel);
        manager.sinkItems([dbModel]);
      }
    }
  }

  void pickDay(){
    dayCaloriesModel = manager.findByDateOnly(DateHelper.toTimestampDate(selectedDayDate))!;
    selectedMealIndex = 0;
  }

  void calcDayChartData(){
    final sections = <PieChartSectionData>[];
    final style = TextStyle(fontSize: 10);
    int? pro;
    int? car;
    int? fat;

    pro = (dayCaloriesModel.meals.fold<double>(0, (pre, element) => pre + element.sumProtein()) *4).toInt();
    car = (dayCaloriesModel.meals.fold<double>(0, (pre, element) => pre + element.sumCarbohydrate()) *4).toInt();
    fat = (dayCaloriesModel.meals.fold<double>(0, (pre, element) => pre + element.sumFat()) *9).toInt();
    final sumCalories = fat + pro + car;

    if(sumCalories < 1){
      final empty = PieChartSectionData(
        title: '',
        value: 100.0,
        color: Colors.grey.shade300,
        radius: 45,
      );

      sections.add(empty);

      dayChartData = PieChartData(
        sections: sections,
        borderData: FlBorderData(border: Border.all(color: Colors.transparent)),
        centerSpaceColor: Colors.black,
        centerSpaceRadius: 0,
        sectionsSpace: 0,
        pieTouchData: PieTouchData(),
      );

      return;
    }

    final proPercent = MathHelper.percentFix(sumCalories.toDouble(), pro);
    final carPercent = MathHelper.percentFix(sumCalories.toDouble(), car);
    final fatPercent = MathHelper.percentFix(sumCalories.toDouble(), fat);

    final p = PieChartSectionData(
      title: '',
      value: pro.toDouble(),
      color: Colors.lightGreenAccent.shade200,
      radius: 45,
      badgeWidget: Text('$proPercent %', style: style),
      badgePositionPercentageOffset: .6,
    );

    final c = PieChartSectionData(
      title: '',
      value: car.toDouble(),
      color: Colors.lightBlue.shade200,
      radius: 45,
      badgeWidget: Text('$carPercent %', style: style,),
      badgePositionPercentageOffset: .6,
    );

    final l = PieChartSectionData(
      title: '',
      value: fat.toDouble(),
      color: Colors.redAccent.shade200,
      radius: 45,
      badgeWidget: Text('$fatPercent %', style: style,),
    );

    sections.add(l);
    sections.add(p);
    sections.add(c);

    dayChartData = PieChartData(
      sections: sections,
      borderData: FlBorderData(border: Border.all(color: Colors.transparent)),
      centerSpaceColor: Colors.black,
      centerSpaceRadius: 0,
      sectionsSpace: 0,
      pieTouchData: PieTouchData(),
    );
  }

  void calcMealChartData(){
    final sections = <PieChartSectionData>[];
    final style = TextStyle(fontSize: 10);
    final meal = currentMeal(false);

    if(meal == null || meal.sumCalories() < 1){
      final empty = PieChartSectionData(
        title: '',
        value: 100.0,
        color: Colors.grey.shade300,
        radius: 45,
      );

      sections.add(empty);

      mealChartData = PieChartData(
        sections: sections,
        borderData: FlBorderData(border: Border.all(color: Colors.transparent)),
        centerSpaceColor: Colors.black,
        centerSpaceRadius: 0,
        sectionsSpace: 0,
        pieTouchData: PieTouchData(),
      );

      return;
    }

    final pro = (meal.sumProtein() *4).toInt();
    final car = (meal.sumCarbohydrate() *4).toInt();
    final fat = (meal.sumFat() *9).toInt();
    final caloriesValue = fat + pro + car;

    final proPercent = MathHelper.percentFix(caloriesValue.toDouble(), pro);
    final carPercent = MathHelper.percentFix(caloriesValue.toDouble(), car);
    final fatPercent = MathHelper.percentFix(caloriesValue.toDouble(), fat);

    final p = PieChartSectionData(
      title: '',
      value: pro.toDouble(),
      color: Colors.lightGreenAccent.shade200,
      radius: 45,
      badgeWidget: Text('$proPercent %', style: style),
      badgePositionPercentageOffset: .6,
    );

    final c = PieChartSectionData(
      title: '',
      value: car.toDouble(),
      color: Colors.lightBlue.shade200,
      radius: 45,
      badgeWidget: Text('$carPercent %', style: style,),
      badgePositionPercentageOffset: .6,
    );

    final l = PieChartSectionData(
      title: '',
      value: fat.toDouble(),
      color: Colors.redAccent.shade200,
      radius: 45,
      badgeWidget: Text('$fatPercent %', style: style,),
    );

    sections.add(l);
    sections.add(p);
    sections.add(c);

    mealChartData = PieChartData(
      sections: sections,
      borderData: FlBorderData(border: Border.all(color: Colors.transparent)),
      centerSpaceColor: Colors.black,
      centerSpaceRadius: 0,
      sectionsSpace: 0,
      pieTouchData: PieTouchData(),
    );
  }

  void addMeal(){
    final meal = MealModel();
    meal.ordering = dayCaloriesModel.getMaxMealsNumber()+1;

    dayCaloriesModel.meals.add(meal);
    dayCaloriesModel.sortMeals();
    selectedMealIndex = dayCaloriesModel.meals.length-1;

    state.stateController.updateMain();
  }

  void promptDeleteMeal(int id){
    DialogCenter.instance.showYesNoDialog(
        state.context,
      desc: state.tInMap('caloriesCounterPage', 'ifDeleteThisMeal')!,
      yesText: state.t('yes'),
      noText: state.t('no'),
      yesFn: (){
        deleteMeal(id);
      },
    );
  }

  void deleteMeal(int id){
    dayCaloriesModel.meals.removeWhere((element) => element.id == id);
    selectedMealIndex = dayCaloriesModel.meals.length -1;

    manager.sinkItems([dayCaloriesModel]);
    state.stateController.updateMain();
  }

  void promptDeleteMaterial(int id){
    DialogCenter.instance.showYesNoDialog(
      state.context,
      desc: state.tInMap('caloriesCounterPage', 'ifDeleteThisMaterial')!,
      yesText: state.t('yes'),
      noText: state.t('no'),
      yesFn: (){
        deleteMaterial(id);
      },
    );
  }

  void deleteMaterial(int materialId){
    final meal = currentMeal(false)!;
    meal.materials.removeWhere((element) => element.materialId == materialId);

    manager.sinkItems([dayCaloriesModel]);
    state.stateController.updateMain();
  }

  MealModel? currentMeal(bool createIfNeed){
    if(dayCaloriesModel.meals.isEmpty){
      if(createIfNeed) {
        addMeal();
      }
      else {
        return null;
      }
    }

    return dayCaloriesModel.meals[selectedMealIndex];
  }

  void promptAddMaterial(){
    currentMeal(true)!;

    showSearchbar = true;
    state.stateController.updateMain();
  }

  void addMaterialToMeal(MaterialModel material, int val){
    final mat = MaterialWithValueModel();
    mat.material = material;
    mat.materialValue = val;
    mat.unit = material.measure.unit;

    final meal = currentMeal(true)!;
    meal.addMaterial(mat);
    manager.sinkItems([dayCaloriesModel]);

    FoodMaterialManager.addItem(material);
    FoodMaterialManager.sinkItems([material]);
  }

  void onClickOnMaterial(MaterialModel material){
    for(final meal in currentMeal(false)!.getProgramMaterials()) {
      if (meal.materialId == material.id) {
        StateXController.globalUpdate(Keys.toast, stateData: '${state.t('thisItemExistInBasket')}');
        return;
      }
    }

    final des = state.t('enterValueOfThisMaterial')?.replaceFirst(RegExp('#'), material.matchTitle?? material.orgTitle);

    AppNavigator.pushNextTransparentPage(
        state.context,
        TopInputFieldScreen(description: des, textInputType: TextInputType.number,),
        name: TopInputFieldScreen.screenName).then((value) {
          int val = MathHelper.clearToInt(value);

          if(val > 0){
            addMaterialToMeal(material, val);

            showSearchbar = false;
            foodMaterialList.clear();
            state.stateController.updateMain();
          }
        });
  }

  void requestSearchFood(String searchText) {
    //FocusHelper.hideKeyboardByService();
    foodMaterialList.clear();

    if(searchText.length < 2){
      showProgress = false;
      state.stateController.update(state.id$searchbarState);
      return;
    }

    filterRequest.setTextToSelectedSearch(searchText);

    final js = <String, dynamic>{};
    js[Keys.request] = 'SearchOnFoodMaterial';
    js[Keys.filtering] = filterRequest.toMap();


    commonRequester.requestPath = RequestPath.GetData;
    commonRequester.bodyJson = js;

    commonRequester.httpRequestEvents.onFailState = (req) async {
      showProgress = false;
      state.stateController.update(state.id$searchbarState);
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

      state.stateController.update(state.id$searchbarState);
    };

    showProgress = true;
    state.stateController.update(state.id$searchbarState);
    commonRequester.request(state.context);
  }
}
