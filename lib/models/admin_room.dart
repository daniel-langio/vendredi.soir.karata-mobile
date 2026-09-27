import 'room_summary.dart';

/// One room as the admin list shows it: everything the player-facing [RoomSummary] carries, plus
/// whether it is closed - which the player-facing list cannot express, because a closed room
/// simply leaves it.
class AdminRoom {
  final RoomSummary room;
  final bool closed;

  const AdminRoom({required this.room, required this.closed});

  factory AdminRoom.fromJson(Map<String, dynamic> j) => AdminRoom(
    room: RoomSummary.fromJson({
      ...j,
      // The admin payload spells the blinds flat, where the player-facing Room nests them.
      'blinds': {'small': j['smallBlind'], 'big': j['bigBlind']},
    }),
    closed: j['closed'] == true,
  );
}
