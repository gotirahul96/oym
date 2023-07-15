
class CartListModel {
  List<CartListData>? data;
  String? error;
  String? message;

  CartListModel({this.data, this.error, this.message});

  CartListModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <CartListData>[];
      json['data'].forEach((v) {
        data!.add(CartListData.fromJson(v));
      });
    }
    else {
      data = [];
    }
    error = json['error'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['error'] = this.error;
    data['message'] = this.message;
    return data;
  }
}

class CartListData {
  List<CartListProduct>? product;
  int? quantity;
  double? shippingCharges;

  CartListData({this.product, this.quantity,this.shippingCharges});

  CartListData.fromJson(Map<String, dynamic> json) {
    if (json['product'] != null) {
      product = <CartListProduct>[];
      json['product'].forEach((v) {
        product!.add(new CartListProduct.fromJson(v));
      });
    }
    shippingCharges = double.parse(json['shippingCharges']);
    quantity = int.parse(json['quantity']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.product != null) {
      data['product'] = this.product!.map((v) => v.toJson()).toList();
    }
    data['quantity'] = this.quantity;
    return data;
  }
}

class CartListProduct {
  String? prodID;
  String? productTitle;
  String? mrp;
  String? stock;
  String? minQtyBuy;
  String? maxQtyBuy;
  String? sellingPrice;
  
  String? image1;

  CartListProduct(
      {this.prodID,
      this.productTitle,
      this.mrp,
      this.stock,
      this.minQtyBuy,
      this.maxQtyBuy,
      this.sellingPrice,
      this.image1});

  CartListProduct.fromJson(Map<String, dynamic> json) {
    prodID = json['prodID'];
    productTitle = json['productTitle'];
    mrp = json['mrp'];
    stock = json['stock'];
    
    minQtyBuy = json['minQtyBuy'];
    maxQtyBuy = json['maxQtyBuy'];
    sellingPrice = json['sellingPrice'];
    image1 = json['image1'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['prodID'] = this.prodID;
    data['productTitle'] = this.productTitle;
    data['mrp'] = this.mrp;
    data['stock'] = this.stock;
    data['minQtyBuy'] = this.minQtyBuy;
    data['maxQtyBuy'] = this.maxQtyBuy;
    data['sellingPrice'] = this.sellingPrice;
    data['image1'] = this.image1;
    return data;
  }
}