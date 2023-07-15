class TagListModel {
  List<TagListData>? data;
  String? error;
  String? message;

  TagListModel({this.data, this.error, this.message});

  TagListModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data =  <TagListData>[];
      json['data'].forEach((v) {
        data!.add(new TagListData.fromJson(v));
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

class TagListData {
  String? keyword;
  bool? history;

  TagListData({this.keyword,this.history});

  TagListData.fromJson(Map<String, dynamic> json) {
    keyword = json['keywords'] != null ? json['keywords'] : '';
    history = false;
  }
  factory TagListData.history(String history) {
    return new TagListData(keyword : history, history: true);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['keywords'] = this.keyword;
    return data;
  }
}