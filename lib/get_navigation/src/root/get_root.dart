import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/routes/test_kit.dart';

import '../../../get.dart';
import '../router_report.dart';

class ConfigData {
  final ValueChanged<Routing?>? routingCallback;

  /// 默认的转场动画
  final Transition? defaultTransition;
  final VoidCallback? onInit;
  final VoidCallback? onReady;
  final VoidCallback? onDispose;
  final bool? enableLog;
  final LogWriterCallback? logWriterCallback;

  /// 对绑定的实例的管理模式, 默认为 [SmartManagement.full]
  final SmartManagement smartManagement;
  final List<Bind> binds;
  final Duration? transitionDuration;
  final bool? defaultGlobalState;
  final List<GetPage>? getPages;

  /// 找不到路由的时候会默认跳转到这个路由
  final GetPage? unknownRoute;
  final RouteInformationProvider? routeInformationProvider;

  /// 用来处理路由的解析, [Router] 小部件使用的委托. 用于将路由信息解析为 [RouteDecoder] 类型的配置.
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final BackButtonDispatcher? backButtonDispatcher;
  final List<NavigatorObserver>? navigatorObservers;
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  /// 本地化翻译的 Map, 如果设置了 [translations], 会被覆盖.
  final Map<String, Map<String, String>>? translationsKeys;

  /// 本地化翻译实例
  final Translations? translations;

  /// 本地化语言
  final Locale? locale;

  /// 本地化备选项
  final Locale? fallbackLocale;
  final String? initialRoute;
  final CustomTransition? customTransition;
  final Widget? home;
  final bool testMode;
  final Key? unikey;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;

  /// 是否默认添加返回滑动手势
  final bool? defaultPopGesture;
  final bool defaultOpaqueRoute;
  final Duration defaultTransitionDuration;
  final Curve defaultTransitionCurve;
  final Curve defaultDialogTransitionCurve;
  final Duration defaultDialogTransitionDuration;
  final Routing routing;
  final Map<String, String?> parameters;
  final SnackBarQueue snackBarQueue = SnackBarQueue();

  ConfigData({
    required this.routingCallback,
    required this.defaultTransition,
    required this.onInit,
    required this.onReady,
    required this.onDispose,
    required this.enableLog,
    required this.logWriterCallback,
    required this.smartManagement,
    required this.binds,
    required this.transitionDuration,
    required this.defaultGlobalState,
    required this.getPages,
    required this.unknownRoute,
    required this.routeInformationProvider,
    required this.routeInformationParser,
    required this.routerDelegate,
    required this.backButtonDispatcher,
    required this.navigatorObservers,
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
    required this.translationsKeys,
    required this.translations,
    required this.locale,
    required this.fallbackLocale,
    required this.initialRoute,
    required this.customTransition,
    required this.home,
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.unikey,
    this.testMode = false,
    this.defaultOpaqueRoute = true,
    this.defaultTransitionDuration = const Duration(milliseconds: 300),
    this.defaultTransitionCurve = Curves.easeOutQuad,
    this.defaultDialogTransitionCurve = Curves.easeOutQuad,
    this.defaultDialogTransitionDuration = const Duration(milliseconds: 300),
    this.parameters = const {},
    required this.defaultPopGesture,
    Routing? routing,
  }) : routing = routing ?? Routing();

