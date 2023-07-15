import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:oym/Helper/Color.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:oym/Screen/ReferEarn.dart';
import 'package:oym/Screen/SendOtp.dart';
import 'package:oym/Screen/Setting.dart';
import 'package:oym/Screen/Login.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Helper/Constant.dart';
import '../Provider/Theme.dart';
import '../main.dart';
import 'Faqs.dart';
import 'Manage_Address.dart';
import 'MyOrder.dart';
import 'My_Wallet.dart';
import 'Privacy_Policy.dart';


class MyProfile extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => StateProfile();
}

class StateProfile extends State<MyProfile> with TickerProviderStateMixin {
  //String? profile, email;
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  var isDarkTheme;
  bool isDark = false;
  late ThemeNotifier themeNotifier;
  List<String> langCode = ["en", "zh", "es", "hi", "ar", "ru", "ja", "de"];
  List<String?> themeList = [];
  List<String?> languageList = [];
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  int? selectLan, curTheme;

  String? curPass, newPass, confPass, mobile;
  bool _showPassword = false, _showNPassword = false, _showCPassword = false;

  final GlobalKey<FormState> _changePwdKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _changeUserDetailsKey = GlobalKey<FormState>();
  final confirmpassController = TextEditingController();
  final newpassController = TextEditingController();
  final passwordController = TextEditingController();
  
  String? currentPwd, newPwd, confirmPwd;
  FocusNode confirmPwdFocus = FocusNode();

  bool _isNetworkAvail = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  @override
  void initState() {
    //getUserDetails();

    new Future.delayed(Duration.zero, () {
      languageList = [
        getTranslated(context, 'ENGLISH_LAN'),
        getTranslated(context, 'CHINESE_LAN'),
        getTranslated(context, 'SPANISH_LAN'),
        getTranslated(context, 'HINDI_LAN'),
        getTranslated(context, 'ARABIC_LAN'),
        getTranslated(context, 'RUSSIAN_LAN'),
        getTranslated(context, 'JAPANISE_LAN'),
        getTranslated(context, 'GERMAN_LAN')
      ];

      themeList = [
        getTranslated(context, 'SYSTEM_DEFAULT'),
        getTranslated(context, 'LIGHT_THEME'),
        getTranslated(context, 'DARK_THEME')
      ];

      _getSaved();
    });

    super.initState();
  }

  _getSaved() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(this.context, listen: false);

    //String get = await settingsProvider.getPrefrence(APP_THEME) ?? '';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? get  =   prefs.getString(APP_THEME);


    curTheme = themeList
        .indexOf(get == '' || get == DEFAULT_SYSTEM ? getTranslated(context, 'SYSTEM_DEFAULT') : get == LIGHT ? getTranslated(context, 'LIGHT_THEME') : getTranslated(context,'DARK_THEME'));


    String getlng = await settingsProvider.getPrefrence(LAGUAGE_CODE) ?? '';

    selectLan = langCode.indexOf(getlng == '' ? "en" : getlng);

