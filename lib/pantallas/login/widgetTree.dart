import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/home/home.dart';
import 'package:cuentas_android/pantallas/info.dart';
import 'package:cuentas_android/pantallas/login/loginPage.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Tree extends StatefulWidget {
  Tree({Key? key}) : super(key: key);

  @override
  _TreeState createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChanged,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Obx(() => Values().cuentaRet.value != null ? Info() : Home());
        } else {
          return LoginPage();
        }
      },
    );
  }
}
