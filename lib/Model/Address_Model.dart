

class GetAllAddressListModel {
  List<AddressData>? data;
  String? error;
  String? message;

  GetAllAddressListModel({this.data, this.error, this.message});

  GetAllAddressListModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <AddressData>[];
      json['data'].forEach((v) {
        data!.add(new AddressData.fromJson(v));
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

class AddressData {
  String? id;
  String? custID;
  String? custAlternateNM;
  String? custAlternateMobile;
  String? address;
  String? address2;
  String? cityNM;
  String? areaNM;
  String? pincode;
  String? country;
  String? setDefault;
  String? addressType;
  String? cityId;
  String? areaId;

  AddressData(
      {this.id,
      this.custID,
      this.custAlternateNM,
      this.custAlternateMobile,
      this.address,
      this.address2,
      this.cityNM,
      this.areaNM,
      this.pincode,
      this.cityId,
      this.areaId,
      this.country,
      this.addressType,
      this.setDefault});

  AddressData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    custID = json['custID'];
    custAlternateNM = json['custAlternateNM'];
    custAlternateMobile = json['custAlternateMobile'];
    address = json['address'];
    address2 = json['address2'] != null ? json['address2'] : '';
    cityNM = json['cityNM'] ?? '';
    cityId = json['cityID'] ?? '';
    areaId = json['areaID'] ?? '';
    areaNM = json['areaNM'] ?? '';
    pincode = json['pincode'] ?? '';
    country = json['country'] ?? '';
    addressType = json['addressType'] ?? '';
    setDefault = json['setDefault'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['custID'] = this.custID;
    data['custAlternateNM'] = this.custAlternateNM;
    data['custAlternateMobile'] = this.custAlternateMobile;
    data['address'] = this.address;
    data['address2'] = this.address2;
    data['cityNM'] = this.cityNM;
    data['areaNM'] = this.areaNM;
    data['pincode'] = this.pincode;
    data['country'] = this.country;
    data['setDefault'] = this.setDefault;
    return data;
  }
}