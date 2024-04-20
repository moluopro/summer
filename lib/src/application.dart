import 'dart:async';
import 'dart:io';

import 'package:summer/src/router/router.dart';

import 'http/http.dart';

class Application with Server, RequestHandler {
  final Map<String, dynamic> _settings = {};
  WebSocketRouterInternal? _webSocketRouter;
  HttpRouterInternal? _httpRouter;
  TCPRouterInternal? _tcpRouter;
  UDPRouterInternal? _udpRouter;

  @override
  Future<void> listen({int? httpPort, int? tcpPort, int? udpPort}) {
    if (httpPort != null) {
      request(_httpHandle, _webSocketHandle);
    }
    if (tcpPort != null) {
      tcpRequest(_tcpHandle);
    }
    if (udpPort != null) {
      udpRequest(_udpHandle);
    }
    return super.listen(httpPort: httpPort, tcpPort: tcpPort, udpPort: udpPort);
  }

  Application set(String setting, dynamic val) {
    _settings[setting] = val;
    return this;
  }

  Application use({String path = '/', required List<HttpHandler> fns}) {
    use() async {
      await _lazyRouter();
      _httpRouter?.use(path: path, fns: fns);
    }

    use();
    return this;
  }

  Application useHttpRouter({String path = '/', required HttpRouter router}) {
    useRouter() async {
      await _lazyRouter();
      _httpRouter?.useRouter(path: path, router: router);
    }

    useRouter();
    return this;
  }

  Application useWebSocketRouter(
      {String path = '/', required WebSocketRouter router}) {
    useRouter() async {
      await _lazyRouter();
      _webSocketRouter?.useRouter(path: path, router: router);
    }

    useRouter();
    return this;
  }

  void useTCPRouter(TCPRouter router) {
    useRouter() async {
      await _lazyRouter();
      _tcpRouter?.useRouter(path: '/', router: router);
    }

    useRouter();
  }

  void useUDPRouter(UDPRouter router) {
    useRouter() async {
      await _lazyRouter();
      _udpRouter?.useRouter(path: '/', router: router);
    }

    useRouter();
  }

  Application params(List<String> names, Function fn) {
    params() async {
      await _lazyRouter();
      for (var name in names) {
        param(name, fn);
      }
    }

    params();
    return this;
  }

  Application param(String name, Function fn) {
    param() async {
      await _lazyRouter();
      _httpRouter?.param(name, fn);
    }

    param();
    return this;
  }

  FutureOr<void> _httpHandle(Request req, Response res,
      void Function(Request req, Response res, String? err)? done) async {
    var handler = done ?? httpFinalHandler;
    await _lazyRouter();
    await _httpRouter?.handle([req, res], handler);
  }

  FutureOr<void> _webSocketHandle(Request req, WebSocket ws,
      void Function(Request req, WebSocket ws, String? err)? done) async {
    var handler = done ?? webSocketFinalHandler;
    await _lazyRouter();
    await _webSocketRouter?.handle([req, ws], handler);
  }

  FutureOr<void> _tcpHandle(
      Socket client, void Function(Socket client, String? err)? done) async {
    await _lazyRouter();
    await _tcpRouter?.handle([client], null);
  }

  FutureOr<void> _udpHandle(RawDatagramSocket client,
      void Function(RawDatagramSocket client, String? err)? done) async {
    await _lazyRouter();
    await _udpRouter?.handle([client], null);
  }

  Future<void> _lazyRouter() async {
    if (await isHttpServerConnected()) {
      _httpRouter ??= HttpRouterInternal();
      _webSocketRouter ??= WebSocketRouterInternal();
    }
    if (await isTCPServerConnected()) {
      _tcpRouter ??= TCPRouterInternal();
    }
    if (await isUDPServerConnected()) {
      _udpRouter ??= UDPRouterInternal();
    }
  }

  Future<void> _checkServerConnection() async {
    if (!await isHttpServerConnected()) {
      throw Exception('Server connection failure');
    }
  }

