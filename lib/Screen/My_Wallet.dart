import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/WalletModel.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
//import 'package:paytm/paytm.dart';
import 'package:provider/provider.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/PaymentRadio.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Transaction_Model.dart';

class MyWallet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateWallet();
  }
}

class StateWallet extends State<MyWallet> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  ScrollController controller = new ScrollController();
  List<TransactionModel> tempList = [];
  TextEditingController? amtC, msgC;
  List<String?> paymentMethodList = [];
  List<String> paymentIconList = [
    'assets/images/paypal.svg',
    'assets/images/rozerpay.svg',
    'assets/images/paystack.svg',
    'assets/images/flutterwave.svg',
    'assets/images/stripe.svg',
    'assets/images/paytm.svg',
  ];
  List<RadioModel> payModel = [];
  bool? paypal, razorpay, paumoney, paystack, flutterwave, stripe, paytm;
  

  int? selectedMethod;
  String? payMethod;
  StateSetter? dialogState;
  bool _isProgress = true;
  //List<TransactionModel> tranList = [];
  List<WalletData> tranList = [];
   int offset = 0;
  int total = 0;
  bool isLoadingmore = true, _isLoading = true, payTesting = true;

  @override
  void initState() {
    super.initState();
   
    controller.addListener(_scrollListener);
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
    amtC = new TextEditingController();
    msgC = new TextEditingController();
    getTransaction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: getAppBar(getTranslated(context, 'MYWALLET')!, context),
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer(context)
                : Stack(
                    children: <Widget>[
                      showContent(),
                     // showCircularProgress(_isProgress, colors.primary),
                    ],
                  )
            : noInternet(context));
  }





  // void paytmPayment(double price) async {
  //   String? payment_response;
  //   setState(() {
  //     _isProgress = true;
  //   });
  //   String orderId = DateTime.now().millisecondsSinceEpoch.toString();

  //   String callBackUrl = (payTesting
  //           ? 'https://securegw-stage.paytm.in'
  //           : 'https://securegw.paytm.in') +
  //       '/theia/paytmCallback?ORDER_ID=' +
  //       orderId;

  //   var parameter = {
  //     AMOUNT: price.toString(),
  //     USER_ID: CUR_USERID,
  //     ORDER_ID: orderId
  //   };

  //   try {
  //     final response = await post(
  //       getPytmChecsumkApi,
  //       body: parameter,
  //       headers: headers,
  //     );
  //     var getdata = json.decode(response.body);
  //     String? txnToken;
  //     setState(() {
  //       txnToken = getdata["txn_token"];
  //     });

  //     var paytmResponse = Paytm.payWithPaytm(paytmMerId!, orderId, txnToken!,
  //         price.toString(), callBackUrl, payTesting);

  //     paytmResponse.then((value) {
  //       setState(() {
  //         _isProgress = false;

  //         if (value['error']) {
  //           payment_response = value['errorMessage'];
  //         } else {
  //           if (value['response'] != null) {
  //             payment_response = value['response']['STATUS'];
  //             if (payment_response == "TXN_SUCCESS")
  //               sendRequest(orderId, "Paytm");
  //           }
  //         }

  //         setSnackbar(payment_response!);
  //       });
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  


  


  

  listItem(int index) {
    Color back;
    if (tranList[index].transactionType!.toLowerCase() == "credit") {
      back = Colors.green;
    } else
      back = Colors.red;
    return Card(
      elevation: 0,
      margin: EdgeInsets.all(5.0),
      child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            getTranslated(context, 'AMOUNT')! +
                                " : " +
                                CUR_CURRENCY! +
                                " " +
                                tranList[index].amount!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(tranList[index].transactionDate!),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(getTranslated(context, 'ID_LBL')! +
                            " : " +
                            tranList[index].transactionID!),
                        Spacer(),
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                              color: back,
                              borderRadius: new BorderRadius.all(
                                  const Radius.circular(4.0))),
                          child: Text(
                            tranList[index].transactionType!,
                            style: TextStyle(color: Theme.of(context).colorScheme.white),
                          ),
                        )
                      ],
                    ),
                    tranList[index].description != null &&
                            tranList[index].description!.isNotEmpty
                        ? Text(getTranslated(context, 'MSG')! +
                            " : " +
                            tranList[index].description!)
                        : Container(),
                  ]))),
    );
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
                  getTransaction();
                } else {
                  await buttonController!.reverse();
                  setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

  Future<Null> getTransaction() async {

    SettingProvider settingProvider = context.read<SettingProvider>();
   settingProvider.getPrefrence('token').then((value) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      //  CUR_USERID = await getPrefrence(ID);
      try {
        var parameter = {
          'startPosition': tranList.length == 0 ? '0' : '${tranList.length}',
          'customerID': CUR_USERID,
        };
        var response =
            await post(walletApi, headers: {
                     "Authorization": 'Bearer ' + value!,
                   }, body: parameter)
                .timeout(Duration(seconds: timeOut));
        
          print(response.body);
          var getdata = json.decode(response.body);
          bool error = getdata["error"] == '200' ? true : false;
          String msg = getdata["message"];
         
          if (error) {
            total = getdata["walletAmount"];
            getdata.containsKey("walletAmount");

            Provider.of<UserProvider>(this.context, listen: false)
                .setBalance(getdata["walletAmount"].toString());
            setState(() {
              WalletModel walletModel = WalletModel.fromJson(getdata);
              tranList.addAll(walletModel.data!);
            });
          } else {
            total = getdata["walletAmount"];
            isLoadingmore = false;
          }
        
        if (mounted)
          setState(() {
            _isLoading = false;
            _isProgress = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);

        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else
      setState(() {
        _isNetworkAvail = false;
      });
   });
    return null;
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

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<Null> _refresh() {
    setState(() {
      _isLoading = true;
    });
    offset = 0;
    total = 0;
    tranList.clear();
    return getTransaction();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;
          _isProgress = true;
           getTransaction();
        });
      }
    }
  }

  showContent() {
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          controller: controller,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).colorScheme.fontColor,
                          ),
                          Text(
                            " " + getTranslated(context, 'CURBAL_LBL')!,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .copyWith(
                                    color: Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                        return Text(
                            CUR_CURRENCY! +
                                " " +
                                double.parse(total.toString()).toString()
                                    ,
                            style: Theme.of(context)
                                .textTheme
                                .headline6!
                                .copyWith(
                                    color: Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold));
                      }),
                    ],
                  ),
                ),
              ),
            ),
            tranList.length == 0
                ? Center(
                  child : Text('No Data')
                )
                : Stack(
                  children: [
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: tranList.length,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return listItem(index);
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: showCircularProgress(_isProgress, colors.primary))
                  ],
                ),
          ]),
        ));
  }
}
