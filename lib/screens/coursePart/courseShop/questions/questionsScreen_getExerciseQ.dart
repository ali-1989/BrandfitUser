import 'package:flutter/material.dart';

import 'package:animate_do/animate_do.dart';
import 'package:iris_tools/models/dataModels/colorTheme.dart';
import 'package:iris_tools/widgets/optionsRow/radioRow.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:iris_tools/widgets/text/autoDirection.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/system/extensions.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';

class QuestionsScreenGetExercise extends StatefulWidget {
  static const screenName = 'QuestionsScreenGetExercise';
  final CourseQuestionModel courseQuestionModel;

  QuestionsScreenGetExercise({
    Key? key,
    required this.courseQuestionModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return QuestionsScreenGetExerciseState();
  }
}
///=====================================================================================
class QuestionsScreenGetExerciseState extends StateBase<QuestionsScreenGetExercise> {
  StateXController stateController = StateXController();
  late final CourseQuestionModel courseQuestionModel;
  TextEditingController exerciseTimeCtr = TextEditingController();
  TextEditingController gymToolsCtr = TextEditingController();
  TextEditingController homeToolsCtr = TextEditingController();
  TextEditingController harmCtr = TextEditingController();
  TextEditingController sportRecordsCtr = TextEditingController();
  TextEditingController dietCtr = TextEditingController();
  late BoxDecoration inputParentDecoration;
  String exercisePlaceTypeGroup = '';
  String gymToolsTypeGroup = '';

