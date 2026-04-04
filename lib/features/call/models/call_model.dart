import 'package:uuid/uuid.dart';

/// Enum representing the type of call (audio or video)
enum CallType { audio, video }

/// Enum representing the current status of a call
enum CallStatus { ringing, accepted, declined, ended, cancelled }

/// Model representing a call between two users
class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String calleeId;
  final String calleeName;
  final String? calleeAvatar;
  final CallType callType;
  final CallStatus status;
  final DateTime timestamp;
  final String roomId;
  final String? offerSdp;
  final String? answerSdp;
  final List<Map<String, dynamic>> iceCandidates;

  CallModel({
    String? callId,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.calleeId,
    required this.calleeName,
    this.calleeAvatar,
    required this.callType,
    this.status = CallStatus.ringing,
    DateTime? timestamp,
    String? roomId,
    this.offerSdp,
    this.answerSdp,
    List<Map<String, dynamic>>? iceCandidates,
  }) : callId = callId ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       roomId = roomId ?? const Uuid().v4(),
       iceCandidates = iceCandidates ?? [];

  /// Create a CallModel from JSON map (Firebase document)
  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      callId: json['callId'] as String,
      callerId: json['callerId'] as String,
      callerName: json['callerName'] as String? ?? '',
      callerAvatar: json['callerAvatar'] as String?,
      calleeId: json['calleeId'] as String,
      calleeName: json['calleeName'] as String? ?? '',
      calleeAvatar: json['calleeAvatar'] as String?,
      callType: json['callType'] == 'video' ? CallType.video : CallType.audio,
      status: _parseStatus(json['status'] as String?),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      roomId: json['roomId'] as String? ?? '',
      offerSdp: json['offerSdp'] as String?,
      answerSdp: json['answerSdp'] as String?,
      iceCandidates: json['iceCandidates'] != null
          ? List<Map<String, dynamic>>.from(json['iceCandidates'] as List)
          : [],
    );
  }

  /// Convert CallModel to JSON map for Firebase
  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'calleeAvatar': calleeAvatar,
      'callType': callType == CallType.video ? 'video' : 'audio',
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'roomId': roomId,
      'offerSdp': offerSdp,
      'answerSdp': answerSdp,
      'iceCandidates': iceCandidates,
    };
  }

  /// Create a copy with updated fields
  CallModel copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String? calleeId,
    String? calleeName,
    String? calleeAvatar,
    CallType? callType,
    CallStatus? status,
    DateTime? timestamp,
    String? roomId,
    String? offerSdp,
    String? answerSdp,
    List<Map<String, dynamic>>? iceCandidates,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      calleeId: calleeId ?? this.calleeId,
      calleeName: calleeName ?? this.calleeName,
      calleeAvatar: calleeAvatar ?? this.calleeAvatar,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      roomId: roomId ?? this.roomId,
      offerSdp: offerSdp ?? this.offerSdp,
      answerSdp: answerSdp ?? this.answerSdp,
      iceCandidates: iceCandidates ?? this.iceCandidates,
    );
  }

  /// Check if call is active
  bool get isActive =>
      status == CallStatus.ringing || status == CallStatus.accepted;

  /// Check if current user is the caller
  bool isCaller(String userId) => callerId == userId;

  /// Parse status from string
  static CallStatus _parseStatus(String? status) {
    switch (status) {
      case 'ringing':
        return CallStatus.ringing;
      case 'accepted':
        return CallStatus.accepted;
      case 'declined':
        return CallStatus.declined;
      case 'ended':
        return CallStatus.ended;
      case 'cancelled':
        return CallStatus.cancelled;
      default:
        return CallStatus.ringing;
    }
  }

  @override
  String toString() {
    return 'CallModel(callId: $callId, callerId: $callerId, calleeId: $calleeId, '
        'callType: $callType, status: $status, roomId: $roomId)';
  }
}
