// ignore_for_file: prefer_const_constructors

import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
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

  Country? selectedCountry;
  String? selectedGender;

  String imageUrl = '';
  Uint8List? fileData;
  bool flag = false;
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
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
              AppText(text: 'Date of birth'),
              sizedbox,
              Container(
                padding: EdgeInsets.only(left: 20, right: 20),
                height: 50,
                width: double.maxFinite,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.onBackground),
                  borderRadius: borderRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(CupertinoIcons.calendar_badge_plus),
                    AppText(
                      text: '${selectedDate.toLocal()}',
                    ),
                    Container(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                          onTap: () {
                            _selectDate(context);
                          },
                          child: Icon(CupertinoIcons.chevron_compact_down)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              AppText(text: 'Gender'),
              sizedbox,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Ink(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.42,
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        borderRadius: borderRadius),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Radio(
                          value: 'Man',
                          groupValue: selectedGender,
                          activeColor:
                              Theme.of(context).colorScheme.onBackground,
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value!;
                              print(selectedGender);
                            });
                          },
                        ),
                        Text('Man'),
                      ],
                    ),
                  ),
                  Ink(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.42,
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        borderRadius: borderRadius),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Radio(
                          value: 'Woman',
                          groupValue: selectedGender,
                          activeColor:
                              Theme.of(context).colorScheme.onBackground,
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value!;
                              print(selectedGender);
                            });
                          },
                        ),
                        Text('Woman'),
                      ],
                    ),
                  )
                ],
              ),
              sizedbox,
              sizedbox,
              NextButton(
                onTap: () {},
                child: Text('save'),
              ),
              IconButton(
                icon: 
                isLoading?
                CircularProgressIndicator():
                Row(
                  children: [
                    AppText(
                      text: 'Se Deconnecter',
                    ),
                    Icon(Icons.logout),
                  ],
                ),
                onPressed: () => {
                  _logout(context),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  cardtext() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      height: 50,
      width: double.maxFinite,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(CupertinoIcons.calendar_badge_plus),
          AppText(
            text: '${selectedDate.toLocal()}',
          ),
          Container(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                _selectDate(context);
              },
              child: Icon(CupertinoIcons.chevron_compact_down),
            ),
          ),
        ],
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

class Country {
  String name;
  String iso;
  String flag;

  Country({required this.name, required this.iso, required this.flag});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iso': iso,
      'flag': flag,
    };
  }

  factory Country.fromMap(Map<String, dynamic> map) {
    return Country(
      name: map['name'] ?? '',
      iso: map['iso'] ?? '',
      flag: map['flag'] ?? '',
    );
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