    if (mounted) setState(() {});
  }

  /* getUserDetails() async {

    CUR_USERID = await getPrefrence(ID);
    CUR_USERNAME = await getPrefrence(USERNAME);
    email = await getPrefrence(EMAIL);
    profile = await getPrefrence(IMAGE);



    if (mounted) setState(() {});
  }*/

  _getHeader() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 10.0, top: 10),
        child: Container(
          padding: EdgeInsetsDirectional.only(
            start: 10.0,
          ),
          child: Row(
            children: [
              // Selector<UserProvider, String>(
              //     selector: (_, provider) => provider.profilePic,
              //     builder: (context, profileImage, child) {
              //       return getUserImage(
              //           profileImage);
              //     }),
              /*         Container(
                margin: EdgeInsetsDirectional.only(end: 20),
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 1.0, color: Theme.of(context).colorScheme.white)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100.0),
                  child: Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        return userProvider.profilePic != ''
                            ? new FadeInImage(
                          fadeInDuration: Duration(milliseconds: 150),
                          image: NetworkImage(userProvider.profilePic),
                          height: 64.0,
                          width: 64.0,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(64),
                          placeholder: placeHolder(64),
                        )
                            : imagePlaceHolder(62);
                      }),
                ),
              ),*/
              const SizedBox(
                height: 5,
              ),
              Consumer<UserProvider>(
                builder: (context,userProvider,child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Selector<SettingProvider, String>(
                          selector: (_, provider) => provider.userName,
                          builder: (context, userName, child) {
                            
                            return Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[300]
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Icon(Icons.person,size: 15,),
                                  )),
                                  const SizedBox(width: 5,),
                                Text(
                                  userName == ""
                                      ? getTranslated(context, 'GUEST')!
                                      : userName,
                                  style:
                                      Theme.of(context).textTheme.subtitle1!.copyWith(
                                            color: Theme.of(context).colorScheme.fontColor,
                                          ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(
                      height: 5,
                    ),
                      Selector<SettingProvider, String>(
                          selector: (_, provider) => provider.mobile,
                          builder: (context, userMobile, child) {
                            return userMobile != ""
                                ? Row(
                                  children: [
                                    Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[300]),
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Icon(
                                            Icons.phone,
                                            size: 15,
                                          ),
                                        )),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                        userMobile,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                                color: Theme.of(context).colorScheme.fontColor,
                                                fontWeight: FontWeight.normal),
                                      ),
                                  ],
                                )
                                : Container(
                                    height: 0,
                                  );
                          }),
                          const SizedBox(
                      height : 5,
                    ),
                      Selector<SettingProvider, String>(
                          selector: (_, provider) => provider.email,
                          builder: (context, userEmail, child) {
                            
                            return userEmail != ""
                                ? Row(
                                  children: [
                                    Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[300]),
                                        child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Icon(
                                            Icons.email,
                                            size: 15,
                                          ),
                                        )),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                        userEmail,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                                color: Theme.of(context).colorScheme.fontColor,
                                                fontWeight: FontWeight.normal),
                                      ),
                                  ],
                                )
                                : Container(
                                    height: 0,
                                  );
                          }),

                      /* Consumer<UserProvider>(builder: (context, userProvider, _) {
                        print("mobb**${userProvider.profilePic}");
                        return (userProvider.mob != "")
                            ? Text(
                                userProvider.mob,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(color: Theme.of(context).colorScheme.fontColor),
                              )
                            : Container(
                                height: 0,
                              );
                      }),*/
                      Consumer<SettingProvider>(builder: (context, userProvider, _) {
                        return userProvider.userName == ""
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(top: 7),
                                child: InkWell(
                                  child: Text(
                                      getTranslated(context, 'LOGIN_REGISTER_LBL')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .caption!
                                          .copyWith(
                                            color: colors.primary,
                                            decoration: TextDecoration.underline,
                                          )),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Login(),
                                        ));
                                  },
                                ))
                            : Container();
                      }),
                    ],
                  );
                }
              ),
            ],
          ),
        ));
  }

  List<Widget> getLngList(BuildContext ctx,StateSetter setModalState) {
    return languageList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  if (mounted)
                    setState(() {
                      selectLan = index;
                      _changeLan(langCode[index], ctx);
                    });
                  setModalState(() {});

                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectLan == index
                                    ? colors.grad2Color
                                    : Theme.of(context).colorScheme.white,
                                border: Border.all(color: colors.grad2Color)),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: selectLan == index
                                  ? Icon(
                                      Icons.check,
                                      size: 17.0,
                                      color: Theme.of(context).colorScheme.white,
                                    )
                                  : Icon(
                                      Icons.check_box_outline_blank,
                                      size: 15.0,
                                      color: Theme.of(context).colorScheme.white,
                                    ),
                            ),
                          ),
                          Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: 15.0,
                              ),
                              child: Text(
                                languageList[index]!,
                                style: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(color: Theme.of(context).colorScheme.lightBlack),
                              ))
                        ],
                      ),
                      // index == languageList.length - 1
                      //     ? Container(
                      //         margin: EdgeInsetsDirectional.only(
                      //           bottom: 10,
                      //         ),
                      //       )
                      //     : Divider(
                      //         color: Theme.of(context).colorScheme.lightBlack,
                      //       ),
                    ],
                  ),
                ),
              )),
        )
        .values
        .toList();
  }

  void _changeLan(String language, BuildContext ctx) async {
    Locale _locale = await setLocale(language);

    MyApp.setLocale(ctx, _locale);
  }


  Future<void> changePassword() async {
  
    
_isNetworkAvail = await isNetworkAvailable();
    SettingProvider settingProvider = context.read<SettingProvider>();
    settingProvider.getPrefrence('token').then((value) async {
       
    if (_isNetworkAvail) {
      try {
        print(CUR_USERID);
        
        var parameter =  {
      'custID': CUR_USERID,
      'currentPassword': passwordController.text,
      'newPassword': newpassController.text
      };
        print(parameter);
        Response response =
            await post(changePasswordApi, body: parameter, headers: {
              "Authorization": 'Bearer ' + value!,
            })
                .timeout(Duration(seconds: timeOut));
        print(response.body);
        var getdata = json.decode(response.body);
        int error = int.parse(getdata["error"]);
        String msg = getdata["message"];
        if (error == 200) {
          setSnackbar(msg);
          
           setState(() {});
           Navigator.of(context).pop();
           

        } else {
          setSnackbar(msg);
        }
        
        
      } on TimeoutException catch (_) {}
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
    });
    
    return null;
  }

/*  Future<void> setUpdateUser() async {
    var data = {USER_ID: CUR_USERID, OLDPASS: curPass, NEWPASS: newPass};

    Response response =
        await post(getUpdateUserApi, body: data, headers: headers)
            .timeout(Duration(seconds: timeOut));
    if (response.statusCode == 200) {
      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String? msg = getdata["message"];

      if (!error) {
        setSnackbar(getTranslated(context, 'USER_UPDATE_MSG')!);
      } else {
        setSnackbar(msg!);
      }
    }
  }*/

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

  _getDrawer() {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      children: <Widget>[
        CUR_USERID == "" || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'MY_ORDERS_LBL')!),
       // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        CUR_USERID == "" || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'MANAGE_ADD_LBL')!),
        //CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        CUR_USERID == "" || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'MYWALLET')!),
       // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        
       // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
       // _getDrawerItem(getTranslated(context, 'CHANGE_THEME_LBL')!),
       // _getDivider(),
       // _getDrawerItem(getTranslated(context, 'CHANGE_LANGUAGE_LBL')!),
      //  CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        CUR_USERID == "" || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'CHANGE_PASS_LBL')!),
       // _getDivider(),
        CUR_USERID == "" || CUR_USERID == null || !refer
            ? Container()
            : _getDrawerItem(getTranslated(context, 'REFEREARN')!),
       // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        _getDrawerItem(getTranslated(context, 'CUSTOMER_SUPPORT')!),
       // _getDivider(),
        _getDrawerItem(getTranslated(context, 'ABOUT_LBL')!),
       // _getDivider(),
        _getDrawerItem(getTranslated(context, 'CONTACT_LBL')!),
       // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'FAQS')!),
        _getDrawerItem(
              getTranslated(context, 'SHIP')!
            ),
       // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'PRIVACY')!),
       // _getDivider(),
        _getDrawerItem(
            getTranslated(context, 'TERM')!),
        _getDrawerItem(
          getTranslated(context, 'RETURN')!
        ),
       // _getDivider(),
        // _getDrawerItem(
        //     getTranslated(context, 'RATE_US')!),
       // _getDivider(),
        _getDrawerItem(getTranslated(context, 'SHARE_APP')!),
       // CUR_USERID == "" || CUR_USERID == null ? Container() : _getDivider(),
        CUR_USERID == "" || CUR_USERID == null
            ? Container()
            : _getDrawerItem(getTranslated(context, 'LOGOUT')!),
      ],
    );
  }

