import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file_safe/open_file_safe.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/OrderListModel.dart';
import 'package:oym/Model/Order_Model.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:oym/Screen/Cart.dart';
import 'package:oym/Screen/Seller_Details.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../Model/User.dart';


class OrderDetail extends StatefulWidget {
  final OrderListData? model;

  // final Function? updateHome;

  const OrderDetail({Key? key, this.model}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateOrder();
  }
}

class StateOrder extends State<OrderDetail>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();
  ScrollController controller = ScrollController();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  List<User> tempList = [];
  late bool _isCancleable, _isReturnable;
  bool _isProgress = false;
  int offset = 0;
  int total = 0;
  List<User> reviewList = [];
  bool isLoadingmore = true;
  bool _isReturnClick = true;
  bool downloading = false;
  double downloadprogress = 0.0;
  var progress = "";
  String? proId, image;
  List<File> files = [];

  int _selectedTabIndex = 0;
  late TabController _tabController;

  List<File> reviewPhotos = [];
  TextEditingController commentTextController = TextEditingController();
  double curRating = 0.0;

  @override
  void initState() {
    super.initState();
    files.clear();
    reviewPhotos.clear();
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
    _tabController = TabController(
      length: 5,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
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

    var model = widget.model!;
    String? pDate, prDate, sDate, dDate, cDate, rDate;


    _isCancleable = model.cancellable == "1" ? true : false;
    _isReturnable = model.returnable == "1" ? true : false;

    return WillPopScope(
      onWillPop: () async {
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar:
        getSimpleAppBar(getTranslated(context, "ORDER_DETAIL")!, context),
        body: _isNetworkAvail
            ? SingleChildScrollView(
              padding: EdgeInsets.all(8.0),
              child: Stack(
          children: [
              Column(
                children: [
                  getOrderDetails(model),
                ],
              ),
              Center(child: showCircularProgress(_isProgress, colors.primary)),
          ],
        ),
            )
            : noInternet(context),
      ),
    );
  }

/*  returnable() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.grad1Color, colors.grad2Color],
            stops: [0, 1]),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.black26, blurRadius: 10)],
      ),
      width: deviceWidth,
      child: InkWell(
        onTap: _isReturnClick
            ? () {
          setState(() {
            _isReturnClick = false;
            _isProgress = true;
          });
          cancelOrder(RETURNED, updateOrderApi, widget.model!.id);
        }
            : null,
        child: Center(
            child: Text(
              getTranslated(context, 'RETURN_ORDER')!,
              style: Theme
                  .of(context)
                  .textTheme
                  .button!
                  .copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.white),
            )),
      ),
    );
  }*/

  /* cancelable() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.grad1Color, colors.grad2Color],
            stops: [0, 1]),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.black26, blurRadius: 10)],
      ),
      width: deviceWidth,
      child: InkWell(
        onTap: _isReturnClick
            ? () {
          setState(() {
            _isReturnClick = false;
            _isProgress = true;
          });
          cancelOrder(CANCLED, updateOrderApi, widget.model!.id);
        }
            : null,
        child: Center(
            child: Text(
              getTranslated(context, 'CANCEL_ORDER')!,
              style: Theme
                  .of(context)
                  .textTheme
                  .button!
                  .copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.white),
            )),
      ),
    );
  }*/

  priceDetails() {
    return Card(
        elevation: 0,
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(getTranslated(context, 'PRICE_DETAIL')!,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold))),
              Divider(
                color: Theme.of(context).colorScheme.lightBlack,
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${getTranslated(context, 'PRICE_LBL')!} :",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: Theme.of(context).colorScheme.lightBlack2)),
                    Text("${CUR_CURRENCY!} ${widget.model!.totalCostwithoutShipping.toString()}",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated(context, 'DELIVERY_CHARGE')! + " " + ":",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: Theme.of(context).colorScheme.lightBlack2)),
                    Text("+ " + CUR_CURRENCY! + " " + widget.model!.orderDetail![0].shippingCharges.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              // Padding(
              //   padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text(
              //           getTranslated(context, 'PROMO_CODE_DIS_LBL')! +
              //               " " +
              //               ":",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: Theme.of(context).colorScheme.lightBlack2)),
              //       Text("- " + CUR_CURRENCY! + " " + widget.model!.promoDis!,
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: Theme.of(context).colorScheme.lightBlack2))
              //     ],
              //   ),
              // ),
              
              // Padding(
              //   padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text(getTranslated(context, 'PAYABLE') + " " + ":",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button
              //               .copyWith(color: Theme.of(context).colorScheme.lightBlack2)),
              //       Text(CUR_CURRENCY + " " + widget.model.payable,
              //           style: Theme.of(context)
              //               .textTheme
              //               .button
              //               .copyWith(color: Theme.of(context).colorScheme.lightBlack2))
              //     ],
              //   ),
              // ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                    start: 15.0, end: 15.0, top: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated(context, 'PAYABLE')! + " " + ":",
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack,
                            fontWeight: FontWeight.bold)),
                    Text(CUR_CURRENCY! + " " + widget.model!.totalCostwithShipping.toString(),
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack,
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ])));
  }

  shippingDetails() {
    return Card(
        elevation: 0,
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(getTranslated(context, 'SHIPPING_DETAIL')!,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold))),
              Divider(
                color: Theme.of(context).colorScheme.lightBlack,
              ),
              
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(widget.model!.shippingAddress![0].custName!,
                      style: TextStyle(color: Theme.of(context).colorScheme.lightBlack2))),
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(widget.model!.shippingAddress![0].mobile!,
                      style: TextStyle(color: Theme.of(context).colorScheme.lightBlack2))),
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(widget.model!.shippingAddress![0].address!,
                      style: TextStyle(color: Theme.of(context).colorScheme.lightBlack2))),
          widget.model!.shippingAddress![0].address2! != '' ? Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(widget.model!.shippingAddress![0].address2!,
                      style: TextStyle(color: Theme.of(context).colorScheme.lightBlack2))) : Container(),
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(widget.model!.shippingAddress![0].cityNM!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                      ))),
              Padding(
                  padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(widget.model!.shippingAddress![0].stateNM!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2,
                      ))),
            ])));
  }

  productItem(OrderListData orderItem,) {
     String? pDate, prDate, sDate, dDate, cDate, rDate, aDate;
   
    // if (orderItem.listStatus!.contains(WAITING)) {
    //   aDate = orderItem.listDate![orderItem.listStatus!.indexOf(WAITING)];
    // }
    //if (orderItem.orderDetail![0].deliveryStatus!.contains('Placed')) {
      pDate = orderItem.orderDetail![0].orderDate;
    //}
    //if (orderItem.orderDetail![0].deliveryStatus!.contains('Processed')) {
      prDate = orderItem.orderDetail![0].orderProcessDate;
    //}
    //if (orderItem.orderDetail![0].deliveryStatus!.contains('Shipped')) {
      sDate = orderItem.orderDetail![0].orderShippedDate;
    //}
    //if (orderItem.orderDetail![0].deliveryStatus!.contains('Delivered')) {
      dDate = orderItem.orderDetail![0].orderDeliveredDate;
    //}
    //if (orderItem.orderDetail![0].deliveryStatus!.contains('Cancelled')) {
      cDate = orderItem.orderDetail![0].orderCancelReturnDate;
    //}
    //if (orderItem.orderDetail![0].deliveryStatus!.contains('Returned')) {
      rDate = orderItem.orderDetail![0].orderCancelReturnDate;
    //}
    // List att = [], val = [];
    // if (orderItem.attr_name!.isNotEmpty) {
    //   att = orderItem.attr_name!.split(',');
    //   val = orderItem.varient_values!.split(',');
    // }

    OrderDetails orderDetails = orderItem.orderDetail![0];
    ProductDetail productDetail = orderItem.productDetail![0];
    
    return Card(
        elevation: 0,
        child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(7.0),
                        child: FadeInImage(
                          fadeInDuration: Duration(milliseconds: 150),
                          image: NetworkImage(imageBaseUrl + productDetail.image1!),
                          height: 90.0,
                          width: 90.0,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              erroWidget(90),
                          placeholder: placeHolder(90),
                        )),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productDetail.productTitle!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                  color: Theme.of(context).colorScheme.lightBlack,
                                  fontWeight: FontWeight.normal),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            

                            Row(
                              children: [
                              Text(
                                getTranslated(context, 'QUANTITY_LBL')! + ":",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(color: Theme.of(context).colorScheme.lightBlack2),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.only(start: 5.0),
                                child: Text(
                                  orderDetails.qty!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2!
                                      .copyWith(color: Theme.of(context).colorScheme.lightBlack),
                                ),
                              )
                            ]),
                            Text(
                              CUR_CURRENCY! + " " + orderDetails.amt!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
                            ),
                            //  Text(orderItem.status)
                          ],
                        ),
                      ),
                    )
                  ],
                ),

                Divider(
                  color: Theme.of(context).colorScheme.lightBlack,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     // pDate != null ? 
                      getPlaced(pDate!),
                      //: getPlaced(aDate!),
                      getProcessed(prDate, cDate),
                      getShipped(sDate, cDate),
                      getDelivered(dDate, cDate),
                      orderItem.orderDetail![0].deliveryStatus!.contains('Cancelled') ?  getCanceled(cDate) : Container(),
                      orderItem.orderDetail![0].deliveryStatus!.contains('Returned') ? getReturned(rDate) : Container(),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsetsDirectional.only(
                      start: 20.0, end: 20.0, top: 5),
                  height: files.length > 0 ? 180 : 0,
                  child: Row(
                    children: [
                      Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: files.length,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, i) {
                              return InkWell(
                                child: Stack(
                                  alignment: AlignmentDirectional.topEnd,
                                  children: [
                                    Image.file(
                                      files[i],
                                      width: 180,
                                      height: 180,
                                    ),
                                    Container(
                                        color: Theme.of(context).colorScheme.black26,
                                        child: Icon(
                                          Icons.clear,
                                          size: 15,
                                        ))
                                  ],
                                ),
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      files.removeAt(i);
                                    });
                                  }
                                },
                              );
                            },
                          )
                      ),
                    ],
                  ),
                ),

                /////
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (orderItem.orderDetail![0].deliveryStatus!.toLowerCase() == 'delivered')
                     if (orderItem.reviewed == '0')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            openBottomSheet(context, orderItem.orderDetail![0].productID);
                          },
                          icon: Icon(Icons.rate_review_outlined),
                          label: Text(
                            getTranslated(context, "WRITE_REVIEW_LBL")!,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.btnColor),
                          ),
                        ),
                      ),
                    if (_isCancleable)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Align(
                            alignment: Alignment.bottomRight,
                            child: OutlinedButton(
                              onPressed: _isCancleable
                                  ? () {
                              cancelReturnAlert(
                                type: 'Cancelled',
                                productId: orderItem.orderDetail![0].productID,
                                orderId : orderItem.orderDetail![0].orderID,
                                userOrderId: orderItem.orderDetail![0].userOrderID
                              );
                                
                              }
                                  : null,
                              child:
                              Text('Cancel'),
                            )),
                      )
                    else
                      (_isReturnable) ? 
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: OutlinedButton(
                          onPressed:_isReturnClick
                              ? () {
                            cancelReturnAlert(
                                type: 'Returned',
                                productId: orderItem.orderDetail![0].productID,
                                orderId : orderItem.orderDetail![0].orderID,
                                userOrderId: orderItem.orderDetail![0].userOrderID
                              );
                          }
                              : null,
                          child: Text('Return'),
                        ),
                      )
                          : Container(),
                  ],
                ),
              ],
            )));
  }


  cancelReturnAlert({String? type,String? orderId,String? userOrderId,String? productId}){

    final _formKey = GlobalKey<FormState>();
    TextEditingController message = TextEditingController();
    if(type == 'Cancelled') type = 'cancel'; else type = 'return';

    checkValid(){
      if (_formKey.currentState!.validate()) {
         setState(() {
           type == 'Returned' ? _isReturnClick = false : _isCancleable = false;
                                                    _isProgress = true;
                                                  });
          cancelOrder(
            userOrderId: userOrderId,
            productid: productId,
            message: message.text,
            flag: type == 'cancel' ? 'Cancelled' : 'Returned'
          );
      }
    }
    return showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(
                                      builder: (context,setstate) {
                                        return Form(
                                          key: _formKey,
                                          child: AlertDialog(
                                            scrollable: true,
                                            insetPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                                            title: Text(
                                              getTranslated(
                                                  context, 'ARE_YOU_SURE?')!,
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.fontColor),
                                            ),
                                            content: Column(
                                              children: [
                                                Text(
                                                  "Would you like to $type this product?",
                                                  style: TextStyle(
                                                      color: Theme.of(context).colorScheme.fontColor),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.only(top : 8.0),
                                                  child: TextFormField(
                                                    controller: message,
                                                    validator: (val){
                                                      if(val!.trim().isEmpty)
                                                       return 'This field is required.';
                                                    },
                                                    maxLines: 4,
                                                    decoration: InputDecoration(
                                                      hintText: '$type reason',
                                                      border: OutlineInputBorder(
                                                        borderSide: BorderSide()
                                                      )
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  getTranslated(context, 'YES')!,
                                                  style: TextStyle(
                                                      color: colors.primary),
                                                ),
                                                onPressed: () {
                                                  
                                                 
                                                  checkValid();
                                                  
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  getTranslated(context, 'NO')!,
                                                  style: TextStyle(
                                                      color: colors.primary),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              )
                                            ],
                                          ),
                                        );
                                      }
                                    );
                                  },
                                );
  }


  bankProof(OrderModel model) {
    String status = model.attachList![0].bankTranStatus!;
    Color clr;
    if (status == "0") {
      status = "Pending";
      clr = Colors.cyan;
    } else if (status == "1") {
      status = "Rejected";
      clr = Colors.red;
    } else {
      status = "Accepted";
      clr = Colors.green;
    }

    return Card(
        elevation: 0,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: model.attachList!.length,
                  //scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        child: Text(
                          "Attachment " + (i + 1).toString(),
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Theme.of(context).colorScheme.fontColor),
                        ),
                        onTap: () {
                          _launchURL(model.attachList![i].attachment!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
                decoration: BoxDecoration(
                    color: clr, borderRadius: BorderRadius.circular(5)),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(status),
                ))
          ],
        ));
  }


  void _launchURL(String _url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';


  _imgFromGallery() async {
    var result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      files = result.paths.map((path) => File(path!)).toList();
      if (mounted) setState(() {});
    } else {
      // User canceled the picker
    }
  }

  getPlaced(String pDate) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(
          Icons.circle,
          color: colors.primary,
          size: 15,
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_NPLACED')!,
                style: TextStyle(fontSize: 8),
              ),
              Text(
                pDate,
                style: TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  getProcessed(String? prDate, String? cDate) {
    return cDate == ''
        ? Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                height: 30,
                child: VerticalDivider(
                  thickness: 2,
                  color: prDate == '' ? Colors.grey : colors.primary,
                )),
            Icon(
              Icons.circle,
              color: prDate == '' ? Colors.grey : colors.primary,
              size: 15,
            ),
          ],
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_PROCESSED')!,
                style: TextStyle(fontSize: 8),
              ),
              Text(
                prDate ?? " ",
                style: TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    )
        : prDate == ''
        ? Container()
        : Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 30,
              child: VerticalDivider(
                thickness: 2,
                color: colors.primary,
              ),
            ),
            Icon(
              Icons.circle,
              color: colors.primary,
              size: 15,
            ),
          ],
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_PROCESSED')!,
                style: TextStyle(fontSize: 8),
              ),
              Text(
                prDate!,
                style: TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  getShipped(String? sDate, String? cDate) {
    return cDate == ''
        ? Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          children: [
            Container(
              height: 30,
              child: VerticalDivider(
                thickness: 2,
                color: sDate == '' ? Colors.grey : colors.primary,
              ),
            ),
            Icon(
              Icons.circle,
              color: sDate == '' ? Colors.grey : colors.primary,
              size: 15,
            ),
          ],
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_SHIPPED')!,
                style: TextStyle(fontSize: 8),
                textAlign: TextAlign.center,
              ),
              Text(
                sDate ?? " ",
                style: TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    )
        : sDate == ''
        ? Container()
        : Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          children: [
            Container(
              height: 30,
              child: VerticalDivider(
                thickness: 2,
                color: colors.primary,
              ),
            ),
            Icon(
              Icons.circle,
              color: colors.primary,
              size: 15,
            ),
          ],
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_SHIPPED')!,
                style: TextStyle(fontSize: 8),
                textAlign: TextAlign.center,
              ),
              Text(
                sDate!,
                style: TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  getDelivered(String? dDate, String? cDate) {
    return cDate == ''
        ? Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          children: [
            Container(
              height: 30,
              child: VerticalDivider(
                thickness: 2,
                color: dDate == '' ? Colors.grey : colors.primary,
              ),
            ),
            Icon(
              Icons.circle,
              color: dDate == '' ? Colors.grey : colors.primary,
              size: 15,
            ),
          ],
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_DELIVERED')!,
                style: TextStyle(fontSize: 8),
                textAlign: TextAlign.center,
              ),
              Text(
                dDate ?? " ",
                style: TextStyle(fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    )
        : Container();
  }

  getCanceled(String? cDate) {
    return cDate != ''
        ? Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          children: [
            Container(
              height: 30,
              child: VerticalDivider(
                thickness: 2,
                color: colors.primary,
              ),
            ),
            Icon(
              Icons.cancel_rounded,
              color: colors.primary,
              size: 15,
            ),
          ],
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_CANCLED')!,
                style: TextStyle(fontSize: 8),
              ),
              Text(
                cDate!,
                style: TextStyle(fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    )
        : Container();
  }

  getReturned(String? rDate,) {
    return rDate != null
        ? Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          children: [
            Container(
              height: 30,
              child: VerticalDivider(
                thickness: 2,
                color: colors.primary,
              ),
            ),
            Icon(
              Icons.cancel_rounded,
              color: colors.primary,
              size: 15,
            ),
          ],
        ),
        Container(
            margin: const EdgeInsetsDirectional.only(start: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslated(context, 'ORDER_RETURNED')!,
                  style: TextStyle(fontSize: 8),
                ),
                Text(
                  rDate,
                  style: TextStyle(fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ],
            )),
      ],
    )
        : Container();
  }

  Future<void> cancelOrder({String? userOrderId, String? productid , String? message , String? flag}) async {

    SettingProvider settingProvider = context.read<SettingProvider>();
   settingProvider.getPrefrence('token').then((value) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = 
        {
          'productID' : productid, 
           'custID' : CUR_USERID,
           'userOrderID' : userOrderId,
           'message' : message,
           'flag' : flag
        
        };
        var response = await http.post(returnCancellAPI, body: parameter, headers: {
                     "Authorization": 'Bearer ' + value!,
                   },)
            .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        bool error = getdata["error"] == '200' ? true : false;
        String msg = getdata["message"];
        if (error) {
          Future.delayed(Duration(seconds: 1)).then((_) async {
            Navigator.pop(context, 'update');
          });
          
          Navigator.pop(context);
        }

        if (mounted) {
          setState(() {
            _isProgress = false;
            _isReturnClick = true;
          });
        }
        setSnackbar(msg);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
          _isReturnClick = true;
        });
      }
    }
   });
  }

  setSnackbar(String msg) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  dwnInvoice() {
    return  widget.model!.orderDetail![0].invoiceFile == '' ? Container() : Card(
      elevation: 0,
      child: InkWell(
          child: ListTile(
            dense: true,
            trailing: Icon(
              Icons.keyboard_arrow_right,
              color: colors.primary,
            ),
            leading: Icon(
              Icons.receipt,
              color: colors.primary,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslated(context, 'DWNLD_INVOICE')!,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(color: Theme.of(context).colorScheme.lightBlack),
                ),
                downloading == true ? Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: LinearProgressIndicator(
                    value: downloadprogress,
                  ),
                ) : Container(),
              ],
            ),
          ),
          onTap: () async {
            final status = await Permission.storage.request();
            Map<Permission, PermissionStatus> statuses = await [Permission.storage,Permission.mediaLibrary].request();
            if (statuses[Permission.storage] == PermissionStatus.granted
            && statuses[Permission.mediaLibrary] == PermissionStatus.granted) 
            {
              var targetPath;

              if (Platform.isIOS) {
                var target = await getApplicationDocumentsDirectory();
                targetPath = target.path.toString();
              } else {
                var downloadsDirectory =
                await DownloadsPathProvider.downloadsDirectory;
                targetPath = downloadsDirectory!.path.toString();
              }
              var targetFileName = "/${widget.model!.orderDetail![0].invoiceFile!}";
              print(pdfBaseUrl + widget.model!.orderDetail![0].invoiceFile!);
              print(targetPath);
     try {
        Dio? dio = Dio();
        await dio.download(pdfBaseUrl + widget.model!.orderDetail![0].invoiceFile!, targetPath + targetFileName,
            onReceiveProgress: (receivedBytes, totalBytes) {
          print('here 1');
          if(mounted)
              setState(() {
                downloading = true;
                downloadprogress = receivedBytes/totalBytes;
                progress = ((receivedBytes / totalBytes) * 100).toStringAsFixed(0) + "%";
                print(progress);
                if (downloadprogress == 1) {
                  downloading = false;
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                content: Text(
                  "${getTranslated(context, 'INVOICE_PATH')} $targetFileName",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.black),
                ),
                action: SnackBarAction(
                    label: getTranslated(context, 'VIEW')!,
                    onPressed: () async {
                      final result = await OpenFile.open(targetPath + targetFileName);
                    }),
                backgroundColor: Theme.of(context).colorScheme.white,
                elevation: 1.0,
              ));
                }
              });
            });
      } catch (e) {
        print('catch catch catch');
        Fluttertoast.showToast(msg: e.toString());
        print(e);
      }

              // if (mounted) {
              //   setState(() {
              //     _isProgress = false;
              //   });
              // }
             
           }
           else{
             await [Permission.storage,Permission.manageExternalStorage,Permission.mediaLibrary].request();
           }
          }),
    );
  }


  Widget getSubHeadingsTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: TabBar(
        controller: _tabController,
        tabs: [
          getTab("All Details"),
          getTab("Processing"),
          getTab("Delivered"),
          getTab("Cancelled"),
          getTab("Returned"),
        ],
        indicator: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(50),
          color: colors.primary,
        ),
        isScrollable: true,
        unselectedLabelColor: Theme.of(context).colorScheme.black,
        labelColor: Theme.of(context).colorScheme.white,
        automaticIndicatorColorAdjustment: true,
        indicatorPadding: EdgeInsets.symmetric(horizontal: 1.0),
      ),
    );
  }

  getOrderDetails(OrderListData model) {
    return SingleChildScrollView(
      controller: controller,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            getOrderNoAndOTPDetails(model.orderDetail![0]),
            getSingleProduct(model),
            getStatus(),
            dwnInvoice(),
            shippingDetails(),
            priceDetails(),
          ],
        ),
      ),
    );
  }

  getStatus(){
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5)
      ),
      margin : EdgeInsets.only(left: 4,right : 4),
      child: ListTile(
              dense: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status - ${widget.model!.orderDetail![0].deliveryStatus}',
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2!
                        .copyWith(color: Theme.of(context).colorScheme.lightBlack),
                  ),
                ],
              ),
            ),
    );
       }


  getSingleProduct(OrderListData model) {
  
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 1,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) {
        proId = model.orderDetail![0].productID;
          return productItem(model);
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  void openBottomSheet(BuildContext context, var productID) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: Wrap(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      bottomSheetHandle(),
                      rateTextLabel(),
                      ratingWidget(),
                      writeReviewLabel(),
                      writeReviewField(),
                      getImageField(),
                      sendReviewButton(productID),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
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

  Widget rateTextLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: getHeading("PRODUCT_REVIEW"),
    );
  }

  Widget ratingWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RatingBar.builder(
        initialRating: 0,
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: false,
        itemCount: 5,
        itemSize: 32,
        itemPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
        itemBuilder: (context, _) => const Icon(
          Icons.star,
          color: colors.yellow,
        ),
        onRatingUpdate: (rating) {
          curRating = rating;
        },
      ),
    );
  }

  Widget writeReviewLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Text(
        getTranslated(context, 'REVIEW_OPINION')!,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.subtitle1!,
      ),
    );
  }

  Widget writeReviewField() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: TextField(
          controller: commentTextController,
          style: Theme.of(context).textTheme.subtitle2,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.lightBlack, width: 1.0)),
            hintText: getTranslated(context, 'REVIEW_HINT_LBL'),
            hintStyle: Theme.of(context)
                .textTheme
                .subtitle2!
                .copyWith(color: Theme.of(context).colorScheme.lightBlack2.withOpacity(0.7)),
          ),
        ));
  }

  Widget getImageField() {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding:
            const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 5),
            height: 100,
            child: Row(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(50.0)),
                        child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: Theme.of(context).colorScheme.white,
                              size: 25.0,
                            ),
                            onPressed: () {
                              _reviewImgFromGallery(setModalState);
                            }),
                      ),
                      Text(
                        getTranslated(context, 'ADD_YOUR_PHOTOS')!,
                        style: TextStyle(color: Theme.of(context).colorScheme.lightBlack, fontSize: 11),
                      )
                    ],
                  ),
                ),
                Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: reviewPhotos.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, i) {
                        return InkWell(
                          child: Stack(
                            alignment: AlignmentDirectional.topEnd,
                            children: [
                              Image.file(
                                reviewPhotos[i],
                                width: 100,
                                height: 100,
                              ),
                              Container(
                                  color: Theme.of(context).colorScheme.black26,
                                  child: const Icon(
                                    Icons.clear,
                                    size: 15,
                                  ))
                            ],
                          ),
                          onTap: () {
                            if (mounted) {
                              setModalState(() {
                                reviewPhotos.removeAt(i);
                              });
                            }
                          },
                        );
                      },
                    )),
              ],
            ),
          );
        });
  }

  void _reviewImgFromGallery(StateSetter setModalState) async {
    var result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      //allowMultiple: true,
    );
    if (result != null) {
      if(reviewPhotos.length < 3)
      reviewPhotos.addAll(result.paths.map((path) => File(path!)).toList());
      if (mounted) setModalState(() {});
    } else {
      // User canceled the picker
    }
  }

  Widget sendReviewButton(var productID) {
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
              onPressed: () {
                if (curRating != 0 ||
                    commentTextController.text != '' ||
                    (reviewPhotos.isNotEmpty)) {
                  Navigator.pop(context);
                  setRating(curRating, commentTextController.text, reviewPhotos,
                      productID);
                } else {
                  Navigator.pop(context);
                  setSnackbar(getTranslated(context, 'REVIEW_W')!);
                }
              },
              child: Text(getTranslated(context, 'SEND_REVIEW')!),
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Text getHeading(
      String title,
      ) {
    return Text(
      getTranslated(context, title)!,
      style: Theme.of(context)
          .textTheme
          .headline6!
          .copyWith(fontWeight: FontWeight.bold),
    );
  }

  Future<void> setRating(
      double rating, String comment, List<File> files, var productID) async {

    SettingProvider settingProvider = context.read<SettingProvider>();
   settingProvider.getPrefrence('token').then((value) async {
    _isNetworkAvail = await isNetworkAvailable();
    var dio = new Dio();
    FormData formdata;

    if (_isNetworkAvail) {
      try {
        // var request = http.MultipartRequest("POST", setRatingApi);
        // request.headers.addAll(headers);
        // request.fields['custID'] = CUR_USERID!;
        // request.fields['productID'] = productID;

        // if (files != null) {
        //   for (var i = 0; i < files.length; i++) {
        //     var pic = await http.MultipartFile.fromPath(IMGS, files[i].path);
        //     request.files.add(pic);
        //   }
        // }

        // if (comment != "") request.fields['message'] = comment;
        // if (rating != 0) request.fields['rating'] = rating.toString();
        // var response = await request.send();
        // var responseData = await response.stream.toBytes();
        // var responseString = String.fromCharCodes(responseData);
        
        
        //var getdata = json.decode(responseString);
        Map<String, String> headers = {
    'Content-Type': 'application/json;charset=UTF-8',
    'Charset': 'utf-8',
    'Accept': "application/json",
    'Authorization' : 'Bearer $value',
}; 
dio.options.connectTimeout = 5000; 
    dio.options.receiveTimeout = 5000;
    dio.options.headers = headers;
    dio.options.baseUrl = oymBaseUrl;
    formdata = FormData.fromMap({
    'custID' : CUR_USERID,
    'productID' : productID,
    'message' : comment,
    'rating' : rating.toString(),
    'image1': files.length > 0 ? await MultipartFile.fromFile(
        files[0].path,
      ) : '',
      
      'image2' : files.length > 1 ? await MultipartFile.fromFile(
        files[1].path,
      ) : '',
      'image3' : files.length > 2 ? await MultipartFile.fromFile(
        files[2].path,
      ) : ''
   });
        

        // if (!error) {
        //   setSnackbar(msg!);
        // } else {
        //   setSnackbar(msg!);
        // }
        print(formdata);

        var response = await dio.post("addReviewAPI",
        data: formdata,
        
        options: Options(
          validateStatus: (status) {
              return status! < 500;
            },
            method: 'POST',
            contentType: 'multipart/form-data',
            responseType: ResponseType.plain // or ResponseType.JSON
            ));
        print(response.data);
        print(response.statusCode);
        var getdata = json.decode(response.data);
        bool error = getdata["error"] == '200' ? true : false;
        String? msg = getdata['message'];
        
        commentTextController.text = "";
        files.clear();
        reviewPhotos.clear();
        setSnackbar(msg!);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
   });
  }

  Widget getOrderNoAndOTPDetails(OrderDetails model) {

    DateTime orderDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(model.orderDate!);
    return Card(
      elevation: 0.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${getTranslated(context, "ORDER_ID_LBL")!} - ${model.userOrderID}",
                  style: TextStyle(color: Theme.of(context).colorScheme.lightBlack2),
                ),
              ],
            ),
            Text(
                  "Order Date - ${DateFormat.yMMMMEEEEd().format(orderDate)}",
                  style: TextStyle(color: Theme.of(context).colorScheme.lightBlack2),
                )
            
          ],
        ),
      ),
    );
  }

  getTab(String title) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      height: 35,
      child: Center(
        child: Text(title),
      ),
    );
  }
}
