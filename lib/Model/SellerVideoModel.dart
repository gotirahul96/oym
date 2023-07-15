class SellerVideoModel {
  String? videoLink;
  List<Data>? data;
  String? error;
  String? message;

  SellerVideoModel({this.videoLink, this.data, this.error, this.message});

  SellerVideoModel.fromJson(Map<String, dynamic> json) {
    videoLink = json['videoLink'] != null ? json['videoLink'] : '';
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
    data['videoLink'] = this.videoLink;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['error'] = this.error;
    data['message'] = this.message;
    return data;
  }
}

class Data {
  String? businessName;
  String? businessState;
  String? businessProfile;

  Data({this.businessName, this.businessState, this.businessProfile});

  Data.fromJson(Map<String, dynamic> json) {
    businessName = json['businessName'];
    businessState = json['businessState'];
    businessProfile = json['businessProfile'] != null ? json['businessProfile'] : '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['businessName'] = this.businessName;
    data['businessState'] = this.businessState;
    data['businessProfile'] = this.businessProfile;
    return data;
  }
}