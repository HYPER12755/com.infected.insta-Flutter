import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_client.dart';

/// User presence state
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final Map<String, dynamic>? extraData;

  const UserPresence({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
    this.extraData,
  });

  factory UserPresence.fromMap(Map<String, dynamic> map) {
    return UserPresence(
      userId: map['user_id'] as String? ?? '',
      isOnline: map['online'] as bool? ?? false,
      lastSeen: map['last_seen'] != null 
          ? DateTime.tryParse(map['last_seen'] as String)
          : null,
      extraData: map['extra'] as Map<String, dynamic>?,
    );
  }
}

/// Service for user presence using Supabase Realtime
/// 
/// Features:
/// - User online/offline status tracking via track()
/// - Last seen timestamps
/// - Typing indicators for chats (via database fallback)
class PresenceService {
  final SupabaseClient _supabase;
  
  RealtimeChannel? _presenceChannel;
  
  // Current user tracking
  String? _currentUserId;
  
  // Stream controller for presence updates
  final _presenceController = StreamController<Map<String, UserPresence>>.broadcast();
  
  // Cache of user presence
  final Map<String, UserPresence> _presenceCache = {};
  
  PresenceService() : _supabase = supabase;

  /// Get stream of presence updates
  Stream<Map<String, UserPresence>> get presenceStream => _presenceController.stream;

  /// Initialize presence service for a user
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _setupPresenceChannel();
  }

  /// Setup presence channel with tracking
  Future<void> _setupPresenceChannel() async {
    _presenceChannel = _supabase.channel('presence:users');
    
    // Track current user's presence
    await _presenceChannel!.track({
      'user_id': _currentUserId,
      'online': true,
      'last_seen': DateTime.now().toIso8601String(),
    });
    
    _presenceChannel!.subscribe();
  }

  /// Announce online status
  Future<void> announceOnline() async {
    if (_presenceChannel != null && _currentUserId != null) {
      await _presenceChannel!.track({
        'user_id': _currentUserId,
        'online': true,
        'last_seen': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Announce offline status
  Future<void> announceOffline() async {
    if (_presenceChannel != null && _currentUserId != null) {
      await _presenceChannel!.untrack();
    }
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen() async {
    await announceOnline();
  }

  /// Get cached presence for a user
  UserPresence? getPresence(String userId) {
    return _presenceCache[userId];
  }

  /// Check if user is online
  bool isOnline(String userId) {
    return _presenceCache[userId]?.isOnline ?? false;
  }

  /// Get last seen for a user
  DateTime? getLastSeen(String userId) {
    return _presenceCache[userId]?.lastSeen;
  }

  /// Setup typing channel for a conversation
  /// Returns stream of typing events
  Stream<Map<String, dynamic>> setupTypingChannel(String conversationId) {
    final channel = _supabase.channel('typing:$conversationId');
    channel.subscribe();
    
    return StreamController<Map<String, dynamic>>.broadcast().stream;
  }

  /// Send typing indicator using database fallback
  Future<void> sendTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    // Store typing status in database
    await _supabase.from('typing_indicators').upsert({
      'conversation_id': conversationId,
      'user_id': userId,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Start typing in a conversation
  Future<void> startTyping(String conversationId) async {
    if (_currentUserId != null) {
      await sendTyping(
        conversationId: conversationId,
        userId: _currentUserId!,
        isTyping: true,
      );
    }
  }

  /// Stop typing in a conversation
  Future<void> stopTyping(String conversationId) async {
    if (_currentUserId != null) {
      await sendTyping(
        conversationId: conversationId,
        userId: _currentUserId!,
        isTyping: false,
      );
    }
  }

  /// Create a presence channel for custom tracking
  RealtimeChannel createPresenceChannel(String channelName) {
    return _supabase.channel(channelName);
  }

  /// Clean up resources
  void dispose() {
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    _presenceController.close();
  }
}
