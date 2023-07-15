class GetChecksumModel {
  int? oRDERID;
  String? cUSTID;
  //String? iNDUSTRYTYPEID;
  //String? wEBSITE;
  //String? cHANNELID;
  int? tXNAMOUNT;
  //String? cHECKSUM;
  String? error;
  String? message;

  GetChecksumModel(
      {this.oRDERID,
      this.cUSTID,
      //this.iNDUSTRYTYPEID,
      //this.wEBSITE,
      //this.cHANNELID,
      this.tXNAMOUNT,
      //this.cHECKSUM,
      this.error,
      this.message});

  GetChecksumModel.fromJson(Map<String, dynamic> json) {
    oRDERID = json['ORDER_ID'];
    cUSTID = json['CUST_ID'];
   // iNDUSTRYTYPEID = json['INDUSTRY_TYPE_ID'];
    //wEBSITE = json['WEBSITE'];
    //cHANNELID = json['CHANNEL_ID'];
    //tXNAMOUNT = json['TXN_AMOUNT'];
    //cHECKSUM = json['CHECKSUM'];
    error = json['error'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ORDER_ID'] = this.oRDERID;
    data['CUST_ID'] = this.cUSTID;
    //data['INDUSTRY_TYPE_ID'] = this.iNDUSTRYTYPEID;
    //data['WEBSITE'] = this.wEBSITE;
    //data['CHANNEL_ID'] = this.cHANNELID;
    data['TXN_AMOUNT'] = this.tXNAMOUNT;
    //data['CHECKSUM'] = this.cHECKSUM;
    data['error'] = this.error;
    data['message'] = this.message;
    return data;
  }
}