import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:radio_player/radio_player.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'funcoes.dart';
import 'config.dart';
import 'new_version_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Função chamada para processar notificações em background
  print('Recebeu uma mensagem em background: [32m${message.messageId}[0m');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configura o estilo da barra de status
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      statusBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Trava a orientação para retrato
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp();

  // Configura o handler para mensagens em segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicia o app PRIMEIRO
  runApp(const NewVersionPlus());

  // Configura FCM DEPOIS que o app já está rodando
  _delayedFCMSetup();

  // Quando o app está em segundo plano e o usuário CLICA na notificação
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final url = message.data['url'];
    if (url != null) {
      launchUrl(Uri.parse(url));
    }
  });
}

// Configura FCM de forma assíncrona após a inicialização do app
Future<void> _delayedFCMSetup() async {
  try {
    // Aguarda um breve momento para garantir que o app inicializou
    await Future.delayed(const Duration(seconds: 2));

    // Solicita permissões de notificação
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print(
      'Permissões de notificação: [34m${settings.authorizationStatus}[0m',
    );

    // CANCELAR inscrição no tópico antigo (se necessário)
    // await FirebaseMessaging.instance.unsubscribeFromTopic("br.com.rodrigoti.push");

    // Inscrever no tópico
    await FirebaseMessaging.instance.subscribeToTopic(AppSettings.androidId);
    print('✅ Inscrito no tópico: ${AppSettings.androidId}');
  } catch (e) {
    print('❌ Erro na configuração FCM: $e');
  }
}

class NewVersionPlus extends StatelessWidget {
  const NewVersionPlus({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.black, // cor de fundo da status bar
          statusBarIconBrightness: Brightness.light, // ícones brancos (Android)
          statusBarBrightness: Brightness.dark, // texto branco (iOS)
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Builder(
          builder: (context) {
            // Chama o update checker aqui, com contexto já válido
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppVersionChecker.checkAndPromptUpdate(context);
            });
            return MyApp();
          },
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Inicio());
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

  load() {
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
                    child: CircularProgressIndicator(color: Color(0xff171815)),
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
                        child: Text("Tentar novamente"),
                      ),
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

          RadioPlayer.setStation(
            title: AppSettings.appName,
            url: message.message,
            logoAssetPath: 'assets/logo.png',
          );
          
          // Autoplay ao configurar a estação
          RadioPlayer.play();

          RadioPlayer.playbackStateStream.listen((state) {
            isPlaying = state.toString() == 'PlaybackState.playing';
            if (isPlaying) {
              _controller.runJavaScriptReturningResult(
                'document.querySelector("#play").classList.remove("mdi-play")+document.querySelector("#play").classList.add("mdi-pause")',
              );
            } else {
              _controller.runJavaScriptReturningResult(
                'document.querySelector("#play").classList.add("mdi-play")+document.querySelector("#play").classList.remove("mdi-pause")',
              );
            }
          });
        },
      )
      ..addJavaScriptChannel(
        'tocar',
        onMessageReceived: (JavaScriptMessage message) {
          //se false para tudo(serve pra parar o som na TV), se nao altera entre para e tocar
          if (message.message == 'false') {
            if (isPlaying) {
              RadioPlayer.reset();
            }
          } else {
            isPlaying ? RadioPlayer.reset() : RadioPlayer.play();
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
        Uri.parse(AppSettings.apiUrl),
      ); //"https://acesso.ehostsolucoes.com.br/super/apps/?id=985"

    Site = WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        } else {
          return sair(context);
        }
      },
      child: WebViewWidget(controller: _controller),
    );
  }

  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    // Garante a cor preta da barra de status em cada build
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Stack(children: [Site, Preload]),
      ),
    );
  }
}
