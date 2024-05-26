// ignore_for_file: prefer_const_constructors, use_build_context_synchronously


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:provider/provider.dart';
import 'package:taxaero/language/choose_language.dart';
import 'package:taxaero/pages/history_page.dart';
import 'package:taxaero/pages/user_page.dart';
import 'package:taxaero/theme/theme_provider.dart';
import 'package:taxaero/widget/app_text.dart';
import 'package:taxaero/widget/lign.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(icon: const Icon(Icons.close, weight: 2,), onPressed: () {
        //   context.pop();
        // }),
        centerTitle: true,
        title: AppText(
          text: translate("settings.title"),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20),
        child: ListView(
          children: [
            SizedBox(height: 20),
            AppText(
              text: translate("settings.general").toUpperCase(),
              color: Theme.of(context).colorScheme.onBackground,
            ),
            Container(
              margin: const EdgeInsets.only(
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).highlightColor,
                borderRadius: const BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  card1(
                      ontap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserPage(),
                          ),
                        );
                      },
                      icon: Icons.person_outlined,
                      title: translate("settings.personal_info"),
                      showLast: false),
                  card1(
                      ontap: () {
                       Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryPage(),
                          ),
                        );
                      },
                      icon: Icons.payment,
                      title: translate("Historique"),
                      showLast: false),
                  // card1(ontap:  (){}, icon: Icons.system_update_alt_outlined, title: "Upgrade to Money Ai",  showLast: false),
                
                  card1(
                      ontap: () {
                        // onActionSheetPress(context);
                        // showI18nDialog(context: context);
                        showI18nDialog(context: context);
                      },
                      icon: Icons.translate_outlined,
                      title: translate("settings.language"),
                      icon2: Icons.switch_right_outlined,
                      showLast: false),
                  Consumer<ThemeProvider>(
                    builder: (context, provider, child) {
                      bool theme = provider.currentTheme;

                      return myCard(
                        ontap: () => provider.changeTheme(!theme),
                        context: context,
                        fistWidget: Icon(CupertinoIcons.brightness),
                        title: theme
                            ? translate('theme.light')
                            : translate('theme.dark'),
                        secondWidget: Icon(CupertinoIcons.light_max),
                        showLast: true,
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            AppText(
              text: translate("settings.general").toUpperCase(),
              color: Theme.of(context).colorScheme.onBackground,
            ),
            Container(
              margin: const EdgeInsets.only(
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).highlightColor,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Column(
                children: [
                  card1(
                      ontap: () {
                        //  showMessageDialog(
                        //      context,
                        //      title: translate("settings.contactUs"),
                        //      message: "Email: teama.xrun@gmail.com"
                        //  );
                      },
                      icon: CupertinoIcons.phone,
                      title: translate("settings.contactUs"),
                      showLast: false),
                  card1(
                      ontap: () {
                        // var url = Platform.isAndroid
                        //     ? 'https://play.google.com/store/apps/details?id=com.wexende.expensexai'
                        //     : 'https://apps.apple.com/us/app/money-ai/id6474200248';
                        // myLaunchUrl(url);
                      },
                      icon: Icons.star_half_outlined,
                      title: translate("settings.leaveReview"),
                      showLast: true),
                ],
              ),
            ),
            SizedBox(height: 20),
            AppText(
              text: translate("settings.general").toUpperCase(),
              color: Theme.of(context).colorScheme.onBackground,
            ),
            Container(
              margin: const EdgeInsets.only(
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).highlightColor,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Column(
                children: [
                  card1(
                      ontap: () {
                        // myLaunchUrl(
                        //     'https://raw.githubusercontent.com/SleentOS/compTIA-Acronyms-Terms-And-Conditions/main/README.md');
                      },
                      icon: Icons.privacy_tip_outlined,
                      title: translate("settings.privacy_policy"),
                      showLast: false),
                  card1(
                      ontap: () {
                        // myLaunchUrl(
                        //     'https://raw.githubusercontent.com/SleentOS/compTIA-Acronyms-Terms-And-Conditions/main/README.md');
                      },
                      icon: CupertinoIcons.arrow_3_trianglepath,
                      title: translate("settings.terms_and_conditions"),
                      showLast: false),
                  card1(
                      ontap: () {},
                      icon: Icons.help_center_outlined,
                      title: translate("settings.terms_and_conditions"),
                      showLast: true),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).highlightColor,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: card1(
                  ontap: () {
                  },
                  icon: Icons.exit_to_app,
                  title: 'Sign Out',
                  showLast: true),
            )
          ],
        ),
      ),
    );
  }

  card1(
      {required Function() ontap,
      required IconData icon,
      required String title,
      IconData icon2 = Icons.navigate_next_outlined,
      bool showLast = false}) {
    return InkWell(
      onTap: ontap,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              icon,
              // color: AppColors.bigTextColor,
            ),
            title: Container(
              alignment: Alignment.centerLeft,
              child: AppText(
                text: title,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            trailing: Icon(
              icon2,
              // color: AppColors.bigTextColor,
            ),
            // subtitle: Container(),
          ),
          if (!showLast)
            Container(
              margin: EdgeInsets.only(left: 60),
              height: 0.5,
              color:Colors.blue,
            )
        ],
      ),
    );
  }

  Widget myCard({
    required BuildContext context,
    required Function() ontap,
    required Widget fistWidget,
    required String title,
    Widget secondWidget = const Icon(
      CupertinoIcons.brightness,
    ),
    bool showLast = false,
  }) {
    return InkWell(
      onTap: ontap,
      child: Column(
        children: [
          ListTile(
            leading: fistWidget,
            title: Container(
              alignment: Alignment.centerLeft,
              child: AppText(
                text: title,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            trailing: secondWidget,
            // subtitle: Container(),
          ),
          if (!showLast) const Lign(indent: 60, endIndent: 0,)
        ],
      ),
    );
  }
}
