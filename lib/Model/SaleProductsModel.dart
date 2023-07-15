class SaleProductsModel {
  List<SaleProductsData>? data;
  String? error;
  String? message;

  SaleProductsModel({this.data, this.error, this.message});

  SaleProductsModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <SaleProductsData>[];
      json['data'].forEach((v) {
        data!.add(new SaleProductsData.fromJson(v));
      });
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

class SaleProductsData {
  String? title;
  String? subtitle;
  List<Product>? product = [];

  SaleProductsData({this.title, this.subtitle, this.product});

  SaleProductsData.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    subtitle = json['subtitle'];
    if (json['product'] != null) {
      product = <Product>[];
      json['product'].forEach((v) {
        product!.add(new Product.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['subtitle'] = this.subtitle;
    if (this.product != null) {
      data['product'] = this.product!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Product {
  String? sellerID;
  String? prodID;
  String? productTitle;
  String? image1;
  String? mrp;
  String? sellingPrice;

  Product(
      {this.sellerID,
      this.prodID,
      this.productTitle,
      this.image1,
      this.mrp,
      this.sellingPrice});

  Product.fromJson(Map<String, dynamic> json) {
    sellerID = json['sellerID'];
    prodID = json['prodID'];
    productTitle = json['productTitle'];
    image1 = json['image1'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sellerID'] = this.sellerID;
    data['prodID'] = this.prodID;
    data['productTitle'] = this.productTitle;
    data['image1'] = this.image1;
    data['mrp'] = this.mrp;
    data['sellingPrice'] = this.sellingPrice;
    return data;
  }
}