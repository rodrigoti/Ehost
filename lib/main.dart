import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:radio_player/radio_player.dart';
import 'funcoes.dart';
import 'config.dart';

void main() => {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Color(0xff171815), // navigation bar color
          statusBarColor: Color(0xff171815),
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      WidgetsFlutterBinding.ensureInitialized(),
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
          .then(
        (value) => runApp(MyApp()),
      )
    };

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Inicio(),
    );
  }
}

class Inicio extends StatefulWidget {
  Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  Widget Site = Container();
  Widget Preload = Container();
  final _controller = WebViewController();

  bool isPlaying = false;
  RadioPlayer radioPlayer = RadioPlayer();

  load() {
    _controller
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              Preload = Container(
                width: double.infinity,
                height: double.infinity,
                color: Color.fromARGB(0, 0, 0, 0),
                child: Center(
                  child: Container(
                    width: 35,
                    height: 35,
                    child: CircularProgressIndicator(
                      color: Color(0xff171815),
                    ),
                  ),
                ),
              );
            });
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              Preload = Container();
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == true) {
              setState(() {
                Site = Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/ops.png',
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 30),
                        child: Text(
                          'Ocorreu um erro na conexão...',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            load();
                          });
                        },
                        child: Text(
                          "Tentar novamente",
                        ),
                      )
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                  ),
                );
              });
              Future.delayed(const Duration(milliseconds: 2000), () {
                setState(() {
                  Preload = Container();
                });
              });
            }
            //print('erro ${error.errorCode} | ${error.description} | ${error.errorType} | ${error.isForMainFrame}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('')) {
              Future.delayed(const Duration(milliseconds: 2000), () {
                setState(() {
                  Preload = Container();
                });
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'stream',
        onMessageReceived: (JavaScriptMessage message) {
          radioPlayer.setChannel(
              title: AppSettings.appName,
              url: message.message,
              imagePath: 'assets/logo.png');

          radioPlayer.stateStream.listen((value) {
            isPlaying = value;

            if (isPlaying) {
              _controller.runJavaScriptReturningResult(
                  'document.querySelector("#play").classList.remove("mdi-play")+document.querySelector("#play").classList.add("mdi-pause")');
            } else {
              _controller.runJavaScriptReturningResult(
                  'document.querySelector("#play").classList.add("mdi-play")+document.querySelector("#play").classList.remove("mdi-pause")');
            }
          });
        },
      )
      ..addJavaScriptChannel(
        'tocar',
        onMessageReceived: (JavaScriptMessage message) {
          //se false para tudo(serve pra parar o som na TV), se nao altera entre para e tocar
          if (message.message == 'false') {
            if (isPlaying) radioPlayer.stop();
          } else {
            isPlaying ? radioPlayer.stop() : radioPlayer.play();
          }
        },
      )
      ..addJavaScriptChannel(
        'openUrl',
        onMessageReceived: (JavaScriptMessage message) {
          openUrl(message.message);
        },
      )
      ..addJavaScriptChannel(
        'share',
        onMessageReceived: (JavaScriptMessage message) {
          share(message.message);
        },
      )
      ..loadRequest(
          Uri.parse(AppSettings.apiUrl)); //"https://acesso.ehostsolucoes.com.br/super/apps/?id=985"

    Site = WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        } else {
          return sair(context);
        }
      },
      child: WebViewWidget(
        controller: _controller,
      ),
    );
  }

  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [Site, Preload],
        ),
      ),
    );
  }
}
