import 'json.dart';

/// UserProfile — `id` é o shopifyCustomerId (identidade do cliente).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.cpf,
    this.phone,
    this.gender,
    required this.hasSubscription,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;

  /// mascarado: ***.***.123-45
  final String? cpf;
  final String? phone;
  final String? gender;
  final bool hasSubscription;

  String get fullName => '$firstName $lastName'.trim();

  factory UserProfile.fromJson(Json json) => UserProfile(
        id: asString(json['id']),
        email: asString(json['email']),
        firstName: asString(json['firstName']),
        lastName: asString(json['lastName']),
        cpf: asStringOrNull(json['cpf']),
        phone: asStringOrNull(json['phone']),
        gender: asStringOrNull(json['gender']),
        hasSubscription: asBool(json['hasSubscription']),
      );

  Json toJson() => compact(<String, dynamic>{
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'cpf': cpf,
        'phone': phone,
        'gender': gender,
        'hasSubscription': hasSubscription,
      });
}

class UpdateProfileRequest {
  const UpdateProfileRequest({this.firstName, this.lastName, this.phone, this.gender});

  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? gender;

  Json toJson() => compact(<String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'gender': gender,
      });
}
