import 'package:brandfit_user/tools/centers/dialogCenter.dart';
import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:iris_tools/api/generator.dart';
import 'package:iris_tools/api/helpers/fileHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/api/managers/assetManager.dart';
import 'package:iris_tools/api/tools.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/modules/stateManagers/selfRefresh.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '/abstracts/viewController.dart';
import '/models/dataModels/courseModels/pupilCourseModel.dart';
import '/models/dataModels/programModels/foodDay.dart';
import '/models/dataModels/programModels/foodMeal.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/programModels/foodSuggestion.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/programViewPart/treeScreen/materialScreen.dart';
import '/screens/programViewPart/treeScreen/treeScreen.dart';
import '/system/extensions.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/infoDisplayCenter.dart';
import '/tools/centers/sheetCenter.dart';

class TreeFoodProgramCtr implements ViewController {
  late TreeFoodProgramScreenState state;
  late Requester commonRequester;
  late UserModel user;
  late UserModel? pupilUser;
  late PupilCourseModel pupilCourse;
  late FoodProgramModel programModel;
  List<Node> nodeList = [];
  String currentNodeKey = '';
  late TreeViewController treeViewController;
  TreeViewTheme? treeViewTheme;
  late ExpanderPosition expanderPosition;
  late ExpanderType expanderType;
  late ExpanderModifier expanderWrap;
  late Map<ExpanderModifier, Widget> expansionWrapOptions;
  late String dayLabel;
  late String mealLabel;
  late String suggestLabel;
  late PieChartData chartData;
  int caloriesValue = 0;
  int proteinValue = 0;
  int carValue = 0;
  int fatValue = 0;


  @override
  void onInitState<E extends State>(E state){
    this.state = state as TreeFoodProgramScreenState;

    user = Session.getLastLoginUser()!;
    pupilCourse = state.widget.pupilCourseModel;
    pupilUser = state.widget.pupilUser;
    programModel = state.widget.programModel;

    commonRequester = Requester();
    treeViewController = TreeViewController(children: nodeList);

    dayLabel = state.tInMap('treeFoodProgramPage', 'day')!;
    mealLabel = state.tInMap('treeFoodProgramPage', 'meal')!;
    suggestLabel = state.tInMap('treeFoodProgramPage', 'suggestion')!;

    prepareTree();
    prepareNodes();
  }

  @override
  void onBuild(){
    buildTheme();
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }
  ///=====================================================================================================
  void prepareNodes(){
    nodeList.clear();
    programModel.sortChildren();
    nodeList.addAll(buildNodes(programModel.foodDays, 0, null));
  }

  List<Node> buildNodes(List foods, int level, Node? parent){
    final res = <Node>[];
    var label = dayLabel;
    final idx = programModel.getCurrentReportDay()?? 1;

    if(level == 1){
      label = mealLabel;
    }
    else if(level == 2){
      label = suggestLabel;
    }

    for(int i =0; i < foods.length; i++){
      final item = foods[i];

      final node = Node(
        label: '$label ${item.ordering}',
        key: '${Generator.generateName(8)}_${item.id}',
        data: item,
        children: <Node>[],
        expanded: level == 0? (i+1 == idx): false,
      );

      res.add(node);

      if(level == 0) {
        item.sortChildren();
        node.children = buildNodes(item.mealList, level + 1, node);
      }
      else if(level == 1) {
        item.sortChildren();
        node.children = buildNodes(item.suggestionList, level + 1, node);
      }
    }

    return res;
  }

  void prepareTree(){
    /*expansionPositionOptions = const {
      ExpanderPosition.start: Text('Start'),
      ExpanderPosition.end: Text('End'),
    };

    expansionTypeOptions = {
      ExpanderType.none: SizedBox(),
      ExpanderType.caret: Icon(Icons.arrow_drop_down, size: 28,),
      ExpanderType.arrow: Icon(Icons.arrow_downward),
      ExpanderType.chevron: Icon(Icons.expand_more),
      ExpanderType.plusMinus: Icon(Icons.add),
    };*/

    expansionWrapOptions = const {
      ExpanderModifier.none: ExpanderWrap(ExpanderModifier.none),
      ExpanderModifier.circleFilled: ExpanderWrap(ExpanderModifier.circleFilled),
      ExpanderModifier.circleOutlined: ExpanderWrap(ExpanderModifier.circleOutlined),
      ExpanderModifier.squareFilled: ExpanderWrap(ExpanderModifier.squareFilled),
      ExpanderModifier.squareOutlined: ExpanderWrap(ExpanderModifier.squareOutlined),
    };

    expanderPosition = ExpanderPosition.end;
    expanderType = ExpanderType.caret;
    expanderWrap = ExpanderModifier.circleFilled;
  }

