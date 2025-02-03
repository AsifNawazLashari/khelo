import '../../api/live_stream/live_stream_model.dart';
import '../../api/network/endpoint.dart';

class CreateLiveStreamEndPoint extends Endpoint {
  final String name;
  final String matchId;
  final String? channelId;
  final DateTime scheduledStartTime;
  final YouTubeResolution resolution;
  final MediumOption option;
  final PrivacyStatus? privacyStatus;

  CreateLiveStreamEndPoint({
    required this.name,
    required this.matchId,
    this.channelId,
    required this.scheduledStartTime,
    required this.resolution,
    required this.option,
    this.privacyStatus,
  });

  @override
  String get path => 'liveStream/createYouTubeStream';

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  dynamic get data => {
        "name": name,
        "matchId": matchId,
        "channelId": channelId,
        "scheduledStartTime": scheduledStartTime.toIso8601String(),
        "resolution": resolution.stringResolution,
        "option": option.name,
        "privacyStatus": privacyStatus?.name,
      };
}

class GetYTChannelEndPoint extends Endpoint {
  @override
  String get path => 'liveStream/getYouTubeChannel';

  @override
  HttpMethod get method => HttpMethod.get;
}

class EndYTBroadcastEndPoint extends Endpoint {
  final String broadcastId;

  EndYTBroadcastEndPoint({
    required this.broadcastId,
  });

  @override
  String get path => 'liveStream/endYouTubeBroadcast';

  @override
  HttpMethod get method => HttpMethod.get;

  @override
  dynamic get data => {"broadcastId": broadcastId};
}

enum YouTubeResolution {
  p1080,
  p720,
  p480,
  p360,
  p240,
  p144;

  String get stringResolution => '${name.replaceFirst('p', '')}p';
}
