import 'package:brandfit_user/tools/app/appThemes.dart';
import 'package:flutter/material.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:iris_tools/plugins/launcher.dart';
import 'package:iris_tools/widgets/animations/glowAnimation.dart';
import 'package:iris_tools/modules/stateManagers/refresh.dart';
import 'package:iris_tools/modules/stateManagers/selfRefresh.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/screens/centerPagePart/centerPageScreenCtr.dart';
import '/system/extensions.dart';
import '/tools/advertisingTools.dart';
import '/tools/app/appSizes.dart';
import '/tools/uriTools.dart';

class CenterPageScreen extends StatefulWidget {
  static const screenName = 'CenterPageScreen';

  CenterPageScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CenterPageScreenState();
  }
}
///=============================================================================================================
class CenterPageScreenState extends StateBase<CenterPageScreen> {
  StateXController stateController = StateXController();
  CenterPageScreenCtr controller = CenterPageScreenCtr();
  RefreshController carouselRefresher = RefreshController();


  @override
  void initState() {
    super.initState();
    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    controller.onBuild();

    return getPage();
  }

  @override
  void dispose() {
    controller.onDispose();
    stateController.dispose();
    carouselRefresher.dispose();

    super.dispose();
  }

  Widget getPage() {
    var  d = '''
 برای افرادی که  اهدافی مثل: چربی سوزی، عضله سازی، تثبیت وزن و... دارند و قصد دارند رژیم غذایی و برنامه تمرینی داشته باشند این امکان را فراهم کرده تا بصورتی علمی و آسان بتوانند آموزشهای لازم را ببینند و با مربی های خود در بستری مطمئن و مجهز در ارتباط باشند.
     ''';

    var  d2 = '''
در اپلیکیشن برندفیت میتوانید: 
متابولیسم پایه (BMR)
کالری تثبیت (TDEE)
شاخص توده بدنی ( BMI)
کالری روزانه خود و میزان درشت مغذی ها و ریز مغذی های هر ماده غذایی را به راحتی محاسبه کنید
    ''';

    var  d3 = '''
در اپلیکیشن برندفیت میتوانید:
در اپلیکیشن برندفیت
اجرای هر حرکت ورزشی را بصورت تصویری آموزش خواهید دید
و همچنین دیگر نگران جزئیات برنامه ورزشی خود ائم از اینکه با چه وزنه ای و با چه شدتی و با چه استراحتی و... حرکت خود را انجام دهید نخواهید بود
''';

 var  d4 = '''
در اپلیکیشن برندفیت
در صورتی که مایل باشید میتوانید به سادگی گزارشات غذایی و تمرینی خود را بصورت اتوماتیک برای مربیتان ارسال کنید
و همچنین جهت برقراری ارتباط متنی، صوتی و تصویری با مربی خود به هیچ پلتفرم دیگه ای احتیاج ندارید
    ''';

    return StateX(
        isMain: true,
        controller: stateController,
        builder: (ctx, ctr, data){
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppSizes.getScreenWidth(context),
              maxHeight: AppSizes.getScreenHeight(context),
            ),

            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  /// carousel
                  /*Refresh(
                    controller: carouselRefresher,
                    builder: (ctx, ctr){
                      if(ctr.attachment() != null) {
                        return ctr.attachment();
                      }

                      return SizedBox();
                    },
                  ),*/

                  /// list 1
                  /*Expanded(
                    child: Align(
                      child: FractionallySizedBox(
                        widthFactor: 0.8,
                        heightFactor: 0.8,
                        child: Card(
                          child: Image.asset('assets/images/ad1.png'),
                        ),
                      ),
                    ),
                  ),*/

                  SizedBox(height: 30,),
                  SizedBox(
                    width: double.maxFinite,
                    child: Stack(
                      children: [
                        Center(
                            child: Image.asset('assets/images/app_icon.jpg', width: 120, height: 120,)
                        ),

                        Align(
                          alignment: AlignmentDirectional.topStart,
                          child: GlowAnimation(
                            endRadius: 40,
                            shape: BoxShape.rectangle,
                            glowColor: AppThemes.currentTheme.primaryColor,
                            child: ElevatedButton(
                              onPressed: (){
                                controller.gotoTrainerSearch();
                              },
                              child: Text('جستجو مربی'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10,),
                  Text('اپلیکیشن برندفیت').bold().fsR(4).boldFont().color(Colors.purpleAccent),
                  SizedBox(height: 10,),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(d).bold().fsR(2),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(d2).bold().fsR(2).color(Colors.red),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(d3).bold().fsR(2).color(Colors.blue),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(d4).bold().fsR(2).color(Colors.pink),
                  ),

                  /// bottom pad
                  SizedBox(height: 20,),
                ],
              ),
            ),
          );
        }
    );
  }
  ///===========================================================================================================
  Widget buildCarouselView(){
    return AspectRatio(
      aspectRatio: 16/10,
      //height: 200,
      //width: double.infinity,
      child: SelfRefresh(
        builder: (ctx, ctr){
          return GestureDetector(
            onTap: (){
              if(ctr.get('Link') != null){
                Launcher.launchInBrowser(UriTools.addHttpIfNeed(ctr.get('Link')));
              }
            },
            child: Stack(
              children: [
                CarouselSlider(
                    items: AdvertisingTools.carouselModelList.map((e) => e.imageWidget!).toList(),
                    options: CarouselOptions(
                      height: 200,
                      aspectRatio: 16/9,
                      viewportFraction: 0.9,
                      initialPage: 0,
                      scrollDirection: Axis.horizontal,
                      enableInfiniteScroll: true,
                      reverse: true,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      autoPlayInterval: Duration(seconds: 7),
                      autoPlayAnimationDuration: Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      onPageChanged: (idx, reason){
                        final model = AdvertisingTools.carouselModelList.elementAt(idx);
                        final title = model.title;
                        final link = model.clickLink;

                        if(link != null && link.isEmpty) {
                          ctr.set('Link', null);
                        } else {
                          ctr.set('Link', link);
                        }

                        if(title != null && title.isEmpty) {
                          ctr.set('Title', null);
                        } else {
                          ctr.set('Title', title);
                        }

                        ctr.update();
                      },
                    )
                ),

                if(ctr.get('Title') != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(30),
                            Colors.black.withAlpha(80),
                            Colors.black.withAlpha(150),
                          ]

                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Text('${ctr.get('Title')}').color(Colors.white).fsR(5).bold(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
