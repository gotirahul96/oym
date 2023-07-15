class SearchParameters {
  String? keyword;
  String? minimumPrice;
  String? maximumPrice;
  String? from;
  String? custid;
  String? salePercent;
  List<String>? brand;
  List<String>? gender;
  List<String>? color;
  String? startPosition;

  SearchParameters(
      {this.keyword,
      this.minimumPrice,
      this.maximumPrice,
      this.from,
      this.salePercent,
      this.brand,
      this.gender,
      this.custid,
      this.color,
      this.startPosition});

  SearchParameters.fromJson(Map<String, dynamic> json) {
    keyword = json['keyword'];
    minimumPrice = json['minimum_price'];
    maximumPrice = json['maximum_price'];
    from = json['from'];
    custid = json['custid'];
    salePercent = json['salePercent'];
    brand = json['brand'].cast<String>();
    gender = json['gender'].cast<String>();
    color = json['color'].cast<String>();
    startPosition = json['startPosition'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['keyword'] = this.keyword;
    data['minimum_price'] = this.minimumPrice;
    data['maximum_price'] = this.maximumPrice;
    data['from'] = this.from;
    data['salePercent'] = this.salePercent;
    data['brand'] = this.brand;
    data['custid'] = this.custid;
    data['gender'] = this.gender;
    data['color'] = this.color;
    data['startPosition'] = this.startPosition;
    return data;
  }
}