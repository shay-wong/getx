import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/iterable_extensions.dart';

import '../../../get_instance/src/bindings_interface.dart';
import '../../../get_utils/src/platform/platform.dart';
import '../../../route_manager.dart';

/// 导航代理, 用来处理导航相关的逻辑
class GetDelegate extends RouterDelegate<RouteDecoder>
    with
        ChangeNotifier,
        PopNavigatorRouterDelegateMixin<RouteDecoder>,
        IGetNavigation {
  factory GetDelegate.createDelegate({
    GetPage<dynamic>? notFoundRoute,
    List<GetPage> pages = const [],
    List<NavigatorObserver>? navigatorObservers,
    TransitionDelegate<dynamic>? transitionDelegate,
    PopMode backButtonPopMode = PopMode.history,
    PreventDuplicateHandlingMode preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return GetDelegate(
      notFoundRoute: notFoundRoute,
      navigatorObservers: navigatorObservers,
      transitionDelegate: transitionDelegate,
      backButtonPopMode: backButtonPopMode,
      preventDuplicateHandlingMode: preventDuplicateHandlingMode,
      pages: pages,
      navigatorKey: navigatorKey,
    );
  }

  /// 记录当前 push 的路由栈, 当 push 的时候会在栈顶添加
  final List<RouteDecoder> _activePages = <RouteDecoder>[];
  final PopMode backButtonPopMode;
  final PreventDuplicateHandlingMode preventDuplicateHandlingMode;

  final GetPage notFoundRoute;

  final List<NavigatorObserver>? navigatorObservers;
  final TransitionDelegate<dynamic>? transitionDelegate;

  final Iterable<GetPage> Function(RouteDecoder currentNavStack)?
  pickPagesForRootNavigator;

  List<RouteDecoder> get activePages => _activePages;

  /// 路由树, 即传入的 pages, [GetDelegate] 初始化的时候会调用 [addPages] 存储所有的路由
  final _routeTree = ParseRouteTree(routes: []);

  /// 已注册的路由
  List<GetPage> get registeredRoutes => _routeTree.routes;

  /// 添加路由
  void addPages(List<GetPage> getPages) {
    _routeTree.addRoutes(getPages);
  }

  /// 清除所有路由
  void clearRouteTree() {
    _routeTree.routes.clear();
  }

  /// 添加单个路由
  void addPage(GetPage getPage) {
    _routeTree.addRoute(getPage);
  }

  /// 移除单个路由
  void removePage(GetPage getPage) {
    _routeTree.removeRoute(getPage);
  }

  /// 匹配路由
  RouteDecoder matchRoute(String name, {PageSettings? arguments}) {
    return _routeTree.matchRoute(name, arguments: arguments);
  }

  // GlobalKey<NavigatorState> get navigatorKey => Get.key;

  /// 全局的 Navigator Key, 用来访问 Navigator 控制导航
  @override
  GlobalKey<NavigatorState> navigatorKey;

  final String? restorationScopeId;

  GetDelegate({
    GetPage? notFoundRoute,
    this.navigatorObservers,
    this.transitionDelegate,
    this.backButtonPopMode = PopMode.history,
    this.preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
    this.pickPagesForRootNavigator,
    this.restorationScopeId,
    bool showHashOnUrl = false,
    GlobalKey<NavigatorState>? navigatorKey,
    required List<GetPage> pages,
  }) : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
       notFoundRoute = notFoundRoute ??= GetPage(
         name: '/404',
         page: () =>
             const Scaffold(body: Center(child: Text('Route not found'))),
       ) {
    if (!showHashOnUrl && GetPlatform.isWeb) setUrlStrategy();
    addPages(pages);
    addPage(notFoundRoute);
    Get.log('GetDelegate is created !');
  }

  Future<RouteDecoder?> runMiddleware(RouteDecoder config) async {
    // 获取 [GetPage] 中的 [middlewares] 列表
    final middlewares = config.currentTreeBranch.last.middlewares;
    if (middlewares.isEmpty) {
      // 如果没有中间件, 则不重定向, 直接返回传入的 [RouteDecoder], 即将要显示界面
      return config;
    }
    var iterator = config;
    // 正序遍历中间件, 所有 [GetPage] 里前面的中间件会先执行
    for (var item in middlewares) {
      // 执行 redirectDelegate 函数
      var redirectRes = await item.redirectDelegate(iterator);
      // 返回 null 和上面返回 config 结果是一样的, 都是不重定向
      if (redirectRes == null) {
        config.route?.completer?.complete();
        return null;
      }
      // 如果 redirectRes 不为空则覆盖 iterator
      if (config != redirectRes) {
        config.route?.completer?.complete();
        Get.log('Redirect to ${redirectRes.pageSettings?.name}');
      }

      iterator = redirectRes;
      // Stop the iteration over the middleware if we changed page
      // and that redirectRes is not the same as the current config.
      // 如果 redirectDelegate 中返回的不是传入的 config, 则结束迭代
      // 当其中某一个中间件进行了重定向, 则后面所有的中间件都不会再执行
      if (config != redirectRes) {
        break;
      }
    }
    // If the target is not the same as the source, we need
    // to run the middlewares for the new route.
    // 如果进行了重定向，则会递归调用 runMiddleware，运行重定向后新路由的所有中间件。
    if (iterator != config) {
      return await runMiddleware(iterator);
    }
    // 返回重定向后最终的 [RouteDecoder]
    return iterator;
  }

  Future<void> _unsafeHistoryAdd(RouteDecoder config) async {
    final res = await runMiddleware(config);
    if (res == null) return;
    _activePages.add(res);
  }

  // Future<T?> _unsafeHistoryRemove<T>(RouteDecoder config, T result) async {
  //   var index = _activePages.indexOf(config);
  //   if (index >= 0) return _unsafeHistoryRemoveAt(index, result);
  //   return null;
  // }

  Future<T?> _unsafeHistoryRemoveAt<T>(int index, T result) async {
    if (index == _activePages.length - 1 && _activePages.length > 1) {
      //removing WILL update the current route
      final toCheck = _activePages[_activePages.length - 2];
      final resMiddleware = await runMiddleware(toCheck);
      if (resMiddleware == null) return null;
      _activePages[_activePages.length - 2] = resMiddleware;
    }

    final completer = _activePages.removeAt(index).route?.completer;
    if (completer?.isCompleted == false) completer!.complete(result);

    return completer?.future as T?;
  }

  T arguments<T>() {
    return currentConfiguration?.pageSettings?.arguments as T;
  }

  Map<String, String> get parameters {
    return currentConfiguration?.pageSettings?.params ?? {};
  }

  PageSettings? get pageSettings {
    return currentConfiguration?.pageSettings;
  }

  Future<void> _pushHistory(RouteDecoder config) async {
    if (config.route!.preventDuplicates) {
      final originalEntryIndex = _activePages.indexWhere(
        (element) => element.pageSettings?.name == config.pageSettings?.name,
      );
      if (originalEntryIndex >= 0) {
        switch (preventDuplicateHandlingMode) {
          case PreventDuplicateHandlingMode.popUntilOriginalRoute:
            popModeUntil(config.pageSettings!.name, popMode: PopMode.page);
            break;
          case PreventDuplicateHandlingMode.reorderRoutes:
            await _unsafeHistoryRemoveAt(originalEntryIndex, null);
            await _unsafeHistoryAdd(config);
            break;
          case PreventDuplicateHandlingMode.doNothing:
          default:
            break;
        }
        return;
      }
    }
    await _unsafeHistoryAdd(config);
  }

  Future<T?> _popHistory<T>(T result) async {
    if (!_canPopHistory()) return null;
    return await _doPopHistory(result);
  }

  Future<T?> _doPopHistory<T>(T result) async {
    return _unsafeHistoryRemoveAt<T>(_activePages.length - 1, result);
  }

  Future<T?> _popPage<T>(T result) async {
    if (!_canPopPage()) return null;
    return await _doPopPage(result);
  }

  // returns the popped page
  Future<T?> _doPopPage<T>(T result) async {
    final currentBranch = currentConfiguration?.currentTreeBranch;
    if (currentBranch != null && currentBranch.length > 1) {
      //remove last part only
      final remaining = currentBranch.take(currentBranch.length - 1);
      final prevHistoryEntry = _activePages.length > 1
          ? _activePages[_activePages.length - 2]
          : null;

      //check if current route is the same as the previous route
      if (prevHistoryEntry != null) {
        //if so, pop the entire _activePages entry
        final newLocation = remaining.last.name;
        final prevLocation = prevHistoryEntry.pageSettings?.name;
        if (newLocation == prevLocation) {
          //pop the entire _activePages entry
          return await _popHistory(result);
        }
      }

      //create a new route with the remaining tree branch
      final res = await _popHistory<T>(result);
      await _pushHistory(
        RouteDecoder(
          remaining.toList(),
          null,
          //TOOD: persist state??
        ),
      );
      return res;
    } else {
      //remove entire entry
      return await _popHistory(result);
    }
  }

  Future<T?> _pop<T>(PopMode mode, T result) async {
    switch (mode) {
      case PopMode.history:
        return await _popHistory<T>(result);
      case PopMode.page:
        return await _popPage<T>(result);
    }
  }

  Future<T?> popHistory<T>(T result) async {
    return await _popHistory<T>(result);
  }

  bool _canPopHistory() {
    return _activePages.length > 1;
  }

  Future<bool> canPopHistory() {
    return SynchronousFuture(_canPopHistory());
  }

  bool _canPopPage() {
    final currentTreeBranch = currentConfiguration?.currentTreeBranch;
    if (currentTreeBranch == null) return false;
    return currentTreeBranch.length > 1 ? true : _canPopHistory();
  }

  Future<bool> canPopPage() {
    return SynchronousFuture(_canPopPage());
  }

  bool _canPop(PopMode mode) {
    switch (mode) {
      case PopMode.history:
        return _canPopHistory();
      case PopMode.page:
        return _canPopPage();
    }
  }

  /// gets the visual pages from the current _activePages entry
  ///
  /// visual pages must have [GetPage.participatesInRootNavigator] set to true
  Iterable<GetPage> getVisualPages(RouteDecoder? currentHistory) {
    final res = currentHistory!.currentTreeBranch.where(
      (r) => r.participatesInRootNavigator != null,
    );
    if (res.isEmpty) {
      //default behavior, all routes participate in root navigator
      return _activePages.map((e) => e.route!);
    } else {
      //user specified at least one participatesInRootNavigator
      return res.where(
        (element) => element.participatesInRootNavigator == true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentHistory = currentConfiguration;
    final pages = currentHistory == null
        ? <GetPage>[]
        : pickPagesForRootNavigator?.call(currentHistory).toList() ??
              getVisualPages(currentHistory).toList();
    if (pages.isEmpty) {
      return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
    }
    return GetNavigator(
      key: navigatorKey,
      onPopPage: _onPopVisualRoute,
      pages: pages,
      observers: navigatorObservers,
      transitionDelegate:
          transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
    );
  }

  @override
  Future<void> goToUnknownPage([bool clearPages = false]) async {
    if (clearPages) _activePages.clear();

    final pageSettings = _buildPageSettings(notFoundRoute.name);
    final routeDecoder = _getRouteDecoder(pageSettings);

    _push(routeDecoder!);
  }

  @protected
  void _popWithResult<T>([T? result]) {
    // 移除栈顶的页面
    final completer = _activePages.removeLast().route?.completer;
    if (completer?.isCompleted == false) completer!.complete(result);
  }

  /// 除了 [page] 和 [arguments]，其他参数都没有用到, 其实可以删除
  @override
  Future<T?> toNamed<T>(
    String page, {
    dynamic arguments,
    dynamic id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) async {
    // 根据 [page] 和 [arguments] 创建一个 [PageSettings] 对象
    final args = _buildPageSettings(page, arguments);
    // 根据 [args] 创建一个 [RouteDecoder] 对象
    final route = _getRouteDecoder<T>(args);
    if (route != null) {
      return _push<T>(route);
    } else {
      // 如果找不到对应的路由, 就直接跳转到未找到路由页面
      goToUnknownPage();
    }
    return null;
  }

  @override
  Future<T?> to<T>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? id,
    String? routeName,
    bool fullscreenDialog = false,
    dynamic arguments,
    List<BindingsInterface> bindings = const [],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
    bool rebuildStack = true,
    PreventDuplicateHandlingMode preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
  }) async {
    routeName ??= _cleanRouteName("/${page.runtimeType}");
    // if (preventDuplicateHandlingMode ==
    //PreventDuplicateHandlingMode.Recreate) {
    //   routeName = routeName + page.hashCode.toString();
    // }

    final getPage = GetPage<T>(
      name: routeName,
      opaque: opaque ?? true,
      page: page,
      gestureWidth: gestureWidth,
      showCupertinoParallax: showCupertinoParallax,
      popGesture: popGesture ?? Get.defaultPopGesture,
      transition: transition ?? Get.defaultTransition,
      curve: curve ?? Get.defaultTransitionCurve,
      fullscreenDialog: fullscreenDialog,
      bindings: bindings,
      transitionDuration: duration ?? Get.defaultTransitionDuration,
      preventDuplicateHandlingMode: preventDuplicateHandlingMode,
    );

    _routeTree.addRoute(getPage);
    final args = _buildPageSettings(routeName, arguments);
    final route = _getRouteDecoder<T>(args);
    final result = await _push<T>(route!, rebuildStack: rebuildStack);
    _routeTree.removeRoute(getPage);
    return result;
  }

  @override
  Future<T?> off<T>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? id,
    String? routeName,
    bool fullscreenDialog = false,
    dynamic arguments,
    List<BindingsInterface> bindings = const [],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
  }) async {
    routeName ??= _cleanRouteName("/${page.runtimeType}");
    final route = GetPage<T>(
      name: routeName,
      opaque: opaque ?? true,
      page: page,
      gestureWidth: gestureWidth,
      showCupertinoParallax: showCupertinoParallax,
      popGesture: popGesture ?? Get.defaultPopGesture,
      transition: transition ?? Get.defaultTransition,
      curve: curve ?? Get.defaultTransitionCurve,
      fullscreenDialog: fullscreenDialog,
      bindings: bindings,
      transitionDuration: duration ?? Get.defaultTransitionDuration,
    );

    final args = _buildPageSettings(routeName, arguments);
    return _replace(args, route);
  }

  @override
  Future<T?>? offAll<T>(
    Widget Function() page, {
    bool Function(GetPage route)? predicate,
    bool opaque = true,
    bool? popGesture,
    String? id,
    String? routeName,
    dynamic arguments,
    List<BindingsInterface> bindings = const [],
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
  }) async {
    routeName ??= _cleanRouteName("/${page.runtimeType}");
    final route = GetPage<T>(
      name: routeName,
      opaque: opaque,
      page: page,
      gestureWidth: gestureWidth,
      showCupertinoParallax: showCupertinoParallax,
      popGesture: popGesture ?? Get.defaultPopGesture,
      transition: transition ?? Get.defaultTransition,
      curve: curve ?? Get.defaultTransitionCurve,
      fullscreenDialog: fullscreenDialog,
      bindings: bindings,
      transitionDuration: duration ?? Get.defaultTransitionDuration,
    );

    final args = _buildPageSettings(routeName, arguments);

    final newPredicate = predicate ?? (route) => false;

    while (_activePages.length > 1 && !newPredicate(_activePages.last.route!)) {
      _popWithResult();
    }

    return _replace(args, route);
  }

  @override
  Future<T?>? offAllNamed<T>(
    String newRouteName, {
    // bool Function(GetPage route)? predicate,
    dynamic arguments,
    String? id,
    Map<String, String>? parameters,
  }) async {
    final args = _buildPageSettings(newRouteName, arguments);
    final route = _getRouteDecoder<T>(args);
    if (route == null) return null;

    while (_activePages.length > 1) {
      _activePages.removeLast();
    }

    return _replaceNamed(route);
  }

  @override
  Future<T?>? offNamedUntil<T>(
    String page, {
    bool Function(GetPage route)? predicate,
    dynamic arguments,
    String? id,
    Map<String, String>? parameters,
  }) async {
    final args = _buildPageSettings(page, arguments);
    final route = _getRouteDecoder<T>(args);
    if (route == null) return null;

    final newPredicate = predicate ?? (route) => false;

    while (_activePages.length > 1 && !newPredicate(_activePages.last.route!)) {
      _activePages.removeLast();
    }

    return _push(route);
  }

  @override
  Future<T?> offNamed<T>(
    String page, {
    dynamic arguments,
    String? id,
    Map<String, String>? parameters,
  }) async {
    final args = _buildPageSettings(page, arguments);
    final route = _getRouteDecoder<T>(args);
    if (route == null) return null;
    _popWithResult();
    return _push<T>(route);
  }

  @override
  Future<T?> toNamedAndOffUntil<T>(
    String page,
    bool Function(GetPage) predicate, [
    Object? data,
  ]) async {
    final arguments = _buildPageSettings(page, data);

    final route = _getRouteDecoder<T>(arguments);

    if (route == null) return null;

    while (_activePages.isNotEmpty && !predicate(_activePages.last.route!)) {
      _popWithResult();
    }

    return _push<T>(route);
  }

  @override
  Future<T?> offUntil<T>(
    Widget Function() page,
    bool Function(GetPage) predicate, [
    Object? arguments,
  ]) async {
    while (_activePages.isNotEmpty && !predicate(_activePages.last.route!)) {
      _popWithResult();
    }

    return to<T>(page, arguments: arguments);
  }

  @override
  void removeRoute<T>(String name) {
    _activePages.remove(RouteDecoder.fromRoute(name));
  }

  /// 是否可以返回, 当 [_activePages] 只有一个页面时返回值为 false
  bool get canBack {
    return _activePages.length > 1;
  }

  /// 检查是否可以返回, 如果不可以返回抛出异常
  void _checkIfCanBack() {
    assert(() {
      if (!canBack) {
        final last = _activePages.last;
        final name = last.route?.name;
        throw 'The page $name cannot be popped';
      }
      return true;
    }());
  }

  @override
  Future<R?> backAndtoNamed<T, R>(
    String page, {
    T? result,
    Object? arguments,
  }) async {
    final args = _buildPageSettings(page, arguments);
    final route = _getRouteDecoder<R>(args);
    if (route == null) return null;
    _popWithResult<T>(result);
    return _push<R>(route);
  }

  /// Removes routes according to [PopMode]
  /// until it reaches the specific [fullRoute],
  /// DOES NOT remove the [fullRoute]
  @override
  Future<void> popModeUntil(
    String fullRoute, {
    PopMode popMode = PopMode.history,
  }) async {
    // remove history or page entries until you meet route
    var iterator = currentConfiguration;
    while (_canPop(popMode) && iterator != null) {
      //the next line causes wasm compile error if included in the while loop
      //https://github.com/flutter/flutter/issues/140110
      if (iterator.pageSettings?.name == fullRoute) {
        break;
      }
      await _pop(popMode, null);
      // replace iterator
      iterator = currentConfiguration;
    }
    notifyListeners();
  }

  /// 循环返回直到条件成立
  /// ? 为什么是这个判断条件? 写错了吧...
  /// ? (_activePages.length <= 1 && !predicate(_activePages.last.route!))
  /// 果然是之前的判断条件错了
  @override
  void backUntil(bool Function(GetPage) predicate) {
    while (_activePages.length > 1 && !predicate(_activePages.last.route!)) {
      _popWithResult();
    }

    notifyListeners();
  }

  Future<T?> _replace<T>(PageSettings arguments, GetPage<T> page) async {
    final index = _activePages.length > 1 ? _activePages.length - 1 : 0;
    _routeTree.addRoute(page);

    final activePage = _getRouteDecoder(arguments);

    // final activePage = _configureRouterDecoder<T>(route!, arguments);

    _activePages[index] = activePage!;

    notifyListeners();
    final result = await activePage.route?.completer?.future as Future<T?>?;
    _routeTree.removeRoute(page);

    return result;
  }

  Future<T?> _replaceNamed<T>(RouteDecoder activePage) async {
    final index = _activePages.length > 1 ? _activePages.length - 1 : 0;
    // final activePage = _configureRouterDecoder<T>(page, arguments);
    _activePages[index] = activePage;

    notifyListeners();
    final result = await activePage.route?.completer?.future as Future<T?>?;
    return result;
  }

  /// Takes a route [name] String generated by [to], [off], [offAll]
  /// (and similar context navigation methods), cleans the extra chars and
  /// accommodates the format.
  /// TODO: check for a more "appealing" URL naming convention.
  /// `() => MyHomeScreenView` becomes `/my-home-screen-view`.
  String _cleanRouteName(String name) {
    name = name.replaceAll('() => ', '');

    /// uncomment for URL styling.
    // name = name.paramCase!;
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }

  PageSettings _buildPageSettings(String page, [Object? data]) {
    var uri = Uri.parse(page);
    return PageSettings(uri, data);
  }

  /// 根据 [arguments] 生成 [RouteDecoder] 对象
  @protected
  RouteDecoder? _getRouteDecoder<T>(PageSettings arguments) {
    // 获取路由 path
    var page = arguments.uri.path;
    final parameters = arguments.params;
    // 如果有 [parameters] 则拼接参数
    if (parameters.isNotEmpty) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    // 根据正则匹配 route, 从这个路由数中获取匹配的路由子树
    final decoder = _routeTree.matchRoute(page, arguments: arguments);
    // 取出子树中的栈顶路由, 即展示在最前面的 GetPage
    final route = decoder.route;
    if (route == null) return null;

    // 解码路由, 即合并参数
    return _configureRouterDecoder<T>(decoder, arguments);
  }

  /// 合并所有的参数, 并将新的参数覆盖旧的参数
  /// 返回新的 [RouteDecoder]
  @protected
  RouteDecoder _configureRouterDecoder<T>(
    RouteDecoder decoder,
    PageSettings arguments,
  ) {
    final parameters = arguments.params.isEmpty
        ? arguments.query
        : arguments.params;
    arguments.params.addAll(arguments.query);
    if (decoder.parameters.isEmpty) {
      decoder.parameters.addAll(parameters);
    }

    decoder.route = decoder.route?.copyWith(
      // ???: 页面保活? _activePages 里存的是什么? 后面再看
      completer: _activePages.isEmpty ? null : Completer<T?>(),
      arguments: arguments,
      parameters: parameters,
      key: ValueKey(arguments.name),
    );

    return decoder;
  }

  Future<T?> _push<T>(RouteDecoder decoder, {bool rebuildStack = true}) async {
    /// 跳转之前运行中间件
    var res = await runMiddleware(decoder);
    // 如果中间件返回 null 则不跳转
    if (res == null) return null;
    // // 最终要 push 的路由
    // final res = mid ?? decoder;
    // if (res == null) res = decoder;

    final preventDuplicateHandlingMode =
        res.route?.preventDuplicateHandlingMode ??
        PreventDuplicateHandlingMode.reorderRoutes;

    /// 当前路由栈中是否有重复路由
    final onStackPage = _activePages
        .firstWhereOrNull((element) => element.route?.key == res.route?.key);

    /// There are no duplicate routes in the stack
    // 没有重复的路由, 则将新路由添加到路由栈中
    if (onStackPage == null) {
      _activePages.add(res);
    } else {
      /// There are duplicate routes, reorder
      // 如果存在重复路线，需要对路由栈重新排序
      switch (preventDuplicateHandlingMode) {
        case PreventDuplicateHandlingMode.doNothing:
          break;
        // 将找到的重复路由移除, 并将新路由添加到路由栈栈顶
        case PreventDuplicateHandlingMode.reorderRoutes:
          _activePages.remove(onStackPage);
          _activePages.add(res);
          break;
        // 移除找到的重复路由后面的所有路由
        case PreventDuplicateHandlingMode.popUntilOriginalRoute:
          while (_activePages.last == onStackPage) {
            _popWithResult();
          }
          break;
        // 和 reorderRoutes 模式一样
        case PreventDuplicateHandlingMode.recreate:
          _activePages.remove(onStackPage);
          _activePages.add(res);
      }
    }
    // 如果需要重新构建路由栈, 则通知监听
    if (rebuildStack) {
      notifyListeners();
    }

    return decoder.route?.completer?.future as Future<T?>?;
  }

  @override
  Future<void> setNewRoutePath(RouteDecoder configuration) async {
    final page = configuration.route;
    if (page == null) {
      goToUnknownPage();
      return;
    } else {
      _push(configuration);
    }
  }

  @override
  RouteDecoder? get currentConfiguration {
    if (_activePages.isEmpty) return null;
    final route = _activePages.last;
    return route;
  }

  Future<bool> handlePopupRoutes({Object? result}) async {
    Route? currentRoute;
    navigatorKey.currentState!.popUntil((route) {
      currentRoute = route;
      return true;
    });
    if (currentRoute is PopupRoute) {
      return await navigatorKey.currentState!.maybePop(result);
    }
    return false;
  }

  @override
  Future<bool> popRoute({Object? result, PopMode? popMode}) async {
    //Returning false will cause the entire app to be popped.
    final wasPopup = await handlePopupRoutes(result: result);
    if (wasPopup) return true;

    if (_canPop(popMode ?? backButtonPopMode)) {
      await _pop(popMode ?? backButtonPopMode, result);
      notifyListeners();
      return true;
    }

    return super.popRoute();
  }

  @override
  void back<T>([T? result]) {
    // 检查是否有可以返回的页面
    _checkIfCanBack();
    // 移除栈顶的页面
    _popWithResult<T>(result);
    // 通知监听
    notifyListeners();
  }

  bool _onPopVisualRoute(Route<dynamic> route, dynamic result) {
    final didPop = route.didPop(result);
    if (!didPop) {
      return false;
    }
    _popWithResult(result);
    // final settings = route.settings;
    // if (settings is GetPage) {
    //   final config = _activePages.cast<RouteDecoder?>().firstWhere(
    //         (element) => element?.route == settings,
    //         orElse: () => null,
    //       );
    //   if (config != null) {
    //     _removeHistoryEntry(config, result);
    //   }
    // }
    notifyListeners();
    //return !route.navigator!.userGestureInProgress;
    return true;
  }
}
