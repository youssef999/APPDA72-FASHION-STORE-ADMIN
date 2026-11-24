class PaymentConfigModel {
  static const String collection = 'store_settings';
  static const String docId = 'payment_config';

  final bool isTapEnabled;
  final bool isMoyasarEnabled;
  final bool isSandboxMode;
  final String publishableKeyTest;
  final String publishableKeyLive;
  final String merchantId;
  final String applePayMerchantId;
  final String moyasarPublishableKeyTest;
  final String moyasarPublishableKeyLive;
  final String moyasarApplePayMerchantId;
  final String currency;
  final String countryCode;
  final String androidBundleId;
  final String iosBundleId;
  final String webhookUrl;
  final List<String> supportedMethods;

  const PaymentConfigModel({
    this.isTapEnabled = false,
    this.isMoyasarEnabled = false,
    this.isSandboxMode = true,
    this.publishableKeyTest = '',
    this.publishableKeyLive = '',
    this.merchantId = '',
    this.applePayMerchantId = '',
    this.moyasarPublishableKeyTest = '',
    this.moyasarPublishableKeyLive = '',
    this.moyasarApplePayMerchantId = '',
    this.currency = 'SAR',
    this.countryCode = 'SA',
    this.androidBundleId = '',
    this.iosBundleId = '',
    this.webhookUrl = '',
    this.supportedMethods = const ['MADA', 'APPLE_PAY', 'VISA', 'MASTERCARD', 'STC_PAY'],
  });

  factory PaymentConfigModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const PaymentConfigModel();
    final methods = data['supportedMethods'];
    return PaymentConfigModel(
      isTapEnabled: data['isTapEnabled'] == true,
      isMoyasarEnabled: data['isMoyasarEnabled'] == true,
      isSandboxMode: data['isSandboxMode'] != false,
      publishableKeyTest: '${data['publishableKeyTest'] ?? ''}',
      publishableKeyLive: '${data['publishableKeyLive'] ?? ''}',
      merchantId: '${data['merchantId'] ?? ''}',
      applePayMerchantId: '${data['applePayMerchantId'] ?? ''}',
      moyasarPublishableKeyTest: '${data['moyasarPublishableKeyTest'] ?? ''}',
      moyasarPublishableKeyLive: '${data['moyasarPublishableKeyLive'] ?? ''}',
      moyasarApplePayMerchantId: '${data['moyasarApplePayMerchantId'] ?? ''}',
      currency: '${data['currency'] ?? 'SAR'}'.toUpperCase(),
      countryCode: '${data['countryCode'] ?? 'SA'}'.toUpperCase(),
      androidBundleId: '${data['androidBundleId'] ?? ''}',
      iosBundleId: '${data['iosBundleId'] ?? ''}',
      webhookUrl: '${data['webhookUrl'] ?? ''}',
      supportedMethods: methods is List
          ? methods.map((e) => '$e').where((e) => e.isNotEmpty).toList()
          : const ['MADA', 'APPLE_PAY', 'VISA', 'MASTERCARD', 'STC_PAY'],
    );
  }

  Map<String, dynamic> toMap() => {
        'isTapEnabled': isTapEnabled,
        'isMoyasarEnabled': isMoyasarEnabled,
        'isSandboxMode': isSandboxMode,
        'publishableKeyTest': publishableKeyTest,
        'publishableKeyLive': publishableKeyLive,
        'merchantId': merchantId,
        'applePayMerchantId': applePayMerchantId,
        'moyasarPublishableKeyTest': moyasarPublishableKeyTest,
        'moyasarPublishableKeyLive': moyasarPublishableKeyLive,
        'moyasarApplePayMerchantId': moyasarApplePayMerchantId,
        'currency': currency,
        'countryCode': countryCode,
        'androidBundleId': androidBundleId,
        'iosBundleId': iosBundleId,
        'webhookUrl': webhookUrl,
        'supportedMethods': supportedMethods,
      };

  PaymentConfigModel copyWith({
    bool? isTapEnabled,
    bool? isMoyasarEnabled,
    bool? isSandboxMode,
    String? publishableKeyTest,
    String? publishableKeyLive,
    String? merchantId,
    String? applePayMerchantId,
    String? moyasarPublishableKeyTest,
    String? moyasarPublishableKeyLive,
    String? moyasarApplePayMerchantId,
    String? currency,
    String? countryCode,
    String? androidBundleId,
    String? iosBundleId,
    String? webhookUrl,
    List<String>? supportedMethods,
  }) {
    return PaymentConfigModel(
      isTapEnabled: isTapEnabled ?? this.isTapEnabled,
      isMoyasarEnabled: isMoyasarEnabled ?? this.isMoyasarEnabled,
      isSandboxMode: isSandboxMode ?? this.isSandboxMode,
      publishableKeyTest: publishableKeyTest ?? this.publishableKeyTest,
      publishableKeyLive: publishableKeyLive ?? this.publishableKeyLive,
      merchantId: merchantId ?? this.merchantId,
      applePayMerchantId: applePayMerchantId ?? this.applePayMerchantId,
      moyasarPublishableKeyTest:
          moyasarPublishableKeyTest ?? this.moyasarPublishableKeyTest,
      moyasarPublishableKeyLive:
          moyasarPublishableKeyLive ?? this.moyasarPublishableKeyLive,
      moyasarApplePayMerchantId:
          moyasarApplePayMerchantId ?? this.moyasarApplePayMerchantId,
      currency: currency ?? this.currency,
      countryCode: countryCode ?? this.countryCode,
      androidBundleId: androidBundleId ?? this.androidBundleId,
      iosBundleId: iosBundleId ?? this.iosBundleId,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      supportedMethods: supportedMethods ?? this.supportedMethods,
    );
  }
}

