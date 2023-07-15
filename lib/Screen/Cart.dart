import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:oym/Helper/Constant.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/Address_Model.dart';
import 'package:oym/Model/CartListModel.dart';
import 'package:oym/Model/GetCheckSumModel.dart';
import 'package:oym/Provider/CartProvider.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
//import 'package:paytm/paytm.dart';
import 'package:provider/provider.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';
import '../Model/Model.dart';
import '../Model/Section_Model.dart';
import 'Manage_Address.dart';
import 'Order_Success.dart';

class Cart extends StatefulWidget {
  final bool fromBottom;
  final String? productId;

  const Cart({Key? key, required this.fromBottom, this.productId})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateCart();
}

List<AddressData> addressList = [];
//List<SectionModel> cartList = [];
List<Promo> promoList = [];
double totalPrice = 0, oriPrice = 0, delCharge = 0, taxPer = 0;
int? selectedAddress = 0;
String? selAddress, payMethod = '', selTime, selDate, promocode;
bool? isTimeSlot,
    isPromoValid = false,
    isUseWallet = false,
    isPayLayShow = true;
int? selectedTime, selectedDate, selectedMethod;
int walletAmount = 0;
bool? fromAddress = false;
double promoAmt = 0;
double remWalBal = 0, usedBal = 0;

bool payTesting = true;
/*String gpayEnv = "TEST",
    gpayCcode = "US",
    gpaycur = "USD",
    gpayMerId = "01234567890123456789",
    gpayMerName = "Example Merchant Name";*/

