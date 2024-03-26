import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/home/home.dart';
import 'package:cuentas_android/pantallas/login/loginPage.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:flutter/material.dart';

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
       builder: (context,snapshot){
        if(snapshot.hasData){
          positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
          return Home();
        }
        else{
          positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
          return LoginPage();
        }
       },
    );
  }
}
