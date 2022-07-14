import 'package:brandfit_user/screens/trainerSearchPart/trainerSearchScreen.dart';
import 'package:brandfit_user/tools/app/appNavigator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/screens/centerPagePart/centerPageScreen.dart';
import '/tools/advertisingTools.dart';

class CenterPageScreenCtr implements ViewController {
  late CenterPageScreenState state;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as CenterPageScreenState;

    reBuildCarouselView();
  }

  @override
  void onBuild(){
    AdvertisingTools.prepareCarousel();
    AdvertisingTools.callRequestAdvertising();
  }

  @override
  void onDispose(){
    //HttpCenter.cancelAndClose(loginRequester?.httpRequester);
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is CenterPageScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  void reBuildCarouselView(){
    if(AdvertisingTools.carouselModelList.isNotEmpty) {
      state.carouselRefresher.attach(state.buildCarouselView());
    }
    else {
      state.carouselRefresher.attach(null);
    }
  }

  void gotoTrainerSearch(){
    AppNavigator.pushNextPage(
        state.context,
        TrainerSearchScreen(),
        name: TrainerSearchScreen.screenName
    );
  }
}
