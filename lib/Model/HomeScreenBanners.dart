class HomeScreenBanners {
  List<HomeScreenBannersData>? data;
  String? error;
  String? message;

  HomeScreenBanners({this.data, this.error, this.message});

  HomeScreenBanners.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <HomeScreenBannersData>[];
      json['data'].forEach((v) {
        data!.add(new HomeScreenBannersData.fromJson(v));
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

class HomeScreenBannersData {
  String? imageNM;
  String? type;
  String? keywordLink;

  HomeScreenBannersData({this.imageNM, this.type, this.keywordLink});

  HomeScreenBannersData.fromJson(Map<String, dynamic> json) {
    imageNM = json['imageNM'];
    type = json['type'];
    keywordLink = json['keywordLink'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imageNM'] = this.imageNM;
    data['type'] = this.type;
    data['keywordLink'] = this.keywordLink;
    return data;
  }
}