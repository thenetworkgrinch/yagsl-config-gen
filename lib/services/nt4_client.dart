import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

enum MessageType {
  publish,
  properties,
  announce,
  unannounce,
  setProperties,
  unpublish,
}

enum DataType {
  boolean,
  double,
  int,
  float,
  string,
  json,
  raw,
  rpc,
  msgpack,
  protobuf,
  structSchema,
  structData,
  boolean_array,
  double_array,
  int_array,
  float_array,
  string_array,
}

class NT4Subscription {
  final int uid;
  final List<String> topics;
  final List<String> prefixes;
  final Map<String, dynamic> options;
  final Function(String topic, dynamic value, int timestamp) onValueChanged;

  NT4Subscription({
    required this.uid,
    required this.topics,
    required this.prefixes,
    required this.options,
    required this.onValueChanged,
  });
}

class NT4Topic {
  final String name;
  final int id;
  final DataType type;
  dynamic value;
  int timestamp;

  NT4Topic({
    required this.name,
    required this.id,
    required this.type,
    this.value,
    this.timestamp = 0,
  });
}

class NT4Client {
  static final NT4Client _instance = NT4Client._internal();
  static NT4Client get instance => _instance;

  NT4Client._internal();

  WebSocketChannel? _ws;
  bool _connected = false;
  bool get isConnected => _connected;

  final Map<int, NT4Topic> _topics = {};
  final Map<int, NT4Subscription> _subscriptions = {};
  int _nextSubscriptionUid = 1;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  String? _serverAddress;
  String? get serverAddress => _serverAddress;

  // Connect to NetworkTables server
  Future<bool> connect(String serverAddress, {int port = 5810}) async {
    if (_connected) {
      await disconnect();
    }

    try {
      final wsUrl = 'ws://$serverAddress:$port/nt/ws';
      _ws = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      _serverAddress = serverAddress;

      _ws!.stream.listen(
        _onData,
        onDone: _onDisconnected,
        onError: (error) {
          print('WebSocket error: $error');
          _onDisconnected();
        },
      );

      // Wait a bit to see if connection is established
      await Future.delayed(const Duration(milliseconds: 500));
      _connected = true;
      _connectionStatusController.add(_connected);
      
      return true;
    } catch (e) {
      print('Failed to connect to NT server: $e');
      _onDisconnected();
      return false;
    }
  }

  // Disconnect from NetworkTables server
  Future<void> disconnect() async {
    if (_ws != null) {
      await _ws!.sink.close();
      _ws = null;
    }
    _onDisconnected();
  }

  // Handle disconnection
  void _onDisconnected() {
    _connected = false;
    _topics.clear();
    _connectionStatusController.add(_connected);
    _serverAddress = null;
  }

  // Process incoming data
  void _onData(dynamic data) {
    if (data is! String) return;

    try {
      final jsonData = jsonDecode(data);
      if (jsonData is! List) return;

      for (var message in jsonData) {
        if (message is! Map<String, dynamic>) continue;

        final messageType = message['method'];
        if (messageType == null) continue;

        switch (messageType) {
          case 'announce':
            _handleAnnounce(message);
            break;
          case 'publish':
            _handlePublish(message);
            break;
          case 'unannounce':
            _handleUnannounce(message);
            break;
          default:
            // Ignore other message types for now
            break;
        }
      }
    } catch (e) {
      print('Error processing NT data: $e');
    }
  }

  // Handle topic announcements
  void _handleAnnounce(Map<String, dynamic> message) {
    final name = message['name'];
    final id = message['id'];
    final typeStr = message['type'];
    
    if (name == null || id == null || typeStr == null) return;

    DataType type;
    try {
      type = DataType.values.firstWhere(
        (t) => t.toString().split('.').last == typeStr,
        orElse: () => DataType.string,
      );
    } catch (_) {
      type = DataType.string;
    }

    final topic = NT4Topic(
      name: name,
      id: id,
      type: type,
    );

    _topics[id] = topic;
  }

  // Handle topic updates
  void _handlePublish(Map<String, dynamic> message) {
    final topicId = message['id'];
    final timestamp = message['timestamp'] ?? DateTime.now().millisecondsSinceEpoch * 1000;
    final value = message['value'];
    
    if (topicId == null || value == null) return;

    final topic = _topics[topicId];
    if (topic == null) return;

    topic.value = value;
    topic.timestamp = timestamp;

    // Notify subscribers
    for (var subscription in _subscriptions.values) {
      if (subscription.topics.contains(topic.name) || 
          subscription.prefixes.any((prefix) => topic.name.startsWith(prefix))) {
        subscription.onValueChanged(topic.name, value, timestamp);
      }
    }
  }

  // Handle topic removals
  void _handleUnannounce(Map<String, dynamic> message) {
    final topicId = message['id'];
    if (topicId == null) return;

    _topics.remove(topicId);
  }

  // Subscribe to topics
  int subscribe(
    List<String> topics,
    List<String> prefixes,
    Function(String topic, dynamic value, int timestamp) onValueChanged,
    {Map<String, dynamic> options = const {}}
  ) {
    final uid = _nextSubscriptionUid++;
    
    final subscription = NT4Subscription(
      uid: uid,
      topics: List<String>.from(topics),
      prefixes: List<String>.from(prefixes),
      options: Map<String, dynamic>.from(options),
      onValueChanged: onValueChanged,
    );
    
    _subscriptions[uid] = subscription;
    
    if (_connected) {
      _sendSubscription(subscription);
    }
    
    return uid;
  }

  // Unsubscribe from topics
  void unsubscribe(int uid) {
    if (!_subscriptions.containsKey(uid)) return;
    
    if (_connected) {
      _sendUnsubscription(uid);
    }
    
    _subscriptions.remove(uid);
  }

  // Send subscription message
  void _sendSubscription(NT4Subscription subscription) {
    if (_ws == null) return;
    
    final message = [
      {
        'method': 'subscribe',
        'uid': subscription.uid,
        'topics': subscription.topics,
        'prefixes': subscription.prefixes,
        'options': subscription.options,
      }
    ];
    
    _ws!.sink.add(jsonEncode(message));
  }

  // Send unsubscription message
  void _sendUnsubscription(int uid) {
    if (_ws == null) return;
    
    final message = [
      {
        'method': 'unsubscribe',
        'uid': uid,
      }
    ];
    
    _ws!.sink.add(jsonEncode(message));
  }

  // Publish a value to NetworkTables
  void publish(String topic, dynamic value, DataType type) {
    if (!_connected || _ws == null) return;
    
    // Find if topic already exists
    int? topicId;
    for (var entry in _topics.entries) {
      if (entry.value.name == topic) {
        topicId = entry.key;
        break;
      }
    }
    
    if (topicId == null) {
      // Announce new topic
      final message = [
        {
          'method': 'publish',
          'topic': topic,
          'type': type.toString().split('.').last,
          'value': value,
        }
      ];
      
      _ws!.sink.add(jsonEncode(message));
    } else {
      // Update existing topic
      final message = [
        {
          'method': 'publish',
          'id': topicId,
          'value': value,
        }
      ];
      
      _ws!.sink.add(jsonEncode(message));
    }
  }

  // Clean up resources
  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }
}
