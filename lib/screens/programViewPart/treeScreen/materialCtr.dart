import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/foodModels/materialModel.dart';
import '/models/dataModels/foodModels/materialWithValueModel.dart';
import '/models/dataModels/programModels/foodDay.dart';
import '/models/dataModels/programModels/foodMeal.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/programModels/foodSuggestion.dart';
import '/models/dataModels/programModels/fundamentalTypes.dart';
import '/screens/commons/topInputFieldScreen.dart';
import '/screens/programViewPart/selectOtherMaterial/selectOtherMaterialScreen.dart';
import '/screens/programViewPart/treeScreen/materialScreen.dart';
import '/system/extensions.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';

class SelectMaterialCtr implements ViewController {
  late MaterialScreenState state;
  late Requester commonRequester;
  List<MaterialModel> foodMaterialList = [];
  late FoodProgramModel foodProgram;
  late FoodDay foodDay;
  late FoodMeal foodMeal;
  late FoodSuggestion foodSuggestion;
  late BarChartData barChartData;
  late PieChartData chartData;
  int proteinValue = 0;
  int carValue = 0;
  int fatValue = 0;
  bool inReportState = false;
  bool readOnlyState = false;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as MaterialScreenState;

    commonRequester = Requester();

    foodProgram = state.widget.foodProgram;
    foodDay = state.widget.foodDay;
    foodMeal = state.widget.foodMeal;
    foodSuggestion = state.widget.foodSuggestion;
    readOnlyState = foodSuggestion.usedMaterialList.isNotEmpty;

