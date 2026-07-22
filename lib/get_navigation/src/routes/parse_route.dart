import 'package:flutter/foundation.dart';

import '../../../get.dart';

@immutable
class RouteDecoder {
  const RouteDecoder(
    this.currentTreeBranch,
    this.pageSettings,
  );

  /// 从路由字符串匹配到的, 从根路由开始到当前路由的路由列表
  final List<GetPage> currentTreeBranch;

  ///
  final PageSettings? pageSettings;

  factory RouteDecoder.fromRoute(String location) {
    var uri = Uri.parse(location);
    final args = PageSettings(uri);
    final decoder = (Get.rootController.rootDelegate).matchRoute(
      location,
      arguments: args,
    );
    decoder.route = decoder.route?.copyWith(
      completer: null,
      arguments: args,
      parameters: args.params,
    );
    return decoder;
  }

  GetPage? get route =>
      currentTreeBranch.isEmpty ? null : currentTreeBranch.last;

  GetPage routeOrUnknown(GetPage onUnknow) =>
      currentTreeBranch.isEmpty ? onUnknow : currentTreeBranch.last;

  set route(GetPage? getPage) {
    if (getPage == null) return;
    if (currentTreeBranch.isEmpty) {
      currentTreeBranch.add(getPage);
    } else {
      currentTreeBranch[currentTreeBranch.length - 1] = getPage;
    }
  }

  List<GetPage>? get currentChildren => route?.children;

  Map<String, String> get parameters => pageSettings?.params ?? {};

  dynamic get args {
    return pageSettings?.arguments;
  }

  T? arguments<T>() {
    final args = pageSettings?.arguments;
    if (args is T) {
      return pageSettings?.arguments as T;
    } else {
      return null;
    }
  }

  // void replaceArguments(Object? arguments) {
  //   final newRoute = route;
  //   if (newRoute != null) {
  //     final index = currentTreeBranch.indexOf(newRoute);
  //     currentTreeBranch[index] = newRoute.copyWith(arguments: arguments);
  //   }
  // }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RouteDecoder &&
        listEquals(other.currentTreeBranch, currentTreeBranch) &&
        other.pageSettings == pageSettings;
  }

  @override
  int get hashCode => currentTreeBranch.hashCode ^ pageSettings.hashCode;

  @override
  String toString() =>
      'RouteDecoder(currentTreeBranch: $currentTreeBranch, pageSettings: $pageSettings)';
}

class ParseRouteTree {
  ParseRouteTree({required this.routes});

  /// 路由列表, 即 app_pages.dart 中的 routes
  final List<GetPage> routes;

  /// 从整个路由数中筛选出匹配的路由子树
  /// 返回一个 [RouteDecoder] 对象, 其中包含所有匹配的路由子树和参数信息。
  ///
  /// ```dart
  /// final result = matchRoute('/home/products/1711205037025');
  /// print(split); // WhereIterable<String> ((home, products, 1711205142604))
  /// print(cumulativePaths); // ['/', 'home', 'products', '1711205037025']
  /// print(treeBranch); // [{'/': GetPage()}, {'home': GetPage()}, {'home/products': : GetPage()}, {'/home/products/1711205142604':GetPage(),}]
  /// ```
  RouteDecoder matchRoute(String name, {PageSettings? arguments}) {
    final uri = Uri.parse(name);
    // 根据 '/' 分割字符串，并过滤掉空字符串
    final split = uri.path.split('/').where((element) => element.isNotEmpty);
    // 存储从根路径开始逐步累积的所有可能的路径
    var curPath = '/';
    final cumulativePaths = <String>['/'];
    for (var item in split) {
      if (curPath.endsWith('/')) {
        curPath += item;
      } else {
        curPath += '/$item';
      }
      cumulativePaths.add(curPath);
    }

    // 使用 cumulativePaths 中的每个路径尝试找到匹配的路由，如果找到，则将其及其关联的信息（如路径、参数等）存储在 treeBranch 中。
    final treeBranch = cumulativePaths
        .map((e) => MapEntry(e, _findRoute(e)))
        // 移除未找到的 key
        .where((element) => element.value != null)

        // Prevent page be disposed
        // 防止页面被销毁
        .map((e) => MapEntry(e.key, e.value!.copyWith(key: ValueKey(e.key))))
        .toList();

    // 解析路径参数（如果有）并将它们与查询参数合并。
    final params = Map<String, String>.from(uri.queryParameters);
    if (treeBranch.isNotEmpty) {
      // route is found, do further parsing to get nested query params
      // 找到路由，进行进一步解析以获取嵌套的 query params
      final lastRoute = treeBranch.last;
      // 解析路径参数
      final parsedParams = _parseParams(name, lastRoute.value.path);
      if (parsedParams.isNotEmpty) {
        params.addAll(parsedParams);
      }
      // copy parameters to all pages.
      // 将参数复制到所有页面。
      final mappedTreeBranch = treeBranch
          .map(
            (e) => e.value.copyWith(
              parameters: {
                if (e.value.parameters != null) ...e.value.parameters!,
                ...params,
              },
              name: e.key,
            ),
          )
          .toList();
      arguments?.params.clear();
      arguments?.params.addAll(params);
      // 如果找到匹配的路由，返回一个 RouteDecoder 对象，其中包含所有匹配的路由子树和参数信息。
      return RouteDecoder(
        mappedTreeBranch,
        arguments,
      );
    }

    arguments?.params.clear();
    arguments?.params.addAll(params);

    // route not found
    // 如果没有找到匹配的路由，返回一个包含空路由信息的 [RouteDecoder] 对象。
    return RouteDecoder(
      treeBranch.map((e) => e.value).toList(),
      arguments,
    );
  }

