import 'package:loja/models/app_user.dart';
import 'package:loja/models/user_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:loja/helpers/validators.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar'),
        centerTitle: true,
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: (){
              Navigator.of(context).pushReplacementNamed('/signup');
            },
            child: const Text(
              'CRIAR CONTA',
              style: TextStyle(fontSize: 14),
            ),
          )
        ],
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: formKey,
            child: Consumer<UserManager>(
              builder: (_, userManager, child){
                if(userManager.loadingFace){
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).primaryColor
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  children: <Widget>[
                    TextFormField(
                      controller: emailController,
                      enabled: !userManager.loading,
                      decoration: const InputDecoration(hintText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: (email){
                        if(email == null || !emailValid(email)) {
                          return 'E-mail inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16,),
                    TextFormField(
                      controller: passController,
                      enabled: !userManager.loading,
                      decoration: const InputDecoration(hintText: 'Senha'),
                      autocorrect: false,
                      obscureText: true,
                      validator: (pass){
                        if(pass == null || pass.isEmpty || pass.length < 6) {
                          return 'Senha inválida';
                        }
                        return null;
                      },
                    ),
                    child!,
                    const SizedBox(height: 16,),
                    ElevatedButton(
                      onPressed: userManager.loading ? null : (){
                        if(formKey.currentState!.validate()){
                          userManager.signIn(
                              user: AppUser(
                                  email: emailController.text,
                                  password: passController.text
                              ),
                              onFail: (e){
                                if(!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Falha ao entrar: $e'),
                                      backgroundColor: Colors.red,
                                    )
                                );
                              },
                              onSuccess: (){
                                if(!mounted) return;
                                Navigator.of(context).pop();
                              }
                          );
                        }
                      },
                      child: userManager.loading ?
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ) :
                      const Text(
                        'Entrar',
                        style: TextStyle(
                            fontSize: 15
                        ),
                      ),
                    ),
                    SignInButton(
                      Buttons.facebook,
                      text: 'Entrar com Facebook',
                      onPressed: (){
                        userManager.facebookLogin(
                            onFail: (e){
                              if(!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Falha ao entrar: $e'),
                                    backgroundColor: Colors.red,
                                  )
                              );
                            },
                            onSuccess: (){
                              if(!mounted) return;
                              Navigator.of(context).pop();
                            }
                        );
                      },
                    )
                  ],
                );
              },
              child: Align( // Procedimento de esqueci minha senha
                alignment: Alignment.centerRight,
                child: Consumer<UserManager>(
                  builder: (_, userManager, _) {
                    return TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () {
                        if (emailController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text(
                                'Insira seu e-mail para recuperação'
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 4),
                          ));
                        } else {
                          userManager.recoverPass(emailController.text);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text(
                                'Confira seu e-mail.'
                            ),
                            backgroundColor: Theme.of(context).primaryColor,
                            duration: Duration(seconds: 4),
                          ));
                        }
                      },
                      child: const Text(
                        'Esqueci minha senha',
                      ),
                    );
                  },
                ),
              )
            ),
          ),
        ),
      ),
    );
  }
}