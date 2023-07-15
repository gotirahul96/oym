class WalletModel {
  List<WalletData>? data;
  int? walletAmount;
  String? error;
  String? message;

  WalletModel({this.data, this.walletAmount, this.error, this.message});

  WalletModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <WalletData>[];
      json['data'].forEach((v) {
        data!.add(new WalletData.fromJson(v));
      });
    }
    walletAmount = json['walletAmount'];
    error = json['error'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['walletAmount'] = this.walletAmount;
    data['error'] = this.error;
    data['message'] = this.message;
    return data;
  }
}

class WalletData {
  String? transactionDate;
  String? transactionID;
  String? description;
  String? transactionType;
  String? amount;

  WalletData(
      {this.transactionDate,
      this.description,
      this.transactionType,
      this.transactionID,
      this.amount});

  WalletData.fromJson(Map<String, dynamic> json) {
    transactionDate = json['transactionDate'];
    description = json['description'];
    transactionID = json['transactionID'];
    transactionType = json['transactionType'];
    amount = json['amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['transactionDate'] = this.transactionDate;
    data['description'] = this.description;
    data['transactionType'] = this.transactionType;
    data['amount'] = this.amount;
    return data;
  }
}