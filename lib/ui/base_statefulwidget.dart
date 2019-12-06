import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_base_architecture/data/local/sharedpreferences/user_stores.dart';
import 'package:flutter_base_architecture/dto/user_dto.dart';
import 'package:flutter_base_architecture/exception/base_error.dart';
import 'package:flutter_base_architecture/exception/base_error_handler.dart';
import 'package:flutter_base_architecture/exception/base_error_parser.dart';
import 'package:flutter_base_architecture/extensions/widget_extensions.dart';
import 'package:flutter_base_architecture/utils/app_colors.dart';
import 'package:flutter_base_architecture/utils/asset_icons.dart';
import 'package:flutter_base_architecture/viewmodels/base_view_model.dart';
import 'package:provider/provider.dart';

import 'base_error_widget.dart';
import 'base_widget.dart';

/// Every StatefulWidget should be inherited from this
abstract class BaseStatefulWidget extends StatefulWidget {
  const BaseStatefulWidget({Key key}) : super(key: key);
}

abstract class _BaseState<T extends BaseStatefulWidget,ErrorParser extends BaseErrorParser, BaseViewModel>
    extends State<T> {
  bool _requiresLogin = true;
  UserStore _userStore;
  ErrorHandler<ErrorParser> _errorHandler;



  @override
  void initState() {
    super.initState();
    _performLoginCheck();
  }

  _performLoginCheck() {
    if (isRequiresLogin()) {
      Future.delayed(Duration(seconds: 0), () {
        userIsLoggedIn().then((loggedIn) {
          if (!loggedIn) {
            Navigator.pushReplacementNamed(context, onBoardingRoutePath());
            return;
          }
        });
      });
    }
  }

  String onBoardingRoutePath();

  isRequiresLogin() {
    return _requiresLogin;
  }

  setRequiresLogin(bool requiresLogin) {
    this._requiresLogin = requiresLogin;
  }

  Future<bool> setUser(UserDto userDto) async {
    return await _userStore.setUser(userDto);
  }

  @protected
  Future<bool> userIsLoggedIn() async {
    return await _userStore.userIsLoggedIn();
  }

  Future<UserDto> getLoggedInUser() async {
    return await _userStore.getLoggedInUser();
  }

  void showToastMessage(String message) {
    widget?.toastMessage(message);
  }

  String getErrorMessage(BaseError errorType) {
    return _errorHandler.parseErrorType(context, errorType);
  }
}

abstract class BaseStatefulScreen<B extends BaseStatefulWidget,
ErrorParser extends BaseErrorParser,VM extends BaseViewModel> extends _BaseState<B,ErrorParser, VM> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  VM viewModel;

  BaseStatefulScreen();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //viewModel = Provider.of(context);
    viewModel = initViewModel();
  }

  @override
  Widget build(BuildContext context) {
    addDefaultErrorWidget(context);
    _userStore = Provider.of(context);
    _errorHandler = Provider.of(context,listen: false);
    return getLayout();
  }

  void addDefaultErrorWidget(context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return BaseErrorScreen(getErrorLogo());
    };
  }

  VM getViewModel() {
    return viewModel;
  }

  Widget getLayout() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: getStatusBarColor(),
      ),
      child: BaseWidget<VM>(
          viewModel: getViewModel(),
          builder: (BuildContext context, VM model, Widget child) {
            return Scaffold(
              backgroundColor: getScaffoldColor(),
              key: scaffoldKey,
              appBar: buildAppbar(),
              body: buildBody(),
              resizeToAvoidBottomPadding: true,
            );
          }),
    );
  }

  // Can be overridden in extended widget to support AppBar

  Color getScaffoldColor() {
    return BaseAppColors.whiteBg;
  }

  Color getStatusBarColor() {
    return BaseAppColors.black;
  }

  String getErrorLogo() {
    return AssetIcons.logo.assetName;
  }

  Widget buildAppbar() {
    return null;
  }

  /// Should be overridden in extended widget
  Widget buildBody();

  VM initViewModel();

  @override
  void dispose() {
    getViewModel().dispose();
    super.dispose();
  }
}