  void addRoutes<T>(List<GetPage<T>> getPages) {
    for (final route in getPages) {
      addRoute(route);
    }
  }

  void removeRoutes<T>(List<GetPage<T>> getPages) {
    for (final route in getPages) {
      removeRoute(route);
    }
  }

  void removeRoute<T>(GetPage<T> route) {
    routes.remove(route);
    for (var page in _flattenPage(route)) {
      removeRoute(page);
    }
  }

  void addRoute<T>(GetPage<T> route) {
    routes.add(route);

    // Add Page children.
    for (var page in _flattenPage(route)) {
      addRoute(page);
    }
  }

  List<GetPage> _flattenPage(GetPage route) {
    final result = <GetPage>[];
    if (route.children.isEmpty) {
      return result;
    }

    final parentPath = route.name;
    for (var page in route.children) {
      // Add Parent middlewares to children
      final parentMiddlewares = [
        if (page.middlewares.isNotEmpty) ...page.middlewares,
        if (route.middlewares.isNotEmpty) ...route.middlewares,
      ];

      final parentBindings = [
        if (page.binding != null) page.binding!,
        if (page.bindings.isNotEmpty) ...page.bindings,
        if (route.bindings.isNotEmpty) ...route.bindings,
      ];

      final parentBinds = [
        if (page.binds.isNotEmpty) ...page.binds,
        if (route.binds.isNotEmpty) ...route.binds,
      ];

      result.add(
        _addChild(
          page,
          parentPath,
          parentMiddlewares,
          parentBindings,
          parentBinds,
        ),
      );

      final children = _flattenPage(page);
      for (var child in children) {
        result.add(
          _addChild(
            child,
            parentPath,
            [
              ...parentMiddlewares,
              if (child.middlewares.isNotEmpty) ...child.middlewares,
            ],
            [
              ...parentBindings,
              if (child.binding != null) child.binding!,
              if (child.bindings.isNotEmpty) ...child.bindings,
            ],
            [...parentBinds, if (child.binds.isNotEmpty) ...child.binds],
          ),
        );
      }
    }
    return result;
  }

  /// Change the Path for a [GetPage]
  GetPage _addChild(
    GetPage origin,
    String parentPath,
    List<GetMiddleware> middlewares,
    List<BindingsInterface> bindings,
    List<Bind> binds,
  ) {
    return origin.copyWith(
      middlewares: middlewares,
      name: origin.inheritParentPath
          ? (parentPath + origin.name).replaceAll(r'//', '/')
          : origin.name,
      bindings: bindings,
      binds: binds,
      // key:
    );
  }

  /// 查找 [routes] 中第一个匹配 [name] 的 [GetPage]
  /// 具体匹配规则在 [GetPage._nameToRegex] 中
  GetPage? _findRoute(String name) {
    final value = routes.firstWhereOrNull(
      (route) => route.path.regex.hasMatch(name),
    );

    return value;
  }

  /// 解析路径参数
  Map<String, String> _parseParams(String path, PathDecoded routePath) {
    final params = <String, String>{};
    var idx = path.indexOf('?');
    final uri = Uri.tryParse(path);
    if (uri == null) return params;
    if (idx > -1) {
      // 如果 path 中有 ? 表示有参数, 有参数则添加所有参数
      params.addAll(uri.queryParameters);
    }
    // 根据提前生成好的正则匹配出路由上所有的参数
    var paramsMatch = routePath.regex.firstMatch(uri.path);
    if (paramsMatch == null) {
      return params;
    }
    for (var i = 0; i < routePath.keys.length; i++) {
      // 参数解码
      var param = Uri.decodeQueryComponent(paramsMatch[i + 1]!);
      // 参数替换
      params[routePath.keys[i]!] = param;
    }
    return params;
  }
}
