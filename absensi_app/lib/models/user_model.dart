import 'package:flutter/material.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String idKaryawan;
  final String departemen;
  final String? profilePhotoUrl; // <--- DITAMBAHKAN

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.idKaryawan,
    required this.departemen,
    this.profilePhotoUrl, // <--- DITAMBAHKAN
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      idKaryawan: json['id_karyawan'] as String,
      departemen: json['departemen'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?, // <--- DITAMBAHKAN
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'id_karyawan': idKaryawan,
      'departemen': departemen,
      'profile_photo_url': profilePhotoUrl, // <--- DITAMBAHKAN
    };
  }
}
