import 'dart:async';
import 'package:Prism/data/favourites/provider/favouriteProvider.dart';
import 'package:provider/provider.dart';
import 'package:Prism/main.dart' as main;
import 'package:Prism/theme/jam_icons_icons.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:Prism/analytics/analytics_service.dart';
import 'package:Prism/routes/routing_constants.dart';
import 'package:Prism/theme/themeModel.dart';
import 'package:Prism/ui/widgets/popup/changelogPopUp.dart';
import 'package:Prism/ui/widgets/popup/signInPopUp.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Prism/global/globals.dart' as globals;
import 'package:Prism/theme/toasts.dart' as toasts;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final List<String> supportPurchase = ['support', 'support_more', 'support_max'];

class SettingsList extends StatefulWidget {
  @override
  _SettingsListState createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  InAppPurchaseConnection _iap = InAppPurchaseConnection.instance;
  bool _available = true;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  StreamSubscription _subscription;
  @override
  void initState() {
    _initialize();
    super.initState();
  }

  void _initialize() async {
    _available = await _iap.isAvailable();
    if (_available) {
      List<Future> futures = [_getProducts(), _getPastPurchases()];
      await Future.wait(futures);
      _subscription = _iap.purchaseUpdatedStream.listen(
        (data) => setState(
          () {
            _purchases.addAll(data);
            _verifyPurchase(data[data.length - 1].productID);
          },
        ),
      );
    }
  }

