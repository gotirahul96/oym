class OrderListModel {
  List<OrderListData>? data;
  String? error;
  String? message;

  OrderListModel({this.data, this.error, this.message});

  OrderListModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <OrderListData>[];
      json['data'].forEach((v) {
        data!.add( OrderListData.fromJson(v));
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

class OrderListData {
  String? returnable;
  String? cancellable;
  String? reviewed;
  String? totalCostwithShipping;
  String? totalCostwithoutShipping;
  List<OrderDetails>? orderDetail;
  List<ProductDetail>? productDetail;
  List<ShippingAddress>? shippingAddress;

  OrderListData({this.orderDetail,this.cancellable,this.returnable, this.productDetail, this.shippingAddress});
  
  
  OrderListData.fromJson(Map<String, dynamic> json) {

   returnable = json['returnable'];
   cancellable = json['cancellable'];
   reviewed = json['reviewed'];
   totalCostwithShipping = json['totalCostWithShipping'];
   totalCostwithoutShipping = json['totalCostWithOutShipping'];
  //  returnable = '1';
  //  cancellable = '1';
    if (json['orderDetail'] != null) {
      orderDetail = <OrderDetails>[];
      json['orderDetail'].forEach((v) {
        orderDetail!.add(new OrderDetails.fromJson(v));
      });
    }
    if (json['productDetail'] != null) {
      productDetail = <ProductDetail>[];
      json['productDetail'].forEach((v) {
        productDetail!.add(new ProductDetail.fromJson(v));
      });
    }
    if (json['shippingAddress'] != null) {
      shippingAddress = <ShippingAddress>[];
      json['shippingAddress'].forEach((v) {
        shippingAddress!.add(new ShippingAddress.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.orderDetail != null) {
      data['orderDetail'] = this.orderDetail!.map((v) => v.toJson()).toList();
    }
    if (this.productDetail != null) {
      data['productDetail'] =
          this.productDetail!.map((v) => v.toJson()).toList();
    }
    if (this.shippingAddress != null) {
      data['shippingAddress'] =
          this.shippingAddress!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class OrderDetails {
  String? orderID;
  String? orderDate;
  String? userOrderID;
  String? qty;
  String? amt;
  String? shippingCharges;
  String? orderProcessDate;
  String? orderShippedDate;
  String? orderDeliveredDate;
  String? orderCancelReturnDate;
  String? productID;
  String? sellerID;
  String? buyerReturnID;
  String? deliveryStatus;
  String? invoiceFile;

  OrderDetails(
      {this.orderID,
      this.orderDate,
      this.userOrderID,
      this.qty,
      this.amt,
      this.orderProcessDate,
      this.shippingCharges,
      this.orderShippedDate,
      this.orderDeliveredDate,
      this.orderCancelReturnDate,
      this.productID,
      this.sellerID,
      this.buyerReturnID,
      this.deliveryStatus,
      this.invoiceFile});

  OrderDetails.fromJson(Map<String, dynamic> json) {
    orderID = json['orderID'];
    orderDate = json['orderDate'] != null ? json['orderDate'] : '';
    userOrderID = json['userOrderID'];
    qty = json['qty'];
    amt = json['amt'];
    orderProcessDate = json['orderProcessDate'] != null ? json['orderProcessDate'] : ''; 
    orderShippedDate = json['orderShippedDate'] != null ? json['orderShippedDate'] : '';
    orderDeliveredDate = json['orderDeliveredDate'] != null ? json['orderDeliveredDate'] : '';
    orderCancelReturnDate = json['orderCancelReturnDate'] != null ? json['orderCancelReturnDate'] : '';
    shippingCharges = json['shippingCharges'];
    productID = json['productID'];
    sellerID = json['sellerID'];
    buyerReturnID = json['buyerReturnID'];
    deliveryStatus = json['deliveryStatus'];
    invoiceFile = json['invoice'] != null ? json['invoice'] : '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['orderID'] = this.orderID;
    data['orderDate'] = this.orderDate;
    data['userOrderID'] = this.userOrderID;
    data['qty'] = this.qty;
    data['amt'] = this.amt;
    data['shippingCharges'] = this.shippingCharges;
    data['productID'] = this.productID;
    data['sellerID'] = this.sellerID;
    data['buyerReturnID'] = this.buyerReturnID;
    data['deliveryStatus'] = this.deliveryStatus;
    data['invoiceFile'] = this.invoiceFile;
    return data;
  }
}

class ProductDetail {
  String? productTitle;
  String? color;
  String? size;
  String? brandName;
  String? sKU;
  String? image1;

  ProductDetail(
      {this.productTitle,
      this.color,
      this.size,
      this.brandName,
      this.sKU,
      this.image1});

  ProductDetail.fromJson(Map<String, dynamic> json) {
    productTitle = json['productTitle'];
    color = json['color'];
    size = json['size'];
    brandName = json['brandName'];
    sKU = json['SKU'];
    image1 = json['image1'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['productTitle'] = this.productTitle;
    data['color'] = this.color;
    data['size'] = this.size;
    data['brandName'] = this.brandName;
    data['SKU'] = this.sKU;
    data['image1'] = this.image1;
    return data;
  }
}

class ShippingAddress {
  String? address;
  String? address2;
  String? cityNM;
  String? stateNM;
  String? pincode;
  String? custName;
  String? mobile;

  ShippingAddress(
      {this.address,this.custName, this.address2, this.cityNM, this.stateNM, this.pincode});

  ShippingAddress.fromJson(Map<String, dynamic> json) {
    address = json['address'] != null ? json['address'] : '';
    address2 = json['address2'] != null ? json['address2'] : '';
    cityNM = json['cityNM'] != null ? json['cityNM'] : '';
    mobile = json['mobile'] != null ? json['mobile'] : '';
    custName = json['custName'] != null ? json['custName'] : '';
    stateNM = json['stateNM'] != null ? json['stateNM'] : '';
    pincode = json['pincode'] != null ? json['pincode'] : '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['address'] = this.address;
    data['address2'] = this.address2;
    data['cityNM'] = this.cityNM;
    data['stateNM'] = this.stateNM;
    data['pincode'] = this.pincode;
    return data;
  }
}