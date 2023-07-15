import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/Address_Model.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:oym/Screen/Cart.dart';
import 'package:provider/src/provider.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/user_custom_radio.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/User.dart';
import 'Add_Address.dart';


class ManageAddress extends StatefulWidget {
  final bool? home;

  const ManageAddress({Key? key, this.home}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateAddress();
  }
}

class StateAddress extends State<ManageAddress> with TickerProviderStateMixin {
  bool _isLoading = false, _isProgress = false;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  List<AddressData> addressList = [];
  List<RadioModel> addModel = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    if (widget.home!) {
    } else {
      addAddressModel();
    }
    _getAddress();

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
                  addressList.clear();
                  addModel.clear();
                  if (!ISFLAT_DEL) delCharge = 0;
                  _getAddress();
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

  Future<Null> _getAddress() async {
    _isNetworkAvail = await isNetworkAvailable();
    addressList.clear();
    addModel.clear();
    SettingProvider settingProvider = context.read<SettingProvider>();
    Map<String, String>  headers = {};
    settingProvider.getPrefrence('token').then((value) async {
       headers = {
          "Authorization": 'Bearer ' + value!,
       };
       print(headers.toString());
    if (_isNetworkAvail) {
      try {
        var parameter = {
          'custID' : CUR_USERID,
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

          addressList =
              (data as List).map((data) => AddressData.fromJson(data)).toList();

          for (int i = 0; i < addressList.length; i++) {
            if (addressList[i].setDefault == "1") {
              selectedAddress = i;
              selAddress = addressList[i].custID;
            }
          }

          addAddressModel();
          setState(() {});
        } else {}
        if (mounted)
          setState(() {
            _isLoading = false;
          });
          setState(() {
            
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

  
  Future<void> setAsDefault(int index) async {
    

    _isNetworkAvail = await isNetworkAvailable();
    SettingProvider settingProvider = context.read<SettingProvider>();
    
    settingProvider.getPrefrence('token').then((value) async {
       
       
    if (_isNetworkAvail) {
      try {
        var parameter = {
        'addressID' : addressList[index].id,
        'custID': addressList[index].custID,
      };
        print(parameter);
        Response response =
            await post(setDefaultAddressApi, body: parameter, headers: {
              "Authorization": 'Bearer ' + value!,
            })
                .timeout(Duration(seconds: timeOut));
        print(response.body);
        var getdata = json.decode(response.body);
        int error = int.parse(getdata["error"]);
        String msg = getdata["message"];
        if (error == 200) {
          setSnackbar(msg);
          for (AddressData i in addressList) {
          i.setDefault = "0";
          }
           addressList[index].setDefault = "1";
           setState(() {});

        } else {
          setSnackbar(msg);
        }
        if (mounted)
          setState(() {
            _isProgress = false;
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

  
  Future<void> deleteAddress(int index,String id) async {
    _isNetworkAvail = await isNetworkAvailable();
    SettingProvider settingProvider = context.read<SettingProvider>();
    
    settingProvider.getPrefrence('token').then((value) async {
     if (_isNetworkAvail) {
      try {
        var parameter = {
          'addressID' : id,
        };
        Response response =
            await post(deleteaddressApi, body: parameter, headers: {
              "Authorization": 'Bearer ' + value!,
            })
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);
        int error = int.parse(getdata["error"]);
        String msg = getdata["message"];
        if (error == 200) {
            if (addressList.length != 1) {
              addressList
                  .removeWhere((item) => item.id == id);
              selectedAddress = 0;
              selAddress = addressList[0].custID;
              
            } else {
              addressList
                  .removeWhere((item) => item.id == id);
              selAddress = null;
            }
          context.read<UserProvider>().setaddressList = addressList;
          addModel.clear();
          //setSnackbar(msg);
          addAddressModel();
        } else {
          setSnackbar(msg);
        }
        if (mounted)
          setState(() {
            _isProgress = false;
          });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
    });
    
  }

  Future<Null> _refresh() {
    if (mounted)
      setState(() {
        _isLoading = true;
      });
    addressList.clear();
    addModel.clear();
    if (!ISFLAT_DEL) delCharge = 0;
    return _getAddress();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: getSimpleAppBar( getTranslated(context, "SHIPP_ADDRESS")!,context),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
         Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddAddress(
                      update: false,
                    )),
          ).then((value) {
           
              if (mounted) {
                setState(() {
                  _getAddress();
                });
              }
          });
          if (mounted) {
            setState(() {
              addModel.clear();
              addAddressModel();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      body: _isNetworkAvail
          ? Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? shimmer(context)
                      : addressList.isEmpty
                          ? Center(
                              child: Text(getTranslated(context, 'NOADDRESS')!))
                          : Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: RefreshIndicator(
                                      key: _refreshIndicatorKey,
                                      onRefresh: _refresh,
                                      child: ListView.builder(
                                          // shrinkWrap: true,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          itemCount: addressList.length,
                                          itemBuilder: (context, index) {
                                            return addressItem(index);
                                          })),
                                ),
                                showCircularProgress(
                                    _isProgress, colors.primary),
                              ],
                            ),
                ),
              InkWell(
                  child: Container(
                      alignment: Alignment.center,
                      height: 55,
                      decoration:  const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colors.grad1Color, colors.grad2Color],
                            stops: [0, 1]),
                      ),
                      child: Text(getTranslated(context, 'ADDADDRESS')!,
                          style: Theme.of(context).textTheme.subtitle1!.copyWith(
                                color: Theme.of(context).colorScheme.white,
                              ))),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddAddress(
                                update: false,
                              )),
                    );
                    if (mounted) {
                      setState(() {
                        addModel.clear();
                        addAddressModel();
                      });
                    }
                  },
                )
              ],
            )
          : noInternet(context),
    );
  }


  addressItem(int index) {

    return Card(
        elevation: 0.2,
        child:  InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            if (mounted) {
              setState(() {
                context.read<UserProvider>().setSelectedAddressIndex = index;
                context.read<UserProvider>().setSelAddressId = int.parse(addressList[index].id!);
                addModel.forEach((element) => element.isSelected = false);
                addModel[index].isSelected = true;
              });
            }
          },
          child: RadioItem(addModel[index]),
        ));
  }


  void addAddressModel() {
    for (int i = 0; i < addressList.length; i++) {
      addModel.add(
        RadioModel(
          isSelected: int.parse(addressList[i].id!) == context.read<UserProvider>().selectedAddressId ? true : false,
          name: "${addressList[i].custAlternateNM}",
          add: "${addressList[i].address!}, ${addressList[i].cityNM!}, ${addressList[i].areaNM!}, ${addressList[i].country!}, ${addressList[i].pincode!}",
          addItem: addressList[i],
          show: !widget.home!,
          onSetDefault: () {
            if (mounted) {
              setState(() {
                _isProgress = true;
              });
            }
            setAsDefault(i);
          },
          onDeleteSelected: () {
            if (mounted) {
              setState(() {
                _isProgress = true;
              });
            }
            deleteAddress(i,addressList[i].id!);
          },
          onEditSelected: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAddress(
                    update: true,
                    addressData : addressList[i],
                  ),
                )).then((value) {
                  if (mounted) {
              setState(() {
                _getAddress();
                addModel.clear();
                addAddressModel();
              });
            }
         });
      }
     ));
    }
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:  Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }
}
