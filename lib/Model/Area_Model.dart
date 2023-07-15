class AreaModel {
  List<AreaData>? data;
  String? error;
  String? message;

  AreaModel({this.data, this.error, this.message});

  AreaModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <AreaData>[];
      json['data'].forEach((v) {
        data!.add(new AreaData.fromJson(v));
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

class AreaData {
  String? areaID;
  String? areaName;

  AreaData({this.areaID, this.areaName});

  AreaData.fromJson(Map<String, dynamic> json) {
    areaID = json['areaID'];
    areaName = json['areaName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['areaID'] = this.areaID;
    data['areaName'] = this.areaName;
    return data;
  }
}
