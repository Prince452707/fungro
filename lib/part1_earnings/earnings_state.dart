import 'package:flutter/foundation.dart';
import 'models.dart';

@immutable
sealed class EarningsState {
  const EarningsState();
}

class EarningsInitial extends EarningsState {
  const EarningsInitial();
}

class EarningsLoading extends EarningsState {
  const EarningsLoading();
}

class EarningsData extends EarningsState {
  final List<Earning> items;
  final bool isRefreshing;

  const EarningsData(this.items, {this.isRefreshing = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningsData &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          isRefreshing == other.isRefreshing;

  @override
  int get hashCode => items.hashCode ^ isRefreshing.hashCode;
}

class EarningsEmpty extends EarningsState {
  final String message;

  const EarningsEmpty({
    this.message = 'No earnings yet! Complete your first project to start earning.',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningsEmpty &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

class EarningsError extends EarningsState {
  final String message;

  const EarningsError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarningsError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
