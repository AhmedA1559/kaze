import 'dart:io';

import 'package:udp/udp.dart';

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
}
