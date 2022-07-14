import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '/abstracts/stateBase.dart';
import '/managers/settingsManager.dart';

class TermScreen extends StatefulWidget {
  static const screenName = 'TermScreen';

  TermScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TermScreenState();
  }
}
///=====================================================================================
class TermScreenState extends StateBase<TermScreen> {
  late InAppWebViewGroupOptions webViewGroupOptions;
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();

    webViewGroupOptions = InAppWebViewGroupOptions(
        android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
          clearSessionCache: true,
          overScrollMode: AndroidOverScrollMode.OVER_SCROLL_NEVER,
          minimumLogicalFontSize: 20,
          databaseEnabled: true,
          domStorageEnabled: true,
          allowContentAccess: true,
          allowFileAccess: true,
          loadsImagesAutomatically: true,
        ),
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
        ),
        crossPlatform: InAppWebViewOptions(
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
          cacheEnabled: false,
          clearCache: true,
          disableHorizontalScroll: false,
          horizontalScrollBarEnabled: true,
          disableVerticalScroll: false,
          verticalScrollBarEnabled: true,
          useOnLoadResource: true,
          supportZoom: true,
          minimumFontSize: 22,
          transparentBackground: true,
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: false,
          mediaPlaybackRequiresUserGesture: true,
        )
    );

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
    });
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
        appBar: getAppbar(),
        body: getScaffoldBody(),
      ),
    );
  }

  getAppbar() {
    return AppBar(
      title: Text(tInMap('termPage', 'term&Conditions')!),
    );
  }

  getScaffoldBody() {
    return SizedBox.expand(

      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: InAppWebView(
              initialOptions: webViewGroupOptions,
              initialData: InAppWebViewInitialData(
                encoding: 'utf8',
                data: getContent(),
              ),
              onWebViewCreated: (InAppWebViewController controller) {
                webViewController = controller;
              },
              onLoadStart: (InAppWebViewController controller, Uri? url) {},
              onLoadStop: (InAppWebViewController controller, Uri? url) {},
            ),
          ),
        ],
      ),
    );
  }
  ///========================================================================================================
  String getContent(){
    String lCode = SettingsManager.settingsModel.appLocale.languageCode;
    String? res = contents[lCode];

    res ??= contents['en'];

    return res!;
  }

  Map<String, String> contents = {
    'en': '''<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <!--<meta name="viewport" content="width=device-width, initial-scale=1.0">-->
        <style type="text/css">
            html, body {
            max-width: 100%;
            overflow-x: hidden;
            }
    
            .title {
              font-size: 50px;
              color: rgb(10, 20, 200);
            }
            .text{
                font-size:35px;
                padding: 0 5%;
                text-align: justify;
                text-justify: inter-word;
            }
    
            .fadeIn div {
              animation: fadeIn 3s cubic-bezier(0, 0, 1, 1) backwards, move 1s forwards;
              -webkit-animation: fadeIn 3s cubic-bezier(0, 0, 1, 1) backwards, move 1s forwards;
            }
    
            @keyframes fadeIn {
              0% {opacity:0;}
              100% {opacity:1;}
            }
    
            @-webkit-keyframes fadeIn {
              from {opacity:0;}
              to {opacity:1;}
            }
    
            @keyframes move {
                from { transform : translate(0, 70px); }
                to   { transform : translate(0, 0); }
            }
    
            @-webkit-keyframes move {
              from {-webkit-transform: translate(0, 70px);}
              to {-webkit-transform: translate(0, 0);}
            }
    
        </style>
    </head>
    <body>
    <div dir="rtl">
        <div class="title"><span><strong>قوانین و مقررات استفاده از اپلیکیشن برندفیت:</strong></span></div>
        <p>&nbsp</p>
        <div class="fadeIn">
            <div><span style="font-size:37px;"><strong>اینجانب متعهد می شوم که:</strong></span></div>
            <div class="text"><span>&diams;&nbsp;از این اپلیکیشن در چهارچوب قوانین جمهوری اسلامی ایران و همچنین اهداف این اپلیکیشن که رسیدن به تناسب اندام هست استفاده نمایم و مسولیت هر گونه تخطی از قوانین و شرایط را برعهده می گیرم.</span></div>
            <div class="text"><span>&diams; با مشخصات حقیقی به این اپلیکیشن وارد شده ام و مسولیت وارد نمودن هرگونه اطلاعات غیر واقعی را برعهده می گیرم.</span></div>
            <div class="text"><span>&diams; قبل از هرگونه خرید در این اپلیکیشن تمامی شرایط ، هزینه ها و قوانین برندفیت را مطالعه نموده ام و خود را ملزم به اجرای آن می دانم.</span></div>
        </div>
    </div>
    <script>
        var x = document.querySelectorAll(".fadeIn div");
        for(var i = 0; i < x.length; i++){
           x[i].style.animationDelay = (i*0.5)+"s";
           x[i].style.webkitAnimationDelay = (i*0.5)+"s";
        }
    </script>
    </body>
</html>''',

    'fa': '''<html>
    <head>
        <meta charset="UTF-8" />
        <!--<meta name="viewport" content="width=device-width, initial-scale=1.0">-->
        <style type="text/css">
            html, body {
            max-width: 100%;
            overflow-x: hidden;
            }
    
            .title {
              font-size: 50px;
              color: rgb(10, 20, 200);
            }
            .text{
                font-size:35px;
                padding: 0 5%;
                text-align: justify;
                text-justify: inter-word;
            }
    
            .fadeIn div {
              animation: fadeIn 3s cubic-bezier(0, 0, 1, 1) backwards, move 1s forwards;
              -webkit-animation: fadeIn 3s cubic-bezier(0, 0, 1, 1) backwards, move 1s forwards;
            }
    
            @keyframes fadeIn {
              0% {opacity:0;}
              100% {opacity:1;}
            }
    
            @-webkit-keyframes fadeIn {
              from {opacity:0;}
              to {opacity:1;}
            }
    
            @keyframes move {
                from { transform : translate(0, 70px); }
                to   { transform : translate(0, 0); }
            }
    
            @-webkit-keyframes move {
              from {-webkit-transform: translate(0, 70px);}
              to {-webkit-transform: translate(0, 0);}
            }
    
        </style>
    </head>
    <body>
    <div dir="rtl">
        <div class="title"><span><strong>قوانین و مقررات استفاده از اپلیکیشن برندفیت:</strong></span></div>
        <p>&nbsp</p>
        <div class="fadeIn">
            <div><span style="font-size:37px;"><strong>اینجانب متعهد می شوم که:</strong></span></div>
            <div class="text"><span>&diams;&nbsp;از این اپلیکیشن در چهارچوب قوانین جمهوری اسلامی ایران و همچنین اهداف این اپلیکیشن که رسیدن به تناسب اندام هست استفاده نمایم و مسولیت هر گونه تخطی از قوانین و شرایط را برعهده می گیرم.</span></div>
            <div class="text"><span>&diams; با مشخصات حقیقی به این اپلیکیشن وارد شده ام و مسولیت وارد نمودن هرگونه اطلاعات غیر واقعی را برعهده می گیرم.</span></div>
            <div class="text"><span>&diams; قبل از هرگونه خرید در این اپلیکیشن تمامی شرایط ، هزینه ها و قوانین برندفیت را مطالعه نموده ام و خود را ملزم به اجرای آن می دانم.</span></div>
        </div>
    </div>
    <script>
        var x = document.querySelectorAll(".fadeIn div");
        for(var i = 0; i < x.length; i++){
           x[i].style.animationDelay = (i*0.5)+"s";
           x[i].style.webkitAnimationDelay = (i*0.5)+"s";
        }
    </script>
    </body>
</html>'''
  };
}
