import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

Future<void> openUrl(url) async {
  final Uri _url = Uri.parse(url);
  try {
    await launchUrl(
      _url,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    toast('Erro ao abrir');
  }
}

Future<bool> sair(BuildContext context) async {
  return (await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('O que deseja fazer?'),
      //content: Text('Descricao de alguma coisa'),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Sair'),
        ),
      ],
    ),
  ));
}

Future<void> share(message) async {
  List url = message.split('|');

  if (Platform.isAndroid) {
    await Share.share('Dá uma olhada nesse APP: ${url[0]}');
  } else if (Platform.isIOS) {
    await Share.share('Dá uma olhada nesse APP: ${url[1]}');
  }
}

toast(txt) {
  Fluttertoast.showToast(
      toastLength: Toast.LENGTH_SHORT,
      msg: txt,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 6,
      backgroundColor: Color.fromARGB(255, 174, 29, 0));
}

String removerAcentos(String str) {
  var comAcento =
      'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  var semAcento =
      'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
  for (int i = 0; i < comAcento.length; i++) {
    str = str.replaceAll(comAcento[i], semAcento[i]);
  }
  return str;
}
