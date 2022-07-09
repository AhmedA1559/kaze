import 'dart:async';
import 'dart:math';

import 'package:kaze_proxy/protocol_structs.dart';
import 'package:kaze_proxy/src/client_map.dart';
import 'package:kaze_proxy/src/constants.dart';
import 'package:udp/udp.dart';

import 'src/utils.dart';

class Proxy {
  final UDP _listenSocket;
  final Endpoint _serverEndpoint;
  final ClientMap _clientMap = ClientMap();
  bool _online = false;

  bool get online => _online;

  bool _closed = true;

  final _randomServerID = Random.secure().nextInt(pow(2, 32) as int).toString();

  Proxy(this._listenSocket, this._serverEndpoint);

  static Future<Proxy> bindRemote(
      {required String host, required int port}) async {
    return Proxy(await UDP.bind(Endpoint.any(port: Port(19132))),
        await Utils.hostLookup(host, port));
  }

  void start() async {
    _closed = false;

    readFromClients();
  }

  Future<void> readFromClients() async {
    _online =
        true; // assume online unless server doesnt respond after 5 seconds

    Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_closed) {
        _clientMap.cleanUp();
      }
    });

    _listenSocket.asStream().listen((packet) async {
      // receive packets from clients
      if (packet != null) {
        var endpoint = Endpoint.unicast(packet.address,
            port: Port(packet.port)); // client endpoint

        if (packet.data[0] == Constants.unconnectedPingId && !_online) {
          _listenSocket.send(
              _rewritePong(UnconnectedPing.offlinePong.toBytes()), endpoint);
        }

        // send packet to server after intercept
        _clientMap.get(endpoint, readFromServer).then(
            (sendSocket) => sendSocket.send(packet.data, _serverEndpoint));
      }
    });
  }

  Future<void> readFromServer(UDP sendSocket, Endpoint client) async {
    sendSocket.asStream().timeout(Duration(seconds: 5), onTimeout: (d) {
      _online = false;
    }).listen((packet) async {
      if (!_online) _online = true;
      if (packet != null) {
        if (packet.data[0] == Constants.unconnectedPongId) {
          await _listenSocket.send(_rewritePong(packet.data), client);
        } else {
          await _listenSocket.send(packet.data, client);
        }
      }
    });
  }

  List<int> _rewritePong(List<int> data) {
    var unconnectedPing = UnconnectedPing.fromBytes(data);

    unconnectedPing.pong.serverId = _randomServerID;

    unconnectedPing.pong.port4 = _listenSocket.local.port!.value.toString();
    unconnectedPing.pong.port6 = _listenSocket.local.port!.value.toString();

    return unconnectedPing.toBytes();
  }

  void stop() {
    _closed = true;

    _listenSocket.close();
    _clientMap.close();
  }
}
