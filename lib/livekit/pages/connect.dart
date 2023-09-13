import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_example/livekit/ext.dart';
import 'package:flutter_webrtc_example/livekit/widgets/text_field.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'room.dart';

class ConnectPage extends StatefulWidget {
  //
  const ConnectPage({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _serverUrl = 'wss://tirza-0svfwzsu.livekit.cloud';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (lkPlatformIs(PlatformType.android)) {
      _checkPremissions();
    }
  }

  Future<void> _checkPremissions() async {
    if (kIsWeb) {
      navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
    } else {
      var status = await Permission.bluetooth.request();
      if (status.isPermanentlyDenied) {
        print('Bluetooth Permission disabled');
      }

      status = await Permission.bluetoothConnect.request();
      if (status.isPermanentlyDenied) {
        print('Bluetooth Connect Permission disabled');
      }

      status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        print('Camera Permission disabled');
      }

      status = await Permission.microphone.request();
      if (status.isPermanentlyDenied) {
        print('Microphone Permission disabled');
      }
    }
  }

  Future<void> _connect(
      BuildContext context, String username, String roomId) async {
    //
    try {
      setState(() {
        _busy = true;
      });

      // create new room
      final room = Room(roomOptions: const RoomOptions());

      // Create a Listener before connecting
      final listener = room.createListener();

      //get token
      final response = await http.get(Uri.parse(
          'https://vercel-api-hazel.vercel.app/getToken?username=$username&roomId=$roomId'));

      // Try to connect to the room
      // This will throw an Exception if it fails for any reason.
      await room.connect(
        _serverUrl,
        response.body,
      );

      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => RoomPage(room, listener)),
      );
    } catch (error) {
      print('Could not connect $error');
      await context.showErrorDialog(error);
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _roomIdController,
                    decoration: const InputDecoration(
                      labelText: 'Room ID',
                      hintText: 'Enter room ID',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => _connect(context, _usernameController.text,
                            _roomIdController.text),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_busy)
                          const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        const Text('CONNECT'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
