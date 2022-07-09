import 'dart:io';
import 'dart:math';

import 'package:kaze_proxy/src/constants.dart';
import 'package:kaze_proxy/src/timeout_exception.dart';
import 'package:udp/udp.dart';

import 'protocol_structs.dart';
import 'src/utils.dart';

class PingTool {
  static Future<PongData> ping(
      {required String host, required int port}) async {
    UDP sendSocket = await UDP.bind(Endpoint.any());

    sendSocket.send(_buildPingPacket(), await Utils.hostLookup(host, port));

    var rawPong =
        (sendSocket.asStream().timeout(Duration(seconds: 1), onTimeout: (_) {
      throw ServerTimeoutException();
    }).first);

    return UnconnectedPing.fromBytes((await rawPong)!.data).pong;
  }

  static List<int> _buildPingPacket() {
    BytesBuilder builder = BytesBuilder();

    builder.addByte(Constants.unconnectedPingId);
    builder.add(Constants.empty8Bytes);
    builder.add(Constants.unconnectedMagic);
    builder.add(Utils.encodeEndian(Random.secure().nextInt(pow(2, 32) as int), 4));
    builder.add(Utils.encodeEndian(Random.secure().nextInt(pow(2, 32) as int), 4));

    return builder.toBytes();
  }
}
