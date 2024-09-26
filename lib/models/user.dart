class User {
  final String firstName;
  final String lastName;
  final String image;
  final String email;
  final List accounts;
  final String password;
  final int id;
  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.image,
    required this.accounts,
    required this.password,
    required this.id,
  });

  // Create a User instance from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
        id: map['id'] as int,
        email: map['email'].toString(),
        password: map['password_hash'].toString(),
        accounts: map['accounts'] as List,
        firstName: map['firstName'].toString(),
        image: map['image'].toString(),
        lastName: map['lastName'].toString());
  }

  // Convert User instance to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'image': image,
      'accounts': accounts,
    };
  }
}

// CREATE TABLE users (
//     id INT PRIMARY KEY AUTO_INCREMENT,
//     email VARCHAR(100) NOT NULL UNIQUE,
//     firstName VARCHAR(100) NOT NULL,
//     lastName VARCHAR(100) NOT NULL,
//     image VARCHAR(300),
//     password VARCHAR(64) NOT NULL,
//     accounts VARCHAR(10000)
// );
