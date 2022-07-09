import 'dart:io';

import 'package:udp/udp.dart';

enum EndianType {
  littleEndian,
  bigEndian
}

class Utils {
  static Future<Endpoint> hostLookup(String host, int port) async {
    if (!(1 <= port && 65535 >= port)) {
      throw ArgumentError(
          "Invalid port. Make sure that the port is between 1 and 65535!");
    }
    var firstHost =
        (await InternetAddress.lookup(host, type: InternetAddressType.IPv4))[0];

    return Endpoint.multicast(firstHost, port: Port(port));
  }

  /**
   * TAKEN FROM https://github.com/myamolane/encode-endian
   */
  static List<int> encodeEndian(int n, int k, { endianType = EndianType.bigEndian }) {
    var hexStr = getHexString(n, k);
    var bytes = convertHexString2Bytes(hexStr);

    return convertBytesEndianType(bytes, k, endianType);
  }

  static String getHexString(int n, int k) {
    if (n < 0) {
      n = int.parse('0x1' + '00' * k) + n;
    }

    var str = n.toRadixString(16);

    if (str.length % 2 == 1) {
      str = '0' + str;
    }
    return str;
  }

  static Iterable<int> convertHexString2Bytes(String hexString) {
    return RegExp(r'.{1,2}').allMatches(hexString).map((x) {
      return int.parse(x[0]!, radix: 16);
    });
  }

  static List<int> convertBytesEndianType(Iterable<int> bytes, int k, EndianType endianType) {
    switch(endianType) {
      case EndianType.littleEndian:
        var ret = List<int>.from(bytes).reversed.toList();
        ret.addAll(List<int>.filled(k - bytes.length, 0));
        return ret;
      case EndianType.bigEndian:
      default:
        var ret = List<int>.filled(k - bytes.length, 0, growable: true);
        ret.addAll(bytes);
        return ret;
    }
  }
  /**
   * END ATTRIBUTION
   */
}
