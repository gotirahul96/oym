import 'dart:convert';

import 'package:http/http.dart';
import 'package:oym/Helper/AppBtn.dart';
import 'package:oym/Helper/Color.dart';
import 'package:oym/Helper/String.dart';
import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/AllCategoryModel.dart';
import 'package:oym/Provider/CategoryProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Helper/Session.dart';
import 'ProductList.dart';


class AllCategory extends StatefulWidget {
  AllCategory({Key? key}) : super(key: key);

  @override
  _AllCategoryState createState() => _AllCategoryState();
}

class _AllCategoryState extends State<AllCategory> with TickerProviderStateMixin {


AllCategoryModel _allCategoryModel = AllCategoryModel();
bool _isNetworkAvail = true;

Animation? buttonSqueezeanimation;
AnimationController? buttonController;


@override
  void initState() {
    super.initState();
    getAllCategory();
    buttonController = AnimationController(
        duration: Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: Interval(
        0.0,
        0.150,
      ),
    ));
  }

  @override
  void dispose() {
    
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }


 Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  
                 getAllCategory();
                } else {
                  await buttonController!.reverse();
                  if (mounted) setState(() {});
                }
              });
            },
          )
        ]),
      ),
    );
  }

getAllCategory() async {
  _isNetworkAvail = await isNetworkAvailable();
  if (_isNetworkAvail) {
    
    Response response = await post(getMainCategoryApi);

    print(response.body);
    var getData = json.decode(response.body);
    _allCategoryModel = AllCategoryModel.fromJson(getData);
    Provider.of<CategoryProvider>(context,listen: false).setSubList(_allCategoryModel.data![0].subCategory);
    //Provider<CategoryProvider>().setSubList(_allCategoryModel.data![index].subCategory);
    setState(() {
    });
    
  } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _allCategoryModel.data == null ? Container() : Row(
          children: [
            Expanded(
                flex: 1,
                child: Container(
                    color: Theme.of(context).colorScheme.gray,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      padding: EdgeInsetsDirectional.only(top: 10.0),
                      itemCount: _allCategoryModel.data!.isNotEmpty ? _allCategoryModel.data!.length : 0,
                      itemBuilder: (context, index) {
                        return catItem(index, context);
                      },
                    ))),
            Expanded(
              flex: 3,
              child:
              _allCategoryModel.data!.length > 0 ?
              Column(
                children: [
                  Selector<CategoryProvider, int>(
                    builder: (context, data, child) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(_allCategoryModel.data![data].mainCategory!+" "),
                                Expanded(
                                    child: Divider(
                                      thickness: 2,
                                    ))
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                getTranslated(context, 'All')! +
                                    " " +
                                    _allCategoryModel.data![data].mainCategory! +
                                    " ",
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                            )
                          ],
                        ),
                      );
                    },
                    selector: (_, cat) => cat.curCat,
                  ),
                  Expanded(
                      child: Selector<CategoryProvider, List<SubCategoryList>>(
                        builder: (context, data, child) {

                          return data.length > 0
                              ? GridView.count(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              childAspectRatio: .6,
                              children: List.generate(
                                data.length,
                                    (index) {
                                  return subCatItem(data[index], index, context);
                                },
                              ))
                              : Center(child: Text(getTranslated(context, 'noItem')!));
                        },
                        selector: (_, categoryProvider) => categoryProvider.subList,
                      )),
                ],
              ):Container(),
            ),
          ],
        ));
  }

  Widget catItem(int index, BuildContext context1) {


    return Selector<CategoryProvider, int>(
      builder: (context, data, child) {
       

          return GestureDetector(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: data == index ? Theme.of(context).colorScheme.white : Colors.transparent,
                  border: data == index
                      ? Border(
                    left: BorderSide(width: 5.0, color: colors.primary),
                  )
                      : null
                // borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(25.0),
                          child: FadeInImage(
                            image: NetworkImage(categoryBaseUrl + _allCategoryModel.data![index].mainImage!),
                            fadeInDuration: Duration(milliseconds: 150),
                            fit: BoxFit.fill,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                erroWidget(50),
                            placeholder: placeHolder(50),
                          )),
                    ),
                  ),
                  Text(
                    _allCategoryModel.data![index].mainCategory! + "\n",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme
                        .of(context1)
                        .textTheme
                        .caption!
                        .copyWith(
                        color:
                        data == index ? colors.primary : Theme.of(context).colorScheme.fontColor),
                  )
                ],
              ),
            ),
            onTap: () {
              context1.read<CategoryProvider>().setCurSelected(index);
              context1.read<CategoryProvider>().setSubList(_allCategoryModel.data![index].subCategory);
            },
          );
        
      },
      selector: (_, cat) => cat.curCat,
    );
  }

  subCatItem(SubCategoryList subList, int index, BuildContext context) {
    print(categoryBaseUrl + subList.coverImage!);
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child : Image.network(categoryBaseUrl + subList.coverImage!,
                errorBuilder: (_,__,___) => erroWidget(50),
                fit: BoxFit.fill,
                )
                // child: FadeInImage(
                //   image: NetworkImage(categoryBaseUrl + subList.coverImage!,),
                //   fadeInDuration: Duration(milliseconds: 150),
                //   fit: BoxFit.fill,
                //   imageErrorBuilder: (context, error, stackTrace) =>
                //       erroWidget(50),
                //   placeholder: placeHolder(50),
                // )
                ),
          ),
          Text(
            subList.categoryName! + "\n",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .caption!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          )
        ],
      ),
      onTap: () {

        Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : subList.categoryName!,
                      from: 'category',
                    ),
                  ));
      },
    );
  }

}


