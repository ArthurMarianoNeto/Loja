import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loja/helpers/extensions.dart';
import 'package:loja/helpers/firebase_errors.dart';
import 'package:loja/helpers/validators.dart';

void main() {
  group('emailValid', () {
    test('aceita e-mails válidos', () {
      expect(emailValid('fulano@gmail.com'), isTrue);
      expect(emailValid('fulano.tal@empresa.com.br'), isTrue);
    });

    test('recusa e-mails inválidos', () {
      expect(emailValid(''), isFalse);
      expect(emailValid('fulano'), isFalse);
      expect(emailValid('fulano@'), isFalse);
      expect(emailValid('fulano@gmail'), isFalse);
    });
  });

  group('getErrorString', () {
    test('traduz os códigos do FirebaseAuthException', () {
      expect(getErrorString('weak-password'), 'Sua senha é muito fraca.');
      expect(getErrorString('invalid-email'), 'Seu e-mail é inválido.');
      expect(getErrorString('email-already-in-use'),
          'E-mail já está sendo utilizado em outra conta.');
      expect(getErrorString('invalid-credential'),
          'E-mail ou senha incorretos.');
      expect(getErrorString('wrong-password'), 'Sua senha está incorreta.');
      expect(getErrorString('user-not-found'),
          'Não há usuário com este e-mail.');
    });

    test('código desconhecido ou nulo vira mensagem genérica', () {
      expect(getErrorString('qualquer-coisa'), 'Um erro indefinido ocorreu.');
      expect(getErrorString(null), 'Um erro indefinido ocorreu.');
    });
  });

  group('TimeOfDay', () {
    test('formatted usa o padrão 9h05', () {
      expect(const TimeOfDay(hour: 9, minute: 5).formatted(), '9h05');
      expect(const TimeOfDay(hour: 18, minute: 30).formatted(), '18h30');
    });

    test('toMinutes conta os minutos desde a meia-noite', () {
      expect(const TimeOfDay(hour: 0, minute: 0).toMinutes(), 0);
      expect(const TimeOfDay(hour: 10, minute: 15).toMinutes(), 615);
    });
  });
}
