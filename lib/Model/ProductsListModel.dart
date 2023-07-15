


class ProductListModel {
  List<ProductListData>? data;
  List<String>? brand;
  List<ColorFile>? color;
  List<String>? gender;
  String? error;
  String? message;

  ProductListModel(
      {this.data,
      this.brand,
      this.color,
      this.gender,
      this.error,
      this.message});

  ProductListModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <ProductListData>[];
      json['data'].forEach((v) {
        data!.add(new ProductListData.fromJson(v));
      });
    }
    if(json['brand'] != null)
    brand = json['brand'].cast<String>();
    if (json['color'] != null) {
      color = <ColorFile>[];
      json['color'].forEach((v) {
        color!.add(new ColorFile.fromJson(v));
      });
    }
    if(json['gender'] != null)
    gender = json['gender'].cast<String>();
    error = json['error'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['brand'] = this.brand;
    if (this.color != null) {
      data['color'] = this.color!.map((v) => v.toJson()).toList();
    }
    data['gender'] = this.gender;
    data['error'] = this.error;
    data['message'] = this.message;
    return data;
  }
}

class ProductListData {
  int? totalReviews;
  double? avgRating;
  int? wishList;
  String? soldBy;
  bool? isFavLoading;
  List<Product>? product;

  ProductListData({this.totalReviews,this.soldBy, this.avgRating, this.wishList, this.isFavLoading,this.product});

  ProductListData.fromJson(Map<String, dynamic> json) {
    totalReviews = json['totalReviews'];
    avgRating = double.parse(json['avgRating'].toString());
    wishList = json['wishList'];
    soldBy = json['soldBy'];
    isFavLoading = false;
    if (json['product'] != null) {
      product = <Product>[];
      json['product'].forEach((v) {
        product!.add(new Product.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalReviews'] = this.totalReviews;
    data['avgRating'] = this.avgRating;
    data['wishList'] = this.wishList;
    data['soldBy'] = this.soldBy;
    if (this.product != null) {
      data['product'] = this.product!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Product {
  String? sellerID;
  String? prodID;
  String? color;
  String? size;
  String? brandName;
  String? productTitle;
  String? image1;
  String? mrp;
  String? sellingPrice;

  Product(
      {this.sellerID,
      this.prodID,
      this.color,
      this.size,
      this.brandName,
      this.productTitle,
      this.image1,
      this.mrp,
      this.sellingPrice});

  Product.fromJson(Map<String, dynamic> json) {
    sellerID = json['sellerID'];
    prodID = json['prodID'];
    color = json['color'];
    size = json['size'];
    brandName = json['brandName'];
    productTitle = json['productTitle'];
    image1 = json['image1'];
    mrp = json['mrp'];
    sellingPrice = json['sellingPrice'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sellerID'] = this.sellerID;
    data['prodID'] = this.prodID;
    data['color'] = this.color;
    data['size'] = this.size;
    data['brandName'] = this.brandName;
    data['productTitle'] = this.productTitle;
    data['image1'] = this.image1;
    data['mrp'] = this.mrp;
    data['sellingPrice'] = this.sellingPrice;
    return data;
  }
}

class ColorFile {
  String? colorNM;
  String? colorCode;

  ColorFile({this.colorNM, this.colorCode});

  ColorFile.fromJson(Map<String, dynamic> json) {
    colorNM = json['colorNM'];
    colorCode = json['colorCode'] != null ? json['colorCode'] : '000000';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['colorNM'] = this.colorNM;
    data['colorCode'] = this.colorCode;
    return data;
  }
}