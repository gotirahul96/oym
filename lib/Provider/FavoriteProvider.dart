import 'package:oym/Model/ProductsListModel.dart';
import 'package:oym/Model/Section_Model.dart';
import 'package:flutter/cupertino.dart';

class FavoriteProvider extends ChangeNotifier {
  List<ProductListData> _favList = [];
  //List<String?> _favIdList = [];
  bool _isLoading = true;

  get isLoading => _isLoading;

  get favList => _favList;

  get favIdList => _favList.map((fav) => fav.product![0].prodID).toList();

  setFavID() {
   return _favList.map((fav) => fav.product![0].prodID).toList();
    //notifyListeners();
  }

  setLoading(bool isloading) {
    _isLoading = isloading;
    notifyListeners();
  }

  removeFavItem(String id) {
    _favList.removeWhere((item) => item.product![0].prodID == id);
    notifyListeners();
  }
  addFavItem(ProductListData? item){
    if(item!=null) {
      _favList.add(item);
      notifyListeners();
    }
  }

  setFavlist(List<ProductListData> favList) {
    _favList.clear();
    _favList.addAll(favList);
    notifyListeners();
  }
}