  void onSupport(BuildContext context) async {
    showDialog(
      context: context,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        content: Container(
          height: 200,
          width: 250,
          child: Center(
            child: ListView.builder(
                itemCount: 3,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      index == 0
                          ? JamIcons.coffee
                          : index == 1 ? Icons.fastfood : JamIcons.pizza_slice,
                      color: Theme.of(context).accentColor,
                    ),
                    title: Text(
                      index == 0 ? "Tea" : index == 1 ? "Burger" : "Pan Pizza",
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    onTap: index == 0
                        ? () async {
                            HapticFeedback.vibrate();
                            Navigator.of(context).pop();
                            _buyProduct(_products.firstWhere(
                                (element) => element.id == 'support'));
                          }
                        : index == 1
                            ? () async {
                                HapticFeedback.vibrate();
                                Navigator.of(context).pop();
                                _buyProduct(_products.firstWhere(
                                    (element) => element.id == 'support_more'));
                              }
                            : () async {
                                HapticFeedback.vibrate();
                                Navigator.of(context).pop();
                                _buyProduct(_products.firstWhere(
                                    (element) => element.id == 'support_max'));
                              },
                  );
                }),
          ),
        ),
      ),
    );
  }

  Future<void> _getProducts() async {
    Set<String> ids = Set.from(supportPurchase);
    ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    setState(() {
      _products = response.productDetails;
    });
  }

  Future<void> _getPastPurchases() async {
    QueryPurchaseDetailsResponse response = await _iap.queryPastPurchases();
    setState(() {
      _purchases = response.pastPurchases;
    });
  }

  PurchaseDetails _hasPurchased(String productID) {
    return _purchases.firstWhere((purchase) => purchase.productID == productID,
        orElse: () => null);
  }

  void _verifyPurchase(String productID) {
    PurchaseDetails purchase = _hasPurchased(productID);
    if (purchase != null) {
      if (purchase.status == PurchaseStatus.purchased) {
        toasts.supportSuccess();
      }
    } else {
      toasts.error("Invalid Purchase!");
    }
  }

  void _buyProduct(ProductDetails prod) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
    _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            'Downloads',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        ListTile(
          onTap: () {
            if (!main.prefs.getBool("isLoggedin")) {
              googleSignInPopUp(context, () {
                Navigator.pushNamed(context, DownloadRoute);
              });
            } else {
              Navigator.pushNamed(context, DownloadRoute);
            }
          },
          leading: Icon(JamIcons.download),
          title: Text(
            "My Downloads",
            style: TextStyle(
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.w500,
                fontFamily: "Proxima Nova"),
          ),
          subtitle: Text(
            "See all your downloaded wallpapers",
            style: TextStyle(fontSize: 12),
          ),
          trailing: Icon(JamIcons.chevron_right),
        ),
        main.prefs.getBool("isLoggedin")
            ? ListTile(
                leading: Icon(
                  JamIcons.database,
                ),
                title: new Text(
                  "Clear Downloads",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Proxima Nova"),
                ),
                subtitle: Text(
                  "Clear downloaded wallpapers",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  showDialog(
                    context: context,
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      content: Container(
                        height: 50,
                        width: 250,
                        child: Center(
                          child: Text(
                            "Do you want remove all your downloads?",
                            style: Theme.of(context).textTheme.headline4,
                          ),
                        ),
                      ),
                      actions: <Widget>[
                        FlatButton(
                          shape: StadiumBorder(),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final dir = Directory("storage/emulated/0/Prism/");
                            var status = await Permission.storage.status;
                            if (!status.isGranted) {
                              await Permission.storage.request();
                            }
                            try {
                              dir.deleteSync(recursive: true);
                              Fluttertoast.showToast(
                                  msg: "Deleted all downloads!",
                                  toastLength: Toast.LENGTH_LONG,
                                  timeInSecForIosWeb: 1,
                                  textColor: Colors.white,
                                  backgroundColor: Colors.green[400],
                                  fontSize: 16.0);
                            } catch (e) {
                              Fluttertoast.showToast(
                                  msg: "No downloads!",
                                  toastLength: Toast.LENGTH_LONG,
                                  timeInSecForIosWeb: 1,
                                  textColor: Colors.white,
                                  backgroundColor: Colors.red[400],
                                  fontSize: 16.0);
                            }
                          },
                          child: Text(
                            'YES',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Color(0xFFE57697),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FlatButton(
                            shape: StadiumBorder(),
                            color: Color(0xFFE57697),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'NO',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })
            : Container(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Personalisation',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        ListTile(
          onTap: () {
            main.prefs.getBool("darkMode") == null
                ? analytics.logEvent(
                    name: 'theme_changed', parameters: {'type': 'dark'})
                : main.prefs.getBool("darkMode")
                    ? analytics.logEvent(
                        name: 'theme_changed', parameters: {'type': 'light'})
                    : analytics.logEvent(
                        name: 'theme_changed', parameters: {'type': 'dark'});
            Provider.of<ThemeModel>(context, listen: false).toggleTheme();
            main.RestartWidget.restartApp(context);
          },
          leading: main.prefs.getBool("darkMode") == null
              ? Icon(JamIcons.moon_f)
              : main.prefs.getBool("darkMode")
                  ? Icon(JamIcons.sun_f)
                  : Icon(JamIcons.moon_f),
          title: Text(
            main.prefs.getBool("darkMode") == null
                ? "Dark Mode"
                : main.prefs.getBool("darkMode") ? "Light Mode" : "Dark Mode",
            style: TextStyle(
                color: Theme.of(context).accentColor,
                fontWeight: FontWeight.w500,
                fontFamily: "Proxima Nova"),
          ),
          subtitle: Text(
            "Toggle app theme",
            style: TextStyle(fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'General',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        Column(
          children: [
            ListTile(
                leading: Icon(
                  JamIcons.pie_chart_alt,
                ),
                title: Text(
                  "Clear Cache",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Proxima Nova"),
                ),
                subtitle: Text(
                  "Clear locally cached images",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  DefaultCacheManager().emptyCache();
                  toasts.clearCache();
                }),
            ListTile(
              onTap: () {
                main.RestartWidget.restartApp(context);
              },
              leading: Icon(JamIcons.refresh),
              title: Text(
                "Restart App",
                style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Proxima Nova"),
              ),
              subtitle: Text(
                "Force the application to restart",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'User',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        main.prefs.getBool("isLoggedin") == false
            ? ListTile(
                onTap: () {
                  Dialog loaderDialog = Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context).primaryColor),
                      width: MediaQuery.of(context).size.width * .7,
                      height: MediaQuery.of(context).size.height * .3,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                  if (!main.prefs.getBool("isLoggedin")) {
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) => loaderDialog);
                    globals.gAuth.signInWithGoogle().then((value) {
                      toasts.successLog();
                      main.prefs.setBool("isLoggedin", true);
                      Navigator.pop(context);
                      main.RestartWidget.restartApp(context);
                    }).catchError((e) {
                      print(e);
                      Navigator.pop(context);
                      main.prefs.setBool("isLoggedin", false);
                      toasts.error("Something went wrong, please try again!");
                    });
                  } else {
                    main.RestartWidget.restartApp(context);
                  }
                },
                leading: Icon(JamIcons.log_in),
                title: Text(
                  "Log in",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Proxima Nova"),
                ),
                subtitle: Text(
                  "Log in to sync data across devices",
                  style: TextStyle(fontSize: 12),
                ),
              )
            : Container(),
        main.prefs.getBool("isLoggedin")
            ? Column(
                children: [
                  ListTile(
                      leading: Icon(
                        JamIcons.heart,
                      ),
                      title: new Text(
                        "Clear favourites",
                        style: TextStyle(
                            color: Theme.of(context).accentColor,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Proxima Nova"),
                      ),
                      subtitle: Text(
                        "Remove all favourites",
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () async {
                        showDialog(
                          context: context,
                          child: AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            content: Container(
                              height: 50,
                              width: 250,
                              child: Center(
                                child: Text(
                                  "Do you want remove all your favourites?",
                                  style: Theme.of(context).textTheme.headline4,
                                ),
                              ),
                            ),
                            actions: <Widget>[
                              FlatButton(
                                shape: StadiumBorder(),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  toasts.clearFav();
                                  Provider.of<FavouriteProvider>(context,
                                          listen: false)
                                      .deleteData();
                                },
                                child: Text(
                                  'YES',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Color(0xFFE57697),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FlatButton(
                                  shape: StadiumBorder(),
                                  color: Color(0xFFE57697),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'NO',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ListTile(
                      leading: Icon(
                        JamIcons.log_out,
                      ),
                      title: new Text(
                        "Logout",
                        style: TextStyle(
                            color: Theme.of(context).accentColor,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Proxima Nova"),
                      ),
                      subtitle: Text(
                        "Sign out from your account",
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        globals.gAuth.signOutGoogle();
                        toasts.successLogOut();
                        main.RestartWidget.restartApp(context);
                      }),
                ],
              )
            : Container(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Prism',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        Column(
          children: [
            ListTile(
                leading: Icon(
                  JamIcons.info,
                ),
                title: new Text(
                  "What's new?",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Proxima Nova"),
                ),
                subtitle: Text(
                  "Check out the changelog",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  showChangelog(context, () {});
                }),
            ListTile(
                leading: Icon(
                  JamIcons.share_alt,
                ),
                title: new Text(
                  "Share Prism!",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Proxima Nova"),
                ),
                subtitle: Text(
                  "Quick link to pass on to your friends and enemies",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Share.share(
                      'Hey check out this amazing wallpaper app Prism https://play.google.com/store/apps/details?id=com.hash.prism');
                }),
            ListTile(
                leading: Icon(
                  JamIcons.github,
                ),
                title: new Text(
                  "View Prism on GitHub!",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Proxima Nova"),
                ),
                subtitle: Text(
                  "Check out the code or contribute yourself",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  launch("https://github.com/LiquidatorCoder/Prism");
                }),
            ListTile(
                leading: Icon(
                  JamIcons.picture,
                ),
                title: new Text(
                  "API",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Proxima Nova"),
                ),
                subtitle: Text(
                  "Prism uses Wallhaven and Pexels API for wallpapers",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  showDialog(
                    context: context,
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      content: Container(
                        height: 150,
                        width: 250,
                        child: Center(
                          child: ListView.builder(
                              itemCount: 2,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Icon(
                                    index == 0
                                        ? JamIcons.picture
                                        : JamIcons.camera,
                                    color: Theme.of(context).accentColor,
                                  ),
                                  title: Text(
                                    index == 0 ? "WallHaven API" : "Pexels API",
                                    style:
                                        Theme.of(context).textTheme.headline4,
                                  ),
                                  onTap: index == 0
                                      ? () async {
                                          HapticFeedback.vibrate();
                                          Navigator.of(context).pop();
                                          launch(
                                              "https://wallhaven.cc/help/api");
                                        }
                                      : () async {
                                          HapticFeedback.vibrate();
                                          Navigator.of(context).pop();
                                          launch("https://www.pexels.com/api/");
                                        },
                                );
                              }),
                        ),
                      ),
                    ),
                  );
                }),
            ListTile(
                leading: Icon(
                  JamIcons.computer_alt,
                ),
                title: new Text(
                  "Version",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Proxima Nova"),
                ),
                subtitle: Text(
                  "v2.4.3+11",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {}),
            ListTile(
                leading: Icon(
                  JamIcons.bug,
                ),
                title: new Text(
                  "Report a bug",
                  style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Proxima Nova"),
                ),
                subtitle: Text(
                  "Tell us if you found out a bug",
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  launch("https://github.com/Hash-Studios/Prism/issues");
                }),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Hash Studios',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        Column(children: [
          ListTile(
              leading: Icon(
                JamIcons.luggage,
              ),
              title: new Text(
                "Wanna work with us?",
                style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Proxima Nova"),
              ),
              subtitle: Text(
                "We are recruiting Flutter developers",
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                launch("https://forms.gle/nSt4QtiQVVaZvhdA8");
              }),
          ListTile(
              leading: Icon(
                JamIcons.coffee,
              ),
              title: new Text(
                "Buy us a cup of tea",
                style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Proxima Nova"),
              ),
              subtitle: Text(
                "Support us if you like what we do",
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                onSupport(context);
              }),
          ExpansionTile(
            leading: Icon(
              JamIcons.users,
            ),
            title: new Text(
              "Meet the awesome team",
              style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: "Proxima Nova"),
            ),
            subtitle: Text(
              "Check out the cool devs!",
              style: TextStyle(fontSize: 12),
            ),
            children: [
              ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage("assets/images/AB.jpg"),
                  ),
                  title: new Text(
                    "LiquidatorCoder",
                    style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Proxima Nova"),
                  ),
                  subtitle: Text(
                    "Abhay Maurya",
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    launch("https://github.com/LiquidatorCoder");
                  }),
              ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage("assets/images/AK.jpg"),
                  ),
                  title: new Text(
                    "CodeNameAkshay",
                    style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Proxima Nova"),
                  ),
                  subtitle: Text(
                    "Akshay Maurya",
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    launch("https://github.com/codenameakshay");
                  }),
              ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage("assets/images/PT.jpg"),
                  ),
                  title: new Text(
                    "1-2-ka-4-4-2-ka-1",
                    style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Proxima Nova"),
                  ),
                  subtitle: Text(
                    "Pratyush Tiwari",
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    launch("https://github.com/1-2-ka-4-4-2-ka-1");
                  }),
              ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage("assets/images/AY.jpeg"),
                  ),
                  title: new Text(
                    "MrHYDRA-6469",
                    style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Proxima Nova"),
                  ),
                  subtitle: Text(
                    "Arpit Yadav",
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    launch("https://github.com/MrHYDRA-6469");
                  }),
              ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage("assets/images/AT.jpg"),
                  ),
                  title: new Text(
                    "AyushTevatia99",
                    style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Proxima Nova"),
                  ),
                  subtitle: Text(
                    "Ayush Tevatia",
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    launch("https://github.com/AyushTevatia99");
                  }),
            ],
          ),
        ])
      ],
    );
  }
}