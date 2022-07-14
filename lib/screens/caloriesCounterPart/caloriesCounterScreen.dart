import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_sticky_section_list/sticky_section_list.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

import '/abstracts/stateBase.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/dateTools.dart';
import '/views/preWidgets.dart';
import 'caloriesCounterCtr.dart';

class CaloriesCounterScreen extends StatefulWidget {
  static const screenName = 'CaloriesCounterScreen';

  CaloriesCounterScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CaloriesCounterScreenState();
  }
}
///=======================================================================================================
class CaloriesCounterScreenState extends StateBase<CaloriesCounterScreen> {
  StateXController stateController = StateXController();
  CaloriesCounterCtr controller = CaloriesCounterCtr();
  String id$searchbarState = 'searchbarState';
  late Icon flagIcon;

  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
    flagIcon = Icon(IconList.flag, color: Colors.white,);
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

  Widget getScaffold(){
    return SizedBox(
      width: AppSizes.getScreenWidth(context),
      height: AppSizes.getScreenHeight(context),
      child: Scaffold(
        appBar: getAppBar(),
        body: SafeArea(
          child: getMainBuilder(),
        ),
      ),
    );
  }

  PreferredSizeWidget getAppBar(){
    return AppBar(
      title: Text(tInMap('caloriesCounterPage', 'pageTitle')!),
    );
  }

  Widget getMainBuilder(){
    return StateX(
      controller: stateController,
      isMain: true,
      builder: (context, ctr, data) {
        switch(ctr.mainState){
          case StateXController.state$loading:
            return PreWidgets.flutterLoadingWidget$Center();
          default:
            return Stack(
              fit: StackFit.expand,
              children: [
                getBody(),
                getSearchBar(),
              ],
            );
        }
      },
    );
  }

