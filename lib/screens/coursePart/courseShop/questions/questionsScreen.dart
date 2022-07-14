import 'package:flutter/material.dart';

import 'package:cool_stepper/cool_stepper.dart';
import 'package:iris_tools/dateSection/calendarTools.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/models/dataModels/colorTheme.dart';
import 'package:iris_tools/widgets/horizontalPicker.dart';
import 'package:iris_tools/widgets/multiSelect/multiSelect.dart';
import 'package:iris_tools/widgets/optionsRow/checkRow.dart';
import 'package:iris_tools/widgets/optionsRow/radioRow.dart';
import 'package:iris_tools/modules/stateManagers/selfRefresh.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:iris_tools/widgets/text/autoDirection.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '/abstracts/stateBase.dart';
import '/managers/settingsManager.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/screens/coursePart/courseShop/questions/questionsScreenCtr.dart';
import '/screens/coursePart/courseShop/questions/questionsScreen_getCardImages.dart';
import '/screens/coursePart/courseShop/questions/questionsScreen_getExerciseQ.dart';
import '/screens/coursePart/courseShop/questions/questionsScreen_getImages.dart';
import '/system/extensions.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/dateTools.dart';
import '/tools/widgetTools.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

class QuestionsScreen extends StatefulWidget {
  static const screenName = 'QuestionsScreen';
  final CourseModel courseModel;

  QuestionsScreen({Key? key, required this.courseModel}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return QuestionsScreenState();
  }
}
///=====================================================================================
class QuestionsScreenState extends StateBase<QuestionsScreen> {
  StateXController stateController = StateXController();
  QuestionsScreenCtr controller = QuestionsScreenCtr();
  String illDescriptionInputCtrKey = 'descriptionInputCtr';
  String medicInputCtrKey = 'medicInputCtr';
  String sportTypesInputCtrKey = 'sportTypesInputCtr';


  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();
    controller.onBuild();

