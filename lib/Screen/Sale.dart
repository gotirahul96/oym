import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:oym/Helper/AppBtn.dart';
import 'package:oym/Helper/Color.dart';
import 'package:oym/Helper/Constant.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/SimBtn.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/SaleProductsModel.dart';
import 'package:oym/Model/Section_Model.dart';
import 'package:oym/Provider/HomeProvider.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:oym/Screen/Favorite.dart';
import 'package:oym/Screen/Login.dart';
import 'package:oym/Screen/NotificationLIst.dart';
import 'package:oym/Screen/Search.dart';
import 'package:oym/Screen/SubCategory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Dashboard.dart';
import 'HomePage.dart';
import 'ProductList.dart';
import 'Product_Detail.dart';

class Sale extends StatefulWidget {
  final String? discount;
  const Sale({Key? key, this.discount}) : super(key: key);

  @override
  _SaleState createState() => _SaleState();
}

class _SaleState extends State<Sale>
    with AutomaticKeepAliveClientMixin<Sale>, TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  bool isLoading = false;
  late Animation buttonSqueezeanimation;
  late AnimationController buttonController;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  List<SaleProductsData> productList = [];
  SaleProductsModel saleProductsModel = SaleProductsModel();

  List<String> disList = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  new GlobalKey<RefreshIndicatorState>();
  int curDis = 0;
  bool _loading = true;
  bool _productLoading = true;
  ScrollController scrollController = ScrollController();

  //String? curPin;
  bool _isFirstLoad = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getSetting();
    scrollController.addListener(pagination);
    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  void getSetting() {
    
    //print("")
    Map parameter = Map();
    if (CUR_USERID != null) parameter = {'custID': CUR_USERID}; else parameter = {'custId' : '0'};

    apiBaseHelper.postAPICall(homePageSettingsApi, parameter).then((getdata) async {
      
      int error = int.parse(getdata["error"]);
      String? msg = getdata["message"];

      if (error == 200) {

        if (CUR_USERID != null) {

          context.read<UserProvider>().setCartCount(
              getdata["cartLength"].toString());
        }
        if(context.read<UserProvider>().saleDiscountList.isEmpty){
             context.read<UserProvider>().setsaleDiscountList = getdata["sale"].cast<String>();
        }
          disList.addAll(context.read<UserProvider>().saleDiscountList);
          if (widget.discount != null) {
      //curDis = int.parse(widget.discount!);
      for (var i = 0; i < disList.length; i++) {
        if (int.parse(widget.discount!) == int.parse(disList[i])) {
          curDis = i;
        }
      }
    }
         getProduct(from: '');
        
      } 
    }, onError: (error) {
      setSnackbar(error.toString(), context);
    });
  }

  void pagination() {
      if ((scrollController.position.pixels ==
          scrollController.position.maxScrollExtent)) {
        setState(() {
          isLoading = true;
          getProduct(from: 'Pagination');
          //add api for load the more data according to new page
        });
      }
  }

  Future<void> _refresh() {
    context.read<HomeProvider>().setCatLoading(true);
    context.read<HomeProvider>().setSecLoading(true);
    context.read<HomeProvider>().setSliderLoading(true);

    return getProduct(from: 'refresh');
  }

  
  Future<Null> callApi({String from = ''}) async {
    UserProvider user = Provider.of<UserProvider>(context, listen: false);
    SettingProvider setting =
    Provider.of<SettingProvider>(context, listen: false);

    user.setUserId(setting.userId);

    bool avail = await isNetworkAvailable();
    if (avail) {
      getProduct(from: from);
      
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: _getAppBar(),
       
        body: _isNetworkAvail
            ? RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      getTranslated(context, 'CHOOSE_DIS')!,
                      style: Theme
                          .of(context)
                          .textTheme
                          .subtitle1,
                    ),
                  ),
                  discountRow(),
                  _section(),
                  
                ],
              ),
            ))
            : noInternet(context));
  }
  _section() {
    return _loading
        ? saleShimmer(6)
        : productList.isEmpty ? Center(child: Image.asset('assets/mainimages/no.png',height: deviceHeight!/1.8)) :Stack(
          children: [
            Container(
              height: deviceHeight! / 1.43,
              child: ListView.builder(
      padding: EdgeInsets.all(0),
      controller: scrollController,
      itemCount: productList.length,
      shrinkWrap: true,
      physics: ScrollPhysics(),
      itemBuilder: (context, index) {
              return _singleSection(index);
      },
    ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: showCircularProgress(isLoading, colors.primary)),
          ],
        );
  }

  

  _singleSection(int index) {
    return productList[index].product!.length > 0
        ? Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _getHeading(productList[index].title ?? "", index),
              _getSection(index),
            ],
          ),
        ),
      ],
    )
        : Container();
  }

  _getHeading(String title, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Container(
            padding: EdgeInsetsDirectional.only(
              start: 10,
              bottom: 3,
              top: 3,
            ),
            child: Text(
              title,
              style: Theme
                  .of(context)
                  .textTheme
                  .subtitle1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(productList[index].subtitle ?? "",
                      style: Theme
                          .of(context)
                          .textTheme
                          .subtitle2),
                ),
                InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      getTranslated(context, 'seeAll')!,
                      style: Theme
                          .of(context)
                          .textTheme
                          .caption!
                          .copyWith(color: colors.primary),
                    ),
                  ),
                  onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : productList[index].title,
                      from: 'sale',
                      salePer: disList[curDis].toString(),
                    ),
                  ));
                  },
                ),
              ],
            )),
      ],
    );
  }

  _getSection(int i) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
      child: GridView.count(
          padding: EdgeInsetsDirectional.only(top: 5),
          crossAxisCount: 3,
          shrinkWrap: true,
          childAspectRatio: 0.8,
          physics: NeverScrollableScrollPhysics(),
          children: List.generate(
            productList[i].product!.length < 6
                ? productList[i].product!.length
                : 6,
                (index) {
              return sectionItem(i, index,);
            },
          )),
    );
  }

  Widget sectionItem(int secPos, int index) {
    if (productList[secPos].product!.length > index) {
      
      //$discount = round(($sellingPrice / $mrp * 100)-100);
      double discount = ((double.parse(productList[secPos].product![index].sellingPrice!) / double.parse(productList[secPos].product![index].mrp!)) * 100) - 100;
      double width = deviceWidth! * 0.5;
      
      return Card(
        elevation: 0.0,
        margin: EdgeInsetsDirectional.only(bottom: 2, end: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(

                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5)),
                          child: Hero(
                            transitionOnUserGestures: true,
                            tag:
                            "${productList[secPos].product![index]
                                .prodID}$secPos$index",
                            child: FadeInImage(
                              fadeInDuration: Duration(milliseconds: 150),
                              image: NetworkImage(imageBaseUrl+
                                  productList[secPos].product![index].image1!),
                              height: double.maxFinite,
                              width: double.maxFinite,
                              imageErrorBuilder: (context, error, stackTrace) =>
                                  erroWidget(double.maxFinite),
                              //fit: BoxFit.fill,
                              placeholder: placeHolder(width),
                            ),
                          )),
                    ),
                  ],
                ),
              ),

              Text(" " + CUR_CURRENCY! + " " + productList[secPos].product![index].sellingPrice.toString(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 5.0, bottom: 5, top: 3),
                child:  (((double.parse(productList[secPos].product![index].sellingPrice!) / double.parse(productList[secPos].product![index].mrp!)) * 100) - 100).toStringAsFixed(0) !=
                    '-0'
                    ? Row(
                  children: <Widget>[
                    Text(productList[secPos].product![index].mrp.toString(),
                      style: Theme
                          .of(context)
                          .textTheme
                          .overline!
                          .copyWith(
                          decoration: TextDecoration.lineThrough,
                          letterSpacing: 0),
                    ),
                    Flexible(
                      child: Text(" | " + "${discount.toStringAsFixed(0)}%",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme
                              .of(context)
                              .textTheme
                              .overline!
                              .copyWith(
                              color: colors.primary,
                              letterSpacing: 0)),
                    ),
                  ],
                )
                    : Container(
                  height: 5,
                ),
              )
            ],
          ),
          onTap: () {
          print(productList[secPos].product![index].prodID);
           Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => ProductDetail(
                      productId: productList[secPos].product![index].prodID,
                      index: index,
                      secPos: 0,
                      list: true,
                    )),
          );
          },
        ),
      );
    } else
      return Container();
  }

  


  saleShimmer(int length) {
    return

      Container(
          width: double.infinity,
          child: Column(
            children: [
              Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.simmerBase,
              highlightColor: Theme.of(context).colorScheme.simmerHigh, child:
          GridView.count(
              padding: EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              crossAxisCount: length==4?2:3,
              shrinkWrap: true,
              childAspectRatio: 1.0,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              children: List.generate(
                length,
                    (index) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Theme.of(context).colorScheme.white,
                  );
                },
              ))),
              Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.simmerBase,
              highlightColor: Theme.of(context).colorScheme.simmerHigh, child:
          GridView.count(
              padding: EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              crossAxisCount: length==4?2:3,
              shrinkWrap: true,
              childAspectRatio: 1.0,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              children: List.generate(
                length,
                    (index) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Theme.of(context).colorScheme.white,
                  );
                },
              ))),
            ],
          ));
  }


  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }



  Future<void> getProduct({String from = ''}) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (from == 'discount') {
      productList.clear();
    }
    print(productList.length);
    var parameter = {
      'startPosition': productList.length == 0 ? '0' : '${productList.length}',
      'discount': disList[curDis].toString()
    };
    
    if (_isNetworkAvail) {
      Response response = await post(getSaleProductsApi,body: parameter).timeout(Duration(minutes: 10));

    print(response.body);
    var getdata = json.decode(response.body);
    int error = int.parse(getdata["error"]);
    String? msg = getdata["message"];
    if (error == 200) {

          var data = getdata["data"];
          print(data);
          productList.addAll((data as List).map((data) => new SaleProductsData.fromJson(data)).toList());
          
      } else if(error == 401) {
        if(from == 'discount')
        productList.clear();
        
      }

      setState(() {
        _productLoading = false;
        _loading = false;
        isLoading = false;
      });
    }
    else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
          _productLoading = false;
          _loading = false;
          isLoading = false;
        });
    }
    
  }





  Widget homeShimmer() {
    return Container(
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: SingleChildScrollView(
            child: Column(
              children: [
                catLoading(),
                sliderLoading(),
                sectionLoading(),
              ],
            )),
      ),
    );
  }

  Widget sliderLoading() {
    double width = deviceWidth!;
    double height = width / 2;
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          width: double.infinity,
          height: height,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget deliverLoading() {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ));
  }

  Widget catLoading() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
                    .map((_) =>
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.white,
                        shape: BoxShape.circle,
                      ),
                      width: 50.0,
                      height: 50.0,
                    ))
                    .toList()),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ),
      ],
    );
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
              context.read<HomeProvider>().setCatLoading(true);
              context.read<HomeProvider>().setSecLoading(true);
              context.read<HomeProvider>().setSliderLoading(true);
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  callApi();
                } else {
                  await buttonController.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  sectionLoading() {
    return Column(
        children: [0, 1, 2, 3, 4]
            .map((_) =>
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                            margin: EdgeInsets.only(bottom: 40),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20)))),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            width: double.infinity,
                            height: 18.0,
                            color: Theme.of(context).colorScheme.white,
                          ),
                          GridView.count(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              childAspectRatio: 1.0,
                              physics: NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              children: List.generate(
                                4,
                                    (index) {
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Theme.of(context).colorScheme.white,
                                  );
                                },
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
                sliderLoading()
                //offerImages.length > index ? _getOfferImage(index) : Container(),
              ],
            ))
            .toList());
  }

  discountRow() {
    return Container(
        height: 50,
        color: Theme.of(context).colorScheme.white,
        child: Center(
          child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: disList.length,
            itemBuilder: (context, index) {

              return InkWell(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    curDis == index
                        ? SvgPicture.asset(imagePath + 'tap.svg')
                        : Container(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(disList[index].toString() + "%",style: TextStyle(color:curDis == index? colors.blackTemp:Theme.of(context).colorScheme.fontColor),),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    curDis = index;
                    _loading = true;
                    _productLoading=true;
                    getProduct(from: 'discount');
                  });
                  
                },
              );
            },
          ),
        ));
  }

  AppBar _getAppBar() {
    String? title = getTranslated(context, 'OFFER');

    return AppBar(
      toolbarHeight: widget.discount != null ? kToolbarHeight : 0.0,
      title:  Text(
              title!,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.normal
              ),
            ),

      leading: InkWell(
              child: Icon(Icons.arrow_back_ios,color: Colors.black),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
      // iconTheme: new IconThemeData(color: colors.primary),
      // centerTitle:_curSelected == 0? false:true,
      actions: <Widget>[
        IconButton(
                icon: SvgPicture.asset(
                  imagePath + "search.svg",
                  height: 20,
                  color: colors.primary,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Search(),
                      ));
                }),
        IconButton(
          icon: SvgPicture.asset(imagePath + "desel_notification.svg",color: colors.primary),
          onPressed: () {
            CUR_USERID != null
                ? Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationList(),
                    ))
                : Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ));
          },
        ),
        IconButton(
          padding: EdgeInsets.all(0),
          icon: SvgPicture.asset(imagePath + "desel_fav.svg",color: colors.primary),
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
      backgroundColor: Theme.of(context).colorScheme.white,
    );
  }
}