/*  _getDivider() {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.black26,
    );
  }*/

  _getDrawerItem(String title) {
    return Card(
      elevation: 0,
      child: ListTile(
        trailing: Icon(
          Icons.navigate_next,
          color: colors.primary,
        ),
        dense: true,
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.lightBlack, fontSize: 15),
        ),
        onTap: () {
          if (title == getTranslated(context, 'MY_ORDERS_LBL')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyOrder(),
                ));

            //sendAndRetrieveMessage();
          
          } else if (title == getTranslated(context, 'MYWALLET')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyWallet(),
                ));
          } else if (title == getTranslated(context, 'SETTING')) {
            CUR_USERID == null
                ? Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ))
                : Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Setting(),
                    ));
          } else if (title == getTranslated(context, 'MANAGE_ADD_LBL')) {
            CUR_USERID == null
                ? Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ))
                : Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageAddress(
                        home: true,
                      ),
                    ));
          } else if (title == getTranslated(context, 'REFEREARN')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReferEarn(),
                ));
          } else if (title == getTranslated(context, 'CONTACT_LBL')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'CONTACT_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'CUSTOMER_SUPPORT')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'CUSTOMER_SUPPORT'),
                  ),
                ));
          } else if (title == getTranslated(context, 'TERM')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'TERM'),
                  ),
                ));
          } else if (title == getTranslated(context, 'RETURN')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'RETURN'),
                  ),
                ));
          }
          else if (title == getTranslated(context, 'SHIP')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'SHIP'),
                  ),
                ));
          }
          else if (title == getTranslated(context, 'PRIVACY')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'PRIVACY'),
                  ),
                ));
          } 
          // else if (title == getTranslated(context, 'RATE_US')) {
          //   _openStoreListing();
          // } 
          else if (title == getTranslated(context, 'SHARE_APP')) {
            var str = "$appName\n\n${getTranslated(context, 'APPFIND')}$androidLink$packageName";
                //\n\n ${getTranslated(context, 'IOSLBL')}\n$iosLink

            Share.share(str);
          } else if (title == getTranslated(context, 'ABOUT_LBL')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'ABOUT_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'FAQS')) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'FAQS'),
                  ),
                ));
          } 
          // else if (title == getTranslated(context, 'CHANGE_THEME_LBL')) {
          //   openChangeThemeBottomSheet();
          // } 
          else if (title == getTranslated(context, 'LOGOUT')) {
            logOutDailog();
          } else if (title == getTranslated(context, 'CHANGE_PASS_LBL')) {
            openChangePasswordBottomSheet();
          } 
          // else if (title == getTranslated(context, 'CHANGE_LANGUAGE_LBL')) {
          //   openChangeLanguageBottomSheet();
          // }
        },
      ),
    );
  }



  List<Widget> themeListView(BuildContext ctx) {
    return themeList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  _updateState(index, ctx);
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: curTheme == index
                                    ? colors.grad2Color
                                    : Theme.of(context).colorScheme.white,
                                border: Border.all(color: colors.grad2Color)),
                            child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: curTheme == index
                                    ? Icon(
                                        Icons.check,
                                        size: 17.0,
                                        color: Theme.of(context).colorScheme.white,
                                      )
                                    : Icon(
                                        Icons.check_box_outline_blank,
                                        size: 15.0,
                                        color: Theme.of(context).colorScheme.white,
                                      )),
                          ),
                          Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: 15.0,
                              ),
                              child: Text(
                                themeList[index]!,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(color: Theme.of(context).colorScheme.lightBlack),
                              ))
                        ],
                      ),
                      // index == themeList.length - 1
                      //     ? Container(
                      //         margin: EdgeInsetsDirectional.only(
                      //           bottom: 10,
                      //         ),
                      //       )
                      //     : Divider(
                      //         color: Theme.of(context).colorScheme.lightBlack,
                      //       )
                    ],
                  ),
                ),
              )),
        )
        .values
        .toList();
  }

  _updateState(int position, BuildContext ctx) {
    curTheme = position;

    onThemeChanged(themeList[position]!, ctx);
  }

  void onThemeChanged(
    String value,
    BuildContext ctx,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value == getTranslated(ctx, 'SYSTEM_DEFAULT')) {
      themeNotifier.setThemeMode(ThemeMode.system);
      prefs.setString(APP_THEME, DEFAULT_SYSTEM);

      var brightness = SchedulerBinding.instance.window.platformBrightness;
      if (mounted)
        setState(() {
          isDark = brightness == Brightness.dark;
          if (isDark)
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
          else
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        });
    } else if (value == getTranslated(ctx, 'LIGHT_THEME')) {
      themeNotifier.setThemeMode(ThemeMode.light);
      prefs.setString(APP_THEME, LIGHT);
      if (mounted)
        setState(() {
          isDark = false;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        });
    } else if (value == getTranslated(ctx, 'DARK_THEME')) {
      themeNotifier.setThemeMode(ThemeMode.dark);
      prefs.setString(APP_THEME, DARK);
      if (mounted)
        setState(() {
          isDark = true;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
        });
    }
    ISDARK = isDark.toString();

    //Provider.of<SettingProvider>(context,listen: false).setPrefrence(APP_THEME, value);

  }

  

  logOutDailog() async {
    await dialogAnimate(context,
        StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0))),
          content: Text(
            getTranslated(context, 'LOGOUTTXT')!,
            style: Theme.of(this.context)
                .textTheme
                .subtitle1!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          ),
          actions: <Widget>[
            new TextButton(
                child: Text(
                  getTranslated(context, 'NO')!,
                  style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                }),
            new TextButton(
                child: Text(
                  getTranslated(context, 'YES')!,
                  style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  SettingProvider settingProvider =
                      Provider.of<SettingProvider>(context, listen: false);
                  settingProvider.clearUserSession(context);
                  //favList.clear();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home', (Route<dynamic> route) => false);
                })
          ],
        );
      });
    }));
  }

  @override
  Widget build(BuildContext context) {

    

    themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
        key: scaffoldKey,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getHeader(),
                _getDrawer(),
              ],
            ),
          ),
        ));
  }

  Widget getUserImage(String profileImage,) {
    return Stack(
      children: <Widget>[
        Container(
          margin: EdgeInsetsDirectional.only(end: 20),
          height: 80,
          width: 80,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 1.0, color: Theme.of(context).colorScheme.white)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100.0),
            child: Consumer<UserProvider>(builder: (context, userProvider, _) {

              return userProvider.profilePic != ''
                  ? new FadeInImage(
                      fadeInDuration: Duration(milliseconds: 150),
                      image: NetworkImage(userProvider.profilePic),
                      height: 64.0,
                      width: 64.0,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) =>
                          erroWidget(64),
                      placeholder: placeHolder(64),
                    )
                  : imagePlaceHolder(62,context);
            }),
          ),
        ),
        /*CircleAvatar(
      radius: 40,
      backgroundColor: colors.primary,
      child: profileImage != ""
          ? ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: FadeInImage(
                fadeInDuration: Duration(milliseconds: 150),
                image: NetworkImage(profileImage),
                height: 100.0,
                width: 100.0,
                fit: BoxFit.cover,
                placeholder: placeHolder(100),
                imageErrorBuilder: (context, error, stackTrace) =>
                    erroWidget(100),
              ))
          : Icon(
              Icons.account_circle,
              size: 80,
              color: Theme.of(context).colorScheme.white,
            ),
    ),*/
        if (CUR_USERID != null)
          Positioned.directional(
              textDirection:Directionality.of(context) ,
            end: 20,
              bottom: 5,
              child: Container(
                height: 20,
                width: 20,
                child: InkWell(
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.white,
                    size: 10,
                  ),
                  onTap: () {
                    if (mounted) {
                      
                    }
                  },
                ),
                decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(20),
                    ),
                    border: Border.all(color: colors.primary)),
              )),
      ],
    );
  }

 

  Widget bottomSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Theme.of(context).colorScheme.lightBlack),
        height: 5,
        width: MediaQuery.of(context).size.width * 0.3,
      ),
    );
  }

  Widget bottomsheetLabel(String labelName) => Padding(
        padding: const EdgeInsets.only(top: 30.0,bottom: 20),
        child: getHeading(labelName),
      );

  void _imgFromGallery() async {
    var result = await FilePicker.platform.pickFiles();
    if (result != null) {
      var image = File(result.files.single.path!);
      if (mounted) {
        await setProfilePic(image);
      }
    } else {
      // User canceled the picker
    }
  }

  Future<void> setProfilePic(File _image) async {

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var image;
        var request = http.MultipartRequest("POST", (getUpdateUserApi));
        request.headers.addAll(headers);
        request.fields[USER_ID] = CUR_USERID!;
        var pic = await http.MultipartFile.fromPath(IMAGE, _image.path);
        request.files.add(pic);

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);

        var getdata = json.decode(responseString);
        bool error = getdata["error"];
        String? msg = getdata['message'];
        if (!error) {
          var data = getdata["data"];
          for (var i in data) {
            image = i[IMAGE];
          }

          var settingProvider =
              Provider.of<SettingProvider>(context, listen: false);
          settingProvider.setPrefrence(IMAGE, image!);

          var userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setProfilePic(image!);
          setSnackbar(getTranslated(context, 'PROFILE_UPDATE_MSG')!);
        } else {
          setSnackbar(msg!);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

 

  Widget saveButton(String title, VoidCallback? onBtnSelected) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: MaterialButton(
              height: 45.0,
              textColor: Theme.of(context).colorScheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              onPressed: onBtnSelected,
              child: Text(title),
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> validateAndSave(GlobalKey<FormState> key) async {
    final form = key.currentState!;
    form.save();
    if (form.validate()) {
        await changePassword();
        // passwordController.clear();
        // newpassController.clear();
        // confirmpassController.clear();
      
      return true;
    }
    return false;
  }

  Widget getHeading(String title) {
    return Text(
      getTranslated(context, title)!,
      style: Theme.of(context)
          .textTheme
          .headline6!
          .copyWith(fontWeight: FontWeight.bold),
    );
  }

  void openChangePasswordBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                  key: _changePwdKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      bottomSheetHandle(),
                      bottomsheetLabel("CHANGE_PASS_LBL"),
                      setCurrentPasswordField(),
                      setForgotPwdLable(),
                      newPwdField(),
                      confirmPwdField(),
                      saveButton(getTranslated(context, "SAVE_LBL")!, () {
                        validateAndSave(_changePwdKey);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }

  void openChangeLanguageBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Wrap(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Form(
                  key: _changePwdKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      bottomSheetHandle(),
                      bottomsheetLabel("CHOOSE_LANGUAGE_LBL"),
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setModalState){
                          return SingleChildScrollView(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: getLngList(context,setModalState)),
                          );
                        },

                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }

  

  Widget setCurrentPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            obscuringCharacter: "*",
            decoration: InputDecoration(
                label: Text(getTranslated(context, "CUR_PASS_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            onSaved: (String? value) {
              currentPwd = value;
            },
            validator: (val) => validatePass(
                val!,
                getTranslated(context, 'PWD_REQUIRED'),
                getTranslated(context, 'PWD_LENGTH')),
          ),
        ),
      ),
    );
  }

  Widget setForgotPwdLable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(child: Text(getTranslated(context, "FORGOT_PASSWORD_LBL")!),onTap: (){
          Navigator.of(context).push(MaterialPageRoute(builder: (context)=> SendOtp()));
        },),
      ),
    );
  }

  Widget newPwdField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            controller: newpassController,
            obscureText: true,
            obscuringCharacter: "*",
            decoration: InputDecoration(
                label: Text(getTranslated(context, "NEW_PASS_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            onSaved: (String? value) {
              newPwd = value;
            },
            validator: (val) => validatePass(
                val!,
                getTranslated(context, 'PWD_REQUIRED'),
                getTranslated(context, 'PWD_LENGTH')),
          ),
        ),
      ),
    );
  }

  Widget confirmPwdField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: TextFormField(
            controller: confirmpassController,
            focusNode: confirmPwdFocus,
            obscureText: true,
            obscuringCharacter: "*",
            decoration: InputDecoration(
                label: Text(getTranslated(context, "CONFIRMPASSHINT_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                border: InputBorder.none),
            validator: (value) {
              if (value!.isEmpty) {
                return getTranslated(context, 'CON_PASS_REQUIRED_MSG');
              }
              if (value != newPwd) {
                confirmpassController.text = "";
                confirmPwdFocus.requestFocus();
                return getTranslated(context, 'CON_PASS_NOT_MATCH_MSG');
              } else {
                return null;
              }
            },
          ),
        ),
      ),
    );
  }
}
