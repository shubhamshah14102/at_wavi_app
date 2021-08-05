import 'dart:async';

import 'package:at_wavi_app/common_components/header.dart';
import 'package:at_wavi_app/model/user.dart';
import 'package:at_wavi_app/routes/route_names.dart';
import 'package:at_wavi_app/routes/routes.dart';
import 'package:at_wavi_app/screens/home/widgets/Home_details.dart';
import 'package:at_wavi_app/screens/home/widgets/home_channel.dart';
import 'package:at_wavi_app/screens/home/widgets/home_empty_details.dart';
import 'package:at_wavi_app/screens/home/widgets/home_featured.dart';
import 'package:at_wavi_app/screens/options.dart';
import 'package:at_wavi_app/services/at_key_get_service.dart';
import 'package:at_wavi_app/services/at_key_set_service.dart';
import 'package:at_wavi_app/services/backend_service.dart';
import 'package:at_wavi_app/services/common_functions.dart';
import 'package:at_wavi_app/services/follow_service.dart';
import 'package:at_wavi_app/services/nav_service.dart';
import 'package:at_wavi_app/services/search_service.dart';
import 'package:at_wavi_app/services/size_config.dart';
import 'package:at_wavi_app/services/twitter_service.dart';
import 'package:at_wavi_app/utils/at_enum.dart';
import 'package:at_wavi_app/utils/colors.dart';
import 'package:at_wavi_app/utils/constants.dart';
import 'package:at_wavi_app/utils/text_styles.dart';
import 'package:at_wavi_app/utils/theme.dart';
import 'package:at_wavi_app/view_models/theme_view_model.dart';
import 'package:at_wavi_app/view_models/user_preview.dart';
import 'package:at_wavi_app/view_models/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:at_location_flutter/utils/constants/constants.dart'
    as location_package_constants;

enum HOME_TABS { DETAILS, CHANNELS, FEATURED }

class HomeScreen extends StatefulWidget {
  final ThemeData? themeData;
  final bool isPreview;
  HomeScreen({this.themeData, this.isPreview = false});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  HOME_TABS _currentTab = HOME_TABS.DETAILS;
  bool _isDark = false;
  ThemeData? _themeData;
  late StreamSubscription<dynamic> _intentDataStreamSubscription;
  late String _name;
  late User _currentUser;

  bool _isSearchScreen = false;

