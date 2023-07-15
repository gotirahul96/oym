import 'package:oym/Model/AllCategoryModel.dart';
import 'package:flutter/cupertino.dart';

class CategoryProvider extends ChangeNotifier {
  List<SubCategoryList>? _subList = [];
  int _curCat = 0;

  get subList => _subList;

  get curCat => _curCat;

  setCurSelected(int index) {
    _curCat = index;
    notifyListeners();
  }

  setSubList(List<SubCategoryList>? subList) {
    _subList = subList;
    notifyListeners();
  }
}