    return getScaffold();
  }

  @override
  void dispose() {
    if(stateController.existObject(illDescriptionInputCtrKey)) {
      stateController.object(illDescriptionInputCtrKey).dispose();
    }

    if(stateController.existObject(medicInputCtrKey)) {
      stateController.object(medicInputCtrKey).dispose();
    }

    if(stateController.existObject(sportTypesInputCtrKey)) {
      stateController.object(sportTypesInputCtrKey).dispose();
    }

    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  Widget getScaffold() {
    return WillPopScope(
      onWillPop: () => onWillBack(this),
      child: SizedBox(
        width: AppSizes.getScreenWidth(context),
        height: AppSizes.getScreenHeight(context),
        child: Scaffold(
          key: scaffoldKey,
          appBar: getAppbar(),
          body: getMainBuilder(),
        ),
      ),
    );
  }

  PreferredSizeWidget getAppbar() {
    return AppBar(
      title: Text(tInMap('courseBuyQuestionPage', 'questionsBeforeBuy')!),
    );
  }

  Widget getMainBuilder() {
    return StateX(
      isMain: true,
      controller: stateController,
      builder: (context, ctr, data) {
        switch(ctr.mainState){
          case StateXController.state$loading:
            return PreWidgets.flutterLoadingWidget$Center();
          case StateXController.state$serverNotResponse:
          case StateXController.state$netDisconnect:
            return ServerResponseWrongView(this, tryAgain: controller.tryAgain);
          default:
            return getBody();
        }
      },
    );
  }

  Widget getBody() {
    return CoolStepper(
      onCompleted: controller.onStepsComplete,
      steps: genSteps(),
      contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 8),
      config: CoolStepperConfig(
          backText: t('back'),
          finalText: t('buy'),
          nextText: t('next'),
          ofText: t('of'),
          stepText: t('step'),
          icon: null,//Icon(Icons.accessibility_new_rounded),
          isHeaderEnabled: true,
          headerColor: AppThemes.currentTheme.primaryColor.withAlpha(150),
          backButton: ElevatedButton(
            onPressed: (){},
            style: ButtonStyle(shape: MaterialStateProperty.all(ShapeList.stadiumBorder$Outlined)),
            child: Text('${t('back')}'),
          ),
          nextButton: ElevatedButton(
            onPressed: (){},
            style: ButtonStyle(shape: MaterialStateProperty.all(ShapeList.stadiumBorder$Outlined)),
            child: Text('${t('next')}'),
          ),
          finishButton: ElevatedButton(
            onPressed: (){},
            style: ButtonStyle(
                shape: MaterialStateProperty.all(ShapeList.stadiumBorder$Outlined),
            backgroundColor: MaterialStateProperty.all(AppThemes.currentTheme.accentColor)),
            child: Text('${t('buy')}'),
          )
      ),
    );
  }
  ///========================================================================================================
  List<CoolStep> genSteps(){
    final res = <CoolStep>[];

    res.add(genHeightWeight());
    res.add(genSexBirthdate());
    res.add(genHealth());
    res.add(genJobActivity());
    res.add(genSleep());
    res.add(genExercise());

    if(widget.courseModel.hasExerciseProgram){
      res.add(genExerciseQuestion());
    }

    res.add(genImages());
    res.add(genCardImage());

    return res;
  }

  CoolStep genHeightWeight(){
    return CoolStep(
        title: '',
        subtitle: tInMap('courseBuyQuestionPage', 'defineHeight&weight')!,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tC('heightMan')}:').bold().fs(16).alpha(alpha: 150),
            SizedBox(height: AppSizes.fwSize(8),),
            HorizontalPicker(
              minValue: 40,
              maxValue: 220,
              suffix: ' cm',
              showCursor: true,
              cursorValue: controller.questionsModel.height,
              cellWidth: 70,
              height: 70,
              backgroundColor: AppThemes.currentTheme.backgroundColor,
              itemBackgroundColor: AppThemes.currentTheme.backgroundColor,
              selectedStyle: AppThemes.baseTextStyle().copyWith(
                  color: AppThemes.currentTheme.activeItemColor),
              cursorColor: AppThemes.currentTheme.activeItemColor.withAlpha(150),
              onChanged: (value) {
                controller.questionsModel.height = value as double;
              },
            ),

            SizedBox(height: AppSizes.fwSize(16),),
            ///-------------------------
            Text('${tC('weight')}:').bold().fs(16).alpha(alpha: 150),
            SizedBox(height: AppSizes.fwSize(8),),
            HorizontalPicker(
              minValue: 10,
              maxValue: 200,
              subStepsCount: 0,
              suffix: ' kg',
              showCursor: true,
              cursorValue: controller.questionsModel.weight,
              height: 70,
              backgroundColor: AppThemes.currentTheme.backgroundColor,
              itemBackgroundColor: AppThemes.currentTheme.backgroundColor,
              selectedStyle: AppThemes.baseTextStyle().copyWith(
                  color: AppThemes.currentTheme.activeItemColor),
              cursorColor: AppThemes.currentTheme.activeItemColor.withAlpha(150),
              onChanged: (value) {
                controller.questionsModel.weight = value as double;
              },
            ),
          ],
        ),
        validation: () {
          return null;
        }
    );
  }

  CoolStep genSexBirthdate(){
    var selectedGender = controller.questionsModel.sex -1; //1 man, 2 woman

    if(selectedGender < 0){
      selectedGender = 0;
    }

    int selectedYear, selectedMonth, selectedDay;

    var list = DateTools.splitDateByCalendar(controller.questionsModel.birthdate);
    selectedYear = list[0];
    selectedMonth = list[1];
    selectedDay = list[2];

    void changeCalendar(CalendarType calendarType){
      DateTools.saveAppCalendar(calendarType);

      var list = DateTools.splitDateByCalendar(controller.questionsModel.birthdate);
      selectedYear = list[0];
      selectedMonth = list[1];
      selectedDay = list[2];
    }

    void calcBirthdate(){
      final maxMonthDay = DateTools.calMaxMonthDay(selectedYear, selectedMonth);

      if(selectedDay > maxMonthDay){
        selectedDay = maxMonthDay;
      }

      controller.questionsModel.birthdate = DateTools.getDateByCalendar(selectedYear, selectedMonth, selectedDay)!;
    }

    return CoolStep(
        title: '',
        subtitle: tInMap('courseBuyQuestionPage', 'defineSex&birthdate')!,
        content: SelfRefresh(
          builder: (context, ctr) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${tC('age')}: ${DateHelper.calculateAge(controller.questionsModel.birthdate)}').bold(),

                    SizedBox(
                      height: 46,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10.0)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                              dropdownColor: Colors.grey[400],
                              value: SettingsManager.settingsModel.calendarType,
                              onChanged: (newValue) {
                                changeCalendar(newValue as CalendarType);

                                stateController.updateMain();
                              },
                              items: DateTools.calendarList.map((cal) => DropdownMenuItem(
                                value: cal,
                                child: Text('${tInMap('calendarOptions', cal.name)}'),
                              )).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.fwSize(30),),


                Text('${tC('birthDate')}:').bold().fs(16).alpha(alpha: 140),
                SizedBox(height: AppSizes.fwSize(16),),
                SizedBox(
                  height: AppSizes.fwSize(120),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.ltr,
                    children: [
                      ///--- year
                      NumberPicker(
                        minValue: DateTools.calMinBirthdateYear(),
                        maxValue: DateTools.calMaxBirthdateYear(),
                        value: selectedYear,
                        axis: Axis.vertical,
                        itemWidth: 60,
                        textStyle: AppThemes.baseTextStyle().copyWith(
                          fontSize: AppSizes.fwFontSize(15),
                          fontWeight: FontWeight.bold,
                        ),
                        selectedTextStyle: TextStyle(
                          fontSize: AppSizes.fwFontSize(16),
                          fontWeight: FontWeight.bold,
                          color: AppThemes.currentTheme.activeItemColor,
                        ),
                        haptics: true,
                        zeroPad: true,
                        itemHeight: 40,
                        textMapper: (t){
                          return t.toString().localeNum();
                        },
                        onChanged: (val){
                          selectedYear = val;
                          calcBirthdate();

                          ctr.update();
                        },
                      ),

                      ///--- month
                      NumberPicker(
                        minValue: 1,
                        maxValue: 12,
                        itemHeight: 40,
                        itemWidth: 40,
                        value: selectedMonth,
                        axis: Axis.vertical,
                        textStyle: AppThemes.baseTextStyle().copyWith(
                          fontSize: AppSizes.fwFontSize(15),
                          fontWeight: FontWeight.bold,
                        ),
                        selectedTextStyle: TextStyle(
                          fontSize: AppSizes.fwFontSize(16),
                          fontWeight: FontWeight.bold,
                          color: AppThemes.currentTheme.activeItemColor,
                        ),
                        haptics: true,
                        zeroPad: true,
                        infiniteLoop: true,
                        textMapper: (t){
                          return t.toString().localeNum();
                        },
                        onChanged: (val){
                          selectedMonth = val;
                          calcBirthdate();

                          ctr.update();
                        },
                      ),

                      ///--- day
                      SizedBox(
                        width: AppSizes.fwSize(60),
                        height: AppSizes.fwSize(120),
                        child: NumberPicker(
                          minValue: 1,
                          maxValue: DateTools.calMaxMonthDay(selectedYear, selectedMonth),
                          value: selectedDay,
                          axis: Axis.vertical,
                          textStyle: AppThemes.baseTextStyle().copyWith(
                            fontSize: AppSizes.fwFontSize(15),
                            fontWeight: FontWeight.bold,
                          ),
                          selectedTextStyle: TextStyle(
                            fontSize: AppSizes.fwFontSize(16),
                            fontWeight: FontWeight.bold,
                            color: AppThemes.currentTheme.activeItemColor,
                          ),
                          haptics: true,
                          zeroPad: true,
                          itemHeight: 40,
                          itemWidth: 40,
                          infiniteLoop: true,
                          textMapper: (t){
                            return t.toString().localeNum();
                          },
                          onChanged: (val){
                            selectedDay = val;
                            calcBirthdate();

                            ctr.update();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSizes.fwSize(16),),

                //------------ gender
                Text('${tC('gender')}:').bold().fs(16).alpha(alpha: 140),
                SizedBox(height: AppSizes.fwSize(16),),
                ToggleSwitch(
                  initialLabelIndex: selectedGender,
                  cornerRadius: 12.0,
                  //minWidth: 100,
                  activeBgColor: [AppThemes.currentTheme.activeItemColor],
                  inactiveBgColor: Colors.grey[400],
                  activeFgColor: Colors.white,
                  inactiveFgColor: AppThemes.currentTheme.inactiveTextColor,
                  totalSwitches: 2,
                  textDirectionRTL: true,
                  labels: [tC('man')!, tC('woman')!],
                  onToggle: (index) {
                    selectedGender = index!;
                    controller.questionsModel.sex = index+1;
                  },
                ),
              ],
            );
          }
        ),
        validation: () {
          controller.questionsModel.sex = selectedGender +1;
          return null;
        }
    );
  }

  CoolStep genHealth(){
    final allIlsMap = tAsMap('illness')!;
    final allIllsKey = <String>[];
    final selectedIllsIdx = <int>[];


    for(var kv in allIlsMap.entries){
      allIllsKey.add(kv.value);
    }

    if(!stateController.existObject(illDescriptionInputCtrKey)) {
      stateController.setObject(illDescriptionInputCtrKey, TextEditingController());
    }

    if(!stateController.existObject(medicInputCtrKey)) {
      stateController.setObject(medicInputCtrKey, TextEditingController());
    }

    final descriptionInputCtr = stateController.object(illDescriptionInputCtrKey);
    final medicInputCtr = stateController.object(medicInputCtrKey);

    final inputParentDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      border: Border.all(
        color: AppThemes.currentTheme.fabBackColor.withAlpha(150),
        style: BorderStyle.solid,
        width: 0.8,
      ),
    );

    void fetch(){
      descriptionInputCtr.text = controller.questionsModel.illDescription;
      medicInputCtr.text = controller.questionsModel.illMedications;

      if(controller.questionsModel.haveNoIlls){
        descriptionInputCtr.clear();
        selectedIllsIdx.clear();
      }

      final fixIlls = allIlsMap.entries;

      for(var i =0; i < allIlsMap.length; i++) {
        final MapEntry e = fixIlls.elementAt(i);

        if(controller.questionsModel.illList.contains(e.key)) {
          selectedIllsIdx.add(i);
        }
      }
    }

    fetch();

    return CoolStep(
        title: '',
        subtitle: tInMap('courseBuyQuestionPage', 'defineHealth')!,
        content: SelfRefresh(
          builder: (context, ctr) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckBoxRow(
                    value: controller.questionsModel.haveNoIlls,
                    description: Text('${tInMap('courseBuyQuestionPage', 'hasNoAnyIll')}').fsR(4).boldFont(),
                    onChanged: (v){
                      controller.questionsModel.haveNoIlls = v;

                      if(v){
                        selectedIllsIdx.clear();
                        descriptionInputCtr.clear();
                        controller.questionsModel.illList.clear();
                        controller.questionsModel.illDescription = '';
                      }

                      ctr.update();
                    }
                ),

                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(2, 2, 2, 8),
                    child: Text('${tInMap('courseBuyQuestionPage', 'chooseYourDiseases')}',
                      textAlign: TextAlign.start,).fsR(2, max: 20),
                  ),
                ),

                MultiSelect(
                  spacing: 4,
                  isRadio: false,
                  isDisable: controller.questionsModel.haveNoIlls,
                  borderRadius: BorderRadius.circular(30.0),
                  buttons: [
                    ...allIllsKey,
                  ],
                  selectedButtons: selectedIllsIdx,
                  onChangeState: (idx, value, isSelected){
                    if(isSelected){
                      if(!selectedIllsIdx.contains(idx)) {
                        selectedIllsIdx.add(idx);
                      }
                    }
                    else {
                      selectedIllsIdx.remove(idx);
                    }

                    controller.questionsModel.illList.clear();

                    for(var i in selectedIllsIdx){
                      final k = allIlsMap.keys.elementAt(i);
                      controller.questionsModel.illList.add(k);
                    }
                  },
                  selectedIcon: Icon(Icons.check).rSiz(-2).textColor(),
                  selectedColor: AppThemes.currentTheme.activeItemColor,
                  unselectedColor: AppThemes.currentTheme.activeItemColor.withAlpha(90),
                ),

                SizedBox(height: 12,),
                Text('${tJoin('healthConditionDescription')}',
                  textAlign: TextAlign.start,).fsR(2, max: 20),

                SizedBox(height: 12,),
                DecoratedBox(
                  decoration: inputParentDecoration,
                  child: AutoDirection(
                    builder: (context, autoController) {
                      return TextField(
                        controller: descriptionInputCtr,
                        textDirection: autoController.getTextDirection(descriptionInputCtr.text),
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.text,
                        minLines: 4,
                        maxLines: 4,
                        expands: false,
                        enabled: !controller.questionsModel.haveNoIlls,
                        decoration: ColorTheme.noneBordersInputDecoration,
                        onChanged: (t){
                          autoController.onChangeText(t);
                          controller.questionsModel.illDescription = t;
                        },
                      );
                    },
                  ),
                ),

                SizedBox(height: 12,),
                SizedBox(
                  width: double.infinity,
                  child: Text('${tC('medications')}:',
                    textAlign: TextAlign.start,).fsR(2, max: 20),
                ),

                SizedBox(height: 12,),
                DecoratedBox(
                  decoration: inputParentDecoration,
                  child: AutoDirection(
                      builder: (context, autoController) {
                        return TextField(
                          controller: medicInputCtr,
                          textDirection: autoController.getTextDirection(medicInputCtr.text),
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.text,
                          minLines: 4,
                          maxLines: 4,
                          expands: false,
                          decoration: ColorTheme.noneBordersInputDecoration,
                          onChanged: (t){
                            autoController.onChangeText(t);
                            controller.questionsModel.illMedications = t;
                          },
                        );
                      }
                  ),
                ),
              ],
            );
          }
        ),
        validation: () {
          if(controller.questionsModel.illList.isEmpty){
            if(!controller.questionsModel.haveNoIlls){
              SheetCenter.showSheetOk(context, tInMap('courseBuyQuestionPage', 'mustSelectAIllOrTickNo')!);
              return 'no';
            }
          }

          return null;
        }
    );
  }

  CoolStep genJobActivity(){
    var selectedJob = controller.questionsModel.jobType?? '';
    var selectedActivity = controller.questionsModel.noneWorkActivity?? '';
    final Map jobsMap = tAsMap('jobTypes')!;
    final Map nonWorkingMap = tAsMap('nonWorkingActivity')!;
    final jobs = jobsMap.entries;
    final nonWorking = nonWorkingMap.entries;

    if(selectedJob.isNotEmpty){
      final find = jobs.firstWhereSafe((element) {
        return element.key == selectedJob;
      });

      if(find != null) {
        selectedJob = find.key;
      }
      else {
        selectedJob = '';
      }
    }
    /*else {
      selectedJob = jobs.first.key;
    }*/

    if(selectedActivity.isNotEmpty){
      final find = nonWorking.firstWhereSafe((element) {
        return element.key == selectedActivity;
      });

      if(find != null) {
        selectedActivity = find.key;
      }
      else {
        selectedActivity = '';
      }
    }

    return CoolStep(
        title: '',
        subtitle: tInMap('courseBuyQuestionPage', 'defineJobState')!,
        content: SelfRefresh(
          builder: (context, ctr) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tInMap('courseBuyQuestionPage', 'jobType')}:').bold().fs(16).alpha(alpha: 150),
                SizedBox(height: AppSizes.fwSize(8),),
                ...jobs.map((e){
                  return RadioRow(
                    value: e.key,
                    groupValue: selectedJob,
                    description: Text(' ${e.value}', style: AppThemes.baseTextStyle(),),
                    onChanged: (val){
                      if(val != null) {
                        controller.questionsModel.jobType = val;
                        selectedJob = val;
                        ctr.update();
                      }
                    },
                  );
                }).toList(),

                SizedBox(height: AppSizes.fwSize(16),),
                ///-------------------------
                Text('${tInMap('courseBuyQuestionPage', 'activityDuringNonWorkingHours')}:').bold().fs(16).alpha(alpha: 150),
                SizedBox(height: AppSizes.fwSize(8),),
                ...nonWorking.map((e){
                  return RadioRow(
                    value: e.key,
                    groupValue: selectedActivity,
                    description: Text(' ${e.value}', style: AppThemes.baseTextStyle(),),
                    onChanged: (val){
                      if(val != null) {
                        controller.questionsModel.noneWorkActivity = val;
                        selectedActivity = val;
                        ctr.update();
                      }
                    },
                  );
                }).toList(),
              ],
            );
          }
        ),
        validation: () {
          if(selectedJob.isEmpty){
            SheetCenter.showSheetOk(context, tInMap('courseBuyQuestionPage', 'selectJobType')!);
            return '';
          }

          if(selectedActivity.isEmpty){
            SheetCenter.showSheetOk(context, tInMap('courseBuyQuestionPage', 'selectNonActivity')!);
            return '';
          }

          return null;
        }
    );
  }

  CoolStep genSleep(){
    return CoolStep(
        title: '',
        subtitle: tInMap('courseBuyQuestionPage', 'defineSleepState')!,
        content: SelfRefresh(
            builder: (context, ctr) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tInMap('courseBuyQuestionPage', 'averageHoursSleepAtNight')}:')
                      .bold().fs(16).alpha(alpha: 150),

                  SizedBox(height: AppSizes.fwSize(8),),
                  HorizontalPicker(
                    minValue: 2,
                    maxValue: 12,
                    subStepsCount: 0,
                    suffix: '',
                    showCursor: true,
                    useIntOnly: true,
                    cursorValue: controller.questionsModel.sleepHoursAtNight,
                    height: 60,
                    backgroundColor: AppThemes.currentTheme.backgroundColor,
                    itemBackgroundColor: AppThemes.currentTheme.backgroundColor,
                    selectedStyle: AppThemes.baseTextStyle().copyWith(
                        color: AppThemes.currentTheme.activeItemColor),
                    cursorColor: AppThemes.currentTheme.activeItemColor.withAlpha(150),
                    onChanged: (value) {
                      controller.questionsModel.sleepHoursAtNight = value as int;
                      ctr.update();
                    },
                  ),


                  SizedBox(height: AppSizes.fwSize(16),),
                  ///-------------------------
                  Text('${tInMap('courseBuyQuestionPage', 'averageHoursSleepAtDay')}:').bold().fs(16).alpha(alpha: 150),

                  SizedBox(height: AppSizes.fwSize(8),),
                  HorizontalPicker(
                    minValue: 0,
                    maxValue: 12,
                    subStepsCount: 0,
                    suffix: '',
                    showCursor: true,
                    useIntOnly: true,
                    cursorValue: controller.questionsModel.sleepHoursAtDay,
                    height: 60,
                    backgroundColor: AppThemes.currentTheme.backgroundColor,
                    itemBackgroundColor: AppThemes.currentTheme.backgroundColor,
                    selectedStyle: AppThemes.baseTextStyle().copyWith(
                        color: AppThemes.currentTheme.activeItemColor),
                    cursorColor: AppThemes.currentTheme.activeItemColor.withAlpha(150),
                    onChanged: (value) {
                      controller.questionsModel.sleepHoursAtDay = value as int;
                      ctr.update();
                    },
                  ),
                ],
              );
            }
        ),
        validation: () {
          return null;
        }
    );
  }

  CoolStep genExercise(){
    final inputParentDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      border: Border.all(
        color: AppThemes.currentTheme.fabBackColor.withAlpha(150),
        style: BorderStyle.solid,
        width: 0.8,
      ),
    );

    if(!stateController.existObject(sportTypesInputCtrKey)) {
      stateController.setObject(sportTypesInputCtrKey, TextEditingController());
    }

    final sportInputCtr = stateController.object(sportTypesInputCtrKey);
    sportInputCtr.text = controller.questionsModel.sportTypeDescription?? '';

    return CoolStep(
        title: '',
        subtitle: tInMap('courseBuyQuestionPage', 'defineExerciseState')!,
        content: SelfRefresh(
            builder: (context, ctr) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tInMap('courseBuyQuestionPage', 'averageHoursExercisePerWeek')}:').bold().fs(16).alpha(alpha: 150),
                  SizedBox(height: AppSizes.fwSize(8),),
                  HorizontalPicker(
                    minValue: 0,
                    maxValue: 42,
                    subStepsCount: 0,
                    suffix: '',
                    showCursor: true,
                    useIntOnly: true,
                    cursorValue: controller.questionsModel.exerciseHours,
                    height: 70,
                    backgroundColor: AppThemes.currentTheme.backgroundColor,
                    itemBackgroundColor: AppThemes.currentTheme.backgroundColor,
                    selectedStyle: AppThemes.baseTextStyle().copyWith(
                        color: AppThemes.currentTheme.activeItemColor),
                    cursorColor: AppThemes.currentTheme.activeItemColor.withAlpha(150),
                    onChanged: (value) {
                      controller.questionsModel.exerciseHours = value as int;
                      ctr.update();
                    },
                  ),


                  SizedBox(height: AppSizes.fwSize(16),),
                  ///-------------------------
                  Text('${tInMap('courseBuyQuestionPage', 'sportType')}:').bold().fs(16).alpha(alpha: 150),
                  SizedBox(height: AppSizes.fwSize(8),),
                  DecoratedBox(
                    decoration: inputParentDecoration,
                    child: AutoDirection(
                      builder: (context, autoController) {
                        return TextField(
                          controller: sportInputCtr,
                          textDirection: autoController.getTextDirection(sportInputCtr.text),
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.text,
                          minLines: 4,
                          maxLines: 4,
                          expands: false,
                          decoration: ColorTheme.noneBordersInputDecoration,
                          onChanged: (t){
                            autoController.onChangeText(t);
                            controller.questionsModel.sportTypeDescription = t;
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }
        ),
        validation: () {
          return null;
        }
    );
  }

  CoolStep genImages(){
    return CoolStep(
        title: '',
        subtitle: tInMap('courseBuyQuestionPage', 'defineImages')!,
        content: QuestionsScreenGetImage(courseQuestionModel: controller.questionsModel,),
        validation: () {
          return null;
        }
    );
  }

  CoolStep genCardImage(){
    return CoolStep(
        title: '',
        subtitle: tInMap('courseBuyQuestionPage', 'defineCard')!,
        content: QuestionsScreenGetCardImage(courseQuestionModel: controller.questionsModel,),
        validation: () {
          return null;
        }
    );
  }

  CoolStep genExerciseQuestion(){
    return CoolStep(
        title: '',
        subtitle: tInMap('courseBuyQuestionPage', 'defineExerciseQuestion')!,
        content: QuestionsScreenGetExercise(courseQuestionModel: controller.questionsModel,),
        validation: () {
          var canContinue = controller.questionsModel.exercisePlaceType != null;

          if(!canContinue){
            SheetCenter.showSheetOk(context, '${tInMap('courseBuyQuestionPage', 'selectExercisePlacePlease')}');
            return '';
          }

          if(canContinue && controller.questionsModel.exercisePlaceType == ExercisePlaceType.workAtGyn.name){
            canContinue = canContinue && controller.questionsModel.gymToolsType != null;
          }

          if(!canContinue){
            SheetCenter.showSheetOk(context, '${tInMap('courseBuyQuestionPage', 'selectGymToolsPlease')}');
            return '';
          }

          return null;
        }
    );
  }
}
