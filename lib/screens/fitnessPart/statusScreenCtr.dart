import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/managers/userChartManager.dart';
import '/models/dataModels/chartModels/chartDataModel.dart';
import '/models/dataModels/usersModels/fitnessDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/fitnessPart/statusScreen.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appThemes.dart';
import '/tools/bmiTools.dart';
import '/tools/centers/cacheCenter.dart';
import '/tools/centers/dbCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/snackCenter.dart';
import '/tools/dateTools.dart';

class StatusScreenCtr implements ViewController {
  late StatusScreenState state;
  Requester? statusRequester;
  UserModel? user;
  UserChartManager? chartManager;
  late TextStyle chartLabelStyle;
  double bmiResultNum = 0;
  String bmiResultText = '';
  NodeNames currentChartTypeKey = NodeNames.height_node;
  late ChartDataModel chartData;


  @override
  void onInitState<E extends State>(E state){
    this.state = state as StatusScreenState;

    statusRequester = Requester();
    statusRequester!.requestPath = RequestPath.GetData;

    Session.addLoginListener(onLogin);
    Session.addLogoffListener(onLogout);

    if(Session.hasAnyLogin()){
      user = Session.getLastLoginUser()!;
      chartManager = UserChartManager.managerFor(user!.userId);
      final map = DbCenter.fetchKv(sk$lastChartType)?? {};
      final t = map['u${user!.userId}'];
      currentChartTypeKey = NodeNames.height_node.byName(t)?? NodeNames.height_node;
      prepareChartData();
    }
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(statusRequester?.httpRequester);
    Session.removeLoginListener(onLogin);
    Session.removeLogoffListener(onLogout);
  }

  void onLogin(UserModel user){
    this.user = user;
    chartManager = UserChartManager.managerFor(user.userId);
    final map = DbCenter.fetchKv(sk$lastChartType)?? {};
    final t = map['u${user.userId}'];
    currentChartTypeKey = NodeNames.height_node.byName(t)?? NodeNames.height_node;

    prepareChartData();

    state.stateController.updateMain();
  }

  void onLogout(UserModel user){
    HttpCenter.cancelAndClose(statusRequester?.httpRequester);
    this.user = null;

    state.stateController.updateMain();
  }