    calcChartData();
    calcBarChartsData();
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }
  ///========================================================================================================
  void gotoReportState(){
    /*if(!foodProgram.isCurrentReport(foodDay)){
      SheetCenter.showSheetOk(state.context, '${state.tInMap('treeFoodProgramPage', 'canNotSendReportForThisDay')}');
      return;
    }*/

    inReportState = true;
    foodSuggestion.copyMaterialsToUsedMaterials();
    reDraw();

    final l1 = state.tInMap('treeFoodProgramPage', 'registerMeans');
    final l2 = state.tInMap('treeFoodProgramPage', 'canNotEditAfterRegister');

    DialogCenter.instance.showDialog(
        state.context,
      desc: '$l1\n$l2'
    );
  }

  void cancelReport(){
    inReportState = false;
    foodSuggestion.usedMaterialList.clear();
    reDraw();
  }

  void sendReport(){
    if(foodSuggestion.sumUsedFundamentalInt(FundamentalTypes.calories) < 2){
      SheetCenter.showSheetOk(state.context, '${state.tInMap('treeFoodProgramPage', 'mustYourCaloriesMore')}');
      return;
    }

    DialogCenter.instance.showYesNoDialog(
        state.context,
        desc: '${state.tInMap('treeFoodProgramPage', 'isValidToSend')}',
        yesText: state.t('yes'),
        noText: state.t('no'),
      yesFn: (){
        requestSendReport();
      }
    );
  }

  void addOtherMaterial(){
    AppNavigator.pushNextPage(
        state.context,
        SelectOtherMaterialScreen(foodSuggestion: foodSuggestion),
        name: SelectOtherMaterialScreen.screenName
    ).then((value) {
      state.stateController.updateMain();
    });
  }

  void calcBarChartsData(){
    final groups = <BarChartGroupData>[];

    final caloriesGRods = <BarChartRodData>[];
    final proteinGRods = <BarChartRodData>[];
    final carGRods = <BarChartRodData>[];
    final fatGRods = <BarChartRodData>[];

    final orgCaloriesPercent = MathHelper.percent(
        foodProgram.getPlanCalories()!.toDouble(), foodSuggestion.sumFundamentalInt(FundamentalTypes.calories));

    final myCaloriesPercent = MathHelper.percent(
        foodProgram.getPlanCalories()!.toDouble(), foodSuggestion.sumUsedFundamentalInt(FundamentalTypes.calories));

    final orgProteinPercent = MathHelper.percent(
        foodProgram.getPlanProtein()!.toDouble(), foodSuggestion.sumFundamentalInt(FundamentalTypes.protein));

    final myProteinPercent = MathHelper.percent(
        foodProgram.getPlanProtein()!.toDouble(), foodSuggestion.sumUsedFundamentalInt(FundamentalTypes.protein));

    final orgCarbohydratePercent = MathHelper.percent(
        foodProgram.getPlanCarbohydrate()!.toDouble(), foodSuggestion.sumFundamentalInt(FundamentalTypes.carbohydrate));

    final myCarbohydratePercent = MathHelper.percent(
        foodProgram.getPlanCarbohydrate()!.toDouble(), foodSuggestion.sumUsedFundamentalInt(FundamentalTypes.carbohydrate));

    final orgFatPercent = MathHelper.percent(
        foodProgram.getPlanFat()!.toDouble(), foodSuggestion.sumFundamentalInt(FundamentalTypes.fat));

    final myFatPercent = MathHelper.percent(
        foodProgram.getPlanFat()!.toDouble(), foodSuggestion.sumUsedFundamentalInt(FundamentalTypes.fat));

    final orgCaloriesBar = BarChartRodData(
      y: MathHelper.minDouble(orgCaloriesPercent, 100),
      colors: [Colors.blue.shade900],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade300],
      ),
    );

    final myCaloriesBar = BarChartRodData(
      y: MathHelper.minDouble(myCaloriesPercent, 100),
      colors: [Colors.blue.shade900],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade300],
      ),
    );

    final orgProteinBar = BarChartRodData(
      y: MathHelper.minDouble(orgProteinPercent, 100),
      colors: [Colors.lightGreenAccent.shade400],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade300],
      ),
    );

    final myProteinBar = BarChartRodData(
      y: MathHelper.minDouble(myProteinPercent, 100),
      colors: [Colors.lightGreenAccent.shade200],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade300],
      ),
    );

    final orgCarBar = BarChartRodData(
      y: MathHelper.minDouble(orgCarbohydratePercent, 100),
      colors: [Colors.lightBlue.shade400],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade300],
      ),
    );

    final myCarBar = BarChartRodData(
      y: MathHelper.minDouble(myCarbohydratePercent, 100),
      colors: [Colors.lightBlue.shade200],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade300],
      ),
    );

    final orgFatBar = BarChartRodData(
      y: MathHelper.minDouble(orgFatPercent, 100),
      colors: [Colors.redAccent.shade400],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade300],
      ),
    );

    final myFatBar = BarChartRodData(
      y: MathHelper.minDouble(myFatPercent, 100),
      colors: [Colors.redAccent.shade200],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade300],
      ),
    );

    caloriesGRods.add(orgCaloriesBar);
    caloriesGRods.add(myCaloriesBar);
    proteinGRods.add(orgProteinBar);
    proteinGRods.add(myProteinBar);
    carGRods.add(orgCarBar);
    carGRods.add(myCarBar);
    fatGRods.add(orgFatBar);
    fatGRods.add(myFatBar);

    final caloriesG = BarChartGroupData(
      x: 1,
      barRods: caloriesGRods,
      barsSpace: 12,
    );

    final proteinG = BarChartGroupData(
      x: 2,
      barRods: proteinGRods,
      barsSpace: 12,
    );

    final carG = BarChartGroupData(
      x: 3,
      showingTooltipIndicators: [10, 22],
      barRods: carGRods,
      barsSpace: 12,
    );

    final fatG = BarChartGroupData(
      x: 4,
      barRods: fatGRods,
      barsSpace: 12,
    );

    groups.add(fatG);
    groups.add(carG);
    groups.add(proteinG);
    groups.add(caloriesG);

    barChartData = BarChartData(
      barGroups: groups,
      minY: 0,
      maxY: 100,
      barTouchData: BarTouchData(enabled: false),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        checkToShowHorizontalLine: (v)=> true,
        drawVerticalLine: false,
        horizontalInterval: 10,
      ),
      axisTitleData: FlAxisTitleData(show: false),
      titlesData: FlTitlesData(
          show: true,
        leftTitles: SideTitles(showTitles: false),
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
            showTitles: true,
            rotateAngle: 0,
          getTextStyles: (context, value){
              if(value.toInt() == 1){
                return AppThemes.boldTextStyle();
              }

              return AppThemes.subTextStyle();//009688
          },
          getTitles: (double axis){
              switch(axis.toInt()){
                case 1:
                  return 'کالری';
                case 2:
                  return 'پروتئین';
                case 3:
                  return 'کربو';
                case 4:
                  return 'چربی';
              }

              return '';
          }
        ),
      ),
    );
  }

  void calcChartData(){
    proteinValue = foodSuggestion.sumFundamentalInt(FundamentalTypes.protein);
    carValue = foodSuggestion.sumFundamentalInt(FundamentalTypes.carbohydrate);
    fatValue = foodSuggestion.sumFundamentalInt(FundamentalTypes.fat);

    final sections = <PieChartSectionData>[];
    final pro = (proteinValue *4);
    final car = (carValue *4);
    final fat = (fatValue *9);
    int sumCalories = fat + pro + car;

    final proPercent = MathHelper.percentFix(sumCalories.toDouble(), pro);
    final carPercent = MathHelper.percentFix(sumCalories.toDouble(), car);
    final fatPercent = MathHelper.percentFix(sumCalories.toDouble(), fat);

    final p = PieChartSectionData(
      title: '',
      value: pro.toDouble(),
      color: Colors.lightGreenAccent.shade200,
      radius: 48,
      badgeWidget: Text('$proPercent %').subFont(),
    );

    final c = PieChartSectionData(
      title: '',
      value: car.toDouble(),
      color: Colors.lightBlue.shade200,
      radius: 48,
      badgeWidget: Text('$carPercent %').subFont(),
    );

    final l = PieChartSectionData(
      title: '',
      value: fat.toDouble(),
      color: Colors.redAccent.shade200,
      radius: 48,
      badgeWidget: Text('$fatPercent %').subFont(),
    );

    final empty = PieChartSectionData(
      title: '',
      value: 100.0,
      color: Colors.grey.shade300,
      radius: 48,
    );

    sections.add(l);
    sections.add(p);
    sections.add(c);

    if(sumCalories < 5) {
      sections.add(empty);
    }

    chartData = PieChartData(
      sections: sections,
      borderData: FlBorderData(border: Border.all(color: Colors.transparent)),
      centerSpaceColor: Colors.black,
      centerSpaceRadius: 0,
      sectionsSpace: 0,
      pieTouchData: PieTouchData(),
    );
  }

  void reDraw(){
    //calcChartData();
    calcBarChartsData();

    state.stateController.updateMain();
  }

  void promptDeleteMaterial(MaterialWithValueModel material){
    DialogCenter.instance.showYesNoDialog(
      state.context,
      desc: state.t('wantToDeleteThisItem')!,
      yesText: state.t('yes'),
      noText: state.t('no'),
      yesFn: (){
        deleteMaterial(material.materialId);
      },
    );
  }

  void deleteMaterial(int materialId){
    foodSuggestion.usedMaterialList.removeWhere((element) => element.materialId == materialId);

    reDraw();
  }

  void showEditMaterialValuePrompt(MaterialWithValueModel material){
    final des = state.t('enterValueOfThisMaterial')?.replaceFirst(RegExp('#'),
        material.material!.matchTitle?? material.material!.orgTitle);

    AppNavigator.pushNextTransparentPage(
        state.context,
        TopInputFieldScreen(
          description: des,
          preValue: '${material.materialValue}',
          textInputType: TextInputType.number,
          hint: '${material.materialValue}',
        ),
        name: TopInputFieldScreen.screenName
    )
        .then((value) {
          int val = MathHelper.clearToInt(value);

          if(val > 0){
            material.materialValue = val;

            reDraw();
          }
    });
  }

  void requestSendReport() {
    final user = Session.getLastLoginUser()!;

    final js = <String, dynamic>{};
    js[Keys.request] = 'SetSuggestionReport';
    js[Keys.requesterId] = user.userId;
    js[Keys.forUserId] = user.userId;
    js['program_id'] = foodProgram.id;
    js['suggestion_id'] = foodSuggestion.id;
    js['data'] = foodSuggestion.toMapUsedMaterials();

    commonRequester.requestPath = RequestPath.SetData;
    commonRequester.bodyJson = js;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      SheetCenter.showSheet$OperationFailedTryAgain(state.context);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      inReportState = false;
      state.stateController.updateMain();

      SheetCenter.showSheet$SuccessOperation(state.context);
    };

    state.showLoading();
    commonRequester.request(state.context);
  }
}
