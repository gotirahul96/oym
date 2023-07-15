import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:oym/Helper/Constant.dart';
import 'package:oym/Helper/Session.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/Address_Model.dart';
import 'package:oym/Model/Area_Model.dart';
import 'package:oym/Model/City_Model.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/String.dart';

class AddAddress extends StatefulWidget {
  final bool? update;
  final AddressData? addressData;

  const AddAddress({Key? key, this.update, this.addressData}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateAddress();
  }
}

//String? latitude, longitude, state, country;

class StateAddress extends State<AddAddress> with TickerProviderStateMixin {
  String? name,
      mobile,
      city,
      area,
      address,
      address2,
      pincode,
      landmark,
      altMob,
      type = "Home",
      isDefault;
  bool checkedDefault = false, isArea = false;
  bool _isProgress = false;
  StateSetter? areaState, cityState;

  //bool _isLoading = false;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool cityLoading = true, areaLoading = true;
  TextEditingController? nameC,
      mobileC,
      pincodeC,
      addressC,
      address2c,
      //stateC,
      countryC,
      altMobC;
  int? selectedType = 1;
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  FocusNode? nameFocus,
      monoFocus,
      almonoFocus,
      addFocus,
      landFocus,
      locationFocus = FocusNode();
  int? selAreaPos = -1, selCityPos = -1;
  final TextEditingController _areaController = TextEditingController();
  //final TextEditingController _cityController = TextEditingController();
  List<CityListData> cityListData = [];
  CityListData? selectedCity;
  List<AreaData> areaListData = [];
  AreaData? selectedArea;

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
    initData();
    mobileC = new TextEditingController();
    nameC = new TextEditingController();
    altMobC = new TextEditingController();
    pincodeC = new TextEditingController();
    addressC = new TextEditingController();
    address2c = TextEditingController();
    //stateC = new TextEditingController();
    countryC = new TextEditingController();
    countryC!.text = 'Oman';
  }


  Future<void> initData() async {
    getAllCity().then((value) async {
        if (widget.update!) {
        AddressData? item = widget.addressData;

        mobileC!.text = item!.custAlternateMobile!;
        nameC!.text = item.custAlternateNM!;
        pincodeC!.text = item.pincode!;
        addressC!.text = item.address!;
        address2c!.text =item.address2!;
        if (item.cityNM!.isNotEmpty) {
            print(item.cityId);
            print(item.cityNM);
            selectedCity = cityListData.firstWhere((element) => element.id == item.cityId);
            await getAreaData(item.cityId!);
            selectedArea = areaListData.firstWhere((element) => element.areaID == item.areaId); 
        }
        //stateC!.text = item.stateNM!;
        countryC!.text = item.country!;
        // _cityController.text = item.cityNM!;
        //stateC!.text = item.stateNM!;
        type = item.addressType;

        if (type!.toLowerCase() == HOME.toLowerCase()) {
          selectedType = 1;
        } else if (type!.toLowerCase() == OFFICE.toLowerCase()) {
          selectedType = 2;
        } else {
          selectedType = 3;
        }

        checkedDefault = item.setDefault == "1" ? true : false;
      } else {
        //getCurrentLoc();
      }
    });
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: getSimpleAppBar(getTranslated(context, "ADDRESS_LBL")!, context),
      body: _isNetworkAvail ? _showContent() : noInternet(context),
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

  addBtn() {
    return AppBtn(
      title: widget.update!
          ? getTranslated(context, 'UPDATEADD')
          : getTranslated(context, 'ADDADDRESS'),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () {
        validateAndSubmit();
      },
    );
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      checkNetwork();
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();
    if (form.validate()) {
      if (selectedCity == null) {
        setSnackbar(getTranslated(context, 'cityWarning')!);
      }  else {
        return true;
      }
    }
    return false;
  }

  Future<void> checkNetwork() async {
    bool avail = await isNetworkAvailable();
    if (avail) {
      addNewAddress();
    } else {
      Future.delayed(Duration(seconds: 2)).then((_) async {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
        await buttonController!.reverse();
      });
    }
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode? nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  setUserName() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            focusNode: nameFocus,
            controller: nameC,
            textCapitalization: TextCapitalization.words,
            validator: (val) => validateUserName(
                val!,
                getTranslated(context, 'USER_REQUIRED'),
                getTranslated(context, 'USER_LENGTH')),
            onSaved: (String? value) {
              name = value;
            },
            onFieldSubmitted: (v) {
              _fieldFocusChange(context, nameFocus!, monoFocus);
            },
            style: Theme.of(context)
                .textTheme
                .subtitle2!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            decoration: InputDecoration(
                label: Text(getTranslated(context, "NAME_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                isDense: true,
                hintText: getTranslated(context, 'NAME_LBL'),
                border: InputBorder.none),
          ),
        ),
      ),
    );
  }

  setMobileNo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.number,
            controller: mobileC,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10)
            ],
            textInputAction: TextInputAction.next,
            focusNode: monoFocus,
            style: Theme.of(context)
                .textTheme
                .subtitle2!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            validator: (val) => validateMob(
                val!,
                getTranslated(context, 'MOB_REQUIRED'),
                getTranslated(context, 'VALID_MOB')),
            onSaved: (String? value) {
              mobile = value;
            },
            onFieldSubmitted: (v) {
              _fieldFocusChange(context, monoFocus!, almonoFocus);
            },
            decoration: InputDecoration(
                label: Text(getTranslated(context, "MOBILEHINT_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                isDense: true,
                hintText: getTranslated(context, 'MOBILEHINT_LBL'),
                border: InputBorder.none),
          ),
        ),
      ),
    );
  }

  setAddress1() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(color: Theme.of(context).colorScheme.fontColor),
                  focusNode: addFocus,
                  controller: addressC,
                  validator: (val) => validateField(
                      val!, getTranslated(context, 'FIELD_REQUIRED')),
                  onSaved: (String? value) {
                    address = value;
                  },
                  onFieldSubmitted: (v) {
                    _fieldFocusChange(context, addFocus!, locationFocus);
                  },
                  decoration: InputDecoration(
                    label: Text('Address 1'),
                    fillColor: Theme.of(context).colorScheme.white,
                    isDense: true,
                    hintText: getTranslated(context, 'ADDRESS_LBL'),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

   setAddres2() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(color: Theme.of(context).colorScheme.fontColor),
                  focusNode: addFocus,
                  controller: address2c,
                  validator: (val) => validateField(
                      val!, getTranslated(context, 'FIELD_REQUIRED')),
                  onSaved: (String? value) {
                    address2 = value;
                  },
                  onFieldSubmitted: (v) {
                    _fieldFocusChange(context, addFocus!, locationFocus);
                  },
                  decoration: InputDecoration(
                    label: Text('Address 2'),
                    fillColor: Theme.of(context).colorScheme.white,
                    isDense: true,
                    hintText: getTranslated(context, 'ADDRESS_LBL'),
                    border: InputBorder.none,
                    
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.primary),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  setcityField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: DropdownButtonFormField<CityListData>(
            value: selectedCity,
              items: cityListData
                  .map<DropdownMenuItem<CityListData>>((e) => DropdownMenuItem<CityListData>(
                        value: e,
                        child: Text(e.cityName.toString(),
                        style: Theme.of(context)
                 .textTheme
                 .subtitle2!
                 .copyWith(color: Theme.of(context).colorScheme.fontColor),),
                      ))
                  .toList(),
              onChanged: (val){
                setState(() {
                  selectedCity = val;
                });
                getAreaData(val!.id!);
              },
              validator: ((value) {
                if (value == null) {
                  return 'This field is required.';
                }
              }),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Select City',
                hintStyle: Theme.of(context)
                  .textTheme
                  .subtitle2!
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              ),
              ),
        ),
      ),
    );
  }

  setAreaField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: DropdownButtonFormField<AreaData>(
            value: selectedArea,
            items: areaListData
                .map<DropdownMenuItem<AreaData>>((e) =>
                    DropdownMenuItem<AreaData>(
                      value: e,
                      child: Text(
                        e.areaName.toString(),
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor),
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                selectedArea = val;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'This field is required.';
              }
            },
            decoration: InputDecoration(
              hintStyle: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor),
              border: InputBorder.none, hintText: 'Select Area'),
          ),
        ),
      ),
    );
  }

  // setStateField() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 5.0),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).colorScheme.white,
  //         borderRadius: BorderRadius.circular(5.0),
  //       ),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(
  //           horizontal: 10.0,
  //         ),
  //         child: TextFormField(
  //           keyboardType: TextInputType.text,
  //           textCapitalization: TextCapitalization.sentences,
  //           controller: stateC,
  //           style: Theme.of(context)
  //               .textTheme
  //               .subtitle2!
  //               .copyWith(color: Theme.of(context).colorScheme.fontColor),
  //           readOnly: false,
  //           //validator: validateField,
  //           onChanged: (v) => setState(() {
  //             state = v;
  //           }),
  //           onSaved: (String? value) {
  //             state = value;
  //           },
  //           decoration: InputDecoration(
  //               label: Text(getTranslated(context, "STATE_LBL")!),
  //               fillColor: Theme.of(context).colorScheme.white,
  //               isDense: true,
  //               hintText: getTranslated(context, 'STATE_LBL'),
  //               border: InputBorder.none),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  setCountry() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: countryC,
            readOnly: true,
            style: Theme.of(context)
                .textTheme
                .subtitle2!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            // onSaved: (String? value) {
            //   country = value;
            // },
            validator: (val) =>
                validateField(val!, getTranslated(context, 'FIELD_REQUIRED')),
            decoration: InputDecoration(
                label: Text(getTranslated(context, "COUNTRY_LBL")!),
                fillColor: Theme.of(context).colorScheme.white,
                isDense: true,
                hintText: getTranslated(context, 'COUNTRY_LBL'),
                border: InputBorder.none),
          ),
        ),
      ),
    );
  }

  Future<void> getAllCity() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        Response response = await get(getOmanCitiesApi);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          CityModel cityModel = CityModel.fromJson(jsonData);
          log(cityModel.data!.length.toString());
          setState(() {
            cityListData = cityModel.data!;
          });

        } else {}
      } catch (e) {}
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }
  //getOmanAreasApi

  Future<void> getAreaData(String cityId) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parms = {
          'cityID' : cityId,
        };
        Response response = await post(getOmanAreasApi,body: parms);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          AreaModel areaModel = AreaModel.fromJson(jsonData);
          log(areaModel.data!.length.toString());
          setState(() {
            areaListData = areaModel.data!;
          });
          if (areaListData.isNotEmpty) {
            setState(() {
             selectedArea = null;
            });
          }
          
        } else {}
      } catch (e) {
      }
      
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }
  

  Future<Null> addNewAddress() async {
    _isNetworkAvail = await isNetworkAvailable();
    SettingProvider settingProvider = context.read<SettingProvider>();

    settingProvider.getPrefrence('token').then((value) async {
      if (_isNetworkAvail) {
        try {
          var parameter = widget.update!
              ? {
                  'addressID': widget.addressData!.id,
                  'custID': CUR_USERID,
                  'fullName': nameC!.text,
                  'mobile': mobileC!.text,
                  'address': addressC!.text,
                  'address2': address2c!.text,
                  'addressType': type,
                  'cityID': selectedCity!.id,
                  'areaID': selectedArea!.areaID,
                  'cityNM': selectedCity!.cityName,
                  'areaNM': selectedArea!.areaName,
                  'country': countryC!.text,
                  'defaultAddress': checkedDefault == true ? '1' : '0',
                }
              : {
                  'custID': CUR_USERID,
                  'fullName': nameC!.text,
                  'mobile': mobileC!.text,
                  'address': addressC!.text,
                  'address2': address2c!.text,
                  'addressType': type,
                  'cityID' : selectedCity!.id,
                  'areaID' : selectedArea!.areaID,
                  'cityNM' : selectedCity!.cityName,
                  'areaNM': selectedArea!.areaName,
                  'country': countryC!.text,
                  'defaultAddress': checkedDefault == true ? '1' : '0',
                };
          print(parameter);
          Response response;
          widget.update!
              ? response =
                  await post(editAddressApi, body: parameter, headers: {
                  "Authorization": 'Bearer ' + value!,
                }).timeout(Duration(seconds: timeOut))
              : response =
                  await post(addNewAddressApi, body: parameter, headers: {
                  "Authorization": 'Bearer ' + value!,
                }).timeout(Duration(seconds: timeOut));
          print(response.body);
          var getdata = json.decode(response.body);
          int error = int.parse(getdata["error"]);
          String msg = getdata["message"];
          if (error == 200) {
            setSnackbar(msg);
            //Navigator.of(context).pop(true);
            Navigator.pop(context);
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

  @override
  void dispose() {
    buttonController!.dispose();
    mobileC?.dispose();
    nameC?.dispose();
    //stateC?.dispose();
    countryC?.dispose();
    altMobC?.dispose();
    addressC!.dispose();
    pincodeC?.dispose();

    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  typeOfAddress() {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: InkWell(
                child: Row(
                  children: [
                    Radio(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      groupValue: selectedType,
                      activeColor: Theme.of(context).colorScheme.fontColor,
                      value: 1,
                      onChanged: (dynamic val) {
                        if (mounted) {
                          setState(() {
                            selectedType = val;
                            type = HOME;
                          });
                        }
                      },
                    ),
                    Expanded(child: Text(getTranslated(context, 'HOME_LBL')!))
                  ],
                ),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      selectedType = 1;
                      type = HOME;
                    });
                  }
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                child: Row(
                  children: [
                    Radio(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      groupValue: selectedType,
                      activeColor: Theme.of(context).colorScheme.fontColor,
                      value: 2,
                      onChanged: (dynamic val) {
                        if (mounted) {
                          setState(() {
                            selectedType = val;
                            type = OFFICE;
                          });
                        }
                      },
                    ),
                    Expanded(child: Text(getTranslated(context, 'OFFICE_LBL')!))
                  ],
                ),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      selectedType = 2;
                      type = OFFICE;
                    });
                  }
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                child: Row(
                  children: [
                    Radio(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      groupValue: selectedType,
                      activeColor: Theme.of(context).colorScheme.fontColor,
                      value: 3,
                      onChanged: (dynamic val) {
                        if (mounted) {
                          setState(() {
                            selectedType = val;
                            type = OTHER;
                          });
                        }
                      },
                    ),
                    Expanded(child: Text(getTranslated(context, 'OTHER_LBL')!))
                  ],
                ),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      selectedType = 3;
                      type = OTHER;
                    });
                  }
                },
              ),
            )
          ],
        ));
  }

  defaultAdd() {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: SwitchListTile(
          value: checkedDefault,
          activeColor: Theme.of(context).accentColor,
          dense: true,
          onChanged: (newValue) {
            if (mounted) {
              setState(() {
                checkedDefault = newValue;
              });
            }
          },
          title: Text(
            getTranslated(context, 'DEFAULT_ADD')!,
            style: Theme.of(context).textTheme.subtitle2!.copyWith(
                color: Theme.of(context).colorScheme.lightBlack,
                fontWeight: FontWeight.bold),
          ),
        ));
  }

  _showContent() {
    return Stack(
      children: [
        Form(
            key: _formkey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Column(
                        children: <Widget>[
                          setUserName(),
                          setMobileNo(),

                          setAddress1(),
                          setAddres2(),
                          setcityField(),
                          setAreaField(),
                          //setStateField(),
                          setCountry(),
                          typeOfAddress(),
                          defaultAdd(),
                          // addBtn(),
                        ],
                      ),
                    ),
                  ),
                ),
                saveButton(getTranslated(context, 'SAVE_LBL')!, () {
                  validateAndSubmit();
                }),
              ],
            )),
        showCircularProgress(_isProgress, colors.primary)
      ],
    );
  }

  // Future<void> getCurrentLoc() async {
  //   final locationStatus = await Permission.location.request();
  //   if (locationStatus == PermissionStatus.granted) {
  //     Position position = await Geolocator.getCurrentPosition(
  //         desiredAccuracy: LocationAccuracy.high);
  //     latitude = position.latitude.toString();
  //     longitude = position.longitude.toString();

  //     List<Placemark> placemark = await placemarkFromCoordinates(
  //         double.parse(latitude!), double.parse(longitude!),
  //         localeIdentifier: "en");

  //     state = placemark[0].administrativeArea;
  //     country = placemark[0].country;
  //     // pincode = placemark[0].postalCode;
  //     // address = placemark[0].name;
  //     if (mounted) {
  //       setState(() {
  //         countryC!.text = country!;
  //         //stateC!.text = state!;
  //         // pincodeC!.text = pincode!;
  //         // addressC!.text = address!;
  //       });
  //     }
  //   } else if (locationStatus == PermissionStatus.permanentlyDenied ||
  //       locationStatus == PermissionStatus.denied) {
  //     await Permission.location.request();
  //   } else {
  //     openAppSettings();
  //   }
  // }

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
}
