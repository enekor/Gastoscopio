import 'package:cuentas_android/pattern/pattern.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cuentas_android/dao/userDao.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = "";
  bool isLogin = true;

  final TextEditingController _emailCOntroller = TextEditingController();
  final TextEditingController _passwordCOntroller = TextEditingController();
  final TextEditingController _repPasswordCOntroller = TextEditingController();

  Future signIn() async{
    try{
      await Auth().signInEmailPassword(email: "${_emailCOntroller.text}@gastoscopio.com", password: _passwordCOntroller.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future registerUser() async{
    
    if (_passwordCOntroller.text == _repPasswordCOntroller.text) {
      try{
        await Auth().registerWithUserPassword(email: "${_emailCOntroller.text}@gastoscopio.com", password: _passwordCOntroller.text);
      } on FirebaseAuthException catch (e){
        setState(() {
          errorMessage = e.message;
        });
      }
    }
    else{
      errorMessage = "Las contraseñas no coinciden";
    }
  }

  bool _hidePass = true;
  void changeVisible(){
    setState(() {
      _hidePass = !_hidePass;
    });
  }
  Widget login() => 
    Center(
      child: Padding(
        padding: const EdgeInsets.all(100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "lib/assets/images/gatohola.png",
              height: 200,
              width: 200,),
            TextField(
              controller: _emailCOntroller,
              decoration: const InputDecoration(
                labelText: "Nombre de usuario"
              ),
            ),
            TextField(
              obscureText: _hidePass,
              controller: _passwordCOntroller,
              decoration: InputDecoration(
                labelText: "Contraseña",
                suffixIcon: IconButton(
                  onPressed: changeVisible, 
                  icon: Icon(_hidePass?Icons.visibility:Icons.visibility_off)
                )

              ),
            ),
            Text(errorMessage!),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: signIn, 
              child: Card(
                color: Theme.of(context).primaryColor,
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text("Iniciar sesion"),
                )
              ),
            ),
          ],
        ),
      ),
    );
    
  Widget register() => 
    Center(
      child: Padding(
        padding: const EdgeInsets.all(100.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "lib/assets/images/gatoapunta.png",
              height: 200,
              width: 200,),
            TextField(
              controller: _emailCOntroller,
              decoration: const InputDecoration(
                labelText: "Nombre de usuario"
              ),
            ),
            TextField(
              obscureText: _hidePass,
              controller: _passwordCOntroller,
              decoration: InputDecoration(
                labelText: "Contraseña",
                suffixIcon: IconButton(
                  onPressed: changeVisible, 
                  icon: Icon(_hidePass?Icons.visibility:Icons.visibility_off)
                )
              ),
            ),
            TextField(
              obscureText: _hidePass,
              controller: _repPasswordCOntroller,
              decoration: InputDecoration(
                labelText: "Repite la contraseña",
                suffixIcon: IconButton(
                  onPressed: changeVisible, 
                  icon: Icon(_hidePass?Icons.visibility:Icons.visibility_off)
                )
              ),
            ),
            Text(errorMessage!),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: registerUser, 
              child: Card(
                color:Theme.of(context).primaryColor,
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text("Registrar"),
                )
              ),
            ),
          ],
        ),
      ),
    );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isLogin ? "Login" : "Register"),
            TextButton(
              onPressed: ()=>setState(() {
                isLogin = !isLogin;
              }), 
              child: Text(isLogin ? "No tengo una cuenta":"Ya tengo una cuenta")
            )
          ],
        )
      ),
      body: CustomPaint(
        painter: MyPattern(context),
          child: SingleChildScrollView(
            child: isLogin
              ?login()
              :register(),
          ),
      ),
    );
  }
}