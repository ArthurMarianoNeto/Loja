import 'package:flutter/material.dart';
import 'package:loja/helpers/validators.dart';
import 'package:loja/models/app_user.dart';
import 'package:loja/models/user_manager.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final AppUser user = AppUser();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: formKey,
            child: Consumer<UserManager>(
              builder: (_, userManager, _){
                return ListView(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  children: <Widget>[
                    TextFormField(
                      decoration: const InputDecoration(hintText: 'Nome Completo'),
                      enabled: !userManager.loading,
                      validator: (name){
                        if(name == null || name.isEmpty) {
                          return 'Campo obrigatório';
                        } else if(name.trim().split(' ').length <= 1) {
                          return 'Preencha seu Nome completo';
                        }
                        return null;
                      },
                      onSaved: (name) => user.name = name,
                    ),
                    const SizedBox(height: 16,),
                    TextFormField(
                      decoration: const InputDecoration(hintText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !userManager.loading,
                      validator: (email){
                        if(email == null || email.isEmpty) {
                          return 'Campo obrigatório';
                        } else if(!emailValid(email)) {
                          return 'E-mail inválido';
                        }
                        return null;
                      },
                      onSaved: (email) => user.email = email,
                    ),
                    const SizedBox(height: 16,),
                    TextFormField(
                      decoration: const InputDecoration(hintText: 'Senha'),
                      obscureText: true,
                      enabled: !userManager.loading,
                      validator: (pass){
                        if(pass == null || pass.isEmpty) {
                          return 'Campo obrigatório';
                        } else if(pass.length < 6) {
                          return 'Senha muito curta';
                        }
                        return null;
                      },
                      onSaved: (pass) => user.password = pass,
                    ),
                    const SizedBox(height: 16,),
                    TextFormField(
                      decoration: const InputDecoration(hintText: 'Repita a Senha'),
                      obscureText: true,
                      enabled: !userManager.loading,
                      validator: (pass){
                        if(pass == null || pass.isEmpty) {
                          return 'Campo obrigatório';
                        } else if(pass.length < 6) {
                          return 'Senha muito curta';
                        }
                        return null;
                      },
                      onSaved: (pass) => user.confirmPassword = pass,
                    ),
                    const SizedBox(height: 16,),
                    ElevatedButton(
                      onPressed: userManager.loading ? null : (){
                        if(formKey.currentState!.validate()){
                          formKey.currentState!.save();

                          if(user.password != user.confirmPassword){
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Senhas não coincidem!'),
                                  backgroundColor: Colors.red,
                                )
                            );
                            return;
                          }

                          userManager.signUp(
                              user: user,
                              onSuccess: (){
                                if(!mounted) return;
                                Navigator.of(context).pop();
                              },
                              onFail: (e){
                                if(!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Falha ao cadastrar: $e'),
                                      backgroundColor: Colors.red,
                                    )
                                );
                              }
                          );
                        }
                      },
                      child: userManager.loading ?
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                          : const Text(
                        'Criar Conta',
                        style: TextStyle(
                            fontSize: 15
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}