  void buildTheme(){
    if(treeViewTheme != null){
      return;
    }

    treeViewTheme = TreeViewTheme(
      dense: true,
      verticalSpacing: 0,
      //horizontalSpacing: 0,
      //levelPadding: 0,
      expanderTheme: ExpanderThemeData(
          type: expanderType,
          modifier: expanderWrap,
          position: expanderPosition,
          size: 18,
          color: Colors.grey
      ),
      labelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.3,
      ),
      parentLabelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w800,
        //color: Colors.blue.shade700,
        color: AppThemes.currentTheme.primaryColor,
      ),
      iconTheme: IconThemeData(
        size: 18,
        color: Colors.grey.shade800,
      ),
      colorScheme: Theme.of(state.context).colorScheme,
    );
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is TreeFoodProgramScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  Node? getParent(String key, {Node? parent}) {
    Node? _found;
    List<Node> _children = parent != null ? parent.children : nodeList;
    Iterator iter = _children.iterator;

    while (iter.moveNext()) {
      Node child = iter.current;

      if (child.key == key) {
        _found = parent?? child;
        break;
      }
      else {
        if (child.isParent) {
          _found = getParent(key, parent: child);

          if (_found != null) {
            break;
          }
        }
      }
    }

    return _found;
  }

  void showFoodSuggestionPrompt(Node node) async {
    Node parent1 = getParent(node.key)!;
    Node parent2 = getParent(parent1.key)!;

    FoodSuggestion suggestion = node.data;
    FoodMeal meal = parent1.data;
    FoodDay day = parent2.data;

    showMaterialPage(day, meal, suggestion);
  }

  void showMaterialPage(FoodDay foodDay, FoodMeal foodMeal, FoodSuggestion sug){
    AppNavigator.pushNextPage(
        state.context,
        MaterialScreen(
          foodProgram: programModel,
          foodDay: foodDay,
          foodMeal: foodMeal,
          foodSuggestion: sug,
        ),
        name: MaterialScreen.screenName
    );
  }

  void showPdfDialog() async {
    DialogCenter.instance.showDialog(
        state.context,
      desc: state.tInMap('treeFoodProgramPage', 'selectSavePath'),
      yesText: state.t('select'),
      yesFn: (){
        createPdf();
      }
    );
  }

  void createPdf() async {
    final pdf = pw.Document();
    //final font = await PdfGoogleFonts.nunitoExtraLight();
    final fontData = await AssetsManager.load('assets/fonts/sans-sub.ttf');
    //final fontData = await AssetsManager.load('assets/fonts/nazanin-base-sub.ttf');
    final ttf = pw.Font.ttf(fontData!.buffer.asByteData());

    final p1 = pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
        ),
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children:[
                      pw.Text(pupilUser!.userName, style: pw.TextStyle(fontSize: 20,),)
                    ]
                  ),
                  pw.Text('${programModel.title}', style: pw.TextStyle(fontSize: 20),),
                ]
            ),

            pw.SizedBox(height: 30),
            pw.Table(
                border: pw.TableBorder.all(),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  ...genTableChildren(),
                ]
            )
          ]; // Center
        });

    pdf.addPage(p1);

    final data = await pdf.save();
    var path = await Tools.openSaveDirectory(title: 'محل ذخیره');

    if(path == null){
      return;
    }

    final name = '${programModel.title}_${Generator.generateName(2)}';
    path += '/$name.pdf';
    await FileHelper.writeByteData(path, data.buffer.asByteData());

    SheetCenter.showSheetOk(state.context, '${state.tInMap('treeFoodProgramPage', 'saveFileByName')}\n $name');
  }

  List<pw.TableRow> genTableChildren(){
    final dayStyle = pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold);
    final mealStyle = pw.TextStyle(fontSize: 18);
    final res = <pw.TableRow>[];

    for(var i=0; i< programModel.foodDays.length; i++){
      final day = programModel.foodDays[i];

      final dayRow = pw.TableRow(
          children: [
            pw.SizedBox(
                width: double.maxFinite,
                child: pw.DecoratedBox(
                    decoration: pw.BoxDecoration(
                      color: PdfColor(0.6, 0.6, 0.6),
                    ),
                    child: pw.Align(
                      child: pw.Padding(
                          padding: pw.EdgeInsets.symmetric(vertical: 8),
                          child: pw.Text('$dayLabel ${day.ordering}', style: dayStyle)
                      ),
                    )
                )
            ),
          ]
      );

      res.add(dayRow);

      for(final meal in day.mealList){
        var mealText = '$mealLabel ${meal.ordering}';

        if(meal.title != null) {
          mealText = '${meal.title}';
        }
        //mealText = LocaleHelper.numberToFarsi(mealText);

        final mealRow = pw.TableRow(
            children: [
              pw.SizedBox(
                  width: double.maxFinite,
                  child: pw.DecoratedBox(
                      decoration: pw.BoxDecoration(
                        color: PdfColor(0.8, 0.8, 0.8),
                      ),
                      child: pw.Align(
                        child: pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Text(mealText, style: mealStyle)
                        ),
                      )
                  )
              ),
            ]
        );

        res.add(mealRow);

        final suggestions = meal.suggestionList;

        final sugTable = pw.TableRow(
            children: [
              pw.Table(
                  border: pw.TableBorder.all(),
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    pw.TableRow(
                        children: [
                          ...List.generate(suggestions.length, (index) {
                            final curSug = suggestions[index];
                            var sugTile = '$suggestLabel ${curSug.ordering}';

                            if(curSug.title != null){
                              sugTile += ' - ${curSug.title}';
                            }

                            if(curSug.isBase){
                              sugTile += ' *';
                            }

                            return pw.Align(
                              child: pw.Padding(
                                  padding: pw.EdgeInsets.symmetric(vertical: 4),
                                  child: pw.Text(sugTile)
                              ),
                            );
                          }),
                        ]
                    ),

                    pw.TableRow(
                        children: [
                          ...List.generate(suggestions.length, (index) {
                            final curSug = suggestions[index];

                            return pw.Wrap(
                                  children: [
                                    ...List.generate(curSug.materialList.length, (index){
                                      final curMat = curSug.materialList[index];
                                      var text = curMat.material!.matchTitle?? curMat.material!.orgTitle;
                                      text += ' ${curMat.materialValue} ${state.tInMap('materialUnits', '${curMat.unit}')}';

                                      //text = LocaleHelper.numberToFarsi(text);

                                      return pw.Padding(
                                          padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          child: pw.DecoratedBox(
                                            decoration: pw.BoxDecoration(
                                                border: pw.Border.all(),
                                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))
                                            ),
                                            child: pw.Padding(
                                                padding: pw.EdgeInsets.symmetric(horizontal: 4),
                                                child: pw.Text(text)
                                            ),
                                          )
                                      );
                                    })
                                  ]
                            );
                          }),
                        ]
                    )
                  ]
              )
            ]
        );

        res.add(sugTable);
      }
    }

    return res;
  }

  void showBaseChart(){
    proteinValue = 0;
    carValue = 0;
    fatValue = 0;
    calcChartData();

    void reCalc(){
      proteinValue = programModel.getPlanProtein()?? 0;
      carValue = programModel.getPlanCarbohydrate()?? 0;
      fatValue = programModel.getPlanFat()?? 0;
      calcChartData();
    }

    final content = GestureDetector(
      behavior: HitTestBehavior.translucent,
        child: GestureDetector(
          onTap: (){},
          child: Align(
            child: SelfRefresh(
                builder: (ctx, ctr) {
                  Future.delayed(Duration(milliseconds: 500), (){
                    if(ctr.exist('reCall')){
                      return;
                    }

                    reCalc();

                    ctr.set('reCall', true);
                    ctr.update();
                  });

                  return FractionallySizedBox(
                    widthFactor: 0.85,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(26.0, 16, 26.0, 26.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${state.tInMap('treeFoodProgramPage', 'mainValuesForAnyDay')}')
                                .boldFont(),

                            Center(
                              child: SizedBox(
                                width: 150,
                                height: 150,
                                child: PieChart(chartData),
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TabPageSelectorIndicator(
                                      backgroundColor: Colors.lightGreenAccent.shade200,
                                      borderColor: Colors.lightGreenAccent.shade200,
                                      size: 15,
                                    ),
                                    Text('${state.tInMap('materialFundamentals', 'protein')}'),
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
                                    Text('${state.tInMap('materialFundamentals', 'carbohydrate')}'),
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
                                    Text('${state.tInMap('materialFundamentals', 'fat')}'),
                                  ],
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(indent: 30, endIndent: 30,),
                            ),

                            Text('${state.tInMap('materialFundamentals', 'calories')} : $caloriesValue').bold(),
                            Text('${state.tInMap('materialFundamentals', 'protein')} : $proteinValue').bold(),
                            Text('${state.tInMap('materialFundamentals', 'carbohydrate')} : $carValue').bold(),
                            Text('${state.tInMap('materialFundamentals', 'fat')} : $fatValue').bold(),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            ),
          ),
        ),
        onTap: (){
          AppNavigator.pop(state.context);
        },
    );

    final dialog = OverlayScreenView(content: content, routingName: 'charDialog',);
    OverlayDialog().show(state.context, dialog, canBack: true, background: Colors.black54);
  }

  void calcChartData(){
    final sections = <PieChartSectionData>[];
    final pro = (proteinValue *4);
    final car = (carValue *4);
    final fat = (fatValue *9);
    caloriesValue = fat + pro + car;

    final proPercent = MathHelper.percentFix(caloriesValue.toDouble(), pro);
    final carPercent = MathHelper.percentFix(caloriesValue.toDouble(), car);
    final fatPercent = MathHelper.percentFix(caloriesValue.toDouble(), fat);

    final p = PieChartSectionData(
      title: '',
      value: pro.toDouble(),
      color: Colors.lightGreenAccent.shade200,
      radius: 60,
      badgeWidget: Text('$proPercent %'),
    );

    final c = PieChartSectionData(
      title: '',
      value: car.toDouble(),
      color: Colors.lightBlue.shade200,
      radius: 60,
      badgeWidget: Text('$carPercent %'),
    );

    final l = PieChartSectionData(
      title: '',
      value: fat.toDouble(),
      color: Colors.redAccent.shade200,
      radius: 60,
      badgeWidget: Text('$fatPercent %'),
    );

    final empty = PieChartSectionData(
      title: '',
      value: 100.0,
      color: Colors.grey.shade300,
      radius: 60,
    );

    sections.add(l);
    sections.add(p);
    sections.add(c);

    if(caloriesValue < 5) {
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

  void showHelp(){
    var lines = state.tJoin('helpTextForTreePage', join: '\n');

    InfoDisplayCenter.showMiniInfo(
        state.context,
        Text('$lines').boldFont(),
    );
  }
}
///=================================================================================
class ExpanderWrap extends StatelessWidget {
  final ExpanderModifier modifier;

  const ExpanderWrap(this.modifier, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _borderWidth = 0;
    BoxShape _shapeBorder = BoxShape.rectangle;
    Color _backColor = Colors.transparent;
    Color _backAltColor = Colors.grey.shade700;

    switch (modifier) {
      case ExpanderModifier.none:
        break;
      case ExpanderModifier.circleFilled:
        _shapeBorder = BoxShape.circle;
        _backColor = _backAltColor;
        break;
      case ExpanderModifier.circleOutlined:
        _borderWidth = 1;
        _shapeBorder = BoxShape.circle;
        break;
      case ExpanderModifier.squareFilled:
        _backColor = _backAltColor;
        break;
      case ExpanderModifier.squareOutlined:
        _borderWidth = 1;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        shape: _shapeBorder,
        border: _borderWidth == 0
            ? null
            : Border.all(
          width: _borderWidth,
          color: _backAltColor,
        ),
        color: _backColor,
      ),
      width: 15,
      height: 15,
    );
  }
}
