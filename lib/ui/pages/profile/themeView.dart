import 'package:Prism/routes/router.dart';
import 'package:Prism/theme/jam_icons_icons.dart';
import 'package:Prism/theme/themeModel.dart';
import 'package:Prism/ui/widgets/profile/animatedThemeSwitch.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Prism/main.dart' as main;
import 'package:Prism/analytics/analytics_service.dart';

class ThemeView extends StatefulWidget {
  final List arguments;
  ThemeView({@required this.arguments});
  @override
  _ThemeViewState createState() => _ThemeViewState();
}

class _ThemeViewState extends State<ThemeView> {
  ThemeData currentTheme;
  @override
  void initState() {
    currentTheme = widget.arguments[0];
    super.initState();
  }

  Future<bool> onWillPop() async {
    if (Provider.of<ThemeModel>(context, listen: false).currentTheme ==
        currentTheme) {
    } else {
      Provider.of<ThemeModel>(context, listen: false).toggleTheme();
    }
    navStack.removeLast();
    print(navStack);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(JamIcons.arrow_left),
              onPressed: () {
                if (Provider.of<ThemeModel>(context, listen: false)
                        .currentTheme ==
                    currentTheme) {
                } else {
                  Provider.of<ThemeModel>(context, listen: false).toggleTheme();
                }
                navStack.removeLast();
                print(navStack);
                Navigator.pop(context);
              }),
          actions: <Widget>[
            IconButton(
                icon: Icon(
                  JamIcons.check,
                  size: 30,
                ),
                onPressed: () {
                  main.RestartWidget.restartApp(context);
                })
          ],
          centerTitle: true,
          elevation: 0,
          title: Text(
            "Pick a Theme",
            style: Theme.of(context).textTheme.headline2,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: Provider.of<ThemeModel>(context, listen: false)
                              .returnTheme() ==
                          ThemeType.Dark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(.9),
                            blurRadius: 38,
                            offset: Offset(0, 19),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(.8),
                            blurRadius: 12,
                            offset: Offset(0, 15),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(.15),
                            blurRadius: 38,
                            offset: Offset(0, 19),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(.10),
                            blurRadius: 12,
                            offset: Offset(0, 15),
                          )
                        ],
                  image: DecorationImage(
                      image: AssetImage(
                        Provider.of<ThemeModel>(context, listen: false)
                                    .returnTheme() ==
                                ThemeType.Dark
                            ? "assets/images/dark_theme.jpg"
                            : "assets/images/light_theme.jpg",
                      ),
                      fit: BoxFit.contain),
                ),
                width: MediaQuery.of(context).size.height * 0.3,
                height: MediaQuery.of(context).size.height * 0.6 - 5,
              ),
            ),
            AnimatedToggle(
              values: main.prefs.getBool("darkMode")
                  ? ['Dark', 'Light']
                  : ['Light', 'Dark'],
              textColor: Theme.of(context).accentColor,
              backgroundColor: Theme.of(context).hintColor,
              buttonColor: Theme.of(context).primaryColor,
              shadows: Provider.of<ThemeModel>(context, listen: false)
                          .returnTheme() ==
                      ThemeType.Dark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(.8),
                        blurRadius: 38,
                        offset: Offset(0, 19),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(.15),
                        blurRadius: 38,
                        offset: Offset(0, 19),
                      ),
                    ],
              onToggleCallback: (index) {
                Provider.of<ThemeModel>(context, listen: false).toggleTheme();
                main.prefs.getBool("darkMode") == null
                    ? analytics.logEvent(
                        name: 'theme_changed', parameters: {'type': 'dark'})
                    : main.prefs.getBool("darkMode")
                        ? analytics.logEvent(
                            name: 'theme_changed',
                            parameters: {'type': 'light'})
                        : analytics.logEvent(
                            name: 'theme_changed',
                            parameters: {'type': 'dark'});
                print("Theme Changed");
              },
            ),
          ],
        ),
      ),
    );
  }
}