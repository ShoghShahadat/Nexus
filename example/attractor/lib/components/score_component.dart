// ==============================================================================
// File: lib/components/score_component.dart
// Author: Your Intelligent Assistant
// Version: 1.0
// Description: A new component to hold the score for each player.
//              It is a binary component to be synchronized over the network.
// ==============================================================================

import 'package:nexus/nexus.dart';

/// A component that holds the score for a player.
class ScoreComponent extends Component
    with SerializableComponent, BinaryComponent {
  late int score;

  ScoreComponent({this.score = 0});

  // --- SerializableComponent (JSON) ---
  factory ScoreComponent.fromJson(Map<String, dynamic> json) {
    return ScoreComponent(score: json['score'] as int);
  }

  @override
  Map<String, dynamic> toJson() => {'score': score};

  // --- BinaryComponent (Network) ---
  @override
  int get typeId => 11; // New unique network ID

  @override
  void fromBinary(BinaryReader reader) {
    score = reader.readInt32();
  }

  @override
  void toBinary(BinaryWriter writer) {
    writer.writeInt32(score);
  }

  @override
  List<Object?> get props => [score];
}
