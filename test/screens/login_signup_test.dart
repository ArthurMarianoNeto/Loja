import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loja/models/user_manager.dart';
import 'package:loja/screens/login/login_screen.dart';
import 'package:loja/screens/signup/signup_screen.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:provider/provider.dart';

/// Abre a [rota] por cima de uma tela inicial, como no app (pushNamed).
Future<void> abrir(WidgetTester tester, UserManager userManager, String rota) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<UserManager>.value(
      value: userManager,
      child: MaterialApp(
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).pushNamed(rota),
              child: const Text('Início'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Início'));
  await tester.pumpAndSettle();
}

Finder campo(String hint) => find.widgetWithText(TextFormField, hint);

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late UserManager userManager;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc('users/u1').set({'name': 'Fulano de Tal'});
    auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'u1', email: 'fulano@gmail.com'),
    );
    userManager = UserManager(
        auth: auth, firestore: firestore, getToken: () async => null);
  });

  group('LoginScreen', () {
    Future<void> entrar(WidgetTester tester, String email, String senha) async {
      await tester.enterText(campo('E-mail'), email);
      await tester.enterText(campo('Senha'), senha);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
    }

    testWidgets('valida e-mail e senha antes de tentar entrar', (tester) async {
      await abrir(tester, userManager, '/login');

      await entrar(tester, 'fulano', '123');

      expect(find.text('E-mail inválido'), findsOneWidget);
      expect(find.text('Senha inválida'), findsOneWidget);
      expect(userManager.isLoggedIn, isFalse);
    });

    testWidgets('falha no login mostra a mensagem traduzida', (tester) async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      await abrir(tester, userManager, '/login');

      await entrar(tester, 'fulano@gmail.com', '123456');

      expect(find.text('Falha ao entrar: E-mail ou senha incorretos.'),
          findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('login com sucesso volta para a tela anterior', (tester) async {
      await abrir(tester, userManager, '/login');

      await entrar(tester, 'fulano@gmail.com', '123456');

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Início'), findsOneWidget);
      expect(userManager.user!.name, 'Fulano de Tal');
    });

    testWidgets('esqueci a senha pede o e-mail antes', (tester) async {
      await abrir(tester, userManager, '/login');

      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();

      expect(find.text('Insira seu e-mail para recuperação'), findsOneWidget);
    });

    testWidgets('CRIAR CONTA troca para a tela de cadastro', (tester) async {
      await abrir(tester, userManager, '/login');

      await tester.tap(find.text('CRIAR CONTA'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('SignUpScreen', () {
    Future<void> preencher(WidgetTester tester, {required String nome,
      required String email, required String senha, required String repetir}) async {
      await tester.enterText(campo('Nome Completo'), nome);
      await tester.enterText(campo('E-mail'), email);
      await tester.enterText(campo('Senha'), senha);
      await tester.enterText(campo('Repita a Senha'), repetir);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar Conta'));
      await tester.pumpAndSettle();
    }

    testWidgets('valida nome completo, e-mail e senha', (tester) async {
      await abrir(tester, userManager, '/signup');

      await preencher(tester,
          nome: 'Fulano', email: 'fulano', senha: '123', repetir: '');

      expect(find.text('Preencha seu Nome completo'), findsOneWidget);
      expect(find.text('E-mail inválido'), findsOneWidget);
      expect(find.text('Senha muito curta'), findsOneWidget);
      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets('senhas diferentes não criam a conta', (tester) async {
      await abrir(tester, userManager, '/signup');

      await preencher(tester, nome: 'Ciclano Souza', email: 'ciclano@gmail.com',
          senha: '123456', repetir: '654321');

      expect(find.text('Senhas não coincidem!'), findsOneWidget);
      expect(userManager.isLoggedIn, isFalse);
    });

    testWidgets('cadastro com sucesso salva o usuário e volta', (tester) async {
      await abrir(tester, userManager, '/signup');

      await preencher(tester, nome: 'Ciclano Souza', email: 'ciclano@gmail.com',
          senha: '123456', repetir: '123456');

      expect(find.byType(SignUpScreen), findsNothing);
      expect(userManager.user!.name, 'Ciclano Souza');
      final doc = await firestore.doc('users/${userManager.user!.id}').get();
      expect(doc.data()!['email'], 'ciclano@gmail.com');
    });
  });
}
