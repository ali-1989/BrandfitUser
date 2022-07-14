import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/colorHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/courseModels/pupilCourseModel.dart';
import '/screens/coursePart/fullInfoPart/requestFullInfoCtr.dart';
import '/system/extensions.dart';
import '/tools/app/appThemes.dart';
import '/tools/currencyTools.dart';
import '/tools/dateTools.dart';

class RequestFullInfoScreen extends StatefulWidget {
  static const screenName = 'RequestFullInfoScreen';
  final PupilCourseModel courseModel;

  const RequestFullInfoScreen({
    Key? key,
    required this.courseModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => RequestFullInfoScreenState();
}
///=====================================================================================
class RequestFullInfoScreenState extends StateBase<RequestFullInfoScreen> {
  StateXController stateController = StateXController();
  RequestFullInfoCtr controller = RequestFullInfoCtr();

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
    controller.onDispose();
    stateController.dispose();

    super.dispose();
  }

  Widget getScaffold(){
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.courseModel.title),
      ),
      body: SafeArea(
          child: getMainBuilder()
      ),
    );
  }

  Widget getMainBuilder(){
    return StateX(
        isMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
          return getBody();
        }
    );
  }

  Widget getBody(){
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: ColoredBox(
              color: ColorHelper.textToColor(controller.courseModel.title),
              child: GestureDetector(
                onTap: (){
                  controller.showFullScreenImage();
                },
                child: Hero(
                  tag: 'h${controller.courseModel.id}',
                  child: IrisImageView(
                    height: 180,
                    imagePath: controller.courseModel.imagePath,
                    url: controller.courseModel.imageUri,
                  ),
                ),
              ),
            ),
          ),

          Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(
                          label: Text('ID: ${controller.courseModel.id}'),
                        ),
                      ],
                    ),

                    /*Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        icon: Icon(IconList.dotsVerM)
                            .primaryOrAppBarItemOnBackColor(),
                        alignment: Alignment.centerLeft,
                        onPressed: (){
                          //controller.showEditSheet();
                        },
                      ),
                    )*/
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text('${context.tC('title')}')
                        .boldFont().color(AppThemes.currentTheme.infoColor),

                    Text(controller.courseModel.title)
                        .boldFont().color(AppThemes.currentTheme.infoColor),
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  
                  children: [
                    Text('${context.tC('creationDate')}'),

                    Text(DateTools.dateRelativeByAppFormat(controller.courseModel.creationDate)).boldFont(),
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text('${context.tC('price')}'),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.ltr,
                      children: [
                        Text(CurrencyTools.formatCurrency(MathHelper.clearToInt(controller.courseModel.price)))
                            .boldFont(),

                        SizedBox(width: 8,),
                        Text('${controller.courseModel.currencyModel.currencySymbol}')
                            .alpha(),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text('${context.tInMap('addCoursePage', 'courseDays')}'),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.ltr,
                      children: [
                        Text(CurrencyTools.formatCurrency(MathHelper.clearToInt(controller.courseModel.durationDay)))
                            .boldFont(),

                        SizedBox(width: 8,),
                        Text('${t('days')}')
                            .alpha(),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text('${t('status')}'),

                    Text(controller.courseModel.getStatusText(context))
                        .bold().color(controller.courseModel.getStatusColor()),
                  ],
                ),

                const SizedBox(height: 6,),
                Visibility(
                    visible: controller.courseModel.getRejectCause(context) != null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${tInMap('coursePage', 'rejectCause')}:'),
                          ],
                        ),

                        SizedBox(height: 5,),
                        Text('${controller.courseModel.getRejectCause(context)}'),
                      ],
                    )
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Visibility(
                        visible: controller.courseModel.hasExerciseProgram,
                        child: Chip(
                          label: Text('${context.tInMap('coursePage', 'exerciseProgram')}'),
                          backgroundColor: AppThemes.currentTheme.infoColor,
                        )
                    ),

                    const SizedBox(width: 4),
                    Visibility(
                        visible: controller.courseModel.hasFoodProgram,
                        child: Chip(
                          label: Text('${context.tInMap('coursePage', 'foodProgram')}'),
                          backgroundColor: AppThemes.currentTheme.infoColor,
                        )
                    ),
                  ],
                ),


                const SizedBox(height: 6,),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                    child: Text('${context.t('description')}:')),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Card(
                    color: Colors.grey.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(controller.courseModel.description),
                    ),
                  ),
                ),

                const SizedBox(height: 20,),
                Row(
                  children: [
                    Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(primary: AppThemes.currentTheme.infoColor),
                          //icon: Icon(IconList.buyBoxM),
                          child: Text('${tInMap('coursePage', 'payInfo')}'),
                          onPressed: (){
                            controller.gotoPayInfoScreen();
                          },
                        )
                    ),

                    const SizedBox(width: 10,),
                    Expanded(
                        child: ElevatedButton(
                          child: Text('${tInMap('coursePage', 'trainerInfo')}'),
                          onPressed: (){
                            controller.gotoTrainerInfo();
                          },
                        )
                    ),
                  ],
                ),

                const SizedBox(height: 15,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
