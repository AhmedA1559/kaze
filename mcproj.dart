import 'package:kaze/ping_tool.dart';

void main() async {
  var ping = (await PingTool.ping(host: "owls2026.tk", port: 25571));
  print(ping.maxPlayers);
  print(ping.edition);
  print(ping.players);
}
