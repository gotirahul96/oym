import 'dart:async';
import 'dart:convert';

import 'package:oym/Helper/PushNotificationService.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Helper/cropped_container.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:oym/Screen/SendOtp.dart';
import 'package:oym/Screen/SignUp.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:oym/Screen/SignUpMobile.dart';
import 'package:oym/Screen/Verify_Otp.dart';
import 'package:provider/provider.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';

class Login extends StatefulWidget {
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<Login> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  
  final mobileController = TextEditingController();
  final emailcontroller = TextEditingController();
  final passwordController = TextEditingController();
  String? countryName;
  FocusNode? passFocus, monoFocus = FocusNode();

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formmobilekey = GlobalKey<FormState>();
  bool visible = false;
  String? password,
      mobile,
      username,
      email,
      id,
      mobileno,
      referCode,
      token;
      
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;

  AnimationController? buttonController;

  Animation? otpbuttonSqueezeanimation;

  AnimationController? otpbuttonController;

  @override
  void initState() {
    super.initState();
    
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
    otpbuttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    otpbuttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController!,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }
  Future<Null> _playotpAnimation() async {
    try {
      await otpbuttonController!.forward();
    } on TickerCanceled {}
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }
  void validateOtpAndSubmit() async {
    if (validateOtpAndSave()) {
      _playotpAnimation();
      checkOtpNetwork();
    }
  }
  Future<void> checkOtpNetwork() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getotpLoginUser();
    } else {
      Future.delayed(Duration(seconds: 2)).then((_) async {
        await otpbuttonController!.reverse();
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
      });
    }
  }

  Future<void> checkNetwork() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getLoginUser();
    } else {
      Future.delayed(Duration(seconds: 2)).then((_) async {
        await buttonController!.reverse();
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
      });
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }
  bool validateOtpAndSave() {
    final form = _formmobilekey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(

      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      elevation: 1.0,
    ));
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(top: kToolbarHeight),
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
  Future<void> getotpLoginUser() async {
    var data = {'mobile':mobileController.text};

    try {
      print(postOtpSigninApi);
      Response response = await post(postOtpSigninApi,body: data);
      print(response.body);
      var getdata = json.decode(response.body);
      int error = int.parse(getdata["error"]);
      String? msg = getdata["message"];
      await otpbuttonController!.reverse();
      if (error == 200) {
        Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        VerifyOtp(
                          mobileNumber: mobile!,
                          
                          title: getTranslated(context, 'SEND_OTP_TITLE'),
                        )));
      }
      else {
       setSnackbar(msg!);
      }
    } catch (e) {
    }
  }
  Future<void> getLoginUser() async {
    var data = {'email': emailcontroller.text, PASSWORD: passwordController.text};
     print(data);
 try{
   print(postSigninApi);
    Response response =
      await post(postSigninApi, body: data)
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
        referCode =i['referalCode'];
        token = i['token'];
        CUR_USERID = id;

        // CUR_USERNAME = name;

        UserProvider userProvider = context.read<UserProvider>();
        userProvider.setName(username ?? "");

        SettingProvider settingProvider = context.read<SettingProvider>();
        settingProvider.saveUserDetail(id!, username, email, mobile, referCode, token,context);
        PushNotificationService(context: context).initialise();
        Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
      } else {
        setSnackbar(msg!);
      }
      if (mounted) setState(() {});
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!);
      await buttonController!.reverse();
    }
  }

  _subLogo() {
    return Expanded(
      flex: 4,
      child: Center(
        child: Image.asset(
          'assets/mainimages/circlelogo.png',
        ),
      ),
    );
  }

  signInTxt() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          top: 0.0,
        ),
        child: Align(
          alignment: Alignment.center,
          child: new Text(
            'Log In With OTP',
            style: Theme.of(context)
                .textTheme
                .subtitle1!
                .copyWith(color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold),
          ),
        ));
  }

  setMobileNo() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: EdgeInsets.only(
        top: 0.0,
      ),
      child: TextFormField(
        // onFieldSubmitted: (v) {
        //   FocusScope.of(context).requestFocus(passFocus);
        // },
        keyboardType: TextInputType.number,
        maxLength: 8,
        controller: mobileController,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontWeight: FontWeight.normal,
        ),
        //focusNode: monoFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(10)],
        validator: (val) => validateMob(
            val!,
            getTranslated(context, 'MOB_REQUIRED'),
            getTranslated(context, 'VALID_MOB')),
        onSaved: (String? value) {
          mobile = value;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.phone_android,
            color: Theme.of(context).colorScheme.fontColor,
            size: 20,
          ),
          hintText: "Mobile Number",
          hintStyle: Theme.of(this.context)
              .textTheme
              .subtitle2!
              .copyWith(color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Theme.of(context).colorScheme.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 40,
            maxHeight: 20,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    ); 
  }

  setEmail() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: EdgeInsets.only(
        top: 0.0,
      ),
      child: TextFormField(
        // onFieldSubmitted: (v) {
        //   FocusScope.of(context).requestFocus(passFocus);
        // },
        keyboardType: TextInputType.emailAddress,
        controller: emailcontroller,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
          fontWeight: FontWeight.normal,
        ),
        
        textInputAction: TextInputAction.next,
        validator: (val) => validateEmail(
            val!,'Email Required!','Invalid Email'),
        onSaved: (String? value) {
          email = value;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.alternate_email_outlined,
            color: Theme.of(context).colorScheme.fontColor,
            size: 17,
          ),
          hintText: "Email",
          hintStyle: Theme.of(this.context)
              .textTheme
              .subtitle2!
              .copyWith(color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Theme.of(context).colorScheme.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 40,
            maxHeight: 20,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    ); 
  }

  setPass() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: EdgeInsets.only(
        top: 10.0,
      ),
      child: TextFormField(
        onFieldSubmitted: (v) {
          FocusScope.of(context).requestFocus(passFocus);
        },
        keyboardType: TextInputType.text,
        obscureText: true,
        controller: passwordController,
        style:
        TextStyle(color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.normal),
        focusNode: passFocus,
        textInputAction: TextInputAction.next,
        validator: (val) => validatePass(
            val!,
            getTranslated(context, 'PWD_REQUIRED'),
            getTranslated(context, 'PWD_LENGTH')),
        onSaved: (String? value) {
          password = value;
        },
        decoration: InputDecoration(
          prefixIcon: SvgPicture.asset(
            "assets/images/password.svg",
            color: Theme.of(context).colorScheme.fontColor,
          ),

          suffixIcon: InkWell(
            onTap: () {
              // SettingProvider settingsProvider =
              // Provider.of<SettingProvider>(this.context, listen: false);
              //
              // settingsProvider.setPrefrence(ID, id!);
              // settingsProvider.setPrefrence(MOBILE, mobile!);

              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SendOtp(
                        title: getTranslated(context, 'FORGOT_PASS_TITLE'),
                        
                      )));
            },
            child: Text(
              getTranslated(context, "FORGOT_LBL")!,
              style: TextStyle(
                color: colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          hintText: getTranslated(context, "PASSHINT_LBL")!,
          hintStyle: Theme.of(this.context).textTheme.subtitle2!.copyWith(
              color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.normal),
          //filled: true,
          fillColor: Theme.of(context).colorScheme.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          suffixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 20),
          prefixIconConstraints: BoxConstraints(minWidth: 40, maxHeight: 20),
          // focusedBorder: OutlineInputBorder(
          //     //   borderSide: BorderSide(color: fontColor),
          //     // borderRadius: BorderRadius.circular(7.0),
          //     ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.lightBlack2),
            borderRadius: BorderRadius.circular(7.0),
          ),
        ),
      ),
    );
  }


  termAndPolicyTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
          bottom: 20.0, start: 25.0, end: 25.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(getTranslated(context, 'DONT_HAVE_AN_ACC')!,
              style: Theme.of(context).textTheme.caption!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.normal)),
          InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => SignUpMobile(title: 'Enter you mobile No'),
                ));
              },
              child: Text(
                getTranslated(context, 'SIGN_UP_LBL')!,
                style: Theme.of(context).textTheme.caption!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.normal),
              ))
        ],
      ),
    );
  }

  loginBtn() {
    return AppBtn(
      title: getTranslated(context, 'SIGNIN_LBL'),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        validateAndSubmit();
      },
    );
  }

  getotpBtn() {
    return AppBtn(
      title: 'Get OTP',
      btnAnim: otpbuttonSqueezeanimation,
      btnCntrl: otpbuttonController,
      onBtnSelected: () async {
        validateOtpAndSubmit();
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        body: _isNetworkAvail
            ? Stack( 
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
        )

            : noInternet(context));
  }

  getLoginContainer() {
    return Positioned.directional(
      start: MediaQuery.of(context).size.width * 0.025,
      // end: width * 0.025,
      // top: width * 0.45,
      top: MediaQuery.of(context).size.height * 0.12, //original
      //    bottom: height * 0.1,
      textDirection: Directionality.of(context),
      child: ClipPath(
        clipper: ContainerClipper(),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom * 0.8),
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width * 0.95,
          color: Theme.of(context).colorScheme.white,
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
                    setSignInotpLabel(),
                    Form(
                      key: _formmobilekey,
                      child: setMobileNo()),
                    getotpBtn(),
                    setSignInemailLabel(),
                    Form(
                      key: _formkey,
                      child: Column(
                        children: [
                          setEmail(),
                          setPass(),
                        ],
                      )),
                    
                    loginBtn(),
                    termAndPolicyTxt(),
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
    );
  }

  Widget getLogo() {
    return Positioned(
      // textDirection: Directionality.of(context),
      left: (MediaQuery.of(context).size.width / 2) - 50,
      // right: ((MediaQuery.of(context).size.width /2)-55),

      top: (MediaQuery.of(context).size.height * 0.12) - 50,
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

  Widget setSignInotpLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text('login with OTP',
          style: const TextStyle(
            color: colors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  Widget setSignInemailLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 20),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text('login with Email',
          style: const TextStyle(
            color: colors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