class StateCart extends State<Cart> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      new GlobalKey<ScaffoldMessengerState>();

  final GlobalKey<ScaffoldMessengerState> _checkscaffoldKey =
      new GlobalKey<ScaffoldMessengerState>();
  List<Model> deliverableList = [];
  bool _isCartLoad = true, _placeOrder = true;

  //HomePage? home;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  bool isWalletUsed = false;
  List<TextEditingController> _controller = [];

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  List<SectionModel> saveLaterList = [];
  String? msg;
  bool _isLoading = true;
  TextEditingController promoC = new TextEditingController();
  TextEditingController noteC = new TextEditingController();
  StateSetter? checkoutState;
  bool deliverable = false;

  //List<PaymentItem> _gpaytItems = [];
  //Pay _gpayClient;

  @override
  void initState() {
    super.initState();
    clearAll();
    _getCart();
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

  Future<void> _refresh() {
    if (mounted)
      setState(() {
        _isCartLoad = true;
      });
    clearAll();

    return _getCart();
  }

  clearAll() {
    totalPrice = 0;
    oriPrice = 0;
    taxPer = 0;
    delCharge = 0;
    addressList.clear();
    context.read<CartProvider>().deliveryCharge = 0;
    // cartList.clear();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<CartProvider>().setCartlist([]);
      context.read<CartProvider>().setProgress(false);
    });

    promoAmt = 0;
    remWalBal = 0;
    usedBal = 0;
    payMethod = '';
    isPromoValid = false;
    isUseWallet = false;
    isPayLayShow = true;
    selectedMethod = null;
  }

  @override
  void dispose() {
    buttonController!.dispose();
    for (int i = 0; i < _controller.length; i++) _controller[i].dispose();
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
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: widget.fromBottom
            ? null
            : getSimpleAppBar(getTranslated(context, 'CART')!, context),
        body: _isNetworkAvail
            ? Stack(
                children: <Widget>[
                  _showContent(context),
                  Selector<CartProvider, bool>(
                    builder: (context, data, child) {
                      return showCircularProgress(data, colors.primary);
                    },
                    selector: (_, provider) => provider.isProgress,
                  ),
                ],
              )
            : noInternet(context));
  }

  Widget listItem(int index) {
    return Consumer<CartProvider>(builder: (context, cartListProvider, child) {
      List<CartListData> cartList = cartListProvider.cartList;
      double discount =
          ((double.parse(cartList[index].product![0].sellingPrice!) /
                      double.parse(cartList[index].product![0].mrp!)) *
                  100) -
              100;
      int minquantity = int.parse(cartList[index].product![0].minQtyBuy!);
      int maxquantity = int.parse(cartList[index].product![0].stock!) >
              int.parse(cartList[index].product![0].maxQtyBuy!)
          ? int.parse(cartList[index].product![0].maxQtyBuy!)
          : int.parse(cartList[index].product![0].stock!);
      return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Card(
                elevation: 0.1,
                child: Row(
                  children: <Widget>[
                    Hero(
                        tag: "$index${cartList[index].product![0].prodID}",
                        child: Stack(
                          children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(7.0),
                                child: FadeInImage(
                                  image: NetworkImage(imageBaseUrl +
                                      cartList[index].product![0].image1!),
                                  height: 125.0,
                                  width: 110.0,
                                  fit: extendImg ? BoxFit.fill : BoxFit.contain,
                                  imageErrorBuilder:
                                      (context, error, stackTrace) =>
                                          erroWidget(125),
                                  placeholder: placeHolder(125),
                                )),
                            discount != 0.0
                                ? Container(
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
                                  )
                                : Container()
                          ],
                        )),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        top: 5.0),
                                    child: Text(
                                      cartList[index].product![0].productTitle!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontSize: 14),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if(widget.productId == null)
                                GestureDetector(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        start: 8.0, end: 8, bottom: 8),
                                    child: Icon(
                                      Icons.close,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                    ),
                                  ),
                                  onTap: () {
                                    if (context
                                            .read<CartProvider>()
                                            .isProgress ==
                                        false)
                                      removeFromCart(
                                          prodId: cartList[index]
                                              .product![0]
                                              .prodID
                                              .toString());
                                  },
                                )
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                discount != 0.0
                                    ? Text(
                                        CUR_CURRENCY! +
                                            " " +
                                            cartList[index]
                                                .product![0]
                                                .mrp
                                                .toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .overline!
                                            .copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                letterSpacing: 0.7),
                                      )
                                    : Container(),
                                Text(
                                  " " +
                                      CUR_CURRENCY! +
                                      " " +
                                      cartList[index]
                                          .product![0]
                                          .sellingPrice
                                          .toString(),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    GestureDetector(
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            cartList[index].quantity! !=
                                                    minquantity
                                                ? Icons.remove
                                                : Icons.delete,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        if (context
                                                .read<CartProvider>()
                                                .isProgress ==
                                            false) {
                                          if (cartList[index].quantity! >
                                              minquantity) {
                                            // setState(() => cartList[index].quantity = cartList[index].quantity! - 1);
                                            context
                                                .read<CartProvider>()
                                                .removeQuantity(cartList[index]
                                                    .product![0]
                                                    .prodID!);
                                            addToCart(
                                                prodId: cartList[index]
                                                    .product![0]
                                                    .prodID,
                                                quantity: cartList[index]
                                                    .quantity
                                                    .toString(),
                                                from: 'remove');
                                          } else {
                                            removeFromCart(
                                              prodId: cartList[index]
                                                  .product![0]
                                                  .prodID,
                                            );
                                            // setSnackbar('Quanity cannot be less than $minquantity', _scaffoldKey);
                                          }
                                        }
                                      },
                                    ),
                                    Container(
                                        width: 20,
                                        height: 20,
                                        child: Center(
                                            child: Text(
                                                '${cartList[index].quantity}'))),
                                    cartList[index].quantity! == maxquantity
                                        ? Container()
                                        : GestureDetector(
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 15,
                                                ),
                                              ),
                                            ),
                                            onTap: cartList[index].quantity! <
                                                    maxquantity
                                                ? () {
                                                    if (context
                                                            .read<
                                                                CartProvider>()
                                                            .isProgress ==
                                                        false) {
                                                      if (cartList[index]
                                                              .quantity! <
                                                          maxquantity) {
                                                        //setState(() => cartList[index].quantity = cartList[index].quantity! + 1);
                                                        context
                                                            .read<
                                                                CartProvider>()
                                                            .addQuantity(
                                                                cartList[index]
                                                                    .product![0]
                                                                    .prodID!);
                                                        addToCart(
                                                            prodId:
                                                                cartList[index]
                                                                    .product![0]
                                                                    .prodID,
                                                            quantity: cartList[
                                                                    index]
                                                                .quantity
                                                                .toString());
                                                      } else {
                                                        setSnackbar(
                                                            'Max Quantity Reached.',
                                                            _scaffoldKey);
                                                      }
                                                    }
                                                  }
                                                : null,
                                          )
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ));
    });
  }

  Widget cartItem(int index) {
    return Consumer<CartProvider>(builder: (context, cartListProvider, child) {
      List<CartListData> cartList = cartListProvider.cartList;
      double discount =
          ((double.parse(cartList[index].product![0].sellingPrice!) /
                      double.parse(cartList[index].product![0].mrp!)) *
                  100) -
              100;
      double minquantity = double.parse(cartList[index].product![0].minQtyBuy!);
      double maxquantity = double.parse(cartList[index].product![0].stock!) >
              double.parse(cartList[index].product![0].maxQtyBuy!)
          ? double.parse(cartList[index].product![0].maxQtyBuy!)
          : double.parse(cartList[index].product![0].stock!);
      double subTotal =
          double.parse(cartList[index].product![0].sellingPrice!) *
              cartList[index].quantity!;
      return Card(
        elevation: 0.1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Hero(
                      tag: "$index${cartList[index].product![0].prodID}",
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(7.0),
                          child: FadeInImage(
                            image: NetworkImage(imageBaseUrl +
                                cartList[index].product![0].image1!),
                            height: 80.0,
                            width: 80.0,
                            fit: extendImg ? BoxFit.fill : BoxFit.contain,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                erroWidget(80),

                            // errorWidget: (context, url, e) => placeHolder(60),
                            placeholder: placeHolder(80),
                          ))),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      top: 5.0),
                                  child: Text(
                                    cartList[index].product![0].productTitle!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .lightBlack),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (widget.productId == null)
                              GestureDetector(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 8.0, end: 8, bottom: 8),
                                  child: Icon(
                                    Icons.close,
                                    size: 13,
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                  ),
                                ),
                                onTap: () {
                                  if (context.read<CartProvider>().isProgress ==
                                      false)
                                    removeFromCart(
                                        prodId: cartList[index]
                                            .product![0]
                                            .prodID
                                            .toString(),
                                        from: 'bottomsheet');
                                },
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Flexible(
                                      child: Text(
                                        discount != 0.0
                                            ? CUR_CURRENCY! +
                                                " " +
                                                cartList[index]
                                                    .product![0]
                                                    .mrp
                                                    .toString()
                                            : "",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .overline!
                                            .copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                letterSpacing: 0.7),
                                      ),
                                    ),
                                    Text(
                                      " " +
                                          CUR_CURRENCY! +
                                          " " +
                                          cartList[index]
                                              .product![0]
                                              .sellingPrice
                                              .toString(),
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      GestureDetector(
                                        child: Card(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(
                                              cartList[index].quantity! !=
                                                      minquantity
                                                  ? Icons.remove
                                                  : Icons.delete,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                        onTap: cartList[index].quantity! >
                                                minquantity
                                            ? () {
                                                if (context
                                                        .read<CartProvider>()
                                                        .isProgress ==
                                                    false) {
                                                  if (cartList[index]
                                                          .quantity! >
                                                      minquantity) {
                                                    // setState(() => cartList[index].quantity = cartList[index].quantity! - 1);
                                                    setState(() => context
                                                        .read<CartProvider>()
                                                        .removeQuantity(
                                                            cartList[index]
                                                                .product![0]
                                                                .prodID!));
                                                    addToCart(
                                                        prodId: cartList[index]
                                                            .product![0]
                                                            .prodID,
                                                        quantity:
                                                            cartList[index]
                                                                .quantity
                                                                .toString(),
                                                        from: 'remove');
                                                  } else {
                                                    removeFromCart(
                                                      prodId: cartList[index]
                                                          .product![0]
                                                          .prodID,
                                                    );
                                                    // setSnackbar('Quanity cannot be less than $minquantity', _scaffoldKey);
                                                  }
                                                }
                                              }
                                            : null,
                                      ),
                                      Container(
                                          width: 20,
                                          height: 20,
                                          child: Center(
                                              child: Text(
                                                  '${cartList[index].quantity}'))),
                                      cartList[index].quantity! == maxquantity
                                          ? Container()
                                          : GestureDetector(
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 15,
                                                  ),
                                                ),
                                              ),
                                              onTap: cartList[index].quantity! <
                                                      maxquantity
                                                  ? () {
                                                      if (context
                                                              .read<
                                                                  CartProvider>()
                                                              .isProgress ==
                                                          false) {
                                                        if (cartList[index]
                                                                .quantity! <
                                                            maxquantity) {
                                                          //setState(() => cartList[index].quantity = cartList[index].quantity! + 1);
                                                          context
                                                              .read<
                                                                  CartProvider>()
                                                              .addQuantity(
                                                                  cartList[
                                                                          index]
                                                                      .product![
                                                                          0]
                                                                      .prodID!);
                                                          addToCart(
                                                              prodId: cartList[
                                                                      index]
                                                                  .product![0]
                                                                  .prodID,
                                                              quantity: cartList[
                                                                      index]
                                                                  .quantity
                                                                  .toString());
                                                        } else {
                                                          setSnackbar(
                                                              'Max Quantity Reached.',
                                                              _scaffoldKey);
                                                        }
                                                      }
                                                    }
                                                  : null,
                                            )
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'SUBTOTAL')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! +
                        " " +
                        cartList[index].product![0].sellingPrice.toString(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! + " " + '${subTotal.toPrecision(3)}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery Charge',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    cartList[index].shippingCharges!.toString(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, 'TOTAL_LBL')!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.lightBlack2),
                  ),
                  Text(
                    CUR_CURRENCY! +
                        " " +
                        '${(subTotal + cartList[index].shippingCharges!).toPrecision(3)}',
                    //+ " "+cartList[index].productList[0].taxrs,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.fontColor),
                  )
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  Future<void> _getCart() async {
    _isNetworkAvail = await isNetworkAvailable();
    SettingProvider settingProvider = context.read<SettingProvider>();
    settingProvider.getPrefrence('token').then((value) async {
      if (_isNetworkAvail) {
        try {
          var parameter = {
            'customerID': CUR_USERID,
            'productID': widget.productId ?? ''
          };

          ///Add productID
          log(parameter.toString());
          log("Authorization: Bearer $value");
          Response response =
              await post(getCartListApi, body: parameter, headers: {
            "Authorization": 'Bearer ' + value!,
          }).timeout(Duration(seconds: timeOut));
          CartListModel cartListModel;
          log(response.body);
          var getdata = json.decode(response.body);
          cartListModel = CartListModel.fromJson(getdata);
          bool error = getdata["error"] == '200' ? true : false;
          String? msg = getdata["message"];
          walletAmount = getdata["walletDiscount"] != null
              ? int.parse(getdata["walletDiscount"].toString())
              : 0;
          if (error) {
            setState(() {
              context.read<CartProvider>().setCartlist(cartListModel.data!);
            });
          } else {
            //if (msg != 'Cart Is Empty !') setSnackbar(msg!, _scaffoldKey);
          }
          if (mounted)
            setState(() {
              _isCartLoad = false;
            });

          getAddress();
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
        }
      } else {
        if (mounted)
          setState(() {
            _isNetworkAvail = false;
          });
      }
    });
  }

  Future<void> addToCart(
      {String? prodId, String? quantity, String? from}) async {
    _isNetworkAvail = await isNetworkAvailable();
    SettingProvider settingProvider = context.read<SettingProvider>();

    settingProvider.getPrefrence('token').then((value) async {
      var parameter = {
        'customerID': CUR_USERID,
        'productID': prodId,
        'quantity': quantity,
        'flag': 'viewcart'
      };

      if (_isNetworkAvail) {
        setState(() => _isLoading = true);
        Response response = await post(addToCartApi, body: parameter, headers: {
          "Authorization": 'Bearer ' + value!,
        }).timeout(Duration(minutes: 10));

        print(response.body);
        var getdata = json.decode(response.body);
        int error = int.parse(getdata["error"]);
        String? msg = getdata["message"];
        if (error == 200) {
          context
              .read<UserProvider>()
              .setCartCount(getdata["cartLength"].toString());
          //if(from == null)
          //setSnackbar(msg!, _scaffoldKey);
          //else
          // setSnackbar('Successfully removed.', _scaffoldKey);
        } else if (error == 401) {
          //setSnackbar(msg!, _scaffoldKey);
        }

        setState(() => _isLoading = false);
      } else {
        if (mounted) setState(() => _isLoading = true);
        setSnackbar('No internet', _scaffoldKey);
      }
    });
  }

  removeFromCart({String? prodId, String from = ''}) async {
    _isNetworkAvail = await isNetworkAvailable();
    SettingProvider settingProvider = context.read<SettingProvider>();
    settingProvider.getPrefrence('token').then((value) async {
      if (_isNetworkAvail) {
        try {
          var parameter = {'customerID': CUR_USERID, 'prodID': prodId};
          setState(() {
            context.read<CartProvider>().setProgress(true);
          });
          Response response =
              await post(removeCartListApi, body: parameter, headers: {
            "Authorization": 'Bearer ' + value!,
          }).timeout(Duration(seconds: timeOut));
          print(response.body);
          var getdata = json.decode(response.body);
          bool error = getdata["error"] == '200' ? true : false;
          String? msg = getdata["message"];
          if (error) {
            setState(() {
              context.read<CartProvider>().removeCartItem(prodId.toString());
              _getCart();
              context
                  .read<UserProvider>()
                  .setCartCount(getdata["cartLength"].toString());
              if (from.isNotEmpty) if (context
                      .read<CartProvider>()
                      .cartList
                      .length ==
                  0) {
                Navigator.of(context).pop();
              }
            });
          } else {
            //setSnackbar(msg!, _scaffoldKey);
          }

          setState(() {
            context.read<CartProvider>().setProgress(false);
          });

          getAddress();
        } on TimeoutException catch (_) {
          context.read<CartProvider>().setProgress(false);
          setSnackbar(getTranslated(context, 'somethingMSg')!, _scaffoldKey);
        }
      } else {
        if (mounted)
          setState(() {
            context.read<CartProvider>().setProgress(false);
            _isNetworkAvail = false;
          });
      }
    });
  }

  setSnackbar(
      String msg, GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey) {
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

  _showContent(BuildContext context) {
    List<CartListData> cartList = context.read<CartProvider>().cartList;

    return _isCartLoad
        ? shimmer(context)
        : cartList.length == 0
            ? cartEmpty()
            : Column(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: RefreshIndicator(
                            key: _refreshIndicatorKey,
                            onRefresh: _refresh,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: cartList.length,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return listItem(index);
                                    },
                                  ),
                                ],
                              ),
                            ))),
                  ),
                  Container(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              margin: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 5),
                              //  width: deviceWidth! * 0.9,
                              child: Column(
                                children: [
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            getTranslated(context, 'SUBTOTAL')!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack2),
                                          ),
                                          Text(
                                            CUR_CURRENCY! +
                                                " " +
                                                (context
                                                        .read<CartProvider>()
                                                        .allTotal -
                                                    context
                                                        .read<CartProvider>()
                                                        .totalDeliveryCharge).toPrecision(3).toString(),
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                                fontWeight: FontWeight.bold),
                                          )
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            getTranslated(
                                                context, 'DELIVERY_CHARGE')!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .lightBlack2),
                                          ),
                                          Text(
                                            CUR_CURRENCY! +
                                                " " +
                                                context
                                                    .read<CartProvider>()
                                                    .totalDeliveryCharge
                                                    .toString(),
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                                fontWeight: FontWeight.bold),
                                          )
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(getTranslated(
                                              context, 'TOTAL_PRICE')!),
                                          Text(
                                            CUR_CURRENCY! +
                                                " ${context.read<CartProvider>().allTotal.toPrecision(3)}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle1!,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              )),
                          SimBtn(
                              size: 0.9,
                              title: getTranslated(context, 'PROCEED_CHECKOUT'),
                              onBtnSelected: () async {
                                if (context.read<CartProvider>().allTotal > 0) {
                                  FocusScope.of(context).unfocus();
                                  if (mounted)
                                    setState(() {
                                      getAddress();
                                      checkout(cartList);
                                    });
                                } else
                                  setSnackbar(
                                      getTranslated(context, 'ADD_ITEM')!,
                                      _scaffoldKey);
                              }),
                        ]),
                  ),
                ],
              );
  }

  cartEmpty() {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noCartImage(context),
          noCartText(context),
          noCartDec(context),
          shopNow()
        ]),
      ),
    );
  }

  getAllPromo() {}

  noCartImage(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/empty_cart.svg',
      fit: BoxFit.contain,
    );
  }

  noCartText(BuildContext context) {
    return Container(
        child: Text(getTranslated(context, 'NO_CART')!,
            style: Theme.of(context).textTheme.headline5!.copyWith(
                color: colors.primary, fontWeight: FontWeight.normal)));
  }

  noCartDec(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(top: 30.0, start: 30.0, end: 30.0),
      child: Text(getTranslated(context, 'CART_DESC')!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline6!.copyWith(
                color: Theme.of(context).colorScheme.lightBlack2,
                fontWeight: FontWeight.normal,
              )),
    );
  }

  shopNow() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 28.0),
      child: CupertinoButton(
        child: Container(
            width: deviceWidth! * 0.7,
            height: 45,
            alignment: FractionalOffset.center,
            decoration: new BoxDecoration(
              color: colors.primary,
              // gradient: LinearGradient(
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //     colors: [colors.grad1Color, colors.grad2Color],
              //     stops: [0, 1]),
              borderRadius: new BorderRadius.all(const Radius.circular(50.0)),
            ),
            child: Text(getTranslated(context, 'SHOP_NOW')!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6!.copyWith(
                    color: Theme.of(context).colorScheme.white,
                    fontWeight: FontWeight.normal))),
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/home', (Route<dynamic> route) => false);
        },
      ),
    );
  }

  checkout(List<CartListData> cartList) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (builder) {
          return Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
            return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              checkoutState = setState;
              return Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8),
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    key: _checkscaffoldKey,
                    body: _isNetworkAvail
                        ? cartProvider.cartList.length == 0
                            ? cartEmpty()
                            // : _isLoading
                            //     ? shimmer(context)
                            : Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: <Widget>[
                                        SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                address(),
                                                cartItems(cartList),
                                                // promo(),
                                                orderSummary(),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Selector<CartProvider, bool>(
                                          builder: (context, data, child) {
                                            return showCircularProgress(
                                                data, colors.primary);
                                          },
                                          selector: (_, provider) =>
                                              provider.isProgress,
                                        ),
                                        /*   showCircularProgress(
                                                  _isProgress, colors.primary),*/
                                      ],
                                    ),
                                  ),
                                  Consumer<CartProvider>(builder:
                                      (context, cartListProvider, child) {
                                    return Container(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      child: Column(
                                        children: [
                                          walletAmount == 0
                                              ? Container()
                                              : CheckboxListTile(
                                                  value: isWalletUsed,
                                                  title: Text(
                                                      'Want to use Wallet Amount - $CUR_CURRENCY $walletAmount'),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      isWalletUsed = val!;
                                                      cartListProvider
                                                          .calculateWithWallet(
                                                              walletAmount:
                                                                  walletAmount,
                                                              walletused:
                                                                  isWalletUsed);
                                                    });
                                                  }),
                                          Row(children: <Widget>[
                                            Padding(
                                                padding:
                                                    EdgeInsetsDirectional.only(
                                                        start: 15.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      CUR_CURRENCY! +
                                                          " ${cartListProvider.allTotal.toPrecision(3)}",
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .fontColor,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(cartListProvider
                                                            .cartList.length
                                                            .toString() +
                                                        " Items"),
                                                  ],
                                                )),
                                            Spacer(),
                                            SimBtn(
                                                size: 0.4,
                                                title: getTranslated(
                                                    context, 'PLACE_ORDER'),
                                                onBtnSelected: () {
                                                  if (context
                                                      .read<UserProvider>()
                                                      .addressList
                                                      .isEmpty) {
                                                    msg = getTranslated(context,
                                                        'addressWarning');
                                                    Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (BuildContext
                                                                  context) =>
                                                              ManageAddress(
                                                            home: false,
                                                          ),
                                                        ));
                                                    checkoutState!(() {
                                                      _placeOrder = true;
                                                    });
                                                  } else
                                                    confirmDialog();
                                                })
                                            //}),
                                          ]),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              )
                        : noInternet(context),
                  ));
            });
          });
        });
  }

  // Future<void> _getAddresss() async {
  //   _isNetworkAvail = await isNetworkAvailable();
  //   if (_isNetworkAvail) {
  //     try {
  //       var parameter = {
  //         USER_ID: CUR_USERID,
  //       };
  //       Response response =
  //           await post(getAddressApi, body: parameter, headers: headers)
  //               .timeout(Duration(seconds: timeOut));

  //       if (response.statusCode == 200) {
  //         var getdata = json.decode(response.body);

  //         bool error = getdata["error"];
  //         // String msg = getdata["message"];
  //         if (!error) {
  //           var data = getdata["data"];

  //           addressList = (data as List)
  //               .map((data) => new User.fromAddress(data))
  //               .toList();

  //           if (addressList.length == 1) {
  //             selectedAddress = 0;
  //             selAddress = addressList[0].id;
  //             if (!ISFLAT_DEL) {
  //               if (totalPrice < double.parse(addressList[0].freeAmt!))
  //                 delCharge = double.parse(addressList[0].deliveryCharge!);
  //               else
  //                 delCharge = 0;
  //             }
  //           } else {
  //             for (int i = 0; i < addressList.length; i++) {
  //               if (addressList[i].isDefault == "1") {
  //                 selectedAddress = i;
  //                 selAddress = addressList[i].id;
  //                 if (!ISFLAT_DEL) {
  //                   if (totalPrice < double.parse(addressList[i].freeAmt!))
  //                     delCharge = double.parse(addressList[i].deliveryCharge!);
  //                   else
  //                     delCharge = 0;
  //                 }
  //               }
  //             }
  //           }

  //           if (ISFLAT_DEL) {
  //             if ((oriPrice) < double.parse(MIN_AMT!))
  //               delCharge = double.parse(CUR_DEL_CHR!);
  //             else
  //               delCharge = 0;
  //           }
  //           totalPrice = totalPrice + delCharge;
  //         } else {
  //           if (ISFLAT_DEL) {
  //             if ((oriPrice) < double.parse(MIN_AMT!))
  //               delCharge = double.parse(CUR_DEL_CHR!);
  //             else
  //               delCharge = 0;
  //           }
  //           totalPrice = totalPrice + delCharge;
  //         }
  //         if (mounted) {
  //           setState(() {
  //             _isLoading = false;
  //           });
  //         }

  //         if (checkoutState != null) checkoutState!(() {});
  //       } else {
  //         setSnackbar(
  //             getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
  //         if (mounted)
  //           setState(() {
  //             _isLoading = false;
  //           });
  //       }
  //     } on TimeoutException catch (_) {}
  //   } else {
  //     if (mounted)
  //       setState(() {
  //         _isNetworkAvail = false;
  //       });
  //   }
  // }

  void paytmPayment({String? amount}) async {
    SettingProvider settingProvider = context.read<SettingProvider>();
    Map<String, String> headers = {};
    settingProvider.getPrefrence('token').then((value) async {
      headers = {
        "Authorization": 'Bearer ' + value!,
      };
      String? paymentResponse;
      context.read<CartProvider>().setProgress(true);

      var parameter = {
        'amount': amount,
        'custID': CUR_USERID,
        'walletUsed': isWalletUsed ? 'YES' : 'NO',
        'addressID': context.read<UserProvider>().selectedAddressId.toString(),
        'productID': widget.productId ?? '',
        'quantity': widget.productId != null
            ? context.read<CartProvider>().cartList[0].quantity.toString()
            : ''
      };
      print(parameter);
      try {
        final response = await post(
          getcheckSumApi,
          body: parameter,
          headers: headers,
        );
        print(response.body);

        var getdata = json.decode(response.body);

        bool error = getdata["error"] == "200" ? true : false;

        if (error) {
          GetChecksumModel getChecksumModel =
              GetChecksumModel.fromJson(getdata);
          addTransaction(getChecksumModel.oRDERID.toString());
          context.read<CartProvider>().setProgress(false);
        } else {
          checkoutState!(() {
            _placeOrder = true;
          });

          context.read<CartProvider>().setProgress(false);

          // setSnackbar(getdata["message"], _checkscaffoldKey);
        }
      } catch (e) {
        print(e);
      }
    });
  }

  Future<void> addTransaction(
    String orderID,
  ) async {
    SettingProvider settingProvider = context.read<SettingProvider>();
    Map<String, String> headers = {};
    settingProvider.getPrefrence('token').then((value) async {
      headers = {
        "Authorization": 'Bearer ' + value!,
      };
      try {
        var parameter = {
          'orderID': orderID,
          'TXNID': 'COD',
          'BANKNAME': 'COD',
        };
        print(parameter);
        Response response =
            await post(getThankyouApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));
        print(response.body);
        var getdata = json.decode(response.body);

        bool error = getdata["error"] == "200" ? true : false;
        String? msg1 = getdata["message"];
        if (error) {
          // CUR_CART_COUNT = "0";

          context.read<UserProvider>().setCartCount("0");
          clearAll();
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => OrderSuccess()),
              ModalRoute.withName('/home'));
        } else {
          setSnackbar(msg1!, _checkscaffoldKey);
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
      }
    });
  }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }

    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  address() {
    return Consumer<UserProvider>(builder: (context, selectedIndex, child) {
      List<AddressData> addressList = selectedIndex.addressList;
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on),
                      Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8.0),
                          child: Text(
                            getTranslated(context, 'SHIPPING_DETAIL') ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.fontColor),
                          )),
                    ],
                  ),
                  addressList.length > 0
                      ? InkWell(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              getTranslated(context, 'CHANGE')!,
                              style: TextStyle(
                                color: colors.primary,
                              ),
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        ManageAddress(
                                          home: false,
                                        ))).then((value) {
                              setState(() {
                                fromAddress = true;
                                getAddress();
                              });
                            });
                            checkoutState!(() {
                              deliverable = false;
                            });
                          },
                        )
                      : Container()
                ],
              ),
              Divider(),
              addressList.length > 0
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(addressList[
                                          selectedIndex.selectedAddressIndex]
                                      .custAlternateNM!)),
                            ],
                          ),
                          Text(
                            addressList[selectedIndex.selectedAddressIndex]
                                    .address ?? '' +
                                ", " +
                                addressList[selectedIndex.selectedAddressIndex]
                                    .cityNM! +
                                ", " +
                                addressList[selectedIndex.selectedAddressIndex]
                                    .areaNM! +
                                ", " +
                                addressList[selectedIndex.selectedAddressIndex]
                                    .country! +
                                ", " +
                                addressList[selectedIndex.selectedAddressIndex]
                                    .pincode!,
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .lightBlack),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              children: [
                                Text(
                                  addressList[
                                          selectedIndex.selectedAddressIndex]
                                      .custAlternateMobile!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: GestureDetector(
                        child: Text(
                          getTranslated(context, 'ADDADDRESS')!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                          ),
                        ),
                        onTap: () async {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      ManageAddress(
                                        home: false,
                                      ))).then((value) {
                            if (mounted)
                              setState(() {
                                fromAddress = true;
                                getAddress();
                              });
                          });
                        },
                      ),
                    )
            ],
          ),
        ),
      );
    });
  }

  Future<Null> getAddress() async {
    _isNetworkAvail = await isNetworkAvailable();
    addressList.clear();

    SettingProvider settingProvider = context.read<SettingProvider>();
    Map<String, String> headers = {};
    settingProvider.getPrefrence('token').then((value) async {
      headers = {
        "Authorization": 'Bearer ' + value!,
      };

      if (_isNetworkAvail) {
        try {
          var parameter = {
            'custID': CUR_USERID,
          };
          print(parameter);
          if (mounted)
            setState(() {
              _isLoading = true;
            });
          Response response =
              await post(getAllAddressApi, body: parameter, headers: headers)
                  .timeout(Duration(seconds: timeOut));
          print(response.body);
          var getdata = json.decode(response.body);
          int error = int.parse(getdata["error"]);
          // String msg = getdata["message"];
          if (error == 200) {
            var data = getdata["data"];
            setState(() {
              addressList = (data as List)
                  .map((data) => AddressData.fromJson(data))
                  .toList();
            });
            context.read<UserProvider>().setaddressList = (data as List)
                .map((data) => AddressData.fromJson(data))
                .toList();
            //if(!fromAddress!)
            if (context.read<UserProvider>().selectedAddressId == 0) {
              for (int i = 0; i < addressList.length; i++) {
                if (addressList[i].setDefault == "1") {
                  context.read<UserProvider>().setSelectedAddressIndex = i;
                  context.read<UserProvider>().setSelAddressId =
                      int.parse(addressList[i].id!);
                }
              }
            }

            setState(() {});
          } else {}
          if (mounted)
            setState(() {
              _isLoading = false;
            });
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

  cartItems(List<CartListData> cartList) {
    return Consumer<CartProvider>(builder: (context, cartListProvider, child) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: cartListProvider.cartList.length,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return cartItem(index);
        },
      );
    });
  }

  orderSummary() {
    return Consumer<CartProvider>(builder: (context, cartListProvider, child) {
      return Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslated(context, 'ORDER_SUMMARY')! +
                      " (" +
                      cartListProvider.cartList.length.toString() +
                      " items)",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold),
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, 'DELIVERY_CHARGE')!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2),
                    ),
                    Text(
                      CUR_CURRENCY! +
                          " " +
                          cartListProvider.totalDeliveryCharge.toString(),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, 'SUBTOTAL')!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack2),
                    ),
                    Text(
                      CUR_CURRENCY! +
                          " " +
                          (context.read<CartProvider>().allTotal.toPrecision(3) )
                              .toString(),
                      style: TextStyle( 
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                  // -
                  //                 context
                  //                     .read<CartProvider>()
                  //                     .totalDeliveryCharge
                ),
                isUseWallet!
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getTranslated(context, 'WALLET_BAL')!,
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.lightBlack2),
                          ),
                          Text(
                            CUR_CURRENCY! + " " + usedBal.toString(),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      )
                    : Container(),
              ],
            ),
          ));
    });
  }

  Future<void> validatePromo(bool check) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);
        if (check) {
          if (this.mounted && checkoutState != null) checkoutState!(() {});
        }
        setState(() {});
        var parameter = {
          USER_ID: CUR_USERID,
          PROMOCODE: promoC.text,
          FINAL_TOTAL: oriPrice.toString()
        };
        Response response =
            await post(validatePromoApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"][0];

            totalPrice = double.parse(data["final_total"]) + delCharge;

            promoAmt = double.parse(data["final_discount"]);
            promocode = data["promo_code"];
            isPromoValid = true;
            setSnackbar(
                getTranslated(context, 'PROMO_SUCCESS')!, _checkscaffoldKey);
          } else {
            isPromoValid = false;
            promoAmt = 0;
            promocode = null;
            promoC.clear();
            var data = getdata["data"];

            totalPrice = double.parse(data["final_total"]) + delCharge;

            setSnackbar(msg!, _checkscaffoldKey);
          }
          if (isUseWallet!) {
            remWalBal = 0;
            payMethod = null;
            usedBal = 0;
            isUseWallet = false;
            isPayLayShow = true;

            selectedMethod = null;
            context.read<CartProvider>().setProgress(false);
            if (mounted && check) checkoutState!(() {});
            setState(() {});
          } else {
            if (mounted && check) checkoutState!(() {});
            setState(() {});
            context.read<CartProvider>().setProgress(false);
          }
        }
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        if (mounted && check) checkoutState!(() {});
        setState(() {});
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
      }
    } else {
      _isNetworkAvail = false;
      if (mounted && check) checkoutState!(() {});
      setState(() {});
    }
  }

  Future<void> flutterwavePayment() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        context.read<CartProvider>().setProgress(true);

        var parameter = {
          AMOUNT: totalPrice.toString(),
          USER_ID: CUR_USERID,
        };
        Response response =
            await post(flutterwaveApi, body: parameter, headers: headers)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);

          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["link"];
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (BuildContext context) => PaypalWebview(
            //               url: data,
            //               from: "order",
            //             )));
          } else {
            setSnackbar(msg!, _checkscaffoldKey);
          }

          context.read<CartProvider>().setProgress(false);
        }
      } on TimeoutException catch (_) {
        context.read<CartProvider>().setProgress(false);
        setSnackbar(getTranslated(context, 'somethingMSg')!, _checkscaffoldKey);
      }
    } else {
      if (mounted)
        checkoutState!(() {
          _isNetworkAvail = false;
        });
    }
  }

  void confirmDialog() {
    showGeneralDialog(
        barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          return Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
            return Transform.scale(
              scale: a1.value,
              child: Opacity(
                  opacity: a1.value,
                  child: AlertDialog(
                    contentPadding: const EdgeInsets.all(0),
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5.0))),
                    content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                              child: Text(
                                getTranslated(context, 'CONFIRM_ORDER')!,
                                style: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                              )),
                          Divider(
                              color: Theme.of(context).colorScheme.lightBlack),
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(context, 'SUBTOTAL')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack2),
                                    ),
                                    Text(
                                      CUR_CURRENCY! +
                                          " " +
                                          cartProvider.totalWithQuantity.toPrecision(3)
                                              .toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      getTranslated(
                                          context, 'DELIVERY_CHARGE')!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .lightBlack2),
                                    ),
                                    Text(
                                      CUR_CURRENCY! +
                                          " " +
                                          cartProvider.totalDeliveryCharge
                                              .toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                                isWalletUsed
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            getTranslated(
                                                context, 'WALLET_BAL')!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .lightBlack2),
                                          ),
                                          Text(
                                            CUR_CURRENCY! +
                                                " " +
                                                walletAmount.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                          )
                                        ],
                                      )
                                    : Container(),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(getTranslated(
                                          context, 'TOTAL_PRICE')!),
                                      Text(
                                        CUR_CURRENCY! +
                                            " ${cartProvider.allTotal.toPrecision(3)}",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                    actions: <Widget>[
                      new TextButton(
                          child: Text(getTranslated(context, 'CANCEL')!,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.lightBlack,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                          onPressed: () {
                            checkoutState!(() {
                              _placeOrder = true;
                            });
                            Navigator.pop(context);
                          }),
                      new TextButton(
                          child: Text(getTranslated(context, 'DONE')!,
                              style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.pop(context);
                            //generateTxnToken(2);
                            paytmPayment(
                                amount: cartProvider.allTotal.toPrecision(3).toString());
                          })
                    ],
                  )),
            );
          });
        },
        transitionDuration: Duration(milliseconds: 200),
        barrierDismissible: false,
        barrierLabel: '',
        context: context,
        pageBuilder: (context, animation1, animation2) {
          return Container();
        });
  }
}
