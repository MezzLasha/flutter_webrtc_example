import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

class LiveKitScreen extends StatefulWidget {
  const LiveKitScreen({super.key});

  @override
  State<LiveKitScreen> createState() => _LiveKitScreenState();
}

class _LiveKitScreenState extends State<LiveKitScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _meetingIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final roomOptions = const RoomOptions(
    adaptiveStream: true,
    dynacast: true,
  );

  late final Room room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wrapper Method'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User Id',
              ),
            ),
            TextFormField(
              controller: _meetingIdController,
              decoration: const InputDecoration(
                labelText: 'Meeting Id',
              ),
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            ElevatedButton(onPressed: () {}, child: const Text('Join Meeting')),
            FutureBuilder(
                future: initLiveKit(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    try {
                      // video will fail when running in ios simulator
                      snapshot.data!.localParticipant!.setCameraEnabled(true);
                    } catch (error) {
                      print('Could not publish video, error: $error');
                    }
                    snapshot.data!.localParticipant!.setMicrophoneEnabled(true);

                    return RoomWidget(snapshot.data!);
                  } else {
                    return const CircularProgressIndicator();
                  }
                })
          ],
        ),
      ),
    );
  }

  Future<Room> initLiveKit() async {
    room = await LiveKitClient.connect('wss://tirza-0svfwzsu.livekit.cloud',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTQ2MDI5MTYsImlzcyI6IkFQSWJYamU1Z244Tk1USiIsIm5iZiI6MTY5NDYwMjAxNiwic3ViIjoiZ3VyYW0iLCJ2aWRlbyI6eyJjYW5QdWJsaXNoIjp0cnVlLCJjYW5QdWJsaXNoRGF0YSI6dHJ1ZSwiY2FuU3Vic2NyaWJlIjp0cnVlLCJyb29tIjoiamFzaGkiLCJyb29tSm9pbiI6dHJ1ZX19.WKivYN6wWZ_nlEKLUoSEMcxb_8cIvSz-0tQ7GFftDG0',
        roomOptions: roomOptions);
    try {
      // video will fail when running in ios simulator
      await room.localParticipant?.setCameraEnabled(true);
    } catch (error) {
      print('Could not publish video, error: $error');
    }

    await room.localParticipant?.setMicrophoneEnabled(true);

    return room;
  }
}

class RoomWidget extends StatefulWidget {
  final Room room;

  const RoomWidget(this.room);

  @override
  State<StatefulWidget> createState() {
    return _RoomState();
  }
}

class _RoomState extends State<RoomWidget> {
  late final EventsListener<RoomEvent> _listener = widget.room.createListener();

  @override
  void initState() {
    super.initState();
    // used for generic change updates
    widget.room.addListener(_onChange);

    // used for specific events
    _listener
      ..on<RoomDisconnectedEvent>((_) {
        // handle disconnect
      })
      ..on<ParticipantConnectedEvent>((e) {
        print("participant joined: ${e.participant.identity}");
      });
  }

  @override
  void dispose() {
    // be sure to dispose listener to stop listening to further updates
    _listener.dispose();
    widget.room.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room state changed: ${widget.room.connectionState}'),
      ),
    );
  }

  VideoTrack? track;

  @override
  Widget build(BuildContext context) {
    if (track != null) {
      return VideoTrackRenderer(track!);
    } else {
      return Container(
        color: Colors.grey,
      );
    }
  }
}
