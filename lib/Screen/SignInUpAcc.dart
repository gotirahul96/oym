import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Screen/Login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:oym/Screen/SignUp.dart';
import 'package:oym/Screen/SignUpMobile.dart';

import '../Helper/Color.dart';
import 'SendOtp.dart';
class SignInUpAcc extends StatefulWidget {
  @override
  _SignInUpAccState createState() => new _SignInUpAccState();
}

class _SignInUpAccState extends State<SignInUpAcc> {
  _subLogo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25),
      child: Padding(
          padding: EdgeInsetsDirectional.only(top: 30.0,),
          child: Image.asset(
            'assets/mainimages/mainlogo.png',height: 200,
          )),
    );
  }

  welcomeEshopTxt() {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: 30.0),
      child: new Text(
        'Welcome to OYM',
        style: Theme.of(context)
            .textTheme
            .subtitle1!
            .copyWith(color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  eCommerceforBusinessTxt() {
    return Padding(
      padding: EdgeInsets.only(
        top: 5.0,
        left: 10,
        right: 10
      ),
      child: new Text(
        "The eCommerce app for all the things ON YOUR MIND",
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .subtitle2!
            .copyWith(color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.normal),
      ),
    );
  }

  signInyourAccTxt() {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: 80.0, bottom: 40),
      child: new Text(
        getTranslated(context, 'SIGNIN_ACC_LBL')!,
        style: Theme.of(context)
            .textTheme
            .subtitle1!
            .copyWith(color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  signInBtn() {
    return CupertinoButton(
      child: Container(
          width: deviceWidth! * 0.8,
          height: 45,
          alignment: FractionalOffset.center,
          decoration: new BoxDecoration(
            color: colors.secondary,
            // gradient: LinearGradient(
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //     colors: [colors.grad1Color, colors.grad2Color],
            //     stops: [0, 1]),
            borderRadius: new BorderRadius.all(const Radius.circular(10.0)),
          ),
          child: Text(getTranslated(context, 'SIGNIN_LBL')!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .subtitle1!
                  .copyWith(color: colors.whiteTemp, fontWeight: FontWeight.normal))),
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (BuildContext context) => Login()));
      },
    );
  }

  createAccBtn() {
    return CupertinoButton(
      child: Container(
          width: deviceWidth! * 0.8,
          height: 45,
          alignment: FractionalOffset.center,
          decoration: new BoxDecoration(
            color: colors.secondary,
            // gradient: LinearGradient(
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //     colors: [colors.grad1Color, colors.grad2Color],
            //     stops: [0, 1]),
            borderRadius: new BorderRadius.all(const Radius.circular(10.0)),
          ),
          child: Text(getTranslated(context, 'CREATE_ACC_LBL')!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .subtitle1!
                  .copyWith(color: colors.whiteTemp, fontWeight: FontWeight.normal))),
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => SignUpMobile(title: 'Enter you mobile No'),
        ));
      },
    );
  }

  skipSignInBtn() {
    return CupertinoButton(
      child: Container(
          width: deviceWidth! * 0.8,
          height: 45,
          alignment: FractionalOffset.center,
          decoration: new BoxDecoration(
            color: colors.secondary,
            // gradient: LinearGradient(
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //     colors: [colors.grad1Color, colors.grad2Color],
            //     stops: [0, 1]),
            borderRadius: new BorderRadius.all(const Radius.circular(10.0)),
          ),
          child: Text(getTranslated(context, 'SKIP_SIGNIN_LBL')!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .subtitle1!
                  .copyWith(color: colors.whiteTemp, fontWeight: FontWeight.normal))),
      onPressed: () {
        Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Container(
        color: Theme.of(context).colorScheme.lightWhite,
        child: Center(
            child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _subLogo(),
                    welcomeEshopTxt(),
                    eCommerceforBusinessTxt(),
                    signInyourAccTxt(),
                    signInBtn(),
                    createAccBtn(),
                    skipSignInBtn(),
                  ],
                ))));
  }
}