  ConfigData copyWith({
    ValueChanged<Routing?>? routingCallback,
    Transition? defaultTransition,
    VoidCallback? onInit,
    VoidCallback? onReady,
    VoidCallback? onDispose,
    bool? enableLog,
    LogWriterCallback? logWriterCallback,
    SmartManagement? smartManagement,
    List<Bind>? binds,
    Duration? transitionDuration,
    bool? defaultGlobalState,
    List<GetPage>? getPages,
    GetPage? unknownRoute,
    RouteInformationProvider? routeInformationProvider,
    RouteInformationParser<Object>? routeInformationParser,
    RouterDelegate<Object>? routerDelegate,
    BackButtonDispatcher? backButtonDispatcher,
    List<NavigatorObserver>? navigatorObservers,
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
    Map<String, Map<String, String>>? translationsKeys,
    Translations? translations,
    Locale? locale,
    Locale? fallbackLocale,
    String? initialRoute,
    CustomTransition? customTransition,
    Widget? home,
    bool? testMode,
    Key? unikey,
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeMode? themeMode,
    bool? defaultPopGesture,
    bool? defaultOpaqueRoute,
    Duration? defaultTransitionDuration,
    Curve? defaultTransitionCurve,
    Curve? defaultDialogTransitionCurve,
    Duration? defaultDialogTransitionDuration,
    Routing? routing,
    Map<String, String?>? parameters,
  }) {
    return ConfigData(
      routingCallback: routingCallback ?? this.routingCallback,
      defaultTransition: defaultTransition ?? this.defaultTransition,
      onInit: onInit ?? this.onInit,
      onReady: onReady ?? this.onReady,
      onDispose: onDispose ?? this.onDispose,
      enableLog: enableLog ?? this.enableLog,
      logWriterCallback: logWriterCallback ?? this.logWriterCallback,
      smartManagement: smartManagement ?? this.smartManagement,
      binds: binds ?? this.binds,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      defaultGlobalState: defaultGlobalState ?? this.defaultGlobalState,
      getPages: getPages ?? this.getPages,
      unknownRoute: unknownRoute ?? this.unknownRoute,
      routeInformationProvider:
          routeInformationProvider ?? this.routeInformationProvider,
      routeInformationParser:
          routeInformationParser ?? this.routeInformationParser,
      routerDelegate: routerDelegate ?? this.routerDelegate,
      backButtonDispatcher: backButtonDispatcher ?? this.backButtonDispatcher,
      navigatorObservers: navigatorObservers ?? this.navigatorObservers,
      navigatorKey: navigatorKey ?? this.navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey ?? this.scaffoldMessengerKey,
      translationsKeys: translationsKeys ?? this.translationsKeys,
      translations: translations ?? this.translations,
      locale: locale ?? this.locale,
      fallbackLocale: fallbackLocale ?? this.fallbackLocale,
      initialRoute: initialRoute ?? this.initialRoute,
      customTransition: customTransition ?? this.customTransition,
      home: home ?? this.home,
      testMode: testMode ?? this.testMode,
      unikey: unikey ?? this.unikey,
      theme: theme ?? this.theme,
      darkTheme: darkTheme ?? this.darkTheme,
      themeMode: themeMode ?? this.themeMode,
      defaultPopGesture: defaultPopGesture ?? this.defaultPopGesture,
      defaultOpaqueRoute: defaultOpaqueRoute ?? this.defaultOpaqueRoute,
      defaultTransitionDuration:
          defaultTransitionDuration ?? this.defaultTransitionDuration,
      defaultTransitionCurve:
          defaultTransitionCurve ?? this.defaultTransitionCurve,
      defaultDialogTransitionCurve:
          defaultDialogTransitionCurve ?? this.defaultDialogTransitionCurve,
      defaultDialogTransitionDuration: defaultDialogTransitionDuration ??
          this.defaultDialogTransitionDuration,
      routing: routing ?? this.routing,
      parameters: parameters ?? this.parameters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConfigData &&
        other.routingCallback == routingCallback &&
        other.defaultTransition == defaultTransition &&
        other.onInit == onInit &&
        other.onReady == onReady &&
        other.onDispose == onDispose &&
        other.enableLog == enableLog &&
        other.logWriterCallback == logWriterCallback &&
        other.smartManagement == smartManagement &&
        listEquals(other.binds, binds) &&
        other.transitionDuration == transitionDuration &&
        other.defaultGlobalState == defaultGlobalState &&
        listEquals(other.getPages, getPages) &&
        other.unknownRoute == unknownRoute &&
        other.routeInformationProvider == routeInformationProvider &&
        other.routeInformationParser == routeInformationParser &&
        other.routerDelegate == routerDelegate &&
        other.backButtonDispatcher == backButtonDispatcher &&
        listEquals(other.navigatorObservers, navigatorObservers) &&
        other.navigatorKey == navigatorKey &&
        other.scaffoldMessengerKey == scaffoldMessengerKey &&
        mapEquals(other.translationsKeys, translationsKeys) &&
        other.translations == translations &&
        other.locale == locale &&
        other.fallbackLocale == fallbackLocale &&
        other.initialRoute == initialRoute &&
        other.customTransition == customTransition &&
        other.home == home &&
        other.testMode == testMode &&
        other.unikey == unikey &&
        other.theme == theme &&
        other.darkTheme == darkTheme &&
        other.themeMode == themeMode &&
        other.defaultPopGesture == defaultPopGesture &&
        other.defaultOpaqueRoute == defaultOpaqueRoute &&
        other.defaultTransitionDuration == defaultTransitionDuration &&
        other.defaultTransitionCurve == defaultTransitionCurve &&
        other.defaultDialogTransitionCurve == defaultDialogTransitionCurve &&
        other.defaultDialogTransitionDuration ==
            defaultDialogTransitionDuration &&
        other.routing == routing &&
        mapEquals(other.parameters, parameters);
  }

  @override
  int get hashCode {
    return routingCallback.hashCode ^
        defaultTransition.hashCode ^
        onInit.hashCode ^
        onReady.hashCode ^
        onDispose.hashCode ^
        enableLog.hashCode ^
        logWriterCallback.hashCode ^
        smartManagement.hashCode ^
        binds.hashCode ^
        transitionDuration.hashCode ^
        defaultGlobalState.hashCode ^
        getPages.hashCode ^
        unknownRoute.hashCode ^
        routeInformationProvider.hashCode ^
        routeInformationParser.hashCode ^
        routerDelegate.hashCode ^
        backButtonDispatcher.hashCode ^
        navigatorObservers.hashCode ^
        navigatorKey.hashCode ^
        scaffoldMessengerKey.hashCode ^
        translationsKeys.hashCode ^
        translations.hashCode ^
        locale.hashCode ^
        fallbackLocale.hashCode ^
        initialRoute.hashCode ^
        customTransition.hashCode ^
        home.hashCode ^
        testMode.hashCode ^
        unikey.hashCode ^
        theme.hashCode ^
        darkTheme.hashCode ^
        themeMode.hashCode ^
        defaultPopGesture.hashCode ^
        defaultOpaqueRoute.hashCode ^
        defaultTransitionDuration.hashCode ^
        defaultTransitionCurve.hashCode ^
        defaultDialogTransitionCurve.hashCode ^
        defaultDialogTransitionDuration.hashCode ^
        routing.hashCode ^
        parameters.hashCode;
  }
}

class GetRoot extends StatefulWidget {
  const GetRoot({
    super.key,
    required this.config,
    required this.child,
  });
  final ConfigData config;
  final Widget child;
  @override
  State<GetRoot> createState() => GetRootState();

