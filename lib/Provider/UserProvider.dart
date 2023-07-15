import 'package:oym/Model/Address_Model.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String _userName = '',
      _cartCount = '',
      _curBal = '',
      _mob = '',
      _profilePic = '',
      _email = '';
  int _selectedAddressIndex = 0;
  int _selAddressId = 0;
  List<AddressData> _addressList  = [];
  String?  _userId = '';
  List<String> _saleDiscountList = [];

  String? _curPincode = '';

  late SettingProvider settingsProvider;

  String get curUserName => _userName;

  List<AddressData> get addressList => _addressList;

  set setaddressList(val){
    _addressList.clear();
       _addressList = val;
       notifyListeners();
  }

  List<String> get saleDiscountList => _saleDiscountList;

  set setsaleDiscountList(List<String> val){
    _saleDiscountList.addAll(val);
  }

  int get selectedAddressIndex => _selectedAddressIndex;

  set setSelectedAddressIndex(int val){
    _selectedAddressIndex = val;
    notifyListeners();
  }

  int get selectedAddressId => _selAddressId;

  set setSelAddressId(int val){
    _selAddressId = val;
    notifyListeners();
  }

  String get curPincode => _curPincode ?? '';

  String get curCartCount => _cartCount;

  String get curBalance => _curBal;

  String get mob => _mob;

  String get profilePic => _profilePic;

  String? get userId => _userId;

  String get email => _email;

  void setPincode(String pin) {
    _curPincode = pin;
    notifyListeners();
  }

  void setCartCount(String count) {
    if (count == 'null') {
      count = '0';
    }
    _cartCount = count;
    notifyListeners();
  }

  void setBalance(String bal) {
    _curBal = bal;
    notifyListeners();
  }

  void setName(String count) {
    //settingsProvider.userName=count;
    _userName = count;
    notifyListeners();
  }

  void setMobile(String count) {
    _mob = count;
    notifyListeners();
  }

  void setProfilePic(String count) {
    _profilePic = count;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setUserId(String? count) {
    _userId = count;
  }
}