  Future<void> _checkTCPConnection() async {
    if (!await isHttpServerConnected()) {
      throw Exception('TCP connection failure');
    }
  }

  Future<void> _checkUDPConnection() async {
    if (!await isHttpServerConnected()) {
      throw Exception('UDP connection failure');
    }
  }

  @override
  Application get(String path, List<HttpHandler> callbacks) {
    void get() async {
      await _lazyRouter();
      await _checkServerConnection();
      var route = _httpRouter?.route(path);
      for (var cb in callbacks) {
        route?.request(HttpMethod.httpGet, cb);
      }
    }

    get();
    return this;
  }

  @override
  Application post(String path, List<HttpHandler> callbacks) {
    void post() async {
      await _lazyRouter();
      await _checkServerConnection();
      var route = _httpRouter?.route(path);
      for (var cb in callbacks) {
        route?.request(HttpMethod.httpPost, cb);
      }
    }

    post();
    return this;
  }

  @override
  Application delete(String path, List<HttpHandler> callbacks) {
    void delete() async {
      await _lazyRouter();
      await _checkServerConnection();
      var route = _httpRouter?.route(path);
      for (var cb in callbacks) {
        route?.request(HttpMethod.httpDelete, cb);
      }
    }

    delete();
    return this;
  }

  @override
  Application head(String path, List<HttpHandler> callbacks) {
    void head() async {
      await _lazyRouter();
      await _checkServerConnection();
      var route = _httpRouter?.route(path);
      for (var cb in callbacks) {
        route?.request(HttpMethod.httpHead, cb);
      }
    }

    head();
    return this;
  }

  @override
  Application options(String path, List<HttpHandler> callbacks) {
    void options() async {
      await _lazyRouter();
      await _checkServerConnection();
      var route = _httpRouter?.route(path);
      for (var cb in callbacks) {
        route?.request(HttpMethod.httpOptions, cb);
      }
    }

    options();
    return this;
  }

  @override
  Application patch(String path, List<HttpHandler> callbacks) {
    void patch() async {
      await _lazyRouter();
      await _checkServerConnection();
      var route = _httpRouter?.route(path);
      for (var cb in callbacks) {
        route?.request(HttpMethod.httpPatch, cb);
      }
    }

    patch();
    return this;
  }

  @override
  Application put(String path, List<HttpHandler> callbacks) {
    void put() async {
      await _lazyRouter();
      await _checkServerConnection();
      var route = _httpRouter?.route(path);
      for (var cb in callbacks) {
        route?.request(HttpMethod.httpPut, cb);
      }
    }

    put();
    return this;
  }

  Application all(String path, List<HttpHandler> callbacks) {
    void all() async {
      await _lazyRouter();
      await _checkServerConnection();
      for (var method in HttpMethod.methods) {
        var route = _httpRouter?.route(path);
        for (var cb in callbacks) {
          route?.request(method, cb);
        }
      }
    }

    all();
    return this;
  }

  @override
  WebSocketMethod ws(String path, List<WebSocketHandler> callbacks) {
    void ws() async {
      await _lazyRouter();
      await _checkServerConnection();
      var route = _webSocketRouter?.route(path);
      for (var cb in callbacks) {
        route?.request(WebSocketMethod.name, cb);
      }
    }

    ws();
    return this;
  }

  @override
  void tcp(TCPSocketHandler callback) {
    void tcp() async {
      await _lazyRouter();
      await _checkTCPConnection();
      var route = _tcpRouter?.route('/');
      route?.request(TCPMethod.name, callback);
    }

    tcp();
  }

  @override
  void udp(UDPSocketHandler callback) {
    udp() async {
      await _lazyRouter();
      await _checkUDPConnection();
      var route = _udpRouter?.route('');
      route?.request(UDPMethod.name, callback);
    }

    udp();
  }
}

Application createApp() {
  return Application();
}