  static bool get treeInitialized => GetRootState._controller != null;

  /// 静态方法获取 GetRootState
  static GetRootState of(BuildContext context) {
    // Handles the case where the input context is a navigator element.
    GetRootState? root;
    if (context is StatefulElement && context.state is GetRootState) {
      root = context.state as GetRootState;
    }

    // 从所有祖先中查到最接近根的 [GetRootState] 类型祖先
    // findRootAncestorStateOfType 就是遍历所有祖先并返回找到的最后一个
    root = context.findRootAncestorStateOfType<GetRootState>() ?? root;
    assert(() {
      if (root == null) {
        throw FlutterError(
          'GetRoot operation requested with a context that does not include a GetRoot.\n'
          'The context used must be that of a '
          'widget that is a descendant of a GetRoot widget.',
        );
      }
      return true;
    }());
    return root!;
  }
}

class GetRootState extends State<GetRoot> with WidgetsBindingObserver {
  static GetRootState? _controller;
  static GetRootState get controller {
    if (_controller == null) {
      throw Exception('GetRoot is not part of the tree');
    } else {
      return _controller!;
    }
  }

  late ConfigData config;

  @override
  void initState() {
    // 关联配置
    config = widget.config;
    // 将 GetRootState 绑定到全局
    GetRootState._controller = this;
    // 添加 WidgetsBinding 的监听
    Engine.instance.addObserver(this);
    // 初始化
    onInit();
    super.initState();
  }

