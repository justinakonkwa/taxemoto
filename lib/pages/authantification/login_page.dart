// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/bouton_next.dart';
import 'package:taxaero/widget/constantes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool visibility = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> login() async {
    const String url = 'https://taxe.happook.com/api/login';

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _phoneNumberController.text,
          'password': _passwordController.text,
        }),
      );

      setState(() {
        isLoading = false;
      });

      // Print the API response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Debug: Print the response data
        print('Response data: $responseData');

        if (responseData.containsKey('token')) {
          final String token = responseData['token'];
          final Map<String, dynamic> userData = responseData['data'];
          final String id = userData['id']; // Extract the user ID
          final String username = userData['name'] ?? 'N/A'; // Exemple d'une autre information

          // Print the extracted ID for debugging
          print('User ID: $id');

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('username', username);
          await prefs.setString('id', id); // Store the user ID
          // Stockez plus d'informations selon vos besoins

          // Si la réponse du serveur est OK, naviguez vers la page principale
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Si le token n'est pas présent dans la réponse
          _showErrorDialog('Réponse invalide du serveur. Veuillez réessayer plus tard.');
        }
      } else {
        // Si la réponse du serveur n'est pas OK, affichez un message d'erreur
        _showErrorDialog(
            'Échec de la connexion. Vérifiez vos identifiants et réessayez.');
      }
    } on http.ClientException catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Problème de connexion : ${e.message}');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(
          'Une erreur inattendue est survenue. Veuillez réessayer plus tard.');
      // Debug: Print the exception
      print('Exception: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: AppText(
          text: 'Erreur',
          textAlign: TextAlign.center,
        ),
        content: AppText(
          text: message,
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            child: AppText(
              text: 'OK',
              textAlign: TextAlign.center,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Image.asset('assets/intro4.png'),
              ),
              const SizedBox(height: 40),
              const Text('Se connecter avec Taxe Moto'),
              sizedbox,
              SizedBox(
                height: 40,
                child: CupertinoTextField(
                  controller: _phoneNumberController,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  placeholder: 'Votre nom',
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Icon(CupertinoIcons.person),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 40,
                child: CupertinoTextField(
                  controller: _passwordController,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  obscureText: !visibility,
                  placeholder: 'Mot de passe',
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 10.0, right: 10.0),
                    child: Icon(CupertinoIcons.lock_shield),
                  ),
                  suffix: Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          visibility = !visibility;
                        });
                      },
                      icon: visibility
                          ? const Icon(CupertinoIcons.eye)
                          : const Icon(CupertinoIcons.eye_slash),
                    ),
                  ),
                ),
              ),
              sizedbox,
              sizedbox,
              NextButton(
                width: double.maxFinite,
                onTap: () async {
                  await login();
                },
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )
                    : AppText(
                        text: "SE CONNECTER",
                        size: 14,
                        color: Colors.white,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
