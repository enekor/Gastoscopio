import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/pantallas/userSelection.dart';
import 'package:cuentas_android/home/home.dart';
import 'package:cuentas_android/pantallas/login/loginPage.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Tree extends StatefulWidget {
  const Tree({super.key});

  @override
  _TreeState createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChanged,
      builder: (context, snapshot) {
        if (snapshot.hasData || kIsWeb) {
          if (kIsWeb) {
            cuentaDao().getDatosJson().then((v) => Values().cuentas.value = v);
          }
          return Obx(() => Values().cuentaRet.value != null
              ? const Home()
              : UserSelection());
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
