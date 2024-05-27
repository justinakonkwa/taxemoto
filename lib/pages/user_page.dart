// ignore_for_file: prefer_const_constructors, unused_shown_name

import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/app_text_large.dart';
import 'package:taxaero/widget/bouton_next.dart';
import 'package:taxaero/widget/constantes.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  TextEditingController name = TextEditingController();

  String imageUrl = '';
  Uint8List? fileData;
  DateTime selectedDate = DateTime.now();

  final ImagePicker _picker = ImagePicker();
  bool isPicture = false;
  String imagePath = '';
  bool isLoading = false;

  Future<void> _logout(BuildContext context) async {
    isLoading == true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/intro');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppTextLarge(size: 14, text: "Profil"),
        actions: [sizedbox2],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.blue,
                      backgroundImage: imagePath.isNotEmpty
                          ? FileImage(
                              File(imagePath),
                            )
                          : (imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl) as ImageProvider<Object>?
                              : null),
                      child: imageUrl == ''
                          ? Icon(
                              CupertinoIcons.person_alt,
                              size: 50,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 110,
                    child: GestureDetector(
                      onTap: () {
                        showPopup(context, 'Choose a methode', [
                          CupertinoActionSheetAction(
                            child: AppText(
                              text: 'Camera',
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                            onPressed: () async {
                              await getImageFromCamera();
                            },
                          ),
                          CupertinoActionSheetAction(
                            child: AppText(
                              text: 'Gallery',
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                            onPressed: () async {
                              await getImageFromGallery();
                            },
                          ),
                        ]);
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.background),
                        ),
                        child: Icon(
                          (Icons.camera_alt_rounded),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              sizedbox,
              sizedbox,
              AppText(text: 'Name'),
              sizedbox,
              Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.onBackground),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(
                        CupertinoIcons.person,
                      ),
                    ),
                    Expanded(
                      child: CupertinoTextField(
                        controller: name,
                        padding: const EdgeInsets.only(
                            top: 7.0, bottom: 7.0, left: 15.0, right: 20.0),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground),
                        placeholder: 'ajouter un votre nom...',
                        keyboardType: TextInputType.multiline,
                        decoration: const BoxDecoration(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              sizedbox,
              sizedbox,
              NextButton(
                onTap: () {
                  _logout(context);
                },
                child: isLoading
                    ? CircularProgressIndicator()
                    : AppText(
                        text: 'Se Deconnecter',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future getImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
        isPicture = true;
      });
    } else {
      log('Aucune image sélectionnée.');
    }
  }

  Future getImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
        isPicture = true;
      });
    } else {
      log('Aucune image sélectionnée.');
    }
  }
}

showPopup(
    BuildContext context, String title, List<CupertinoActionSheetAction> list) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => CupertinoActionSheet(
      message: AppText(
        text: title,
      ),
      actions: list,
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context, null),
        child: AppText(
          text: 'cancel',
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    ),
  );
}
