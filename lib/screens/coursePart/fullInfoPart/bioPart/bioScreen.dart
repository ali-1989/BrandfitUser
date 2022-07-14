import 'package:flutter/material.dart';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/courseModels/pupilCourseModel.dart';
import '/models/dataModels/photoDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/coursePart/fullInfoPart/bioPart/bioScreenCtr.dart';
import '/system/extensions.dart';
import '/tools/app/appSizes.dart';
import '/views/brokenImageView.dart';
import '/views/messageViews/communicationErrorView.dart';
import '/views/preWidgets.dart';

class BioScreen extends StatefulWidget {
  static const screenName = 'BioScreen';
  final PupilCourseModel courseModel;
  final UserModel trainerModel;
  final String? bio;
  final String? cardNumber;
  final List<PhotoDataModel> images;

  BioScreen({
    Key? key,
    required this.courseModel,
    required this.trainerModel,
    required this.bio,
    required this.cardNumber,
    required this.images,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return BioScreenState();
  }
}
///=======================================================================================================
class BioScreenState extends StateBase<BioScreen> {
  StateXController stateController = StateXController();
  BioScreenCtr controller = BioScreenCtr();

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
      title: Text(tInMap('trainerManagementPage', 'biography')!),
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
          case StateXController.state$serverNotResponse:
            return CommunicationErrorView(this);
          default:
            return getBody();
        }
      },
    );
  }

  Widget getBody() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      children: [
        SizedBox(height: 8,),
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 0),
          child: Text(widget.trainerModel.userName)
              .boldFont(),
        ),

        SizedBox(height: 8,),
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 0),
          child: Text('${tInMap('bioPage', 'biography')}')
              .boldFont().alpha(),
        ),

        SizedBox(height: 4,),
        SizedBox(
          height: 250,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: quill.QuillEditor.basic(
              controller: controller.bioCtr,
              readOnly: true,
            ),
          ),
        ).wrapBoxBorder(),

        SizedBox(height: 20,),
        Visibility(
          visible: widget.cardNumber != null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 0),
            child: Row(
              children: [
                Text('${tInMap('coursePage', 'cardNumber')}')
                    .boldFont().alpha(),

                SizedBox(width: 10,),
                Text('${widget.cardNumber}').bold(),
              ],
            ),
          ),
        ),

        SizedBox(height: 20,),
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 0),
          child: Text('${tInMap('bioPage', 'bioPhotos')}')
              .boldFont().alpha(),
        ),

        SizedBox(height: 10,),
        SizedBox(
          height: 170,
          child: Card(
            color: Colors.grey.shade300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.photos.length,
              itemBuilder: (ctx, idx) {
                final ph = controller.photos.elementAt(idx);

                return GestureDetector(
                  onTap: (){
                    controller.openGallery(idx);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child: Padding(
                      padding: EdgeInsets.all(6.0),
                      child: IrisImageView(
                        beforeLoadWidget: PreWidgets.flutterLoadingWidget$Center(),
                        errorWidget: BrokenImageView(),
                        url: ph.uri,
                        imagePath: ph.getPath(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        SizedBox(height: 10,),
      ],
    );
  }
  ///==========================================================================================

}
