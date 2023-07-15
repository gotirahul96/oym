import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:oym/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';

class PrivacyPolicy extends StatefulWidget {
  final String? title;

  const PrivacyPolicy({Key? key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }
}

class StatePrivacy extends State<PrivacyPolicy> with TickerProviderStateMixin {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String? privacy;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  late StreamSubscription<WebViewStateChanged> _onStateChanged;

  @override
  void initState() {
    super.initState();
   
    getSetting();
    flutterWebViewPlugin.close();
    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController!,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));

    _onStateChanged =
        flutterWebViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
   

      if (state.type == WebViewState.abortLoad) {
        _launchSocialNativeLink(state.url);
      }
    });
  }

  Future<void> _launchSocialNativeLink(String url) async {

    if (Platform.isIOS) {
      if (url.contains("tel:")) {
        _launchUrl(url);
      }
    } else if (Platform.isAndroid) {
      if (url.contains("tel:") ||
          url.contains("https://api.whatsapp.com/send")) {
        _launchUrl(url);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
 
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    _onStateChanged.cancel();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => super.widget));
                } else {
                  await buttonController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return privacy != null
            ? WebviewScaffold(
                appBar: getSimpleAppBar(widget.title!, context),
                withJavascript: true,
                appCacheEnabled: true,
                scrollBar: false,
                url: privacy!,
                invalidUrlRegex: Platform.isAndroid
                    ? "^tel:|^https:\/\/api.whatsapp.com\/send|^mailto:"
                    : "^tel:|^mailto:",
              )
            : Scaffold(
                key: _scaffoldKey,
                appBar: getSimpleAppBar(widget.title!, context),
                body: _isNetworkAvail ? Container() : noInternet(context),
              );
         }

  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      
        if (widget.title == getTranslated(context, 'PRIVACY'))
          setState(() => privacy = 'https://www.oymsmartshop.com/privacy-policyApp.php');
        else if (widget.title == getTranslated(context, 'TERM'))
          setState(() => privacy = 'https://www.oymsmartshop.com/terms-and-conditionsApp.php');
        else if (widget.title == getTranslated(context, 'CONTACT_LBL'))
          setState(() => privacy = 'https://www.oymsmartshop.com/contact-usApp.php');
        else if (widget.title == getTranslated(context, 'ABOUT_LBL'))
          setState(() => privacy = 'https://www.oymsmartshop.com/about-usApp.php');
        else if (widget.title == getTranslated(context, 'FAQS'))
          setState(() => privacy = 'https://www.oymsmartshop.com/faqApp.php');
        else if (widget.title == getTranslated(context, 'CUSTOMER_SUPPORT'))
          setState(() => privacy = 'https://www.oymsmartshop.com/customerSupportApp.php');
        else if (widget.title == getTranslated(context, 'SHIP'))
        setState(() => privacy = 'https://www.oymsmartshop.com/shipping-policyApp.php');
        else if (widget.title == getTranslated(context, 'RETURN'))
        setState(() => privacy = 'https://www.oymsmartshop.com/return-policyApp.php');
    } else {
      if (mounted)
        setState(() {
          _isLoading = false;
          _isNetworkAvail = false;
        });
    }
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }
}
