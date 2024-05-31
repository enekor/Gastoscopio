import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  Future signIn() async {
    try {
      await Auth().signInEmailPassword(
          email: _emailCOntroller.text, password: _passwordCOntroller.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future rememberPassword(String email) async {
    try {
      await Auth().rememberPassword(email);
      showToast(
          text: "Email enviado al correo $email", length: Toast.LENGTH_LONG);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future registerUser() async {
    if (_passwordCOntroller.text == _repPasswordCOntroller.text) {
      try {
        await Auth().registerWithUserPassword(
            email: "${_emailCOntroller.text}",
            password: _passwordCOntroller.text);
      } on FirebaseAuthException catch (e) {
        setState(() {
          errorMessage = e.message;
        });
      }
    } else {
      errorMessage = "Las contraseñas no coinciden";
    }
  }

  bool _hidePass = true;
  void changeVisible() {
    setState(() {
      _hidePass = !_hidePass;
    });
  }

  void showEmailResetDialog() {
    TextEditingController _email = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("He olvidado mi contraseña"),
              content: Expanded(
                child: TextField(
                  controller: _email,
                  autofocus: true,
                  decoration: InputDecoration(labelText: "Email del usuario"),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar")),
                TextButton(
                    onPressed: () => rememberPassword(_email.text),
                    child: const Text("Enviar"))
              ],
            ));
  }

  Widget login() => Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(getImageUri(ImageUris.hola), height: 200, width: 200),
              Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: TextField(
                      controller: _emailCOntroller,
                      decoration:
                          const InputDecoration(labelText: "Nombre de usuario"),
                    ),
                  ),
                ],
              ),
              TextField(
                obscureText: _hidePass,
                controller: _passwordCOntroller,
                decoration: InputDecoration(
                    labelText: "Contraseña",
                    suffixIcon: IconButton(
                        onPressed: changeVisible,
                        icon: Icon(_hidePass
                            ? Icons.visibility
                            : Icons.visibility_off))),
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
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              TextButton(
                  onPressed: showEmailResetDialog,
                  child: const Text("He olvidado la contraseña"))
            ],
          ),
        ),
      );

  Widget register() => Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                getImageUri(ImageUris.apunta),
                height: 200,
                width: 200,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 9,
                    child: TextField(
                      controller: _emailCOntroller,
                      decoration:
                          const InputDecoration(labelText: "Nombre de usuario"),
                    ),
                  )
                ],
              ),
              TextField(
                obscureText: _hidePass,
                controller: _passwordCOntroller,
                decoration: InputDecoration(
                    labelText: "Contraseña",
                    suffixIcon: IconButton(
                        onPressed: changeVisible,
                        icon: Icon(_hidePass
                            ? Icons.visibility
                            : Icons.visibility_off))),
              ),
              TextField(
                obscureText: _hidePass,
                controller: _repPasswordCOntroller,
                decoration: InputDecoration(
                    labelText: "Repite la contraseña",
                    suffixIcon: IconButton(
                        onPressed: changeVisible,
                        icon: Icon(_hidePass
                            ? Icons.visibility
                            : Icons.visibility_off))),
              ),
              Text(errorMessage!),
              const SizedBox(height: 50),
              GestureDetector(
                onTap: registerUser,
                child: Card(
                    color: Theme.of(context).primaryColor,
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text("Registrar"),
                    )),
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
              onPressed: () => setState(() {
                    isLogin = !isLogin;
                  }),
              child:
                  Text(isLogin ? "No tengo una cuenta" : "Ya tengo una cuenta"))
        ],
      )),
      body: CustomPaint(
        painter: MyPattern(context),
        child: SingleChildScrollView(
          child: isLogin ? login() : register(),
        ),
      ),
    );
  }
}
