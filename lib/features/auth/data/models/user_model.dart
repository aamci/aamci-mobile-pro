import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final String? avatarUrl;
  final String? phone;
  final String? city;
  final String? specialty;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.city,
    this.specialty,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
