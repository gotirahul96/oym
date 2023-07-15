import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:oym/Helper/Color.dart';
import 'package:oym/Helper/Constant.dart';
import 'package:oym/Helper/PushNotificationService.dart';
import 'package:oym/Helper/cropped_container.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:oym/Screen/SignUp.dart';
import 'package:provider/provider.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';

class VerifyOtp extends StatefulWidget {
  final String? mobileNumber, title, from;

  VerifyOtp(
      {Key? key, required String this.mobileNumber, this.title, this.from})
      : assert(mobileNumber != null),
        super(key: key);

  @override
  _MobileOTPState createState() => _MobileOTPState();
}

class _MobileOTPState extends State<VerifyOtp> with TickerProviderStateMixin {
  final dataKey = GlobalKey();
  String? password, mobile, countrycode;
  String? otp;
  bool isCodeSent = false;
  OtpFieldController otpController = OtpFieldController();
  late String _verificationId;
  String signature = "";
  bool _isClickable = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  String? username, email, id, mobileno, referCode, token;

  @override
  void initState() {
    super.initState();
    getUserDetails();
    Future.delayed(Duration(seconds: 60)).then((_) {
      _isClickable = true;
    });
    buttonController = AnimationController(
        duration: Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: Interval(
        0.0,
        0.150,
      ),
    ));
  }

  getUserDetails() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    mobile = await settingsProvider.getPrefrence(MOBILE);
    countrycode = await settingsProvider.getPrefrence(COUNTRY_CODE);
    if (mounted) setState(() {});
  }

  Future<void> checkNetworkOtp() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      if (_isClickable) {
        _onFormSubmitted();
      } else {
        setSnackbar(getTranslated(context, 'OTPWR')!);
      }
    } else {
      if (mounted) setState(() {});

      Future.delayed(Duration(seconds: 60)).then((_) async {
        bool avail = await isNetworkAvailable();
        if (avail) {
          if (_isClickable)
            _onFormSubmitted();
          else {
            setSnackbar(getTranslated(context, 'OTPWR')!);
          }
        } else {
          await buttonController!.reverse();
          setSnackbar(getTranslated(context, 'somethingMSg')!);
        }
      });
    }
  }

  Widget verifyBtn() {
    return AppBtn(
        title: getTranslated(context, 'VERIFY_AND_PROCEED'),
        btnAnim: buttonSqueezeanimation,
        btnCntrl: buttonController,
        onBtnSelected: () async {
          _onFormSubmitted();
        });
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      elevation: 1.0,
    ));
  }

  void _onFormSubmitted() async {
    String code = otp!.trim();

    if (code.length == 6) {
      _playAnimation();

      if (widget.from == 'signup') {
        try {
          var data = {'mobile': mobile, 'otp': code};
          Response response = await post(getOtpSignup, body: data)
              .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);
          print(response.body);
          bool? error = getdata["error"] == '200' ? true : false;
          String? msg = getdata["message"];
          await buttonController!.reverse();

          SettingProvider settingsProvider =
              Provider.of<SettingProvider>(context, listen: false);

          if (error) {
            setSnackbar(msg!);

            settingsProvider.setPrefrence(MOBILE, mobile!);

            Future.delayed(Duration(seconds: 1)).then((_) {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SignUp(
                            mobileNo: mobile!,
                          )));
            });
          } else {
            setSnackbar(msg!);
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!);
          await buttonController!.reverse();
        }
      } else {
        var data = {'mobile': widget.mobileNumber, 'otp': code};
        print(data);
        try {
          Response response = await post(postOtpVerifyApi, body: data)
              .timeout(Duration(seconds: timeOut));
          print(response.body);
          var getdata = json.decode(response.body);
          int error = int.parse(getdata["error"]);
          String? msg = getdata["message"];
          await buttonController!.reverse();
          if (error == 200) {
            //setSnackbar(getTranslated(context, 'LOGIN_SUCCESS_MSG')!);
            var i = getdata["data"][0];
            id = i['custID'];
            username = i['custName'];
            email = i['custEmail'];
            mobile = i['custMobile'];
            referCode = i['referalCode'];
            token = i['token'];
            CUR_USERID = id;

            // CUR_USERNAME = name;

            UserProvider userProvider = context.read<UserProvider>();
            userProvider.setName(username ?? "");

            SettingProvider settingProvider = context.read<SettingProvider>();
            settingProvider.saveUserDetail(
                id!, username, email, mobile, referCode, token, context);
            PushNotificationService(context: context).initialise();
            Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
          } else {
            setSnackbar(msg!);
            otpController.clear();
          }
          if (mounted) setState(() {});
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!);
          await buttonController!.reverse();
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'ENTEROTP')!);
    }
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  getImage() {
    return Expanded(
      flex: 4,
      child: Center(
        child: SvgPicture.asset('assets/images/homelogo.svg'),
      ),
    );
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> getVerifyUser() async {
    try {
      var data = {'mobile': mobile, 'otp': ''};
      Response response = await post(getOtpSignup, body: data)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      print(response.body);
      bool? error = getdata["error"] == '200' ? true : false;
      String? msg = getdata["message"];

      if (error) {
        setSnackbar('Otp Sent Again');
      } else {
        setSnackbar(msg!);
      }
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!);
      await buttonController!.reverse();
    }
  }

  monoVarifyText() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          top: 20.0,
        ),
        child: Center(
          child: Text(getTranslated(context, 'MOBILE_NUMBER_VARIFICATION')!,
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 25)),
        ));
  }

  otpText() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 30.0, start: 20.0, end: 20.0),
        child: Center(
          child: Text(getTranslated(context, 'SENT_VERIFY_CODE_TO_NO_LBL')!,
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.normal)),
        ));
  }

  mobText() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          bottom: 10.0, start: 20.0, end: 20.0, top: 10.0),
      child: Center(
        child: Text("${widget.mobileNumber}",
            style: Theme.of(context).textTheme.subtitle1!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal)),
      ),
    );
  }

  Widget otpLayout() {
    return Center(
      child: OTPTextField(
        length: 6,
        fieldWidth: 38,
        controller: otpController,
        width: MediaQuery.of(context).size.width,
        style: TextStyle(
            fontSize: 20, color: Theme.of(context).colorScheme.fontColor),
        textFieldAlignment: MainAxisAlignment.spaceAround,
        isDense: true,
        fieldStyle: FieldStyle.box,
        onCompleted: (code) {
          print("Completed: " + code);
          otp = code;
        },
        onChanged: (code) {
          otp = code;
        },
      ),
      // child: PinFieldAutoFill(
      //     decoration: UnderlineDecoration(
      //       textStyle: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.fontColor),
      //       colorBuilder: FixedColorBuilder(colors.primary),
      //     ),
      //     currentCode: otp,
      //     codeLength: 6,
      //     onCodeChanged: (String? code) {
      //       otp = code;
      //     },
      //     onCodeSubmitted: (String code) {
      //       otp = code;
      //     })
    );
  }

  Widget resendText() {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          bottom: 30.0, start: 25.0, end: 25.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            getTranslated(context, 'DIDNT_GET_THE_CODE')!,
            style: Theme.of(context).textTheme.caption!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.normal),
          ),
          InkWell(
              onTap: () async {
                await buttonController!.reverse();
                widget.from == 'signup' ? getVerifyUser() : resendotp();
              },
              child: Text(
                getTranslated(context, 'RESEND_OTP')!,
                style: Theme.of(context).textTheme.caption!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.normal),
              ))
        ],
      ),
    );
  }

  Future<void> resendotp() async {
    var data = {'mobile': widget.mobileNumber};

    try {
      Response response = await post(postOtpSigninApi, body: data);
      print(response.body);
      var getdata = json.decode(response.body);
      int error = int.parse(getdata["error"]);
      String? msg = getdata["message"];
      if (error == 200) {
        setSnackbar(msg!);
      } else {
        setSnackbar(msg!);
      }
    } catch (e) {}
  }

  expandedBottomView() {
    return Expanded(
      flex: 6,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: ScrollConfiguration(
            behavior: MyBehavior(),
            child: SingleChildScrollView(
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: EdgeInsetsDirectional.only(start: 20.0, end: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    monoVarifyText(),
                    otpText(),
                    mobText(),
                    otpLayout(),
                    verifyBtn(),
                    resendText(),
                  ],
                ),
              ),
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: back(),
            ),
            Image.asset(
              'assets/images/doodle.png',
              fit: BoxFit.fill,
              width: double.infinity,
              height: double.infinity,
            ),
            getLoginContainer(),
            getLogo(),
          ],
        ));
  }

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      // end: width * 0.025,
      // top: width * 0.45,
      top: MediaQuery.of(context).size.height * 0.2, //original
      //    bottom: height * 0.1,
      textDirection: Directionality.of(context),
      child: ClipPath(
        clipper: ContainerClipper(),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.6),
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.95,
          color: Theme.of(context).colorScheme.white,
          child: Form(
            // key: _formkey,
            child: ScrollConfiguration(
              behavior: MyBehavior(),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.10,
                      ),
                      monoVarifyText(),
                      otpText(),
                      mobText(),
                      otpLayout(),
                      verifyBtn(),
                      resendText(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getLogo() {
    return Positioned(
      // textDirection: Directionality.of(context),
      left: (MediaQuery.of(context).size.width / 2) - 50,
      // right: ((MediaQuery.of(context).size.width /2)-55),

      top: (MediaQuery.of(context).size.height * 0.2) - 50,
      //  bottom: height * 0.1,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Image.asset(
          'assets/images/loginlogo.png',
        ),
      ),
    );
  }
}
