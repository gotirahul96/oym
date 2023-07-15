class AllCategoryModel {
  List<AllCategoryData>? data;
  String? error;
  String? message;

  AllCategoryModel({this.data, this.error, this.message});

  AllCategoryModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <AllCategoryData>[];
      json['data'].forEach((v) {
        data!.add(new AllCategoryData.fromJson(v));
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

class AllCategoryData {
  String? mainCategory;
  String? mainImage;
  List<SubCategoryList>? subCategory;

  AllCategoryData({this.mainCategory, this.mainImage, this.subCategory});

  AllCategoryData.fromJson(Map<String, dynamic> json) {
    mainCategory = json['mainCategory'] ;
    mainImage = json['mainImage'] != null ? json['mainImage'] : '';
    if (json['subCategory'] != null) {
      subCategory = <SubCategoryList>[];
      json['subCategory'].forEach((v) {
        subCategory!.add(new SubCategoryList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mainCategory'] = this.mainCategory;
    data['mainImage'] = this.mainImage;
    if (this.subCategory != null) {
      data['subCategory'] = this.subCategory!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubCategoryList {
  String? categoryName;
  String? coverImage;

  SubCategoryList({this.categoryName, this.coverImage});

  SubCategoryList.fromJson(Map<String, dynamic> json) {
    categoryName = json['categoryName'] != null ? json['categoryName'] : '';
    coverImage = json['coverImage'] != null ? json['coverImage'] : '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['categoryName'] = this.categoryName;
    data['coverImage'] = this.coverImage;
    return data;
  }
}