  // @override
  // void didUpdateWidget(covariant GetRoot oldWidget) {
  //   if (oldWidget.config != widget.config) {
  //     config = widget.config;
  //   }

  //   super.didUpdateWidget(oldWidget);
  // }

  void onClose() {
    // 调用 onDispose
    config.onDispose?.call();
    // 清除本地化翻译 Map
    Get.clearTranslations();
    // 清除 snackBar
    config.snackBarQueue.disposeControllers();
    // 清除所有路由绑定关系
    RouterReportManager.instance.clearRouteKeys();
    // 销毁 [RouterReportManager] 单例
    RouterReportManager.dispose();
    // 清除所有绑定的实例
    Get.resetInstance(clearRouteBindings: true);
    // 将 GetRootState 从全局中移除
    _controller = null;
    // 移除 WidgetsBinding 的监听
    Engine.instance.removeObserver(this);
  }

  @override
  void dispose() {
    onClose();
    super.dispose();
  }

  void onInit() {
    // 检查配置中是否有 [getPages] 或 [home], 没有则抛出异常
    if (config.getPages == null && config.home == null) {
      throw 'You need add pages or home';
    }

    // 设置默认 [GetDelegate]
    if (config.routerDelegate == null) {
      // 默认使用 home 创建 [GetDelegate]
      final newDelegate = GetDelegate.createDelegate(
        pages: config.getPages ??
            [
              GetPage(
                name: cleanRouteName("/${config.home.runtimeType}"),
                page: () => config.home!,
              ),
            ],
        notFoundRoute: config.unknownRoute,
        navigatorKey: config.navigatorKey,
        navigatorObservers: (config.navigatorObservers == null
            ? <NavigatorObserver>[
                GetObserver(config.routingCallback, Get.routing)
              ]
            : <NavigatorObserver>[
                GetObserver(config.routingCallback, config.routing),
                ...config.navigatorObservers!
              ]),
      );
      // 将新创建的 [GetDelegate] 传到 [config]
      config = config.copyWith(routerDelegate: newDelegate);
    }

    // 初始化路由解析代理
    if (config.routeInformationParser == null) {
      final newRouteInformationParser =
          GetInformationParser.createInformationParser(
        initialRoute: config.initialRoute ??
            config.getPages?.first.name ??
            cleanRouteName("/${config.home.runtimeType}"),
      );

      config =
          config.copyWith(routeInformationParser: newRouteInformationParser);
    }

    // 本地化语言
    if (config.locale != null) Get.locale = config.locale;

    // 设置本地化备选项
    if (config.fallbackLocale != null) {
      Get.fallbackLocale = config.fallbackLocale;
    }

    // 保存本地化翻译的 Map
    if (config.translations != null) {
      Get.addTranslations(config.translations!.keys);
    } else if (config.translationsKeys != null) {
      Get.addTranslations(config.translationsKeys!);
    }

    Get.smartManagement = config.smartManagement;
    // [onInit] 回调
    config.onInit?.call();

    // 是否打印日志
    Get.isLogEnable = config.enableLog ?? kDebugMode;
    Get.log = config.logWriterCallback ?? defaultLogWriterCallback;

    // 设置默认的转场动画
    if (config.defaultTransition == null) {
      config = config.copyWith(defaultTransition: getThemeTransition());
    }

    // defaultOpaqueRoute = config.opaqueRoute ?? true;
    // defaultPopGesture = config.popGesture ?? GetPlatform.isIOS;
    // defaultTransitionDuration =
    //     config.transitionDuration ?? Duration(milliseconds: 300);

    // 调用 onReady
    Future(() => onReady());
  }

