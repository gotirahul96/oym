class SponserBannersModel {
  List<SponserBannersData>? data;
  String? error;
  String? message;

  SponserBannersModel({this.data, this.error, this.message});

  SponserBannersModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <SponserBannersData>[];
      json['data'].forEach((v) {
        data!.add(new SponserBannersData.fromJson(v));
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

class SponserBannersData {
  String? image;
  String? storeLink;
  String? type;

  SponserBannersData({this.image, this.storeLink, this.type});

  SponserBannersData.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    storeLink = json['storeLink'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['image'] = this.image;
    data['storeLink'] = this.storeLink;
    data['type'] = this.type;
    return data;
  }
}