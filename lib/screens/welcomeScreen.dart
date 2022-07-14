import 'package:flutter/material.dart';

import '/abstracts/stateBase.dart';
import '/screens/home/homeScreen.dart';
import '/screens/loginPart/loginScreen.dart';
import '/screens/registeringPart/registerScreen.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/routeCenter.dart';

class WelcomeScreen extends StatefulWidget {
  static const screenName = 'WelcomeScreen';

  WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return WelcomeScreenState();
  }
}
///===============================================================================================
class WelcomeScreenState extends StateBase<WelcomeScreen> {

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
    super.dispose();
  }

  Widget getScaffold() {
    return WillPopScope(
      onWillPop: () => onWillBack(this),
      child: Scaffold(
        key: scaffoldKey,
        extendBodyBehindAppBar: true,
        body: getBody(),
      ),
    );
  }

  getAppbar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: <Widget>[
      ],
    );
  }
  
  getBody() {
    return SizedBox(
      width: AppSizes.getScreenWidth(context),
      height: AppSizes.getScreenHeight(context),
      /// screen
      child: Stack(
        children: [
          /// background
          Positioned.fill(
            child: Image.asset('assets/images/selectLanguage.jpg',
              fit: BoxFit.fill,
            ),
          ),

          Positioned(
            top: 0, left: 0, right: 0,
            child: getAppbar(),
          ),

          Positioned(
            top: AppSizes.fwSize(180), left: AppSizes.fwSize(40), right: AppSizes.fwSize(40),
            child: Column(
              children: [
                ColoredBox(
                  color: Colors.grey.withAlpha(140),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(tC('welcome')!,
                      textScaleFactor: AppSizes.fwTextFactor(3.6),
                      style: AppThemes.baseTextStyle().copyWith(color: Colors.yellow),
                    ),
                  ),
                ),

                SizedBox(height: AppSizes.fwSize(70),),
                ColoredBox(
                  color: Colors.black.withAlpha(100),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(tC('welcomeDescription')!,
                        textScaleFactor: AppSizes.fwTextFactor(1.5),
                        textAlign: TextAlign.center,
                        style: AppThemes.baseTextStyle().copyWith(
                          color: Colors.white,
                        )
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 50, left: 30, right: 30,
            child: ButtonBar(
              alignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              buttonPadding: EdgeInsets.symmetric(horizontal: 14),
              buttonMinWidth: 100,
              overflowButtonSpacing: 8,
              buttonAlignedDropdown: true,
              layoutBehavior: ButtonBarLayoutBehavior.constrained,
              children: [
                ElevatedButton(
                  onPressed: () => loginBtn(),
                  child: Text(tC('login')!),
                ),

                ElevatedButton(
                  onPressed: () => registerBtn(),
                  child: Text(tC('register')!),
                ),

                ElevatedButton(
                  onPressed: () => guestBtn(),
                  child: Text(tC('guest')!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void loginBtn() {
    RouteCenter.navigateRouteScreen(HomeScreen.screenName);
    AppNavigator.pushNextAndRemoveUntilRoot(context, LoginScreen(), name: LoginScreen.screenName);
  }

  void registerBtn() {
    AppNavigator.pushNextPage(context, RegisterScreen(), name: RegisterScreen.screenName);
  }

  void guestBtn() {
    RouteCenter.navigateRouteScreen(HomeScreen.screenName);
    AppNavigator.popRoutesUntilRoot(context);
  }
}




