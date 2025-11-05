/// Arquivo de configuração que será sobrescrito pelo GitHub Actions
/// usando `sed` no workflow flutter-build.yml

class AppSettings {
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Ehost Local',
  );

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://acesso.ehostsolucoes.com.br/super/apps/?id=985',
  );

  static const String androidId = String.fromEnvironment(
    'PACKAGE_NAME',
    defaultValue: 'com.appehost.ehost',
  );

  static const String iOSId = String.fromEnvironment(
    'IOS_ID',
    defaultValue: 'xxxx',
  );

  /*   static const String appIconColor = String.fromEnvironment(
    'APP_ICON_COLOR',
    defaultValue: '#FFE05F',
  ); */
}
