class HomeScreenRecommendationsModel {
  List<Data>? data;
  String? error;
  String? message;

  HomeScreenRecommendationsModel({this.data, this.error, this.message});

  HomeScreenRecommendationsModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
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

class Data {
  String? title;
  List<Product>? product;

  Data({this.title, this.product});

  Data.fromJson(Map<String, dynamic> json) {
    title = json['title'] != null ? json['title'] : '';
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
    sellerID = json['sellerID'] != null ? json['sellerID'] : '';
    prodID = json['prodID'] != null ? json['prodID'] : '';
    productTitle = json['productTitle'] != null ? json['productTitle'] : '';
    image1 = json['image1'] != null ? json['image1'] : '';
    mrp = json['mrp'] != null ? json['mrp'] : '';
    sellingPrice = json['sellingPrice'] != null ? json['sellingPrice'] : '';
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