  @override
  void initState() {
    super.initState();

    courseQuestionModel = widget.courseQuestionModel;

    exerciseTimeCtr.text = courseQuestionModel.exerciseTimesDescription?? '';
    gymToolsCtr.text = courseQuestionModel.gymToolsDescription?? '';
    homeToolsCtr.text = courseQuestionModel.homeToolsDescription?? '';
    harmCtr.text = courseQuestionModel.harmDescription?? '';
    sportRecordsCtr.text = courseQuestionModel.sportsRecordsDescription?? '';
    dietCtr.text = courseQuestionModel.dietDescription?? '';
    exercisePlaceTypeGroup = courseQuestionModel.exercisePlaceType?? '';
    gymToolsTypeGroup = courseQuestionModel.gymToolsType?? '';

    inputParentDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      border: Border.all(
        color: AppThemes.currentTheme.fabBackColor.withAlpha(150),
        style: BorderStyle.solid,
        width: 0.8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    return getMainBuilder();
  }

  @override
  void dispose() {
    exerciseTimeCtr.dispose();
    gymToolsCtr.dispose();
    homeToolsCtr.dispose();
    harmCtr.dispose();
    sportRecordsCtr.dispose();
    dietCtr.dispose();
    stateController.dispose();

    super.dispose();
  }

  Widget getMainBuilder() {
    return StateX(
      isMain: true,
      controller: stateController,
      builder: (context, ctr, data) {
        return getBody();
      },
    );
  }

  Widget getBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${tInMap('courseBuyQuestionPage', 'howManyYouExercise')}').bold().fs(16).alpha(alpha: 150),
        SizedBox(height: AppSizes.fwSize(2),),
        Text('${tInMap('courseBuyQuestionPage', 'howManyYouExercise2')}').bold().fs(16).alpha(alpha: 150),
        SizedBox(height: AppSizes.fwSize(10),),
        DecoratedBox(
          decoration: inputParentDecoration,
          child: AutoDirection(
            builder: (context, autoController) {
              return TextField(
                controller: exerciseTimeCtr,
                textDirection: autoController.getTextDirection(exerciseTimeCtr.text),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                minLines: 4,
                maxLines: 4,
                expands: false,
                decoration: ColorTheme.noneBordersInputDecoration,
                onChanged: (t){
                  autoController.onChangeText(t);
                  courseQuestionModel.exerciseTimesDescription = t;
                },
              );
            },
          ),
        ),

        SizedBox(height: AppSizes.fwSize(14),),
        Text('${tInMap('courseBuyQuestionPage', 'selectExercisePlace')}:').bold().fs(16).alpha(alpha: 150),
        RadioRow(
            description: Text('${tInMap('courseBuyQuestionPage', 'atGym')}'),
            groupValue: exercisePlaceTypeGroup,
            value: ExercisePlaceType.workAtGyn.name,
            onChanged: (v){
              exercisePlaceTypeGroup = v;
              courseQuestionModel.exercisePlaceType = v;

              stateController.updateMain();
            }
        ),
        RadioRow(
            description: Text('${tInMap('courseBuyQuestionPage', 'atHome')}'),
            groupValue: exercisePlaceTypeGroup,
            value: ExercisePlaceType.workAtHome.name,
            onChanged: (v){
              exercisePlaceTypeGroup = v;
              courseQuestionModel.exercisePlaceType = v;
              stateController.updateMain();

              /*Future.delayed(Duration(milliseconds: 100), (){
                gymShowCtr?.reverse();
                homeShowCtr?.reset();
                homeShowCtr?.forward();
              });*/
            }
        ),

        SizedBox(height: AppSizes.fwSize(10),),
        Visibility(
          visible: exercisePlaceTypeGroup == ExercisePlaceType.workAtGyn.name,
          child: FadeInUp(
            animate: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tInMap('courseBuyQuestionPage', 'gymTools')}:').bold().fs(16).alpha(alpha: 150),
                RadioRow(
                    description: Text('${tInMap('courseBuyQuestionPage', 'gymToolsLittle')}'),
                    groupValue: gymToolsTypeGroup,
                    value: GymToolsType.little.name,
                    onChanged: (v){
                      gymToolsTypeGroup = v;
                      courseQuestionModel.gymToolsType = v;
                      stateController.updateMain();
                    }
                ),

                RadioRow(
                    description: Text('${tInMap('courseBuyQuestionPage', 'gymToolsHalf')}'),
                    groupValue: gymToolsTypeGroup,
                    value: GymToolsType.half.name,
                    onChanged: (v){
                      gymToolsTypeGroup = v;
                      courseQuestionModel.gymToolsType = v;
                      stateController.updateMain();
                    }
                ),

                RadioRow(
                    description: Text('${tInMap('courseBuyQuestionPage', 'gymToolsHigh')}'),
                    groupValue: gymToolsTypeGroup,
                    value: GymToolsType.high.name,
                    onChanged: (v){
                      gymToolsTypeGroup = v;
                      courseQuestionModel.gymToolsType = v;
                      stateController.updateMain();
                    }
                ),

                SizedBox(height: AppSizes.fwSize(8),),
                Text('${tInMap('courseBuyQuestionPage', 'gymTools')}:').bold().fs(16).alpha(alpha: 150),

                SizedBox(height: AppSizes.fwSize(2),),
                DecoratedBox(
                  decoration: inputParentDecoration,
                  child: AutoDirection(
                    builder: (context, autoController) {
                      return TextField(
                        controller: gymToolsCtr,
                        textDirection: autoController.getTextDirection(gymToolsCtr.text),
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.text,
                        minLines: 3,
                        maxLines: 3,
                        expands: false,
                        decoration: ColorTheme.noneBordersInputDecoration,
                        onChanged: (t){
                          autoController.onChangeText(t);
                          courseQuestionModel.gymToolsDescription = t;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        Visibility(
          visible: exercisePlaceTypeGroup == ExercisePlaceType.workAtHome.name,
          child: FadeInUp(
            animate: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tInMap('courseBuyQuestionPage', 'homeTools')}:').bold().fs(16).alpha(alpha: 150),
                SizedBox(height: AppSizes.fwSize(5),),
                DecoratedBox(
                  decoration: inputParentDecoration,
                  child: AutoDirection(
                    builder: (context, autoController) {
                      return TextField(
                        controller: homeToolsCtr,
                        textDirection: autoController.getTextDirection(homeToolsCtr.text),
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.text,
                        minLines: 3,
                        maxLines: 3,
                        expands: false,
                        decoration: ColorTheme.noneBordersInputDecoration,
                        onChanged: (t){
                          autoController.onChangeText(t);
                          courseQuestionModel.homeToolsDescription = t;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: AppSizes.fwSize(18),),
        Text('${tInMap('courseBuyQuestionPage', 'harmDescription')}:').bold().fs(16).alpha(alpha: 150),
        SizedBox(height: AppSizes.fwSize(5),),
        DecoratedBox(
          decoration: inputParentDecoration,
          child: AutoDirection(
            builder: (context, autoController) {
              return TextField(
                controller: harmCtr,
                textDirection: autoController.getTextDirection(harmCtr.text),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                minLines: 3,
                maxLines: 3,
                expands: false,
                decoration: ColorTheme.noneBordersInputDecoration,
                onChanged: (t){
                  autoController.onChangeText(t);
                  courseQuestionModel.harmDescription = t;
                },
              );
            },
          ),
        ),

        SizedBox(height: AppSizes.fwSize(18),),
        Text('${tInMap('courseBuyQuestionPage', 'sportsHistoryDescription')}:').bold().fs(16).alpha(alpha: 150),
        SizedBox(height: AppSizes.fwSize(5),),
        DecoratedBox(
          decoration: inputParentDecoration,
          child: AutoDirection(
            builder: (context, autoController) {
              return TextField(
                controller: sportRecordsCtr,
                textDirection: autoController.getTextDirection(sportRecordsCtr.text),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                minLines: 3,
                maxLines: 3,
                expands: false,
                decoration: ColorTheme.noneBordersInputDecoration,
                onChanged: (t){
                  autoController.onChangeText(t);
                  courseQuestionModel.sportsRecordsDescription = t;
                },
              );
            },
          ),
        ),

        SizedBox(height: AppSizes.fwSize(18),),
        Text('${tInMap('courseBuyQuestionPage', 'dietDescription')}:').bold().fs(16).alpha(alpha: 150),
        SizedBox(height: AppSizes.fwSize(5),),
        DecoratedBox(
          decoration: inputParentDecoration,
          child: AutoDirection(
            builder: (context, autoController) {
              return TextField(
                controller: dietCtr,
                textDirection: autoController.getTextDirection(dietCtr.text),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.text,
                minLines: 3,
                maxLines: 3,
                expands: false,
                decoration: ColorTheme.noneBordersInputDecoration,
                onChanged: (t){
                  autoController.onChangeText(t);
                  courseQuestionModel.dietDescription = t;
                },
              );
            },
          ),
        ),
      ],
    );
  }
  ///========================================================================================================
}
