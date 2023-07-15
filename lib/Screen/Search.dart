import 'dart:math';

import 'package:oym/Helper/oym_apiString.dart';
import 'package:oym/Model/TagListModel.dart';
import 'package:oym/Provider/SettingProvider.dart';
import 'package:oym/Provider/UserProvider.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:oym/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import 'ProductList.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class Search extends StatefulWidget {

  @override
  _SearchState createState() => _SearchState();
}

bool buildResult = false;

class _SearchState extends State<Search> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  int pos = 0;
  bool _isProgress = false;
  List<TagListData> productList = [];
  List<TextEditingController> _controllerList = [];
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;

  String query = "";
  int notificationoffset = 0;
  ScrollController? notificationcontroller;
  bool notificationisloadmore = true,
      notificationisgettingdata = false,
      notificationisnodata = false;

  late AnimationController _animationController;
  Timer? _debounce;
  List<TagListData> history = [];
  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;

  String lastStatus = '';
  String _currentLocaleId = '';
  String lastWords = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();
  late StateSetter setStater;
  ChoiceChip? tagChip;
  late UserProvider userProvider;
  List<TagListData> tagListData = [];

  @override
  void initState() {
    super.initState();

    productList.clear();

    notificationoffset = 0;
    getTags();
    

    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        if (mounted)
          setState(() {
            query = "";
          });
      } else {
        query = _controller.text;
        notificationoffset = 0;
        notificationisnodata = false;
        buildResult = false;
        if (query.trim().length > 0) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (query.trim().length > 0) {
              notificationisloadmore = true;
              notificationoffset = 0;

              getProduct();
            }
          });
        }
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );

    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = new Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController!,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  

  @override
  void dispose() {
    buttonController!.dispose();
    
    _controller.dispose();
    for (int i = 0; i < _controllerList.length; i++)
      _controllerList[i].dispose();
    _animationController.dispose();
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
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => super.widget));
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

  @override
  Widget build(BuildContext context) {

    userProvider=Provider.of<UserProvider>(context);

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: Builder(builder: (BuildContext context) {
            return Container(
              margin: EdgeInsets.all(10),
              decoration: shadow(),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4.0),
                  child:
                      Icon(Icons.arrow_back_ios_rounded, color: colors.primary),
                ),
              ),
            );
          }),
          backgroundColor: Theme.of(context).colorScheme.white,
          title: TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
              hintText: getTranslated(context, 'SEARCH_LBL'),
              hintStyle: TextStyle(color: colors.primary.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.white),
              ),
            ),
            onSubmitted: (val){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : val,
                      from: 'search',
                    ),
                  ));
            },
            // onChanged: (query) => updateSearchQuery(query),
          ),
          titleSpacing: 0,
          actions: [
            _controller.text != ""
                ? IconButton(
                    onPressed: () {
                      _controller.text = '';
                    },
                    icon: Icon(
                      Icons.close,
                      color: colors.primary,
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: colors.primary,
                    ),
                    onPressed: () {
                      lastWords = '';
                      if (!_hasSpeech)
                        initSpeechState();
                      else
                        showSpeechDialog();
                    },
                  )
          ],
        ),
        body: _isNetworkAvail
            ? Stack(
                children: <Widget>[
                  _showContent(),
                  showCircularProgress(_isProgress, colors.primary),
                ],
              )
            : noInternet(context));
  }



  void getAvailVarient(List<TagListData> tempList) {
   
    if (notificationoffset == 0) {
      productList = [];
    }

    if (notificationoffset == 0 && !buildResult) {
      TagListData element = TagListData(
          keyword: 'Search Result for "$query"',
          
          history: false);
      productList.insert(0, element);
      for (int i = 0; i < history.length; i++) {
        if (history[i].keyword == query) productList.insert(0, TagListData(keyword: history[i].keyword,history: true));
      }
    }

    productList.addAll(tempList);

    notificationisloadmore = true;
    notificationoffset = notificationoffset + perPage;
  }

  Future getTags() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
       try {
         if (notificationisloadmore) {
           if (mounted) 
             setState(() {
               notificationisloadmore = false;
               notificationisgettingdata = true;
             });
           Response response = await post(getSearchTagsApi).timeout(Duration(seconds: timeOut));
           var getdata = json.decode(response.body);
          print(response.body);
          int error = int.parse(getdata["error"]);
          String? msg = getdata["message"];
          print(getdata['data'].toString());
          if (error == 200) {
          TagListModel tagListModel = TagListModel.fromJson(getdata);
          tagListData = tagListModel.data!;
          // setState(() {
          //   tagListData = tempList!.map((element)=>element).toList();
          // });
          tagListData.forEach((element) { 
            print(element.keyword);
          });
               notificationisgettingdata = false;
          setState(() {
          });
          }
          else {
            setSnackbar(msg!);
          }
         }
       } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        if (mounted)
          setState(() {
            notificationisloadmore = false;
          });
      }
    } else {
       if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }


  Future getProduct() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (notificationisloadmore) {
          if (mounted)
            setState(() {
              notificationisloadmore = false;
              notificationisgettingdata = true;
            });

          var parameter = {
            'keyword': query.trim(),
          };
          Response response =
              await post(getSearchKeywordsApi, headers: headers, body: parameter)
                  .timeout(Duration(seconds: timeOut));
   // print("serach***$parameter***${response.body.toString()}");
          var getdata = json.decode(response.body);
          print(response.body);
          int error = int.parse(getdata["error"]);
          String? msg = getdata["message"];          

          notificationisgettingdata = false;
          
          if (error == 200) {
            if (mounted) {
              new Future.delayed(
                  Duration.zero,
                  () => setState(() {
                        
                     TagListModel tagListModel = TagListModel.fromJson(getdata);
                     List<TagListData>? mainlist = tagListModel.data;
          
                        if (mainlist!.length != 0) {
                          List<TagListData> items = [];
                          List<TagListData> allitems = [];

                          

                          allitems.addAll(mainlist);

                          getAvailVarient(allitems);
                        } else {
                          notificationisloadmore = false;
                        }
                      }));
            }
          } else {
            notificationisloadmore = false;
            if (mounted) setState(() {});
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!);
        if (mounted)
          setState(() {
            notificationisloadmore = false;
          });
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
        });
    }
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.black),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  clearAll() {
    setState(() {
      query = _controller.text;
      notificationoffset = 0;
      notificationisloadmore = true;
      productList.clear();
    });
  }

  _tags() {
 
    if (tagListData.isNotEmpty) {
      List<Widget> chips = [];
      for (int i = 0; i < tagListData.length; i++) {
        tagChip = ChoiceChip(
          selected: false,
          label: Text(tagListData[i].keyword!,
              style: TextStyle(color: Theme.of(context).colorScheme.white, fontSize: 11)),
          backgroundColor: colors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25))),
          onSelected: (bool selected) {
            if (selected) if (mounted)
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : tagListData[i].keyword,
                      from: 'search',
                    ),
                  ));
          },
        );
        chips.add(Padding(
            padding: EdgeInsets.symmetric(horizontal: 2), child: tagChip));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(),
          // tagList.length > 0
          //     ? Padding(
          //         padding: const EdgeInsetsDirectional.only(start: 8.0),
          //         child: Text('Discover more'),
          //       )
          //     : Container(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              children: chips.map<Widget>((Widget chip) {
                return Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: chip,
                );
              }).toList(),
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  _showContent() {
    if (_controller.text == "") {
      SettingProvider settingsProvider =
      Provider.of<SettingProvider>(context, listen: false);

      return FutureBuilder<List<String>>(
          future: settingsProvider.getPrefrenceList(HISTORYLIST),
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              final entities = snapshot.data!;
              List<TagListData> itemList = [];
              for (int i = 0; i < entities.length; i++) {
                TagListData item = TagListData.history(entities[i]);
                itemList.add(item);
              }
              history.clear();
              history.addAll(itemList);

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _SuggestionList(
                      textController: _controller,
                      suggestions: itemList,
                      notificationcontroller: notificationcontroller,
                      getProduct: getProduct,
                      clearAll: clearAll,
                    ),
                    _tags()
                  ],
                ),
              );
            } else {
              return Column();
            }
          });
    } else if (buildResult) {
      return notificationisnodata
          ? getNoItem(context)
          : Column(
            children: <Widget>[
              // Expanded(
              //   child: ListView.builder(
              //       padding: EdgeInsetsDirectional.only(
              //           bottom: 5, start: 10, end: 10, top: 12),
              //       controller: notificationcontroller,
              //       physics: BouncingScrollPhysics(),
              //       itemCount: productList.length,
              //       itemBuilder: (context, index) {
              //         TagListData? item;
              //         try {
              //           item =
              //               productList.isEmpty ? null : productList[index];
              //           if (notificationisloadmore &&
              //               index == (productList.length - 1) &&
              //               notificationcontroller!.position.pixels <= 0) {
              //             getProduct();
              //           }
              //         } on Exception catch (_) {}

              //         return item == null ? Container() : listItem(index);
              //       }),
              // ),
              notificationisgettingdata
                  ? Padding(
                      padding:
                          EdgeInsetsDirectional.only(top: 5, bottom: 5),
                      child: CircularProgressIndicator(),
                    )
                  : Container(),
            ],
          );
    }
    return notificationisnodata
        ? getNoItem(context)
        : Column(
          children: <Widget>[
            Expanded(
                child: _SuggestionList(
              textController: _controller,
              suggestions: productList,
              notificationcontroller: notificationcontroller,

              getProduct: getProduct,
              clearAll: clearAll,
              // onSelected: (String suggestion) {
              //   query = suggestion;
              // },
            )),
            notificationisgettingdata
                ? Padding(
                    padding: EdgeInsetsDirectional.only(top: 5, bottom: 5),
                    child: CircularProgressIndicator(),
                  )
                : Container(),
          ],
        );
  }

  Future<void> initSpeechState() async {

    PermissionStatus speechPermission = await Permission.microphone.request();

    if (speechPermission == PermissionStatus.granted) {
    var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: false,
        finalTimeout: Duration(milliseconds: 0));
    if (hasSpeech) {
      _localeNames = await speech.locales();

      var systemLocale = await speech.systemLocale();
      _currentLocaleId = systemLocale?.localeId ?? '';
    }

    if (!mounted) return;

    setState(() {
      _hasSpeech = hasSpeech;
    });
    if (hasSpeech) showSpeechDialog();
    }
    else  if(speechPermission == PermissionStatus.denied){
      await Permission.microphone.request();
    }
    else {
      openAppSettings();
    }
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      // lastError = '${error.errorMsg} - ${error.permanent}';
      setSnackbar(error.errorMsg);
    });
  }

  void statusListener(String status) {
   
    setStater(() {
      lastStatus = '$status';
    });
  }

  void startListening() {
    lastWords = '';
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5),
        partialResults: true,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.confirmation);
    setStater(() {});
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
   
    setStater(() {
      this.level = level;
    });
  }

  void stopListening() {
    speech.stop();
    setStater(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    speech.cancel();
    setStater(() {
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
  
    setStater(() {
      lastWords = '${result.recognizedWords}';
      query = lastWords;
    });

    if (result.finalResult) {
      Future.delayed(Duration(seconds: 1)).then((_) async {
        clearAll();

        _controller.text = lastWords;
        _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length));

        setState(() {});
        Navigator.of(context).pop();
      });
    }
  }

  showSpeechDialog() {
    return dialogAnimate(context, StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater1) {
            setStater = setStater1;
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.lightWhite,
              title: Text(
                'Search for desired product',
                style: Theme.of(context).textTheme.subtitle1,
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            blurRadius: .26,
                            spreadRadius: level * 1.5,
                            color: Theme.of(context).colorScheme.black.withOpacity(.05))
                      ],
                      color: Theme.of(context).colorScheme.white,
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: IconButton(
                        icon: Icon(
                          Icons.mic,
                          color: colors.primary,
                        ),
                        onPressed: () {
                          if (!_hasSpeech)
                            initSpeechState();
                          else
                            !_hasSpeech || speech.isListening
                                ? null
                                : startListening();
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(lastWords),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    color: Theme.of(context).colorScheme.fontColor.withOpacity(0.1),
                    child: Center(
                      child: speech.isListening
                          ? Text(
                              "I'm listening...",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2!
                                  .copyWith(
                                      color: Theme.of(context).colorScheme.fontColor,
                                      fontWeight: FontWeight.bold),
                            )
                          : Text(
                              'Not listening',
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2!
                                  .copyWith(
                                      color: Theme.of(context).colorScheme.fontColor,
                                      fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          }));
        
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList(
      {this.suggestions,
      this.textController,
      this.searchDelegate,

      this.notificationcontroller,
      this.getProduct,
      this.clearAll});
  final List<TagListData>? suggestions;
  final TextEditingController? textController;

  final notificationcontroller;
  final SearchDelegate<TagListData>? searchDelegate;
  final Function?  getProduct, clearAll;
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: suggestions!.length,
      shrinkWrap: true,
      controller: notificationcontroller,
      separatorBuilder: (BuildContext context, int index) => Divider(),
      itemBuilder: (BuildContext context, int i) {
        final TagListData suggestion = suggestions![i];

        return ListTile(
            title: Text(
              suggestion.keyword!,
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  color: Theme.of(context).colorScheme.lightBlack, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            leading: textController!.text.toString().trim().isEmpty ||
                    suggestion.history!
                ? Icon(Icons.history)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(7.0),
                    child: Image.asset(
                            'assets/images/placeholder.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )),
            trailing: Icon(
              Icons.reply,
            ),
            onTap: () async {
              if (suggestion.keyword!.startsWith('Search Result for ')) {

                SettingProvider settingsProvider =
                Provider.of<SettingProvider>(context, listen: false);

                settingsProvider. setPrefrenceList(
                    HISTORYLIST, textController!.text.toString().trim());
             
                buildResult = true;
                clearAll!();
                getProduct!();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : suggestion.keyword!.replaceAll('Search Result for ', ""),
                      from: 'search',
                    ),
                  ));
              } else if (suggestion.history!) {
                clearAll!();

                buildResult = true;
                textController!.text = suggestion.keyword!;
                textController!.selection = TextSelection.fromPosition(
                    TextPosition(offset: textController!.text.length));
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : suggestion.keyword,
                      from: 'search',
                    ),
                  ));
                    
              } else {
                SettingProvider settingsProvider =
                Provider.of<SettingProvider>(context, listen: false);

                settingsProvider.setPrefrenceList(
                    HISTORYLIST, textController!.text.toString().trim());
                buildResult = false;
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(
                      keyword : suggestion.keyword,
                      from: 'search',
                    ),
                  ));
              }
            });
      },
    );
  }
}