class PaymentSecretsModel {
  static const String collection = 'private_settings';
  static const String docId = 'payment_secrets';

  final String secretKeyTest;
  final String secretKeyLive;
  final String secretKeyTestAndroid;
  final String secretKeyLiveAndroid;
  final String secretKeyTestIos;
  final String secretKeyLiveIos;
  final String moyasarSecretKeyTest;
  final String moyasarSecretKeyLive;

  const PaymentSecretsModel({
    this.secretKeyTest = '',
    this.secretKeyLive = '',
    this.secretKeyTestAndroid = '',
    this.secretKeyLiveAndroid = '',
    this.secretKeyTestIos = '',
    this.secretKeyLiveIos = '',
    this.moyasarSecretKeyTest = '',
    this.moyasarSecretKeyLive = '',
  });

  factory PaymentSecretsModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const PaymentSecretsModel();
    return PaymentSecretsModel(
      secretKeyTest: '${data['secretKeyTest'] ?? ''}',
      secretKeyLive: '${data['secretKeyLive'] ?? ''}',
      secretKeyTestAndroid: '${data['secretKeyTestAndroid'] ?? ''}',
      secretKeyLiveAndroid: '${data['secretKeyLiveAndroid'] ?? ''}',
      secretKeyTestIos: '${data['secretKeyTestIos'] ?? ''}',
      secretKeyLiveIos: '${data['secretKeyLiveIos'] ?? ''}',
      moyasarSecretKeyTest: '${data['moyasarSecretKeyTest'] ?? ''}',
      moyasarSecretKeyLive: '${data['moyasarSecretKeyLive'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap() => {
        'secretKeyTest': secretKeyTest,
        'secretKeyLive': secretKeyLive,
        'secretKeyTestAndroid': secretKeyTestAndroid,
        'secretKeyLiveAndroid': secretKeyLiveAndroid,
        'secretKeyTestIos': secretKeyTestIos,
        'secretKeyLiveIos': secretKeyLiveIos,
        'moyasarSecretKeyTest': moyasarSecretKeyTest,
        'moyasarSecretKeyLive': moyasarSecretKeyLive,
      };

  PaymentSecretsModel copyWith({
    String? secretKeyTest,
    String? secretKeyLive,
    String? secretKeyTestAndroid,
    String? secretKeyLiveAndroid,
    String? secretKeyTestIos,
    String? secretKeyLiveIos,
    String? moyasarSecretKeyTest,
    String? moyasarSecretKeyLive,
  }) {
    return PaymentSecretsModel(
      secretKeyTest: secretKeyTest ?? this.secretKeyTest,
      secretKeyLive: secretKeyLive ?? this.secretKeyLive,
      secretKeyTestAndroid: secretKeyTestAndroid ?? this.secretKeyTestAndroid,
      secretKeyLiveAndroid: secretKeyLiveAndroid ?? this.secretKeyLiveAndroid,
      secretKeyTestIos: secretKeyTestIos ?? this.secretKeyTestIos,
      secretKeyLiveIos: secretKeyLiveIos ?? this.secretKeyLiveIos,
      moyasarSecretKeyTest: moyasarSecretKeyTest ?? this.moyasarSecretKeyTest,
      moyasarSecretKeyLive: moyasarSecretKeyLive ?? this.moyasarSecretKeyLive,
    );
  }
}
