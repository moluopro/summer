library router;

import 'dart:async';

import 'package:sumcat/src/http/http.dart';

import '../layer/layer.dart';

part './route.dart';

class Router {
  final List<Layer> _stack = [];
  final Map<String, List<Function>> _params = {};

  Router use({String path = '/', required List<Function> fns}) {
    for (var fn in fns) {
      var layer = MiddlewareLayer(path, fn);
      _stack.add(layer);
    }
    return this;
  }

  Route route(String path) {
    var route = Route(path);
    var layer = HandleLayer(path, route.dispatch);
    layer.route = route;
    _stack.add(layer);
    return route;
  }

  void param(
      String name,
      void Function(HttpRequestWrapper, HttpResponseWrapper, Completer<String?>,
              dynamic, String name)
          fn) {
    _params[name] ??= [];
    _params[name]?.add(fn);
  }

  void handle(
      HttpRequestWrapper req,
      HttpResponseWrapper res,
      void Function(HttpRequestWrapper, HttpResponseWrapper, String?)?
          done) async {
    String? err;
    String? layerError;
    var idx = 0;
    Map<String, Map<String, dynamic>> paramCalled = {};
    while (true) {
      Layer? layer;
      Route? route;
      layerError = err == 'route' ? '' : err;
      if (layerError == 'router' || layerError == 'finish') {
        Future.microtask(() => done?.call(req, res, ''));
        break;
      }

      if (idx >= _stack.length) {
        Future.microtask(() => done?.call(req, res, layerError));
        break;
      }

      var match = false;
      while (!match && idx < _stack.length) {
        layer = _stack[idx++];
        var path = req.inner.uri;
        route = layer.route;
        match = layer.match(path.path);
        if (!match) {
          continue;
        }
        if (route == null) {
          continue;
        }
        if (layerError != null && layerError.isNotEmpty) {
          match = false;
        }
      }

      if (!match) {
        done?.call(req, res, '');
        break;
      }

      req.params.addAll(layer!.param);

      Future<void> processParams(
          Layer layer,
          Map<String, Map<String, dynamic>> called,
          HttpRequestWrapper req,
          HttpResponseWrapper res,
          Future<void> Function([String?]) done) async {
        var keys = layer.keys;
        var keyIdx = 0;
        String? err = '';
        if (keys.isEmpty) {
          return done();
        }
        while (true) {
          if (err != null && err.isNotEmpty) {
            return await done(err);
          }
          if (keyIdx >= keys.length) {
            return await done();
          }
          var key = keys[keyIdx++];
          var paramVal = layer.param[key];
          var paramCallbacks = _params[key];
          var paramCalled = called[key];
          if (paramVal == null || paramCallbacks == null) {
            continue;
          }
          if (paramCalled != null &&
              (paramCalled['match'] == paramVal ||
                  (paramCalled['err'] != null &&
                      paramCalled['error'] != 'route'))) {
            req.params[key] = paramCalled['value'];
            err = paramCalled['error'];
            continue;
          }
          called[key] = paramCalled = {
            'error': null,
            'match': paramVal,
            'value': paramVal
          };
          var i = 0;
          while (true) {
            paramCalled['value'] = req.params[key];
            if (err != null && err.isNotEmpty) {
              paramCalled['error'] = err;
              break;
            }
            Function fn;
            var completer = Completer<String?>();
            if (i >= paramCallbacks.length) {
              break;
            } else {
              try {
                fn = paramCallbacks[i++];
                fn(req, res, completer, paramVal, key);
              } catch (e) {
                err = e.toString();
              } finally {
                if (!completer.isCompleted) {
                  completer.complete('finish');
                }
              }
              err = await completer.future;
            }
          }
        }
      }

      void trimPrefix(
          Layer layer, String layerError, String layerPath, String path) async {
        if (layerPath.isNotEmpty) {
          if (layerPath != path.substring(0, layerPath.length)) {
            err = layerError;
            return;
          }

          var c = '';
          try {
            c = path[layerPath.length];
          } on RangeError {
            err = layerError;
            return;
          }
          if (c != '/' && c != '.') {
            err = layerError;
            return;
          }

          var next = Completer<String?>();
          layerError.isNotEmpty
              ? await layer.handleError(err, req, res, next)
              : await layer.handleRequest(req, res, next);
          layerError = await next.future ?? '';
        }
      }

      await processParams(layer, paramCalled, req, res, ([String? err]) async {
        if (err != null && err.isNotEmpty) {
          err = layerError != null && layerError.isNotEmpty ? layerError : err;
        } else if (layer is HandleLayer) {
          var next = Completer<String?>();
          await layer.handleRequest(req, res, next);
          err = await next.future;
        } else {
          trimPrefix(layer!, layerError ?? '', layer.path, req.inner.uri.path);
        }
      });
    }
  }
}
