import 'package:flutter/material.dart';

import 'package:iris_tools/widgets/searchBar.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/programModels/foodSuggestion.dart';
import '/screens/programViewPart/selectOtherMaterial/selectOtherMaterialCtr.dart';
import '/system/extensions.dart';
import '/tools/app/appThemes.dart';

class SelectOtherMaterialScreen extends StatefulWidget {
  static const screenName = 'SelectOtherMaterialScreen';
  final FoodSuggestion foodSuggestion;

  const SelectOtherMaterialScreen({
    required this.foodSuggestion,
    Key? key,
  }) : super(key: key);

  @override
  State<SelectOtherMaterialScreen> createState() => SelectOtherMaterialScreenState();
}
///================================================================================================
class SelectOtherMaterialScreenState extends StateBase<SelectOtherMaterialScreen> {
  StateXController stateController = StateXController();
  SelectOtherMaterialCtr controller = SelectOtherMaterialCtr();


  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    controller.onBuild();
    rotateToPortrait();

    return Scaffold(
      appBar: getAppBar(),
      body: StateX(
        controller: stateController,
        isMain: true,
        builder: (context, ctr, data) {
          return getBody();
        }
      ),
    );
  }

  @override
  void dispose() {
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  PreferredSizeWidget getAppBar(){
    return AppBar();
  }

  Widget getBody(){
    return Column(
      children: [
        getSearchBar(),

        Expanded(
          child: ListView.builder(
              itemCount: controller.foodMaterialList.length,
              itemBuilder: (ctx, idx){
                return genListItem(idx);
              }
              ),
        )
      ],
    );
  }

  Widget getSearchBar(){
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: SearchBar(
        hint: '${t('search')}',
        shareTextController: (c){
          controller.searchEditController = c;
        },
        searchEvent: (text){
          if(controller.filterRequest.setTextToSelectedSearch(text)) {
            controller.resetRequest();
          }
        },
        onClearEvent: (){
          if(controller.filterRequest.setTextToSelectedSearch(null)) {
            controller.resetRequest();
          }
        },
      ),
    );
  }

  Widget genListItem(int idx){
    final material = controller.foodMaterialList[idx];

    return GestureDetector(
      onTap: (){
        controller.onClickOnMaterial(material);
      },
      child: Card(
          color: AppThemes.currentTheme.accentColor,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${material.matchTitle}')
                        .fsR(6).bold()
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor),
                    SizedBox(height: 8,),
                    Text(material.getMainFundamentalsPrompt(context))
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),
                  ],
                ),

                SizedBox(height: 2,),
                Column(
                  children: [
                    Text('${material.getTypeTranslate(context)}')
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppThemes.currentTheme.whiteOrAppBarItemOnDifferent()),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.all(4),
                      child: Column(
                        children: [
                          Text(material.measure.unitValue)
                              .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),

                          Text('${tInMap('materialUnits', material.measure.unit)}')
                              .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
      ),
    );
  }
}
