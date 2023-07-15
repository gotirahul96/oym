class HomePageListModel {
  List<HomePageListData>? data;
  String? error;
  String? message;

  HomePageListModel({this.data, this.error, this.message});

  HomePageListModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <HomePageListData>[];
      json['data'].forEach((v) {
        data!.add(new HomePageListData.fromJson(v));
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

class HomePageListData {
  String? categoryName2;
  String? title;
  List<Product>? product;

  HomePageListData({this.categoryName2, this.title, this.product});

  HomePageListData.fromJson(Map<String, dynamic> json) {
    categoryName2 = json['categoryName2'] != null ? json['categoryName2'] : '';
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
    data['categoryName2'] = this.categoryName2;
    data['title'] = this.title;
    if (this.product != null) {
      data['product'] = this.product!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Product {
  String? category3;
  String? image1;
  String? discount;

  Product({this.category3, this.image1, this.discount});

  Product.fromJson(Map<String, dynamic> json) {
    category3 = json['category3'];
    image1 = json['image1'];
    discount = json['discount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['category3'] = this.category3;
    data['image1'] = this.image1;
    data['discount'] = this.discount;
    return data;
  }
}