class CityModel {
  List<CityListData>? data;
  String? error;
  String? message;

  CityModel({this.data, this.error, this.message});

  CityModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <CityListData>[];
      json['data'].forEach((v) {
        data!.add(new CityListData.fromJson(v));
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

class CityListData {
  String? id;
  String? cityName;

  CityListData({this.id, this.cityName});

  CityListData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cityName = json['cityName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['cityName'] = this.cityName;
    return data;
  }
}
