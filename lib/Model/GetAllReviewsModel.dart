class GetAllReviewsModel {
  List<GroupReview>? groupReview;
  List<GetAllReviewsData>? data;
  String? error;
  String? message;

  GetAllReviewsModel({this.groupReview, this.data, this.error, this.message});

  GetAllReviewsModel.fromJson(Map<String, dynamic> json) {
    if (json['groupReview'] != null) {
      groupReview = <GroupReview>[];
      json['groupReview'].forEach((v) {
        groupReview!.add(new GroupReview.fromJson(v));
      });
    }
    if (json['data'] != null) {
      data = <GetAllReviewsData>[];
      json['data'].forEach((v) {
        data!.add(new GetAllReviewsData.fromJson(v));
      });
    }
    error = json['error'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.groupReview != null) {
      data['groupReview'] = this.groupReview!.map((v) => v.toJson()).toList();
    }
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['error'] = this.error;
    data['message'] = this.message;
    return data;
  }
}

class GroupReview {
  String? purchased;
  int? reviews5;
  int? reviews4;
  int? reviews3;
  int? reviews2;
  int? reviews1;
  double? avgRating;
  int? totalReviews;

  GroupReview(
      {this.purchased,
      this.reviews5,
      this.reviews4,
      this.reviews3,
      this.reviews2,
      this.reviews1,
      this.avgRating,
      this.totalReviews});

  GroupReview.fromJson(Map<String, dynamic> json) {
    purchased = json['purchased'];
    reviews5 = json['Reviews5'];
    reviews4 = json['Reviews4'];
    reviews3 = json['Reviews3'];
    reviews2 = json['Reviews2'];
    reviews1 = json['Reviews1'];
    avgRating = double.parse(json['avgRating'].toString());
    totalReviews = json['totalReviews'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['purchased'] = this.purchased;
    data['Reviews5'] = this.reviews5;
    data['Reviews4'] = this.reviews4;
    data['Reviews3'] = this.reviews3;
    data['Reviews2'] = this.reviews2;
    data['Reviews1'] = this.reviews1;
    data['avgRating'] = this.avgRating;
    data['totalReviews'] = this.totalReviews;
    return data;
  }
}

class GetAllReviewsData {
  List<Review>? review;
  List<String>? images;

  GetAllReviewsData({this.review, this.images});

  GetAllReviewsData.fromJson(Map<String, dynamic> json) {
    if (json['review'] != null) {
      review = <Review>[];
      json['review'].forEach((v) {
        review!.add(new Review.fromJson(v));
      });
    }
    images = json['images'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.review != null) {
      data['review'] = this.review!.map((v) => v.toJson()).toList();
    }
    data['images'] = this.images;
    return data;
  }
}

class Review {
  String? id;
  String? custName;
  String? comments;
  String? r1;
  String? r2;
  String? r3;
  String? r4;
  String? r5;
  String? reviewDate;

  Review(
      {this.id,
      this.custName,
      this.comments,
      this.r1,
      this.r2,
      this.r3,
      this.r4,
      this.r5,
      this.reviewDate});

  Review.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    custName = json['custName'];
    comments = json['comments'];
    r1 = json['r1'];
    r2 = json['r2'];
    r3 = json['r3'];
    r4 = json['r4'];
    r5 = json['r5'];
    reviewDate = json['reviewDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['custName'] = this.custName;
    data['comments'] = this.comments;
    data['r1'] = this.r1;
    data['r2'] = this.r2;
    data['r3'] = this.r3;
    data['r4'] = this.r4;
    data['r5'] = this.r5;
    data['reviewDate'] = this.reviewDate;
    return data;
  }
}