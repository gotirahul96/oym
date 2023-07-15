import 'package:flutter/services.dart';
import 'package:oym/Helper/Color.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:oym/Screen/Favorite.dart';
import 'package:oym/Screen/Login.dart';
import 'package:oym/Screen/MyProfile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'All_Category.dart';
import 'Cart.dart';
import 'HomePage.dart';
import 'NotificationLIst.dart';
import 'Sale.dart';
import 'Search.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Dashboard> with TickerProviderStateMixin {
  int _selBottom = 0;
  late TabController _tabController;
  DateTime? backbuttonpressedTime;
  List<Widget> bottomWidgets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
    );
    bottomWidgets = [HomePage(),
              AllCategory(),
              Sale(),
              Cart(
                fromBottom: true,
              ),
              MyProfile()];
    _tabController.addListener(() {
      Future.delayed(Duration(seconds: 0)).then((value) {
        if (_tabController.index == 3) {
          if (CUR_USERID == null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Login(),
                ));
            _tabController.animateTo(0);
          }
        }
      });

      setState(() {
        _selBottom = _tabController.index;
      });
    });
  }
 

 Future<bool> mainonWillPop() {
   var confirm;
     if (_selBottom != 0) {
        setState(() {
        _selBottom = 0 ;
        _tabController.animateTo(_selBottom);
      });
     } else {
       onWillPop();
     }
     return confirm;
  }

  Future<bool> onWillPop() async {
  DateTime currentTime = DateTime.now();
  //Statement 1 Or statement2
  bool backButton = backbuttonpressedTime == null ||
      currentTime.difference(backbuttonpressedTime!) > Duration(seconds: 3);

  if (backButton) {
    backbuttonpressedTime = currentTime;
    Fluttertoast.showToast(
        msg: "Double Click to exit app",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
    return false;
  }
  SystemNavigator.pop();
  return true;
}
  @override
  Widget build(BuildContext context) {
    
    return WillPopScope(
      onWillPop: mainonWillPop,
      child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.lightWhite,
          appBar: _getAppBar(),
          body: TabBarView(
            controller: _tabController,
            children: bottomWidgets,
          ),
          //fragments[_selBottom],
          bottomNavigationBar: _getBottomBar()),
    );
  }

  AppBar _getAppBar() {
    String? title;
    if (_selBottom == 1)
      title = getTranslated(context, 'CATEGORY');
    else if (_selBottom == 2)
      title = getTranslated(context, 'OFFER');
    else if (_selBottom == 3)
      title = getTranslated(context, 'MYBAG');
    else if (_selBottom == 4) title = getTranslated(context, 'PROFILE');

    return AppBar(
      centerTitle: false,
      
      title: _selBottom == 0
          ? Image.asset('assets/mainimages/toplogo.png',width: 140,height: 60,)
          : Text(
              title!,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal
              ),
            ),
      // leading: _selBottom == 0
      //     ? 
      //     : null,
      // iconTheme: new IconThemeData(color: colors.primary),
      // centerTitle:_curSelected == 0? false:true,
      actions: <Widget>[
       IconButton(
                icon: SvgPicture.asset(
                  imagePath + "search.svg",
                  height: 20,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Search(),
                      ));
                }),
        // IconButton(
        //   icon: SvgPicture.asset(imagePath + "desel_notification.svg",color: Colors.white),
        //   onPressed: () {
        //     CUR_USERID != null
        //         ? Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (context) => NotificationList(),
        //             ))
        //         : Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (context) => Login(),
        //             ));
        //   },
        // ),
        IconButton(
          padding: EdgeInsets.all(0),
          icon: SvgPicture.asset(imagePath + "desel_fav.svg",color: Colors.white),
          onPressed: () {
            CUR_USERID != null
                ? Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Favorite(),
                    ))
                : Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ));
          },
        ),

      ],
      backgroundColor: colors.primary,
    );
  }

  Widget _getBottomBar() {
    return Material(
        color: Theme.of(context).colorScheme.white,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.white,
            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.black26, blurRadius: 10)],
          ),
          child: TabBar(
            onTap: (_) {
              if (_tabController.index == 3) {
                if (CUR_USERID == null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Login(),
                      ));
                  _tabController.animateTo(0);
                }
              }
            },
            controller: _tabController,
            tabs: [
              Tab(
                icon: SvgPicture.asset(imagePath + "sel_home.svg",color: colors.primary),
                text:
                    _selBottom == 0 ? getTranslated(context, 'HOME_LBL') : null,
              ),
              Tab(
                icon: SvgPicture.asset(imagePath + "catsvg.svg",color: colors.primary),
                text:
                    _selBottom == 1 ? getTranslated(context, 'category') : null,
              ),
              Tab(
                icon:  SvgPicture.asset(imagePath + "salesvg.svg",color: colors.primary),
                    
                text: _selBottom == 2 ? getTranslated(context, 'SALE') : null,
              ),
              Tab(
                icon: Selector<UserProvider, String>(
                  builder: (context, data, child) {
                    return Stack(
                      children: [
                        Center(
                          child: SvgPicture.asset(imagePath + "cartsvg.svg",color: colors.primary),
                        ),
                        (data != null && data.isNotEmpty && data != "0")
                            ? new Positioned.directional(
                                bottom: _selBottom == 3 ? 6 : 20,
                                textDirection: Directionality.of(context),
                                end: 0,
                                child: Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red),
                                    child: new Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(3),
                                        child: new Text(
                                          data,
                                          style: TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.white),
                                        ),
                                      ),
                                    )),
                              )
                            : Container()
                      ],
                    );
                  },
                  selector: (_, homeProvider) => homeProvider.curCartCount,
                ),


                text: _selBottom == 3 ? getTranslated(context, 'CART') : null,
              ),
              Tab(
                icon: SvgPicture.asset(imagePath + "profile01.svg",color: colors.primary),
                text: _selBottom == 4 ? getTranslated(context, 'ACCOUNT') : null,
              ),
            ],
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: colors.primary, width: 5.0),
              insets: EdgeInsets.fromLTRB(50.0, 0.0, 50.0, 70.0),
            ),
            labelColor: colors.primary,
          ),
        ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
