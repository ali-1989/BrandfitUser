import 'package:flutter/material.dart';

import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/widgets/horizontalPicker.dart';
import 'package:iris_tools/widgets/icon/circularIcon.dart';
import 'package:iris_tools/modules/stateManagers/refresh.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/system/extensions.dart';
import '/system/httpProcess.dart';
import '/system/keys.dart';
import '/system/session.dart';
import '/tools/app/appManager.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/centers/snackCenter.dart';
import '/views/loadingScreen.dart';

class JobActivityScreen extends StatefulWidget {
  JobActivityScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return JobActivityScreenState();
  }
}
///=====================================================================================
class JobActivityScreenState extends StateBase<JobActivityScreen> {
  UserModel user = Session.getLastLoginUser()!;
  HttpRequester? requestObj;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    return getScaffold();
  }

  @override
  void dispose() {
    HttpCenter.cancelAndClose(requestObj);

    super.dispose();
  }

  Widget getScaffold() {
    return WillPopScope(
      onWillPop: () => onWillBack(this),
      child: Scaffold(
        key: scaffoldKey,
        appBar: getAppbar(),
        body: getScaffoldBody(),
      ),
    );
  }

  PreferredSizeWidget getAppbar() {
    return AppBar(
      title: Text(tC('jobActivity')!),
    );
  }

  Widget getScaffoldBody() {
    return SizedBox(
      width: AppSizes.getScreenWidth(context),
      height: AppSizes.getScreenHeight(context),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: AppThemes.currentTheme.activeItemColor.withAlpha(150),
                width: 0.8,
              ),
            ),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              shrinkWrap: true,
              children: [
                getGoal(this),
                Divider(indent: 10, endIndent: 10,),
                getJob(this),
                Divider(indent: 10, endIndent: 10,),
                getWork(this),
                Divider(indent: 10, endIndent: 10,),
                getSleep(this),
                Divider(indent: 10, endIndent: 10,),
                getExercise(this),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///========================================================================================================
  Widget getJob(JobActivityScreenState state){
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){
        showChangeJobType('ChangeJobTypeSheet');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${t('jobType')}  ').infoColor(),

            Flexible(
              child: Builder(builder: (ctx){
                if(user.jobActivityModel.jobType == null) {
                  return Text('${t('select')}',).bold().color(Colors.blue);
                }
                else {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text('${user.jobActivityModel.jobTypeTranslate(context)}',
                            maxLines: 1,).bold(),
                        ),
                        SizedBox(width: 8,),
                        Icon(Icons.arrow_back_ios,
                          size: 12,
                          textDirection: AppThemes.getOppositeDirection(),
                        )
                      ]
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  void showChangeJobType( String screenName){
    var selectedJob = user.jobActivityModel.jobType?? '';
    final Map jobs = tAsMap('jobTypes')!;
    final tra = jobs.entries;

    if(selectedJob.isNotEmpty){
      final find = tra.firstWhereSafe((element) {
        return element.key == selectedJob;
      });

      if(find != null) {
        selectedJob = find.key;
      }
      else {
        selectedJob = tra.first.key;
      }
    }
    else {
      selectedJob = tra.first.key;
    }

    final updater = RefreshController();

    List<Widget> getRadios(){
      final radios = <Widget>[];

      for(var i=0; i < tra.length; i++){
        final cas = tra.elementAt(i);

        final Widget r = Row(
          children: [
            Radio<String>(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              groupValue: selectedJob,
              value: cas.key,
              onChanged: (val) {
                if(val != null) {
                  //selectedJob = tra.firstWhereSafe((element) => element.value == val)!.key;
                  selectedJob = val;
                  updater.update();
                }
              },
            ),
            Text(' ${cas.value}', style: AppThemes.baseTextStyle(),),
          ],
        );

        radios.add(r);
      }

      return radios;
    }

    final Widget view = SizedBox(
      width: AppSizes.getScreenWidth(context),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Transform.translate(
              offset: Offset(0, -18),
              child: GestureDetector(
                onTap: (){AppNavigator.pop(context);},
                child: CircularIcon(
                  icon: Icons.close,
                  size: 38,
                  padding: 6,
                  backColor: AppThemes.currentTheme.backgroundColor,
                  itemColor: AppThemes.currentTheme.textColor,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: FlipInX(
              delay: Duration(milliseconds: 300),
              child: Refresh(
                  controller: updater,
                  builder: (context, ctr) {

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tC('jobType')}:').bold().fs(16),
                        SizedBox(height: AppSizes.fwSize(16),),
                        ...getRadios()
                      ],
                    );
                  }
              ),
            ),
          ),
        ],
      ),
    );

    SheetCenter.showSheetCustom(
      context,
      view,
      useExpanded: false,
      positiveButton: ElevatedButton(
        child: Text('${tC('apply')}'),
        onPressed: (){
          updateJobType(selectedJob);
        },
      ),
      routeName: 'ChangeJobType',
      backgroundColor: AppThemes.currentTheme.backgroundColor,
      contentColor: AppThemes.currentTheme.backgroundColor,
    ).then((value){
      update();
    });
  }

  Widget getGoal(JobActivityScreenState state){
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){
        showChangeGoal('ChangeGoalSheet');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t('mainGoalFromFitness')}').oneLineOverflow$Start().infoColor(),
            SizedBox(height: 8,),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Builder(builder: (ctx){
                      if(user.jobActivityModel.goalOfFitness == null) {
                        return Text('${t('select')}',).bold().color(Colors.blue);
                      }
                      else {
                        return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${user.jobActivityModel.goalOfFitnessTranslate(context)}',).bold(),
                              SizedBox(width: 8,),
                              Icon(Icons.arrow_back_ios,
                                size: 12,
                                textDirection: AppThemes.getOppositeDirection(),
                              )
                            ]
                        );
                      }
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showChangeGoal( String screenName){
    var selectedGoal = user.jobActivityModel.goalOfFitness?? '';
    final Map jobs = tAsMap('mainGoalFromFitnessList')!;
    final tra = jobs.entries;

    if(selectedGoal.isNotEmpty){
      final find = tra.firstWhereSafe((element) {
        return element.key == selectedGoal;
      });

      if(find != null) {
        selectedGoal = find.key;
      }
      else {
        selectedGoal = tra.first.key;
      }
    }
    else {
      selectedGoal = tra.first.key;
    }

    final updater = RefreshController();

    List<Widget> getRadios(){
      final radios = <Widget>[];

      for(var i=0; i < tra.length; i++){
        final cas = tra.elementAt(i);

        final Widget r = Row(
          children: [
            Radio<String>(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              groupValue: selectedGoal,
              value: cas.key,
              onChanged: (val) {
                if(val != null) {
                  //selectedJob = tra.firstWhereSafe((element) => element.value == val)!.key;
                  selectedGoal = val;
                  updater.update();
                }
              },
            ),
            Text(' ${cas.value}', style: AppThemes.baseTextStyle(),),
          ],
        );

        radios.add(r);
      }

      return radios;
    }

    final Widget view = SizedBox(
      width: AppSizes.getScreenWidth(context),
      height: AppSizes.getMaxSheetHeight(context),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Transform.translate(
              offset: Offset(0, -18),
              child: GestureDetector(
                onTap: (){AppNavigator.pop(context);},
                child: CircularIcon(
                  icon: Icons.close,
                  size: 38,
                  padding: 6,
                  backColor: AppThemes.currentTheme.backgroundColor,
                  itemColor: AppThemes.currentTheme.textColor,
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: FlipInX(
                delay: Duration(milliseconds: 300),
                child: Refresh(
                    controller: updater,
                    builder: (context, ctr) {

                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${tC('mainGoalFromFitness')}').bold().oneLineOverflow$Start().fs(14),
                          SizedBox(height: AppSizes.fwSize(16),),
                          Expanded(
                            child: Scrollbar(
                              isAlwaysShown: true,
                              child: ListView(
                                children: [
                                  ...getRadios()
                                ],
                              ),
                            ),
                          )
                        ],
                      );
                    }
                ),
              ),
            ),
          ),
        ],
      ),
    );

    SheetCenter.showSheetCustom(
      context,
      view,
      useExpanded: false,
      positiveButton: ElevatedButton(
        child: Text('${tC('apply')}'),
        onPressed: (){
          updateGoal(selectedGoal);
        },
      ),
      routeName: 'ChangeGoal',
      backgroundColor: AppThemes.currentTheme.backgroundColor,
      contentColor: AppThemes.currentTheme.backgroundColor,
    ).then((value){
      update();
    });
  }

  Widget getWork(JobActivityScreenState state){
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){
        showChangeWork('ChangeWorkSheet');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t('activityDuringNonWorkingHours')}').infoColor().oneLineOverflow$Start(),
            SizedBox(height: 8,),
            Row(
              children: [
                Text('(${t('exceptForExerciseTime')})').infoColor(),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Builder(builder: (ctx){
                      if(user.jobActivityModel.noneWorkActivity == null) {
                        return Text('${t('select')}').bold().oneLineOverflow$End().color(Colors.blue);
                      }
                      else {
                        return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${tInMap('nonWorkingActivity', user.jobActivityModel.noneWorkActivity!)}',)
                                  .bold().oneLineOverflow$End(),
                              SizedBox(width: 8,),
                              Icon(Icons.arrow_back_ios,
                                size: 12,
                                textDirection: AppThemes.getOppositeDirection(),
                              )
                            ]
                        );
                      }
                    }),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void showChangeWork( String screenName){
    var selectedActivity = user.jobActivityModel.noneWorkActivity?? '';
    final updater = RefreshController();

    List<Widget> getRadios(){
      final radios = <Widget>[];

      final Widget r1 = Row(
        children: [
          Radio<String>(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            groupValue: selectedActivity,
            value: 'inactive',
            onChanged: (val) {
              if(val != null) {
                selectedActivity = val;
                updater.update();
              }
            },
          ),
          Text(' ${tInMap('nonWorkingActivity', 'inactive')}', style: AppThemes.baseTextStyle(),),
        ],
      );

      final Widget r2 = Row(
        children: [
          Radio<String>(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            groupValue: selectedActivity,
            value: 'littleActive',
            onChanged: (val) {
              if(val != null) {
                selectedActivity = val;
                updater.update();
              }
            },
          ),
          Text(' ${tInMap('nonWorkingActivity', 'littleActive')}', style: AppThemes.baseTextStyle(),),
        ],
      );

      final Widget r3 = Row(
        children: [
          Radio<String>(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            groupValue: selectedActivity,
            value: 'active',
            onChanged: (val) {
              if(val != null) {
                selectedActivity = val;
                updater.update();
              }
            },
          ),
          Text(' ${tInMap('nonWorkingActivity', 'active')}', style: AppThemes.baseTextStyle(),),
        ],
      );

      final Widget r4 = Row(
        children: [
          Radio<String>(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            groupValue: selectedActivity,
            value: 'veryActive',
            onChanged: (val) {
              if(val != null) {
                selectedActivity = val;
                updater.update();
              }
            },
          ),
          Text(' ${tInMap('nonWorkingActivity', 'veryActive')}', style: AppThemes.baseTextStyle(),),
        ],
      );

      radios.add(r1);
      radios.add(r2);
      radios.add(r3);
      radios.add(r4);

      return radios;
    }

    final Widget view = SizedBox(
      width: AppSizes.getScreenWidth(context),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Transform.translate(
              offset: Offset(0, -18),
              child: GestureDetector(
                onTap: (){AppNavigator.pop(context);},
                child: CircularIcon(
                  icon: Icons.close,
                  size: 38,
                  padding: 6,
                  backColor: AppThemes.currentTheme.backgroundColor,
                  itemColor: AppThemes.currentTheme.textColor,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: FlipInX(
              delay: Duration(milliseconds: 300),
              child: Refresh(
                  controller: updater,
                  builder: (context, ctr) {

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tC('activityDuringNonWorkingHours')}:', maxLines: 1,).bold().fs(15),
                        SizedBox(height: AppSizes.fwSize(16),),
                        ...getRadios()
                      ],
                    );
                  }
              ),
            ),
          ),
        ],
      ),
    );

    SheetCenter.showSheetCustom(
      context,
      view,
      useExpanded: false,
      positiveButton: ElevatedButton(
        child: Text('${tC('apply')}'),
        onPressed: (){
          updateNonWork(selectedActivity);
        },
      ),
      routeName: 'ChangeWork',
      backgroundColor: AppThemes.currentTheme.backgroundColor,
      contentColor: AppThemes.currentTheme.backgroundColor,
    ).then((value){
      update();
    });
  }

  Widget getSleep(JobActivityScreenState state){
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){
        showChangeSleep('ChangeSleepSheet');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t('averageSleepPerDay')}').infoColor().oneLineOverflow$Start(),
            SizedBox(height: 8,),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Builder(
                        builder: (ctx){
                          if(user.jobActivityModel.sleepHoursAtNight == null) {
                            return Text('${t('select')}',).bold().color(Colors.blue);
                          }
                          else {
                            return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${user.jobActivityModel.sleepHoursAtNight! + user.jobActivityModel.sleepHoursAtDay!} ${t('hours')}',).oneLineOverflow$End().bold(),
                                  SizedBox(width: 8,),
                                  Icon(Icons.arrow_back_ios,
                                    size: 12,
                                    textDirection: AppThemes.getOppositeDirection(),
                                  )
                                ]
                            );
                          }
                        }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showChangeSleep( String screenName){
    var selectedNightSleep = user.jobActivityModel.sleepHoursAtNight?? 8;
    var selectedDaySleep = user.jobActivityModel.sleepHoursAtDay?? 0;
    final updater = RefreshController();

    final Widget view = SizedBox(
      width: AppSizes.getScreenWidth(context),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Transform.translate(
              offset: Offset(0, -18),
              child: GestureDetector(
                onTap: (){AppNavigator.pop(context);},
                child: CircularIcon(
                  icon: Icons.close,
                  size: 38,
                  padding: 6,
                  backColor: AppThemes.currentTheme.backgroundColor,
                  itemColor: AppThemes.currentTheme.textColor,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: FlipInX(
              delay: Duration(milliseconds: 300),
              child: Refresh(
                  controller: updater,
                  builder: (context, ctr) {

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tC('averageHoursSleepAtNight')}:', maxLines: 1,).bold().fs(15),
                        SizedBox(height: AppSizes.fwSize(14),),
                        HorizontalPicker(
                          //controller: wBmiController,
                          minValue: 2,
                          maxValue: 12,
                          subStepsCount: 0,
                          suffix: '',
                          showCursor: true,
                          useIntOnly: true,
                          cursorValue: selectedNightSleep,
                          height: 50,
                          backgroundColor: AppThemes.currentTheme.backgroundColor,
                          itemBackgroundColor: AppThemes.currentTheme.backgroundColor,
                          selectedStyle: AppThemes.baseTextStyle().copyWith(
                              color: AppThemes.currentTheme.activeItemColor),
                          cursorColor: AppThemes.currentTheme.activeItemColor.withAlpha(150),
                          onChanged: (value) {
                            selectedNightSleep = value as int;
                            updater.update();
                          },
                        ),


                        Text('${tC('averageHoursSleepAtDay')}:', maxLines: 1,).bold().fs(15),
                        SizedBox(height: AppSizes.fwSize(14),),
                        HorizontalPicker(
                          //controller: wBmiController,
                          minValue: 0,
                          maxValue: 12,
                          subStepsCount: 0,
                          suffix: '',
                          showCursor: true,
                          useIntOnly: true,
                          cursorValue: selectedDaySleep,
                          height: 50,
                          backgroundColor: AppThemes.currentTheme.backgroundColor,
                          itemBackgroundColor: AppThemes.currentTheme.backgroundColor,
                          selectedStyle: AppThemes.baseTextStyle().copyWith(
                              color: AppThemes.currentTheme.activeItemColor),
                          cursorColor: AppThemes.currentTheme.activeItemColor.withAlpha(150),
                          onChanged: (value) {
                            selectedDaySleep = value as int;
                            updater.update();
                          },
                        ),
                      ],
                    );
                  }
              ),
            ),
          ),
        ],
      ),
    );

    SheetCenter.showSheetCustom(
      context,
      view,
      useExpanded: false,
      positiveButton: ElevatedButton(
        child: Text('${tC('apply')}'),
        onPressed: (){
          updateSleep(selectedNightSleep, selectedDaySleep);
        },
      ),
      routeName: 'ChangeSleep',
      backgroundColor: AppThemes.currentTheme.backgroundColor,
      contentColor: AppThemes.currentTheme.backgroundColor,
    ).then((value){
      update();
    });
  }

  Widget getExercise(JobActivityScreenState state){
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){
        showChangeExercise('ChangeExerciseSheet');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t('averageHoursExercisePerWeek')}').oneLineOverflow$Start().infoColor(),
            SizedBox(height: 8,),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Builder(builder: (ctx){
                      if(user.jobActivityModel.exerciseHours == null) {
                        return Text('${t('select')}',).bold().color(Colors.blue);
                      }
                      else {
                        return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${user.jobActivityModel.exerciseHours} ${t('hours')}',).bold(),
                              SizedBox(width: 8,),
                              Icon(Icons.arrow_back_ios,
                                size: 12,
                                textDirection: AppThemes.getOppositeDirection(),
                              )
                            ]
                        );
                      }
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showChangeExercise( String screenName){
    var selectedExercise = user.jobActivityModel.exerciseHours?? 7;
    final updater = RefreshController();

    final Widget view = SizedBox(
      width: AppSizes.getScreenWidth(context),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Transform.translate(
              offset: Offset(0, -18),
              child: GestureDetector(
                onTap: (){AppNavigator.pop(context);},
                child: CircularIcon(
                  icon: Icons.close,
                  size: 38,
                  padding: 6,
                  backColor: AppThemes.currentTheme.backgroundColor,
                  itemColor: AppThemes.currentTheme.textColor,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: FlipInX(
              delay: Duration(milliseconds: 300),
              child: Refresh(
                  controller: updater,
                  builder: (context, ctr) {

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tC('averageHoursExercisePerWeek')}:', maxLines: 1,).bold().fs(15),
                        SizedBox(height: AppSizes.fwSize(16),),
                        HorizontalPicker(
                          minValue: 0,
                          maxValue: 42,
                          subStepsCount: 0,
                          suffix: '',
                          showCursor: true,
                          useIntOnly: true,
                          cursorValue: selectedExercise,
                          height: 70,
                          backgroundColor: AppThemes.currentTheme.backgroundColor,
                          itemBackgroundColor: AppThemes.currentTheme.backgroundColor,
                          selectedStyle: AppThemes.baseTextStyle().copyWith(
                              color: AppThemes.currentTheme.activeItemColor),
                          cursorColor: AppThemes.currentTheme.activeItemColor.withAlpha(150),
                          onChanged: (value) {
                            selectedExercise = value as int;
                            updater.update();
                          },
                        ),
                      ],
                    );
                  }
              ),
            ),
          ),
        ],
      ),
    );

    SheetCenter.showSheetCustom(
      context,
      view,
      useExpanded: false,
      positiveButton: ElevatedButton(
        child: Text('${tC('apply')}'),
        onPressed: (){
          updateExercise(selectedExercise);
        },
      ),
      routeName: 'ChangeExercise',
      backgroundColor: AppThemes.currentTheme.backgroundColor,
      contentColor: AppThemes.currentTheme.backgroundColor,
    ).then((value){
      update();
    });
  }

  void updateJobType( String jobType) {
    FocusHelper.hideKeyboardByService();

    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdateJobTypeProfile';
    js[Keys.userId] = user.userId;
    js['job_type'] = jobType;

    AppManager.addAppInfo(js);

    final request = HttpItem();
    request.pathSection = '/set-data';
    request.method = 'POST';
    request.setResponseIsPlain();
    request.body = JsonHelper.mapToJson(js);

    HttpCenter.cancelAndClose(requestObj);
    LoadingScreen.showLoading(context, canBack: false);

    final response = HttpCenter.send(request);
    requestObj = response;

    response.responseFuture.catchError((e){
      if (e is DioError){
        if(e.message == 'my') {
          return response.emptyError;
        }
      }

      LoadingScreen.hideLoading(context).then((value){
        SnackCenter.showSnack$errorCommunicatingServer(context);
      });
    });

    response.responseFuture.then((val) async{
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

      if(result == Keys.ok) {
        user.jobActivityModel.jobType = jobType;
        await Session.sinkUserInfo(user).then((value) {
          LoadingScreen.hideLoading(context).then((value){
            AppNavigator.pop(context);
            //SnackCenter.showSnack$successOperation(context);
          });
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

  void updateNonWork( String nonActivity) {
    FocusHelper.hideKeyboardByService();

    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdateNonWorkActivityProfile';
    js[Keys.userId] = user.userId;
    js['none_work_activity'] = nonActivity;


    AppManager.addAppInfo(js);

    final request = HttpItem();
    request.pathSection = '/set-data';
    request.method = 'POST';
    request.setResponseIsPlain();
    request.body = JsonHelper.mapToJson(js);

    HttpCenter.cancelAndClose(requestObj);
    LoadingScreen.showLoading(context, canBack: false);

    final response = HttpCenter.send(request);
    requestObj = response;

    response.responseFuture.catchError((e){
      if (e is DioError){
        if(e.message == 'my') {
          return response.emptyError;
        }
      }

      LoadingScreen.hideLoading(context).then((value){
        SnackCenter.showSnack$errorCommunicatingServer(context);
      });
    });

    response.responseFuture.then((val) async{
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

      if(result == Keys.ok) {
        user.jobActivityModel.noneWorkActivity = nonActivity;

        await Session.sinkUserInfo(user).then((value) {
          LoadingScreen.hideLoading(context).then((value){
            AppNavigator.pop(context);
          });
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

  void updateSleep( int night, int day) {
    FocusHelper.hideKeyboardByService();

    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdateSleepStateProfile';
    js[Keys.userId] = user.userId;
    js['sleep_hours_at_night'] = night;
    js['sleep_hours_at_day'] = day;

    AppManager.addAppInfo(js);

    final request = HttpItem();
    request.pathSection = '/set-data';
    request.method = 'POST';
    request.setResponseIsPlain();
    request.body = JsonHelper.mapToJson(js);

    HttpCenter.cancelAndClose(requestObj);
    LoadingScreen.showLoading(context, canBack: false);

    final response = HttpCenter.send(request);
    requestObj = response;

    response.responseFuture.catchError((e){
      if (e is DioError){
        if(e.message == 'my') {
          return response.emptyError;
        }
      }

      LoadingScreen.hideLoading(context).then((value){
        SnackCenter.showSnack$errorCommunicatingServer(context);
      });
    });

    response.responseFuture.then((val) async{
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

      if(result == Keys.ok) {
        user.jobActivityModel.sleepHoursAtNight = night;
        user.jobActivityModel.sleepHoursAtDay = day;

        await Session.sinkUserInfo(user).then((value) {
          LoadingScreen.hideLoading(context).then((value){
            AppNavigator.pop(context);
          });
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

  void updateExercise( int exerciseHours) {
    FocusHelper.hideKeyboardByService();

    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdateExerciseStateProfile';
    js[Keys.userId] = user.userId;
    js['exercise_hours'] = exerciseHours;

    AppManager.addAppInfo(js);

    final request = HttpItem();
    request.pathSection = '/set-data';
    request.method = 'POST';
    request.setResponseIsPlain();
    request.body = JsonHelper.mapToJson(js);

    HttpCenter.cancelAndClose(requestObj);
    LoadingScreen.showLoading(context, canBack: false);

    final response = HttpCenter.send(request);
    requestObj = response;

    response.responseFuture.catchError((e){
      if (e is DioError){
        if(e.message == 'my') {
          return response.emptyError;
        }
      }

      LoadingScreen.hideLoading(context).then((value){
        SnackCenter.showSnack$errorCommunicatingServer(context);
      });
    });

    response.responseFuture.then((val) async{
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

      if(result == Keys.ok) {
        user.jobActivityModel.exerciseHours = exerciseHours;

        await Session.sinkUserInfo(user).then((value) {
          LoadingScreen.hideLoading(context).then((value){
            AppNavigator.pop(context);
          });
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

  void updateGoal( String goalOfFitness) {
    FocusHelper.hideKeyboardByService();

    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdateGoalOfFitnessProfile';
    js[Keys.userId] = user.userId;
    js['goal_of_fitness'] = goalOfFitness;

    AppManager.addAppInfo(js);

    final request = HttpItem();
    request.pathSection = '/set-data';
    request.method = 'POST';
    request.setResponseIsPlain();
    request.body = JsonHelper.mapToJson(js);

    HttpCenter.cancelAndClose(requestObj);
    LoadingScreen.showLoading(context, canBack: false);

    final response = HttpCenter.send(request);
    requestObj = response;

    response.responseFuture.catchError((e){
      if (e is DioError){
        if(e.message == 'my') {
          return response.emptyError;
        }
      }

      LoadingScreen.hideLoading(context).then((value){
        SnackCenter.showSnack$errorCommunicatingServer(context);
      });
    });

    response.responseFuture.then((val) async{
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

      if(result == Keys.ok) {
        user.jobActivityModel.goalOfFitness = goalOfFitness;

        await Session.sinkUserInfo(user).then((value) {
          LoadingScreen.hideLoading(context).then((value){
            AppNavigator.pop(context);
          });
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