  set parameters(Map<String, String?> newParameters) {
    // rootController.parameters = newParameters;
    config = config.copyWith(parameters: newParameters);
  }

  set testMode(bool isTest) {
    config = config.copyWith(testMode: isTest);
    GetTestMode.active = isTest;
  }

  void onReady() {
    // [onReady] 回调
    config.onReady?.call();
  }

  /// 默认的转场动画
  Transition? getThemeTransition() {
    final platform = context.theme.platform;
    final matchingTransition =
        Get.theme.pageTransitionsTheme.builders[platform];
    switch (matchingTransition) {
      case CupertinoPageTransitionsBuilder():
        return Transition.cupertino;
      case ZoomPageTransitionsBuilder():
        return Transition.zoom;
      case FadeUpwardsPageTransitionsBuilder():
        return Transition.fade;
      case OpenUpwardsPageTransitionsBuilder():
        return Transition.native;
      default:
        return null;
    }
  }

  /// 设置语言
  @override
  void didChangeLocales(List<Locale>? locales) {
    Get.asap(() {
      final locale = Get.deviceLocale;
      if (locale != null) {
        Get.updateLocale(locale);
      }
    });
  }

  /// 设置主题
  void setTheme(ThemeData value) {
    if (config.darkTheme == null) {
      config = config.copyWith(theme: value);
    } else {
      if (value.brightness == Brightness.light) {
        config = config.copyWith(theme: value);
      } else {
        config = config.copyWith(darkTheme: value);
      }
    }
    update();
  }

  /// 切换主题模式
  void setThemeMode(ThemeMode value) {
    config = config.copyWith(themeMode: value);
    update();
  }

  /// 重启应用
  void restartApp() {
    config = config.copyWith(unikey: UniqueKey());
    update();
  }

  /// 重建所有小部件
  void update() {
    // 遍历小部件的祖先元素
    context.visitAncestorElements((element) {
      // 标记元素在下一个帧中需要被重建
      element.markNeedsBuild();
      // 返回 false 语句意味着它在标记第一个祖先后就停止了, 因为 GetRoot 基本上只在程序启动时被调用
      return false;
    });
  }

  /// 全局的 Navigator Key, 用来访问 Navigator 控制导航
  GlobalKey<NavigatorState> get key => rootDelegate.navigatorKey;

  /// 全局导航代理, 默认是 [GetDelegate] 类型
  GetDelegate get rootDelegate => config.routerDelegate as GetDelegate;

  RouteInformationParser<Object> get informationParser =>
      config.routeInformationParser!;

  /// 更新全局的 Navigator Key
  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) {
    rootDelegate.navigatorKey = newKey;
    return key;
  }

  /// 用来存放多个 [GetDelegate] 的 Map, 嵌套导航时使用
  Map<String, GetDelegate> keys = {};

  GetDelegate? nestedKey(String? key) {
    // 如果 [key] 为 null, 则返回根导航代理 [rootDelegate]
    if (key == null) {
      return rootDelegate;
    }
    // 如果 [keys] 中不存在对应的 [key], 则创建一个 [GetDelegate] 并放入 [keys] 中
    keys.putIfAbsent(
      key,
      () => GetDelegate(
        showHashOnUrl: true,
        //debugLabel: 'Getx nested key: ${key.toString()}',
        pages: RouteDecoder.fromRoute(key).currentChildren ?? [],
      ),
    );
    // 返回 [key] 对应的 [GetDelegate]
    return keys[key];
  }

  @override
  Widget build(BuildContext context) {
    // child 就是 MaterialApp
    return widget.child;
  }

  /// 格式化路由字符串, 去除 '() => ', 如果不是以 '/' 开头的则在前面添加 '/'.
  String cleanRouteName(String name) {
    name = name.replaceAll('() => ', '');

    /// uncomment for URL styling.
    // name = name.paramCase!;
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }
}