  void prepareChartData(){
    chartData = chartManager!.chartDataFor(currentChartTypeKey);
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is StatusScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  FlGridData getGrid(){
    return FlGridData(
      show: true,
      drawHorizontalLine: true,
      drawVerticalLine: false,
      horizontalInterval: chartData.getChartYInterval(),
      verticalInterval: 2,
      checkToShowHorizontalLine: (double value){
        if(value >= chartData.getChartMaxYAxisLines()) {
          return false;
        }
        //if((value - state.chartData.minValue!) % state.chartData.getChartYInterval() == 0)
        //return true;

        return true;
      },
      getDrawingHorizontalLine: (double val){
        return FlLine(
          color: chartLabelStyle.color,
          strokeWidth: 0.6,
          //dashArray: [7, 5],
        );
      },
      getDrawingVerticalLine: (double val){
        return FlLine(
          color: chartLabelStyle.color,
          strokeWidth: 0.6,
        );
      },
    );
  }

  RangeAnnotations getAnnotations(){
    return RangeAnnotations(
        horizontalRangeAnnotations: [
          //HorizontalRangeAnnotation(y1: 4, y2: 6, color: Colors.cyanAccent),
        ],
        verticalRangeAnnotations: [
          //VerticalRangeAnnotation(x1: 20, x2: 40, color: Colors.brown, ),
        ]
    );
  }

  LineTouchData getTouchData(){
    final style = AppThemes.baseTextStyle().copyWith(
      color: AppThemes.currentTheme.whiteOrBlackOn(AppThemes.currentTheme.differentColor),
      fontWeight: FontWeight.bold,
    );

    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: Colors.grey[600],
        showOnTopOfTheChartBoxArea: false,
        getTooltipItems: (List<LineBarSpot> touchedSpots){
          final res = <LineTooltipItem?>[];

          for(var i=0; i< touchedSpots.length; i++){
            final spot = touchedSpots.elementAt(i);
            var date = '';
            final dt = chartData.findByY(spot.y)?.utcDate;

            if(dt != null) {
              date = DateTools.dateRelativeByAppFormat(dt, format: 'YYYY/MM/DD');
            }

            final it = LineTooltipItem(
                '${spot.y} \n $date',
                style
            );

            res.add(it);
          }

          return res;
        },
      ),
    );
  }

  ExtraLinesData getExtraLines(){
    return ExtraLinesData(
      extraLinesOnTop: false,
      /*horizontalLines: [
                HorizontalLine(y: 1,
                  color: Colors.red,
                  strokeWidth: 1,
                  label: HorizontalLineLabel(show: true,
                      labelResolver: (h)=> 'red',
                      style: state.chartLabel),
                ),
              ],*/
    );
  }

  FlTitlesData getTitles(){
    return FlTitlesData(
      show: true,

      topTitles: SideTitles(
        showTitles: false,
        interval: 1,
        reservedSize: AppThemes.baseFont.size! * 2,
        margin: 2,
        rotateAngle: 0,
        checkToShowTitle: (double minValue, double maxValue, SideTitles sideTitles,
            double appliedInterval, double value) {
          if(maxValue == value) {
            return false;
          }

          if(minValue == value) {
            return true;
          }

          if((value - minValue) % chartData.getChartYInterval() == 0) {
            return true;
          }

          return false;
        },
        getTitles: (double value){
          return '${value.toInt()}';
        },
        getTextStyles: (ctx, double value){
          return chartLabelStyle.copyWith(fontSize: chartLabelStyle.fontSize!+1, fontWeight: FontWeight.bold);
        },
      ),

      rightTitles: SideTitles(
        showTitles: false,
        interval: 1,
        reservedSize: AppThemes.baseFont.size! * 2,
        margin: 2,
        rotateAngle: 0,
        checkToShowTitle: (double minValue, double maxValue, SideTitles sideTitles,
            double appliedInterval, double value) {
          if(maxValue == value) {
            return false;
          }

          if(minValue == value) {
            return true;
          }

          if((value - minValue) % chartData.getChartYInterval() == 0) {
            return true;
          }

          return false;
        },
        getTitles: (double value){
          return '${value.toInt()}';
        },
        getTextStyles: (ctx, double value){
          return chartLabelStyle.copyWith(fontSize: chartLabelStyle.fontSize!+1, fontWeight: FontWeight.bold);
        },
      ),

      leftTitles: SideTitles(
        showTitles: true,
        interval: 1,
        reservedSize: AppThemes.baseFont.size! * 2,
        margin: 2,
        rotateAngle: 0,
        checkToShowTitle: (double minValue, double maxValue, SideTitles sideTitles,
            double appliedInterval, double value) {
          if(maxValue == value) {
            return false;
          }

          if(minValue == value) {
            return true;
          }

          if((value - minValue) % chartData.getChartYInterval() == 0) {
            return true;
          }

          return false;
        },
        getTitles: (double value){
          return '${value.toInt()}';
        },
        getTextStyles: (ctx, double value){
          return chartLabelStyle.copyWith(fontSize: chartLabelStyle.fontSize!+1, fontWeight: FontWeight.bold);
        },
      ),

      bottomTitles: SideTitles(
        showTitles: true,
        interval: 1.0,
        rotateAngle: 45,
        checkToShowTitle: (double minValue, double maxValue, SideTitles sideTitles,
            double appliedInterval, double value) {

          return true;
        },
        getTitles: (double value){
          return chartData.getDateTitle(value);
        },
        getTextStyles: (ctx, double value){
          return chartLabelStyle;
        },
      ),
    );
  }

  FlAxisTitleData getAxisTitles(){
    return FlAxisTitleData(
      show: true,
      bottomTitle: AxisTitle(
        showTitle: true,
        titleText: DateTools.dateRelativeByAppFormat(DateTime.now()),
        textAlign: TextAlign.end,
        textStyle: chartLabelStyle.copyWith(fontSize: 15),
      ),
    );
  }

  FlBorderData getBorders(){
    return FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
            color: chartLabelStyle.color!,
            width: 1,
            style: BorderStyle.solid,
          ),
        )
    );
  }

  List<LineChartBarData> getBars(){
    List<FlSpot> getItems(){
      chartData.prepareX();

      final res = <FlSpot>[];

      for(var i=0; i< chartData.workNodeList.length; i++){
        final d = chartData.workNodeList.elementAt(i);

        res.add(FlSpot(d.x, d.value!));
      }

      return res;
    }

    return [
      LineChartBarData(
        show: true,
        colors: [Colors.white],
        barWidth: 1.5,
        isCurved: false,
        isStrokeCapRound: true,
        isStepLineChart: false,
        //lineChartStepData: LineChartStepData(stepDirection: 2,),
        //showingIndicators: [0, 5, 8],
        dotData: FlDotData(
          show: true,
          checkToShowDot: (FlSpot spot, LineChartBarData barData) => true,
          getDotPainter: (flSpot, d, barData, index){
            return FlDotCirclePainter(
              color: Colors.transparent,
              strokeWidth: chartData.measure > 90? 5 : 3,
              radius: chartData.measure > 90? 2 : 0,
              strokeColor: chartLabelStyle.color,
            );
          },
        ),
        spots: getItems(),
        //aboveBarData: BarAreaData(show: true, spotsLine: BarAreaSpotsLine()),
      ),
    ];
  }

  void calculateBmi(){
    if(!chartManager!.canShowChart) {
      return;
    }

    bmiResultNum = BmiTools.calculateBmi(user!.fitnessDataModel.height!, user!.fitnessDataModel.weight!);
    bmiResultText = BmiTools.bmiDescription(state.context, bmiResultNum);
  }

  double getLastChartValue(){
    var res = 0.0;

    if(chartData.workNodeList.isNotEmpty) {
      res = chartData.workNodeList.last.value?? 0;
    }

    return res;
  }

  void requestUserStatus() {
    if(!CacheCenter.timeoutCache.addTimeout('requestUserStatus', Duration(seconds: 8))) {
      return;
    }

    FocusHelper.hideKeyboardByUnFocus(state.context);

    final js = <String, dynamic>{};
    js[Keys.request] = 'GetUserFitnessStatus';
    js[Keys.userId] = user!.userId;

    statusRequester?.bodyJson = js;

    statusRequester?.httpRequestEvents.onNetworkError = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    statusRequester?.httpRequestEvents.onResponseError = (req, isOk) async {
      if(isOk){
        SnackCenter.showSnack$errorInServerSide(state.context);
      } else {
        SnackCenter.showSnack$serverNotRespondProperly(state.context);
      }
    };

    statusRequester?.httpRequestEvents.onResultError = (req, data) async {
      SnackCenter.showSnack$errorInServerSide(state.context);

      return true;
    };

    statusRequester?.httpRequestEvents.onResultOk = (req, data) async {
      final Map<String, dynamic>? fitness = data['fitness_status_js'];

      if(fitness != null) {
        user!.fitnessDataModel.matchBy(FitnessDataModel.fromMap(fitness));
        prepareChartData();
      }

      chartManager!.setUpdate();

      await Session.sinkUserInfo(user!).then((value) {
        state.stateController.updateMain();
      });
    };

    statusRequester?.request(state.context);
  }
}
