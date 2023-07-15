class ProductDetailModel {
  List<ProductDetailData>? data;
  String? error;
  String? message;

  ProductDetailModel({this.data, this.error, this.message});

  ProductDetailModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <ProductDetailData>[];
      json['data'].forEach((v) {
        data!.add(ProductDetailData.fromJson(v));
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

class ProductDetailData {
  int? totalReviews;
  int? reviews5;
  int? reviews4;
  int? reviews3;
  int? reviews2;
  int? reviews1;
  double? avgRating;
  int? wishList;
  bool? isFavLoading;
  String? storeLink;
  String? soldBy;
  List<String>? images;
  List<Product>? product;
  List<Specification>? specification;
  List<OtherColors>? otherColors;
  List<OtherSizes>? otherSizes;
  List<TwoReviews>? twoReviews;

  ProductDetailData(
      {this.totalReviews,
      this.reviews5,
      this.reviews4,
      this.reviews3,
      this.reviews2,
      this.reviews1,
      this.avgRating,
      this.wishList,
      this.storeLink,
      this.soldBy,
      this.images,
      this.product,
      this.twoReviews,
      this.isFavLoading,
      this.specification,
      this.otherColors,
      this.otherSizes});

  ProductDetailData.fromJson(Map<String, dynamic> json) {
    totalReviews = json['totalReviews'] != null ? json['totalReviews'] : 0;
    reviews5 = json['Reviews5'] != null ? json['Reviews5'] : 0;
    reviews4 = json['Reviews4'] != null ? json['Reviews4'] : 0;
    reviews3 = json['Reviews3'] != null ? json['Reviews3'] : 0;
    reviews2 = json['Reviews2'] != null ? json['Reviews2'] : 0;
    reviews1 = json['Reviews1'] != null ? json['Reviews1'] : 0;
    avgRating = json['avgRating'] != null ? double.parse(json['avgRating'].toString()) :  0;
    wishList = json['wishList'] != null ? json['wishList'] : 0;
    storeLink = json['storeLink'] != null ? json['storeLink'] : "";
    soldBy = json['soldBy']  != null ? json['soldBy'] : "";
    isFavLoading = false;
    images = json['images'] != null ? json['images'].cast<String>() : [];
    if (json['product'] != null) {
      product = <Product>[];
      json['product'].forEach((v) {
        product!.add(new Product.fromJson(v));
      });
    }
    if (json['twoReviews'] != null) {
      twoReviews = <TwoReviews>[];
      json['twoReviews'].forEach((v) {
        twoReviews!.add(new TwoReviews.fromJson(v));
      });
    }
    if (json['specification'] != null) {
      specification = <Specification>[];
      json['specification'].forEach((v) {
        specification!.add(new Specification.fromJson(v));
      });
    }
    else{
      specification = [];
    }
    if (json['otherColors'] != null) {
      otherColors = <OtherColors>[];
      json['otherColors'].forEach((v) {
        otherColors!.add(new OtherColors.fromJson(v));
      });
    }
    else{
      otherColors = [];
    }
    if (json['otherSizes'] != null) {
      otherSizes = <OtherSizes>[];
      json['otherSizes'].forEach((v) {
        otherSizes!.add(new OtherSizes.fromJson(v));
      });
    }
    else{
      otherSizes = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalReviews'] = this.totalReviews;
    data['Reviews5'] = this.reviews5;
    data['Reviews4'] = this.reviews4;
    data['Reviews3'] = this.reviews3;
    data['Reviews2'] = this.reviews2;
    data['Reviews1'] = this.reviews1;
    data['avgRating'] = this.avgRating;
    data['wishList'] = this.wishList;
    data['storeLink'] = this.storeLink;
    data['soldBy'] = this.soldBy;
    data['images'] = this.images;
    if (this.product != null) {
      data['product'] = this.product!.map((v) => v.toJson()).toList();
    }
    if (this.twoReviews != null) {
      data['twoReviews'] = this.twoReviews!.map((v) => v.toJson()).toList();
    }
    
    if (this.specification != null) {
      data['specification'] =
          this.specification!.map((v) => v.toJson()).toList();
    }
    if (this.otherColors != null) {
      data['otherColors'] = this.otherColors!.map((v) => v.toJson()).toList();
    }
    if (this.otherSizes != null) {
      data['otherSizes'] = this.otherSizes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Product {
  String? prodID;
  String? productTitle;
  String? brandName;
  String? stock;
  String? sKU;
  String? color;
  String? size;
  String? description;
  String? additionalInfo;
  String? minQtyBuy;
  String? maxQtyBuy;
  String? mrp;
  String? sellingPrice;
  String? shippingCharges;

  Product(
      {this.prodID,
      this.productTitle,
      this.brandName,
      this.stock,
      this.color,
      this.sKU,
      this.size,
      this.minQtyBuy,
      this.maxQtyBuy,
      this.description,
      this.additionalInfo,
      this.mrp,
      this.sellingPrice,
      this.shippingCharges});

  Product.fromJson(Map<String, dynamic> json) {
    prodID = json['prodID'] !=null ? json['prodID'] : '0';
    color = json['color'] != null ? json['color'] : '';
    size = json['size'] != null ? json['size'] : '';
    minQtyBuy = json['minQtyBuy'] != null ? json['minQtyBuy'] : '';
    maxQtyBuy = json['maxQtyBuy'] != null ? json['maxQtyBuy'] : '';
    productTitle = json['productTitle']  !=null ? json['productTitle'] : '';
    brandName = json['brandName'] !=null ? json['brandName'] : '';
    stock = json['stock'] !=null ? json['stock'] : '';
    sKU = json['SKU'] !=null ? json['SKU'] : '';
    description = json['description'] !=null ? json['description'] : '';
    additionalInfo = json['additionalInfo'] !=null ? json['additionalInfo'] : '';
    mrp = json['mrp'] !=null ? json['mrp'] : '';
    sellingPrice = json['sellingPrice'] !=null ? json['sellingPrice'] : '';
    shippingCharges = json['shippingCharges'] !=null ? json['shippingCharges'] : '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['prodID'] = this.prodID;
    data['productTitle'] = this.productTitle;
    data['brandName'] = this.brandName;
    data['stock'] = this.stock;
    data['SKU'] = this.sKU;
    data['description'] = this.description;
    data['additionalInfo'] = this.additionalInfo;
    data['mrp'] = this.mrp;
    data['sellingPrice'] = this.sellingPrice;
    data['shippingCharges'] = this.shippingCharges;
    return data;
  }
}
class TwoReviews {
  String? custName;
  String? r1;
  String? r2;
  String? r3;
  String? r4;
  String? r5;
  String? comments;
  String? reviewDate;

  TwoReviews(
      {this.custName,
      this.r1,
      this.r2,
      this.r3,
      this.r4,
      this.r5,
      this.comments,
      this.reviewDate});

  TwoReviews.fromJson(Map<String, dynamic> json) {
    custName = json['custName'] ?? '';
    r1 = json['r1'];
    r2 = json['r2'];
    r3 = json['r3'];
    r4 = json['r4'];
    r5 = json['r5'];
    comments = json['comments'];
    reviewDate = json['reviewDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['custName'] = this.custName;
    data['r1'] = this.r1;
    data['r2'] = this.r2;
    data['r3'] = this.r3;
    data['r4'] = this.r4;
    data['r5'] = this.r5;
    data['comments'] = this.comments;
    data['reviewDate'] = this.reviewDate;
    return data;
  }
}

class Specification {
  String? name;
  String? value;

  Specification({this.name, this.value});

  Specification.fromJson(Map<String, dynamic> json) {
    name = json['name'] != null ? json['name'] : '';
    value = json['value'] !=null ? json['value'] : '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['value'] = this.value;
    return data;
  }
}

class OtherColors {
  String? color;
  String? groupID;
  String? sellerID;
  String? size;
  String? image1;

  OtherColors(
      {this.color,this.groupID, this.sellerID, this.size, this.image1});

  OtherColors.fromJson(Map<String, dynamic> json) {
    color = json['color'] != null ? json['color'] : '';
    groupID = json['groupID'] != null ? json['groupID'] : '';
    sellerID = json['sellerID'] != null ? json['sellerID'] : '';
    size = json['size'] != null ? json['size'] : '';
    image1 = json['image1'] != null ? json['image1'] : '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['color'] = this.color;
    data['groupID'] = this.groupID;
    data['sellerID'] = this.sellerID;
    data['size'] = this.size;
    data['image1'] = this.image1;
    return data;
  }
}

class OtherSizes {
  String? color;
  String? groupID;
  String? sellerID;
  String? size;

  OtherSizes({this.color, this.groupID, this.sellerID, this.size});

  OtherSizes.fromJson(Map<String, dynamic> json) {
    color = json['color'] != null ? json['color'] : '';
    groupID = json['groupID'] != null ? json['groupID'] : '';
    sellerID = json['sellerID'] != null ? json['sellerID'] : '';
    size = json['size'] != null ? json['size'] : '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['color'] = this.color;
    data['groupID'] = this.groupID;
    data['sellerID'] = this.sellerID;
    data['size'] = this.size;
    return data;
  }
}