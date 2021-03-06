import 'dart:io';

class AdManager {
  static String get appId {
    if (Platform.isAndroid) {
      // return "ca-app-pub-3940256099942544~4354546703";
      return "ca-app-pub-2551410065860924~7363850433";
    } else if (Platform.isIOS) {
      // return "ca-app-pub-3940256099942544~2594085930";
      return "ca-app-pub-2551410065860924~2781252376";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/8865242552";
      // return "ca-app-pub-2551410065860924/3164395758";
    } else if (Platform.isIOS) {
      return "ca-app-pub-3940256099942544/4339318960";
      // return "ca-app-pub-2551410065860924/9155089038";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // static String get interstitialAdUnitId {
  //   if (Platform.isAndroid) {
  //     return "ca-app-pub-3940256099942544/7049598008";
  //   } else if (Platform.isIOS) {
  //     return "ca-app-pub-3940256099942544/3964253750";
  //   } else {
  //     throw new UnsupportedError("Unsupported platform");
  //   }
  // }

  // static String get rewardedAdUnitId {
  //   if (Platform.isAndroid) {
  //     return "ca-app-pub-3940256099942544/8673189370";
  //   } else if (Platform.isIOS) {
  //     return "ca-app-pub-3940256099942544/7552160883";
  //   } else {
  //     throw new UnsupportedError("Unsupported platform");
  //   }
  // }
}