  Widget getBody() {
    return StickySectionList(
      delegate: StickySectionListDelegate(
          getSectionCount: () => 2,
          getItemCount: (sectionIndex) => 1,
          buildSection: (context, sectionIndex) {
            if(sectionIndex == 0){
              return SizedBox();
            }

            return ColoredBox(
              color: AppThemes.currentTheme.backgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UnconstrainedBox(
                            child: SizedBox(
                              width: 120,
                              height: 110,
                              child: PieChart(controller.dayChartData),
                            ),
                          ),

                          Text('${controller.dayCalories}')
                              .subFont(),

                          Text('${tInMap('caloriesCounterPage', 'dayCalories')}')
                              .boldFont(),
                        ],
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UnconstrainedBox(
                            child: SizedBox(
                              width: 120,
                              height: 110,
                              child: PieChart(controller.mealChartData),
                            ),
                          ),

                          Text('${controller.mealCalories}')
                              .subFont(),

                          Text('${tInMap('caloriesCounterPage', 'mealCalories')}')
                              .boldFont(),
                        ],
                      ),
                    ],
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TabPageSelectorIndicator(
                            backgroundColor: Colors.lightGreenAccent.shade200,
                            borderColor: Colors.lightGreenAccent.shade200,
                            size: 15,
                          ),
                          Text('${tInMap('materialFundamentals', 'protein')}'),
                        ],
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TabPageSelectorIndicator(
                            backgroundColor: Colors.lightBlue.shade200,
                            borderColor: Colors.lightBlue.shade200,
                            size: 15,
                          ),
                          Text('${tInMap('materialFundamentals', 'carbohydrate')}'),
                        ],
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TabPageSelectorIndicator(
                            backgroundColor: Colors.redAccent.shade200,
                            borderColor: Colors.redAccent.shade200,
                            size: 15,
                          ),
                          Text('${tInMap('materialFundamentals', 'fat')}'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          buildItem: (context, sectionIndex, index){
            if(sectionIndex == 0){
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                      child: Text('${tInMap('caloriesCounterPage', 'date')}').boldFont(),
                    ),

                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppThemes.currentTheme.primaryColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: SizedBox(
                          height: 50,
                          child: ListView.builder(
                              itemCount: 30,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (ctx, idx){
                                return genDay(idx);
                              }
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// meal
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                    child: Row(
                      children: [
                        Text('${tInMap('caloriesCounterPage', 'meals')}').boldFont(),

                        SizedBox(width: 10,),

                        TextButton(
                            onPressed: (){
                              controller.addMeal();
                            },
                            child: Text('+ ${tInMap('caloriesCounterPage', 'addMeal')}')
                        ),
                      ],
                    ),
                  ),

                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppThemes.currentTheme.primaryColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: LayoutBuilder(
                        builder: (ctx, c){
                          return SizedBox(
                            height: 50,
                            width: c.maxWidth,
                            child: ListView.builder(
                                itemCount: controller.dayCaloriesModel.meals.length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (ctx, idx){
                                  return genMeal(idx);
                                }
                            ),
                          );
                        },
                      ),
                    ),
                  ),


                  /// material
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                    child: Row(
                      children: [
                        Text('${tInMap('caloriesCounterPage', 'materials')}').boldFont(),

                        SizedBox(width: 10,),

                        TextButton(
                            onPressed: (){
                              controller.promptAddMaterial();
                            },
                            child: Text('+ ${tInMap('caloriesCounterPage', 'addMaterial')}')
                        ),
                      ],
                    ),
                  ),

                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppThemes.currentTheme.primaryColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: SizedBox(
                        height: 250,
                        child: ListView.builder(
                          controller: controller.scrollController,
                            itemCount: controller.currentMeal(false)?.getMaterialCount()?? 0,
                            shrinkWrap: true,
                            physics: controller.scrollPhysics,
                            itemBuilder: (ctx, idx){
                              return genMaterial(idx);
                            }
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10,),
                ],
              ),
            );
          }
      ),
    );
  }
  ///==========================================================================================
  Widget genDay(int idx) {
    DateTime dt;
    bool isToday = false;

    if(idx == 0){
      dt = controller.today;
      isToday = true;
    }
    else {
      dt = controller.today.subtract(Duration(days: idx));
    }

    final dateText = DateTools.dateOnlyRelative(dt, isUtc: false);
    final bColor = controller.selectedDayIndex == idx ?
        AppThemes.currentTheme.infoColor
        : (isToday ? AppThemes.currentTheme.accentColor : AppThemes.themeData.chipTheme.backgroundColor);

    final hasCalories = controller.manager.findByDateOnly(DateHelper.toTimestampDate(dt))?.meals.isNotEmpty?? false;
    final textLabel = isToday? Text('${t('today')} $dateText') : Text(dateText);
    final label = hasCalories ? Row(
      textDirection: TextDirection.ltr,
      children: [
        textLabel, flagIcon,
      ],)
        : textLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InputChip(
        backgroundColor: bColor,
        label: label,
        onPressed: () {
          controller.selectedDayIndex = idx;
          controller.selectedDayDate = dt;
          controller.pickDay();

          stateController.updateMain();
        },
      ),
    );
  }

  Widget genMeal(int idx){
    final m = controller.dayCaloriesModel.meals[idx];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InputChip(
        label: Text('${tInMap('caloriesCounterPage', 'theMeal')} ${idx+1}'),
        backgroundColor: controller.selectedMealIndex == idx?
        AppThemes.currentTheme.infoColor : AppThemes.themeData.chipTheme.backgroundColor,
        onSelected: (v){
          controller.selectedMealIndex = idx;
          stateController.updateMain();
        },
        onDeleted: (){
          controller.promptDeleteMeal(m.id);
        },
      ),
    );
  }

  Widget genMaterial(int idx){
    final meal = controller.currentMeal(true)!;
    final material = meal.getProgramMaterials()[idx];

    return Card(
      color: AppThemes.currentTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(material.material?.matchTitle?? '-')
                .color(Colors.white).boldFont(),

            Text('${material.materialValue} ${tInMap('materialUnits', material.material?.measure.unit?? '')?? '-'}')
                .color(Colors.white).subFont(),

            IconButton(
              icon: Icon(IconList.delete).toColor(Colors.white),
              onPressed: (){
                controller.promptDeleteMaterial(material.materialId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget getSearchBar(){
    return StateX(
      controller: stateController,
        id: id$searchbarState,
        builder: (ctx, ctr, data){
          if(!controller.showSearchbar){
            return SizedBox();
          }

          return FloatingSearchBar(
            hint: '${t('search')}...',
            scrollPadding: const EdgeInsets.only(top: 20, bottom: 30),
            transitionDuration: const Duration(milliseconds: 500),
            debounceDelay: const Duration(milliseconds: 800),//delay char type to call query
            transitionCurve: Curves.easeInOut,
            physics: const BouncingScrollPhysics(),
            axisAlignment: 0.0,
            openAxisAlignment: 0.0,
            //width: 600,
            automaticallyImplyBackButton: false,
            clearQueryOnClose: false,
            progress: controller.showProgress,
            onQueryChanged: (query) {
              controller.requestSearchFood(query);
            },
            //transition: CircularFloatingSearchBarTransition(),
            transition: SlideFadeFloatingSearchBarTransition(),
            actions: [
              FloatingSearchBarAction(
                showIfOpened: false,
                child: CircularButton(
                  icon: Icon(IconList.close),
                  onPressed: () {
                    controller.showSearchbar = false;
                    stateController.updateMain();
                  },
                ),
              ),
              FloatingSearchBarAction.searchToClear(
                showIfClosed: false,
              ),
            ],
            builder: (context, transition) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Material(
                  color: Colors.white,
                  elevation: 4.0,
                  child: ListView.builder(
                    shrinkWrap: true,
                      itemCount: controller.foodMaterialList.length,
                      itemBuilder: (ctx, idx){
                        return genMaterialItem(idx);
                      }
                  ),
                ),
              );
            },
          );
        }
    );
  }

  Widget genMaterialItem(int idx){
    final material = controller.foodMaterialList[idx];

    return GestureDetector(
      onTap: (){
        controller.onClickOnMaterial(material);
      },
      child: Card(
          color: AppThemes.currentTheme.accentColor,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${material.matchTitle}')
                        .fsR(6).bold()
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor),
                    SizedBox(height: 8,),
                    Text(material.getMainFundamentalsPrompt(context))
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),
                  ],
                ),

                SizedBox(height: 2,),
                Column(
                  children: [
                    Text('${material.getTypeTranslate(context)}')
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppThemes.currentTheme.whiteOrAppBarItemOnDifferent()),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.all(4),
                      child: Column(
                        children: [
                          Text(material.measure.unitValue)
                              .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),

                          Text('${tInMap('materialUnits', material.measure.unit)}')
                              .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
      ),
    );
  }
}
