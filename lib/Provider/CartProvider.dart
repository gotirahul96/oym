import 'dart:math';

import 'package:oym/Model/CartListModel.dart';
import 'package:oym/Model/Section_Model.dart';
import 'package:flutter/material.dart';
// extension Ex on double {
//   double toPrecision(int n) => double.parse(toStringAsFixed(n));
// }
extension Precision on double {
  double toPrecision(int fractionDigits) {
    var mod = pow(10, fractionDigits.toDouble()).toDouble();
    return ((this * mod).round().toDouble() / mod);
  }
}
class CartProvider extends ChangeNotifier {
  List<CartListData> _cartList = [];
  double? _allTotal = 0;
  double? _totalDeliveryCharge = 0;
  double? _totalwithquanity = 0;

  List<CartListData> get cartList => _cartList;
   
  double get allTotal => _allTotal!;

  double get totalDeliveryCharge => _totalDeliveryCharge!;

  double get totalWithQuantity => _totalwithquanity!;

  set deliveryCharge(double val){
     _totalDeliveryCharge = val;
  }

  bool _isProgress = false;

  get cartIdList => _cartList.map((fav) => fav.product![0].prodID).toList();

  get qtyList => _cartList.map((fav) => fav.quantity).toList();

  get isProgress => _isProgress;

  setProgress(bool progress) {
    _isProgress = progress;
    notifyListeners();
  }

  removeCartItem(String id) {
    _cartList.removeWhere((item) => item.product![0].prodID == id);
    _allTotal = 0;
    
    calculateTotal();
    notifyListeners();
  }

  removeQuantity(String id){
    _cartList.forEach((element) { 
      if (element.product![0].prodID == id) {
        element.quantity = element.quantity! - 1;
      }
    });
    _allTotal = 0;
    calculateTotal();
    notifyListeners();
  }

  addQuantity(String id){
    _cartList.forEach((element) { 
      if (element.product![0].prodID == id) {
        element.quantity = element.quantity! + 1;
      }
    });
    _allTotal = 0;
    calculateTotal();
    notifyListeners();
  }

  calculateWithWallet({int? walletAmount,bool? walletused}){
      _allTotal = walletused! ? _allTotal! - walletAmount! : _allTotal! + walletAmount!; 
  }
  
  calculateTotal(){
    _totalDeliveryCharge = 0;
    _cartList.forEach((item){
       _totalwithquanity = item.quantity! * double.parse(item.product![0].sellingPrice!).toPrecision(3);
      double totalWithShipping = (_totalwithquanity! + item.shippingCharges!).toPrecision(3);
      _allTotal = _allTotal! + totalWithShipping;
      print(item.shippingCharges!);
      _totalDeliveryCharge = _totalDeliveryCharge! + item.shippingCharges!;
    });
    notifyListeners();
  }
  
  addCartItem(CartListData? item) {
    if (item != null) {
      _cartList.add(item);
      notifyListeners();
    }
  }

  setCartlist(List<CartListData> cartList) {
    _cartList.clear();
    _allTotal = 0;
    _cartList.addAll(cartList);
    calculateTotal();
    notifyListeners();
  }
}
