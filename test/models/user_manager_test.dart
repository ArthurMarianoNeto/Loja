import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loja/models/app_user.dart';
import 'package:loja/models/user_manager.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

Future<String?> tokenFalso() async => 'token-1';

void main() {
  late FakeFirebaseFirestore firestore;
  final MockUser mockUser = MockUser(uid: 'u1', email: 'fulano@gmail.com');

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.doc('users/u1').set({
      'name': 'Fulano de Tal',
      'email': 'fulano@gmail.com',
      'cpf': '123.456.789-09',
    });
  });

  group('carregamento inicial', () {
    test('sem usuário logado, user fica nulo', () async {
      final userManager = UserManager(
        auth: MockFirebaseAuth(mockUser: mockUser),
        firestore: firestore,
        getToken: tokenFalso,
      );
      await pumpEventQueue();

      expect(userManager.user, isNull);
      expect(userManager.isLoggedIn, isFalse);
      expect(userManager.adminEnabled, isFalse);
    });

    test('com usuário logado, carrega dados e salva o token do FCM', () async {
      final userManager = UserManager(
        auth: MockFirebaseAuth(signedIn: true, mockUser: mockUser),
        firestore: firestore,
        getToken: tokenFalso,
      );
      await pumpEventQueue();

      expect(userManager.user!.name, 'Fulano de Tal');
      expect(userManager.user!.cpf, '123.456.789-09');
      expect(userManager.adminEnabled, isFalse);
      final token = await firestore.doc('users/u1/tokens/token-1').get();
      expect(token.data()!['token'], 'token-1');
    });

    test('usuário em admins/ habilita o modo administrador', () async {
      await firestore.doc('admins/u1').set({});

      final userManager = UserManager(
        auth: MockFirebaseAuth(signedIn: true, mockUser: mockUser),
        firestore: firestore,
        getToken: tokenFalso,
      );
      await pumpEventQueue();

      expect(userManager.adminEnabled, isTrue);
    });
  });

  group('signIn', () {
    test('sucesso: carrega o usuário e chama onSuccess', () async {
      final userManager = UserManager(
        auth: MockFirebaseAuth(mockUser: mockUser),
        firestore: firestore,
        getToken: tokenFalso,
      );
      final List<bool> estadosLoading = [];
      userManager.addListener(() => estadosLoading.add(userManager.loading));
      bool sucesso = false;

      await userManager.signIn(
        user: AppUser(email: 'fulano@gmail.com', password: '123456'),
        onFail: (e) => fail('não deveria falhar: $e'),
        onSuccess: () => sucesso = true,
      );

      expect(sucesso, isTrue);
      expect(userManager.user!.name, 'Fulano de Tal');
      expect(estadosLoading.first, isTrue);
      expect(estadosLoading.last, isFalse);
    });

    test('falha: traduz o erro e não loga', () async {
      final auth = MockFirebaseAuth(mockUser: mockUser);
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      final userManager =
          UserManager(auth: auth, firestore: firestore, getToken: tokenFalso);
      String? falha;

      await userManager.signIn(
        user: AppUser(email: 'fulano@gmail.com', password: 'errada'),
        onFail: (e) => falha = e,
        onSuccess: () => fail('não deveria ter sucesso'),
      );

      expect(falha, 'E-mail ou senha incorretos.');
      expect(userManager.isLoggedIn, isFalse);
      expect(userManager.loading, isFalse);
    });
  });

  group('signUp', () {
    test('sucesso: cria a conta e salva os dados em users/{uid}', () async {
      final auth = MockFirebaseAuth();
      final userManager =
          UserManager(auth: auth, firestore: firestore, getToken: tokenFalso);
      bool sucesso = false;

      await userManager.signUp(
        user: AppUser(
          name: 'Ciclano Souza',
          email: 'ciclano@gmail.com',
          password: '123456',
        ),
        onFail: (e) => fail('não deveria falhar: $e'),
        onSuccess: () => sucesso = true,
      );
      await pumpEventQueue();

      expect(sucesso, isTrue);
      final String uid = auth.currentUser!.uid;
      expect(userManager.user!.id, uid);
      final doc = await firestore.doc('users/$uid').get();
      expect(doc.data(), {'name': 'Ciclano Souza', 'email': 'ciclano@gmail.com'});
      expect(userManager.loading, isFalse);
    });

    test('falha: traduz o erro e não salva nada', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      final userManager =
          UserManager(auth: auth, firestore: firestore, getToken: tokenFalso);
      String? falha;

      await userManager.signUp(
        user: AppUser(
          name: 'Ciclano Souza',
          email: 'fulano@gmail.com',
          password: '123456',
        ),
        onFail: (e) => falha = e,
        onSuccess: () => fail('não deveria ter sucesso'),
      );

      expect(falha, 'E-mail já está sendo utilizado em outra conta.');
      expect(userManager.isLoggedIn, isFalse);
      expect((await firestore.collection('users').get()).docs, hasLength(1));
    });
  });

  test('signOut desloga no FirebaseAuth e limpa o usuário', () async {
    final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
    final userManager =
        UserManager(auth: auth, firestore: firestore, getToken: tokenFalso);
    await pumpEventQueue();
    expect(userManager.isLoggedIn, isTrue);

    userManager.signOut();
    await pumpEventQueue();

    expect(userManager.isLoggedIn, isFalse);
    expect(auth.currentUser, isNull);
  });
}
