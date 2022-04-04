import 'dart:async';
import 'dart:collection';

import 'package:udp/udp.dart';

class ClientMap {
  final Map<String, _Client> _clientMap = HashMap<String, _Client>();

  // creates new connection if not present
  Future<UDP> get(
      Endpoint clientEndpoint, Function(UDP, Endpoint) handle) async {
    String ipKey =
        "${clientEndpoint.address!.address}:${clientEndpoint.port!.value}";

    if (_clientMap.containsKey(ipKey) && (_clientMap[ipKey]) != null) {
      var client = _clientMap[ipKey];
      client?.lastActive = DateTime.now(); // refresh active
      return client!.connection;
    } else {
      var newConn = await UDP.bind(Endpoint.any());
      _clientMap[ipKey] = _Client(newConn);

      unawaited(handle(newConn, clientEndpoint));
      return newConn;
    }
  }

  void close() {
    _clientMap.forEach((key, value) {
      value.connection.close();
    });
  }

  void cleanUp() {
    _clientMap.removeWhere((key, value) {
      if (DateTime.now().difference(value.lastActive) > Duration(seconds: 60)) {
        value.connection.close();
        return true;
      } else {
        return false;
      }
    });
  }
}

class _Client {
  final UDP connection;
  DateTime lastActive = DateTime.now();

  _Client(this.connection);
}