  @override
  void initState() {
    if (widget.isPreview) {
      _currentUser = Provider.of<UserPreview>(context, listen: false).user()!;
    } else {
      _currentUser = Provider.of<UserProvider>(context, listen: false).user!;
    }

    if ((widget.isPreview) &&
        (_currentUser.atsign !=
            BackendService().atClientInstance.currentAtSign)) {
      _isSearchScreen = true;
    }

    _name = _currentUser.firstname.value ?? '';
    if (_currentUser.lastname.value != null) {
      _name = '$_name ${_currentUser.lastname.value}';
    }

    if (_name.isEmpty) {
      _name = BackendService()
          .atClientInstance
          .currentAtSign!
          .replaceFirst('@', '');
    }

    initPackages();
    _receiveIntent();
    _getThemeData();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      await FollowService().getFollowers();
      await FollowService().getFollowing();
    });
    super.initState();
  }

  initPackages() async {
    location_package_constants.MixedConstants.setMapKey(MixedConstants.MAP_KEY);
    location_package_constants.MixedConstants.setApiKey(MixedConstants.API_KEY);
  }

  _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  _getThemeData() async {
    if (widget.themeData != null) {
      _themeData = widget.themeData!;
    } else {
      _themeData =
          await Provider.of<ThemeProvider>(context, listen: false).getTheme();
    }

    if (_themeData!.scaffoldBackgroundColor ==
        Themes.darkTheme(ColorConstants.purple).scaffoldBackgroundColor) {
      _isDark = true;
    }

    if (mounted) {
      setState(() {});
    }
  }

  _receiveIntent() async {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      print("Incoming Shared file in home :" +
          (value.map((f) => f.path).join(",")));

      if (value != null) {}
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      print('Incoming images Value in home  is $value');
      if (value != null) {}
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      print('Incoming text Value in home  is $value');
      if (value != null) {
        SetupRoutes.push(context, Routes.ADD_LINK, arguments: {'url': value});
      }
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (value != null) {
        SetupRoutes.push(context, Routes.ADD_LINK, arguments: {'url': value});
      }
      print('Incoming text in home  when app is closed $value');
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    if (_themeData == null) {
      return CircularProgressIndicator();
    } else {
      return Scaffold(
        backgroundColor: _themeData!.scaffoldBackgroundColor,
        bottomNavigationBar: widget.isPreview
            ? null
            : BottomNavigationBar(
                backgroundColor: _themeData!.scaffoldBackgroundColor,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications),
                    label: '',
                  )
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: ColorConstants.orange,
                onTap: _onItemTapped,
                // elevation: 0,
              ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // header
                  Header(
                    leading: Row(
                      children: [
                        widget.isPreview
                            ? InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Icon(
                                  Icons.arrow_back,
                                  color: _themeData!.primaryColor,
                                ),
                              )
                            : SizedBox(),
                        SizedBox(width: 5),
                        Text(
                          widget.isPreview ? 'Preview' : 'My Profile',
                          style: TextStyle(
                              fontSize: 18.toFont,
                              color: _themeData!.primaryColor,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    trailing: widget.isPreview
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InkWell(
                                    onTap: () {
                                      SetupRoutes.push(
                                          context, Routes.SEARCH_SCREEN);
                                    },
                                    child: Icon(Icons.search,
                                        color: _themeData!.primaryColor),
                                  ),
                                ),
                                SizedBox(height: 18.5.toHeight),
                                Divider(
                                  color: _themeData!.highlightColor,
                                ),
                                SizedBox(height: 18.5.toHeight),
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: StadiumBorder(),
                                        builder: (BuildContext context) {
                                          return Container(
                                            height: 350,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 20, horizontal: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.only(
                                                topLeft:
                                                    const Radius.circular(12.0),
                                                topRight:
                                                    const Radius.circular(12.0),
                                              ),
                                            ),
                                            child: Options(),
                                          );
                                        });
                                  },
                                  child: Icon(Icons.more_vert,
                                      color: _themeData!.primaryColor),
                                )
                              ],
                            ),
                          ),
                  ),
                  SizedBox(height: 30.toHeight),

                  // content
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 116.toWidth,
                        height: 116.toWidth,
                        decoration: BoxDecoration(
                          color: ColorConstants.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: (_currentUser.image.value != null)
                            ? CircleAvatar(
                                radius: 50.toFont,
                                backgroundColor: Colors.transparent,
                                backgroundImage:
                                    Image.memory(_currentUser.image.value)
                                        .image,
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                              ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(_name,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: _themeData!.primaryColor,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 8.toHeight),
                            Text(
                              _currentUser.atsign,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ColorConstants.orange,
                                fontSize: 18.toFont,
                              ),
                            ),
                            SizedBox(height: 18.5.toHeight),
                            Divider(
                              color: _themeData!.highlightColor,
                            ),
                            SizedBox(height: 18.5.toHeight),
                            Consumer<FollowService>(
                                builder: (context, _provider, _) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_provider.followers.list!.length}',
                                          style: TextStyle(
                                              fontSize: 18.toFont,
                                              color: _isDark
                                                  ? _themeData!.primaryColor
                                                  : _themeData!.highlightColor,
                                              fontWeight: FontWeight.w800),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            SetupRoutes.push(context,
                                                Routes.FOLLOWING_SCREEN);
                                          },
                                          child: Text(
                                            'Followers',
                                            style: TextStyle(
                                                fontSize: 14.toFont,
                                                color: _themeData!.primaryColor
                                                    .withOpacity(0.5)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_provider.following.list!.length}',
                                          style: TextStyle(
                                              fontSize: 18.toFont,
                                              color: _isDark
                                                  ? _themeData!.primaryColor
                                                  : _themeData!.highlightColor,
                                              fontWeight: FontWeight.w800),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            SetupRoutes.push(context,
                                                Routes.FOLLOWING_SCREEN);
                                          },
                                          child: Text(
                                            'Following',
                                            style: TextStyle(
                                                fontSize: 14.toFont,
                                                color: _themeData!.primaryColor
                                                    .withOpacity(0.5)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              );
                            }),
                          ],
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20.toHeight),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          height: 55.toHeight,
                          child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  _themeData!.highlightColor.withOpacity(0.1)),
                            ),
                            onPressed: widget.isPreview
                                ? () {
                                    if (_isSearchScreen) {
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        backgroundColor: ColorConstants.RED,
                                        content: Text(
                                          'This is a Preview',
                                          style:
                                              CustomTextStyles.customTextStyle(
                                            ColorConstants.white,
                                          ),
                                        ),
                                      ));
                                    }
                                  }
                                : () async {
                                    var _res = await SearchService()
                                        .getAtsignDetails(
                                            'minorgettingplayed7');
                                    // Provider.of<UserPreview>(context,
                                    //         listen: false)
                                    //     .setSearchedUser(_res);
                                    UserPreview().setUser = _res;
                                    await SetupRoutes.push(context, Routes.HOME,
                                        arguments: {
                                          'themeData': SearchService()
                                              .currentAtsignThemeData,
                                          'isPreview': true,
                                        });

                                    ///////////////
                                    // SetupRoutes.push(
                                    //     NavService.navKey.currentContext!,
                                    //     Routes.EDIT_PERSONA);
                                  },
                            child: Text(
                              widget.isPreview ? 'Follow' : 'Edit Profile',
                              style: TextStyle(
                                  fontSize: 16.toFont,
                                  color: _themeData!.primaryColor
                                      .withOpacity(0.5)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 55.toHeight,
                          child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  _themeData!.highlightColor.withOpacity(0.1)),
                            ),
                            onPressed: widget.isPreview
                                ? () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      backgroundColor: ColorConstants.RED,
                                      content: Text(
                                        'This is a Preview',
                                        style: CustomTextStyles.customTextStyle(
                                          ColorConstants.white,
                                        ),
                                      ),
                                    ));
                                  }
                                : () async {
                                    // await TwitetrService().getTweets();
                                    await AtKeyGetService().deleteKeys();
                                  },
                            child: Text('Share Profile',
                                style: TextStyle(
                                    fontSize: 16.toFont,
                                    color: _themeData!.primaryColor
                                        .withOpacity(0.5))),
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 25.toHeight),

                  Container(
                    height: 70.toHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _themeData!.primaryColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _currentTab = HOME_TABS.DETAILS;
                              });
                            },
                            child: tab('Details', HOME_TABS.DETAILS),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                              onTap: () {
                                setState(() {
                                  _currentTab = HOME_TABS.CHANNELS;
                                });
                              },
                              child: tab('Channels', HOME_TABS.CHANNELS)),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _currentTab = HOME_TABS.FEATURED;
                              });
                            },
                            child: tab('Featured', HOME_TABS.FEATURED),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.toHeight),
                  homeContent()
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget tab(String title, HOME_TABS tab) {
    return Container(
      decoration: BoxDecoration(
        color: _currentTab == tab
            ? _themeData!.highlightColor
            : _themeData!.scaffoldBackgroundColor,
        border: _currentTab == tab
            ? Border.all(
                color: _isDark
                    ? _themeData!.highlightColor
                    : ColorConstants.lightGrey)
            : null,
        // borderRadius: _currentTab == tab ? BorderRadius.circular(60) : null,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
              color: _currentTab == tab
                  ? Colors.white
                  : _themeData!.highlightColor,
              fontSize: 18.toFont),
        ),
      ),
    );
  }

  Widget homeContent() {
    if (_currentTab == HOME_TABS.DETAILS) {
      return CommonFunctions().isFieldsPresentForCategory(AtCategory.DETAILS,
                  isPreview: widget.isPreview) ||
              CommonFunctions().isFieldsPresentForCategory(
                  AtCategory.ADDITIONAL_DETAILS,
                  isPreview: widget.isPreview)
          ? HomeDetails(themeData: _themeData, isPreview: widget.isPreview)
          : HomeEmptyDetails();
    } else if (_currentTab == HOME_TABS.CHANNELS) {
      return CommonFunctions().isFieldsPresentForCategory(AtCategory.GAMER,
                  isPreview: widget.isPreview) ||
              CommonFunctions().isFieldsPresentForCategory(AtCategory.SOCIAL,
                  isPreview: widget.isPreview)
          ? HomeChannels(themeData: _themeData, isPreview: widget.isPreview)
          : HomeEmptyDetails();
    } else if (_currentTab == HOME_TABS.FEATURED) {
      return CommonFunctions().isTwitterFeatured(isPreview: widget.isPreview) ||
              CommonFunctions().isInstagramFeatured(isPreview: widget.isPreview)
          ? HomeFeatured(themeData: _themeData)
          : HomeEmptyDetails();
    } else
      return SizedBox();
  }
}
