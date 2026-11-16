import 'package:flutter/foundation.dart';

@immutable
class Earning {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String? detail;

  const Earning({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.detail,
  });

  Earning copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? detail,
  }) {
    return Earning(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      detail: detail ?? this.detail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Earning &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          amount == other.amount &&
          date == other.date &&
          detail == other.detail;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      amount.hashCode ^
      date.hashCode ^
      detail.hashCode;
}
