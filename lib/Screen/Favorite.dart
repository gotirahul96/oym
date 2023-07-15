import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/ProductsListModel.dart';
import 'package:oym/Provider/FavoriteProvider.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Screen/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'Login.dart';
import 'Product_Detail.dart';

class Favorite extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => StateFav();
}

class StateFav extends State<Favorite> with TickerProviderStateMixin {
 // ScrollController controller = new ScrollController();
  //List<Product> tempList = [];

  //String? msg;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  bool _isProgress = false, _isFavLoading = true;

  @override
  void initState() {
    super.initState();

   _getFav();

    //controller.addListener(_scrollListener);
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
                  _getFav();
                } else {
                  await buttonController!.reverse();
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
    return Scaffold(
        appBar: getAppBar(getTranslated(context, 'FAVORITE')!, context),
        body: _isNetworkAvail
            ? Stack(
                children: <Widget>[
                  _showContent(context),
                  showCircularProgress(_isProgress, colors.primary),
                ],
              )
            : noInternet(context));
  }

  Widget listItem(int index, List<ProductListData> favList) {
    if (index < favList.length && favList.length > 0) {
      
       double discount = ((double.parse(favList[index].product![0].sellingPrice!) / double.parse(favList[index].product![0].mrp!)) * 100) - 100;

      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Card(
                elevation: 0.1,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Hero(
                          tag: "$index${favList[index].product![0].prodID}",
                          child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10)),
                              child: Stack(
                                children: [
                                  FadeInImage(
                                    image: NetworkImage(imageBaseUrl + favList[index].product![0].image1!),
                                    height: 125.0,
                                    width: 110.0,
                                    fit: extendImg
                                        ? BoxFit.fill
                                        : BoxFit.contain,

                                    imageErrorBuilder:
                                        (context, error, stackTrace) =>
                                            erroWidget(125),

                                    // errorWidget: (context, url, e) => placeHolder(80),
                                    placeholder: placeHolder(125),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: colors.red,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Text(
                                        discount.toStringAsFixed(0) + "%",
                                        style: TextStyle(
                                            color: colors.whiteTemp,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9),
                                      ),
                                    ),
                                    margin: EdgeInsets.all(5),
                                  ),
                                ],
                              ))),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      favList[index].product![0].productTitle!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(color: Theme.of(context).colorScheme.lightBlack),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(right: 5),
                                    child: InkWell(
                                      child: Icon(
                                        Icons.close,
                                        color: Theme.of(context).colorScheme.lightBlack,
                                      ),
                                      onTap: () {
                                        _removeFav(favList[index]);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating:
                                        double.parse(favList[index].avgRating!.toString()),
                                    itemBuilder: (context, index) => Icon(
                                      Icons.star_rate_rounded,
                                      color: Colors.amber,
                                      //color: colors.primary,
                                    ),
                                    unratedColor: Colors.grey.withOpacity(0.5),
                                    itemCount: 5,
                                    itemSize: 18.0,
                                    direction: Axis.horizontal,
                                  ),
                                  Text(
                                    " (" + favList[index].avgRating!.toString() + ")",
                                    style: Theme.of(context).textTheme.overline,
                                  )
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  Text(
                                    CUR_CURRENCY! +
                                        " " +
                                        favList[index].product![0].sellingPrice.toString() +
                                        " ",
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.fontColor,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    discount !=
                                            0
                                        ? CUR_CURRENCY! +
                                            "" +
                                            favList[index]
                                                .product![0]
                                                .mrp!
                                        : "",
                                    style: Theme.of(context)
                                        .textTheme
                                        .overline!
                                        .copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            letterSpacing: 0.7),
                                  ),
                                ],
                              ),
                              
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  splashColor: colors.primary.withOpacity(0.2),
                  onTap: () {
                    ProductListData model = favList[index];
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                          pageBuilder: (_, __, ___) => ProductDetail(
                                productId: model.product![0].prodID,
                                secPos: 0,
                                index: index,
                                list: true,
                                //  title: productList[index].name,
                              )),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -15,
                right: 0,
                child: InkWell(
                  onTap: () {
                    if (_isProgress == false){
                      addToCart(productListData: favList[index]);
                    }
                  },
                  child: SvgPicture.asset(imagePath + 'bag.svg'),
                ),
              )
            ],
          ));
    } else {
      return Container();
    }
  }

  Future _getFav() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null) {
        Map parameter = {
          'custid': CUR_USERID,
        };
        apiBaseHelper.postAPICall(wishListApi, parameter).then((getdata) {
          int error = int.parse(getdata["error"]);
          String? msg = getdata["message"];
          if (error == 200) {
            var data = getdata["data"];
            log(data.toString());
            List<ProductListData> tempList = (data as List)
                .map((data) => new ProductListData.fromJson(data))
                .toList();

            setState(() {
              context.read<FavoriteProvider>().setFavlist(tempList);
            });
          } else {
            //if (msg != 'No Favourite(s) Product Are Added')
              //setSnackbar(msg!, context);

            //setSnackbar(msg!, context);
          }

          context.read<FavoriteProvider>().setLoading(false);
        }, onError: (error) {
          //setSnackbar(error.toString(), context);
          context.read<FavoriteProvider>().setLoading(false);


        });
      } else {
        context.read<FavoriteProvider>().setLoading(false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }


  Future<void> addToCart({ProductListData? productListData}) async {
    _isNetworkAvail = await isNetworkAvailable();
    SettingProvider settingProvider = context.read<SettingProvider>();
    
    settingProvider.getPrefrence('token').then((value) async {
       var parameter = {
      'customerID': CUR_USERID,
      'productID': productListData!.product![0].prodID,
      'quantity' : '1',
      'flag' : ''
    };
    print(parameter);
    
    if (_isNetworkAvail) {
      setState(()=> _isProgress = true);
      Response response = await post(addToCartApi,body: parameter, headers: {
              "Authorization": 'Bearer ' + value!,
            }).timeout(Duration(minutes: 10));

    print(response.body);
    var getdata = json.decode(response.body);
    int error = int.parse(getdata["error"]);
    String? msg = getdata["message"];
    if (error == 200) {
          setState(() => cartCount = 0);
          
          //setSnackbar(msg!, context);
          
      } else if(error == 401) {
        //setSnackbar(msg!, context);
      }

      setState(()=> _isProgress = false);
    }
    else {
      if (mounted)
        setState(()=> _isProgress = true);
        setSnackbar('No internet', context);
    }
    });
  }

  // Future<void> addToCart(
  //     int index, List<ProductListData> favList, BuildContext context) async {
  //   _isNetworkAvail = await isNetworkAvailable();
  //   if (_isNetworkAvail) {
  //     try {
  //       if (mounted)
  //         setState(() {
  //           _isProgress = true;
  //         });
        

  //       var parameter = {
  //         PRODUCT_VARIENT_ID: favList[index].product![0].prodID,
  //         USER_ID: CUR_USERID,
  //         QTY: 0,
  //       };

  //       Response response =
  //           await post(manageCartApi, body: parameter, headers: headers)
  //               .timeout(Duration(seconds: timeOut));
  //       if (response.statusCode == 200) {
  //         var getdata = json.decode(response.body);

  //         bool error = getdata["error"];
  //         String? msg = getdata["message"];
  //         if (!error) {
  //           var data = getdata["data"];

  //           String? qty = data['total_quantity'];
  //           // CUR_CART_COUNT = data['cart_count'];

  //           context.read<UserProvider>().setCartCount(data['cart_count']);
            
  //         } else {
  //           setSnackbar(msg!, context);
  //         }
  //         if (mounted)
  //           setState(() {
  //             _isProgress = false;
  //           });
  //       }
  //     } on TimeoutException catch (_) {
  //       setSnackbar(getTranslated(context, 'somethingMSg')!, context);
  //       if (mounted)
  //         setState(() {
  //           _isProgress = false;
  //         });
  //     }
  //   } else {
  //     if (mounted)
  //       setState(() {
  //         _isNetworkAvail = false;
  //       });
  //   }
  // }
  
  
  _removeFav(ProductListData model) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (mounted)
        setState(() {
          _isProgress = true;
        });
      var parameter = {
        'custid': CUR_USERID, 
        'productID' : model.product![0].prodID,
        'wishlist' : '0'
        };
       setState(() {
          model.isFavLoading = true;
        });
      Response response = await post(setWishListApi,body: parameter);

      var getdata = json.decode(response.body);
        int error = int.parse(getdata["error"]);
        String? msg = getdata["message"];
        if (error == 200) {
          if (mounted)
        setState(() {
          context
              .read<FavoriteProvider>()
              .removeFavItem(model.product![0].prodID!);
        });
        if (mounted)
          setState(() {
            _isProgress = false;
          });
        } else {
          setSnackbar(msg!, context);
        }
        

    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }



  Future _refresh() {
    if (mounted)
      setState(() {
        _isFavLoading = true;
      });
    offset = 0;
    total = 0;
    return _getFav();
  }

  _showContent(BuildContext context) {
    return Selector<FavoriteProvider, Tuple2<bool, List<ProductListData>>>(
        builder: (context, data, child) {
          return data.item1
              ? shimmer(context)
              : data.item2.length == 0
                  ? Center(child: Text(getTranslated(context, 'noFav')!))
                  : RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: _refresh,
                      child: ListView.builder(
                        shrinkWrap: true,
                       // controller: controller,
                        itemCount: data.item2.length,
                        physics: AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return  listItem(index, data.item2);
                        },
                      ));
        },
        selector: (_, provider) =>
            Tuple2(provider.isLoading, provider.favList));
  }
}
