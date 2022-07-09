// Data Classes templated from phantom.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kaze_proxy/src/constants.dart';
import 'package:kaze_proxy/src/utils.dart';

class UnconnectedPing {
  static final UnconnectedPing offlinePong = UnconnectedPing(
      pingTime: Constants.empty8Bytes,
      id: Constants.empty8Bytes,
      magic: Constants.unconnectedMagic,
      pong: PongData(
          edition: "MCPE",
          motd: "§cServer offline",
          protocolVersion: "390",
          version: "1.14.60",
          players: "0",
          maxPlayers: "0",
          gameType: "Creative",
          nintendoLimited: "1"));

  List<int> pingTime;
  List<int> id;
  List<int> magic;
  PongData pong;

//<editor-fold desc="Data Methods">

  UnconnectedPing({
    required this.pingTime,
    required this.id,
    required this.magic,
    required this.pong,
  });

  List<int> toBytes() {
    var pongBytes = pong.toBytes();

    BytesBuilder builder = BytesBuilder();
    builder.addByte(Constants.unconnectedPongId);
    builder.add(pingTime);
    builder.add(id);
    builder.add(magic);

    builder.add(Utils.encodeEndian(pongBytes.length, 2,
        endianType:
            EndianType.bigEndian)); // not even going to bother with this

    builder.add(pongBytes);

    return builder.toBytes();
  }

  factory UnconnectedPing.fromBytes(List<int> bytes) {
    return UnconnectedPing(
        pingTime: bytes.getRange(1, 9).toList(),
        id: bytes.getRange(9, 17).toList(),
        magic: bytes.getRange(17, 33).toList(),
        pong: PongData.fromBytes(bytes.getRange(35, bytes.length).toList()));
  }

//</editor-fold>
}

class PongData {
  String edition;
  String gameType;
  String motd;
  String maxPlayers;
  String nintendoLimited;
  String players;
  String port4;
  String port6;
  String protocolVersion;
  String serverId;
  String subMOTD;
  String version;

//<editor-fold desc="Data Methods">

  PongData({
    required this.edition,
    this.gameType = "",
    required this.motd,
    required this.maxPlayers,
    required this.nintendoLimited,
    required this.players,
    this.port4 = "",
    this.port6 = "",
    required this.protocolVersion,
    this.serverId = "",
    this.subMOTD = "",
    required this.version,
  });

  List<int> toBytes() {
    return utf8.encode(
        ('$edition;$motd;$protocolVersion;$version;$players;$maxPlayers;$serverId;$subMOTD;$gameType;$nintendoLimited;$port4;$port6;')
            .replaceAll(RegExp(r';{2,}$'), ';'));
  }

  factory PongData.fromBytes(List<int> bytes) {
    var split = utf8.decode(bytes, allowMalformed: true).split(";");
    return PongData(
        edition: split.isNotEmpty ? split[0] : "",
        motd: split.length > 1 ? split[1] : "",
        protocolVersion: split.length > 2 ? split[2] : "",
        version: split.length > 3 ? split[3] : "",
        players: split.length > 4 ? split[4] : "",
        maxPlayers: split.length > 5 ? split[5] : "",
        serverId: split.length > 6 ? split[6] : "",
        subMOTD: split.length > 7 ? split[7] : "",
        gameType: split.length > 8 ? split[8] : "",
        nintendoLimited: split.length > 9 ? split[9] : "",
        port4: split.length > 10 ? split[10] : "",
        port6: split.length > 11 ? split[11] : "");
  }

//</editor-fold>
}
