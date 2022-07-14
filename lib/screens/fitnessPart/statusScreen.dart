import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/widgets/buttons/outsideButton.dart';
import 'package:iris_tools/widgets/optionsRow/radioRow.dart';
import 'package:iris_tools/widgets/panel/panel.dart';
import 'package:iris_tools/widgets/panel/panelController.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/usersModels/fitnessDataModel.dart';
import '/screens/fitnessPart/addChartItem.dart';
import '/screens/fitnessPart/photosScreen.dart';
import '/screens/fitnessPart/statusScreenCtr.dart';
import '/screens/profile/personalInfoScreen.dart';
import '/system/extensions.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dbCenter.dart';
import '/tools/measureTools.dart';
import '/views/messageViews/mustLoginView.dart';

String sk$lastChartType = 'LastChartType';

class StatusScreen extends StatefulWidget {
  static const screenName = 'StatusScreen';

  StatusScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatusScreenState();
  }
}
///=========================================================================================================
class StatusScreenState extends StateBase<StatusScreen> {
  StateXController stateController = StateXController();
  StatusScreenCtr controller = StatusScreenCtr();
  PanelController panelController = PanelController();


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
    controller.onDispose();
    stateController.dispose();

    super.dispose();
  }

  Widget getPage() {
    return StateX(
      controller: stateController,
      isMain: true,
      builder: (context, ctr, data) {
        return SafeArea(
          child: Builder(
            builder: (BuildContext context) {
              if(!Session.hasAnyLogin()) {
                return MustLoginView(this);
              }

              if(!controller.chartManager!.isUpdated()) {
                controller.requestUserStatus();
              }

              if(!controller.chartManager!.canShowChart) {
                return mustUpdateProfile();
              }

              return getBody();
            },
          ),
        );
      }
    );
  }
  ///==========================================================================================================
  Widget mustUpdateProfile(){
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //PreWidgetsCenter.notFound(),
            //SizedBox(height: 40,),
            Text('${tC('yourProfileIsIncomplete')}').subAlpha(),

            SizedBox(height: 8,),
            InkWell(
              onTap: () {
                AppNavigator.pushNextPage(context,
                    PersonalInfoScreen(),
                    name: PersonalInfoScreen.screenName).then((value){
                  controller.prepareChartData();
                  stateController.updateMain();
                });
              },
              child: Text('${tC('profile')}',
                strutStyle: AppThemes.strutStyle,
                style: AppThemes.currentTheme.textUnderlineStyle,
              ).fsR(2, max: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget getBody(){
    controller.calculateBmi();

    controller.chartLabelStyle = AppThemes.baseTextStyle().copyWith(
        color: AppThemes.currentTheme.whiteOrBlackOn(AppThemes.currentTheme.differentColor)
    );

    return Panel(
      controller: panelController,
      panelMinSize: 0,
      panelMaxSize: MathHelper.limitDouble(320, 450, AppSizes.getScreenHeight(context) / 2),
      parallax: true,
      parallaxOffset: 0.3,
      transformScale: true,
      transformScaleEnd: 1.05,
      footerHeight: 48,
      hideFooter: true,
      footer: getPanelFooter(),
      panel: getPanelPanel(),
      body: getPanelBody(),
    );
  }

  Widget getPanelFooter(){
    return ColoredBox(
      color: Colors.white,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: (){
                panelController.show();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 5, 0),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Icon(Icons.arrow_back_ios_outlined,
                        textDirection: TextDirection.ltr,
                        size: 26,).toColor(AppThemes.currentTheme.underLineDecorationColor),
                    ),
                  ),

                  Text('${t('changeParameter')}',
                    style: AppThemes.currentTheme.textUnderlineStyle.copyWith(
                      decoration: TextDecoration.none,
                    ),
                  ).fsR(1, max: 15),
                ],
              ),
            ),

            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: (){
                AppNavigator.pushNextPage(context, PhotoScreen(), name: PhotoScreen.screenName);
              },
              child: Text('    ${t('photos')}    ',
                style: AppThemes.currentTheme.textUnderlineStyle.copyWith(
                  decoration: TextDecoration.none,
                ),
              ).fsR(1, max: 15),
            ),

          ],
        ),
      ),
    );
  }

  Widget getPanelPanel(){
    final items = tAsMap('bodyStatusTypes')!;
    final names = items.entries;

    //SliverGridDelegateWithFixedCrossAxisCount
    //SliverGridDelegateWithMaxCrossAxisExtent

    return SizedBox(
      height: MathHelper.limitDouble(320, 450, AppSizes.getScreenHeight(context) / 2),
      width: double.infinity,
      child: OutsideButton(
        onCloseTap: () {panelController.hide(); },
        splashColor: AppThemes.currentTheme.differentColor,
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16,),
              Text('    ${tC('selectChartParameter')}').oneLineOverflow$Start().bold().color(Colors.black),
              Expanded(
                child: GridView.builder(
                  itemCount: items.length,
                  scrollDirection: Axis.vertical,
                  physics: ScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  primary: false,
                  clipBehavior: Clip.antiAlias,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 0.0,
                    mainAxisSpacing: 0.0,
                    mainAxisExtent: 40,
                  ),
                  itemBuilder: (BuildContext context, int index){
                    return RadioRow(
                        groupValue: controller.currentChartTypeKey.name,
                        value: names.elementAt(index).key,
                        mainAxisAlignment: MainAxisAlignment.start,
                        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                        onChanged: (dynamic v){
                          var map = DbCenter.fetchKv(sk$lastChartType)?? {};
                          map = JsonHelper.reFormat<String, dynamic>(map);
                          map = JsonHelper.updateMap(map, 'u${controller.user!.userId}', v);
                          DbCenter.setKv(sk$lastChartType, map);

                          controller.currentChartTypeKey = NodeNames.height_node.byName(v)!;
                          controller.prepareChartData();

                          panelController.hide();
                          Future.delayed(Duration(milliseconds: 400), (){
                            stateController.updateMain();
                          });
                        },
                        radio: Radio<String>(
                          groupValue: controller.currentChartTypeKey.name,
                          value: names.elementAt(index).key,
                          onChanged: (v){},
                        ),
                        description: Text('${names.elementAt(index).value}',
                        ).bold().color(Colors.black)
                    );
                  },
                ),
              ),

              SizedBox(height: 20,),
            ],
          ),
        ),
      ),
    );
  }

  Widget getPanelBody(){
    return ColoredBox(
      color: AppThemes.currentTheme.primaryWhiteBlackColor,
      child: Column(
        //mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(5, 12, 5, 2),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                Text('BMI: ${controller.bmiResultNum}'.localeNum())
                    .color(Colors.white).fsR(5, max: 24),
                SizedBox(width: 15,),
                Expanded(
                    child: Text(controller.bmiResultText)
                        .fsR(4, max: 24).color(Colors.white).oneLineOverflow$Start(textAlign: TextAlign.right)
                ),
              ],
            ),
          ),

          ///----- chart
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(5, 0, 5, 2),
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.transparent,
                  minY: controller.chartData.getChartMinYAxisLines(),
                  maxY: controller.chartData.getChartMaxYAxisLines(),
                  minX: 0,
                  maxX: controller.chartData.getChartMaxXAxisLines(),
                  //showingTooltipIndicators: [],
                  clipData: FlClipData(
                    top: true,
                    left: false,
                    right: false,
                    bottom: false,
                  ),
                  betweenBarsData: [
                    //BetweenBarsData(fromIndex: 1 ,toIndex: 2, colors: [Colors.red]),
                  ],
                  lineTouchData: controller.getTouchData(),
                  rangeAnnotations: controller.getAnnotations(),
                  gridData: controller.getGrid(),
                  axisTitleData: controller.getAxisTitles(),
                  titlesData: controller.getTitles(),
                  extraLinesData: controller.getExtraLines(),
                  borderData: controller.getBorders(),
                  lineBarsData: controller.getBars(),
                  showingTooltipIndicators: []
                ),

                swapAnimationDuration: Duration(milliseconds: 150), // Optional
                swapAnimationCurve: Curves.linear, // Optional
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(15, 5, 15, 0),
            child: Row(
              textDirection: TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ColoredBox(
                  color: Colors.white.withAlpha(80),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        Text('${tInMap('bodyStatusTypes', controller.currentChartTypeKey.name)}')
                            .color(Colors.white).fsR(12, max: 30).bold().oneLineOverflow$Start(),

                        SizedBox(width: 10,),
                        Text('${MathHelper.getDecimal(controller.getLastChartValue())}')
                            .color(Colors.white).fsR(16, max: 30).bold(),

                        Text(' ${MeasureTools.getMeasureUnitFor(controller.currentChartTypeKey)}')
                            .ltr().color(Colors.white).bold(),
                      ],
                    ),
                  ),
                ),

                Text('+').fs(35).bold().color(Colors.white)
                    .englishFont()
                    .wrapMaterial(
                  padding: EdgeInsets.all(12),
                  materialColor: Colors.white.withAlpha(80),
                  onTapDelay: (){
                    AppNavigator.pushNextPage(
                        context,
                        AddChartItem(nodeName: controller.currentChartTypeKey),
                        name: 'AddStatusScreen').then((value){
                      controller.prepareChartData();
                      stateController.updateMain();
                    });
                  }
                ),
              ],
            ),
          ),

          SizedBox(height: 44,),
        ],
      ),
    );
  }
}
