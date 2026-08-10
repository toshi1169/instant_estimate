import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract final class GoogleMobileAdsBannerTestIds {
  static const android = 'ca-app-pub-3940256099942544/6300978111';
  static const ios = 'ca-app-pub-3940256099942544/2934735716';

  static String? forPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
  }
}

/// Google公式のテスト広告を表示するバナー。
///
/// 広告の読み込み中・取得失敗時は [fallback] を維持し、無料版の画面に
/// 不自然な空白ができないようにする。
class GoogleMobileAdsBanner extends StatefulWidget {
  const GoogleMobileAdsBanner({
    required this.height,
    required this.fallback,
    super.key,
  });

  final double height;
  final Widget fallback;

  @override
  State<GoogleMobileAdsBanner> createState() => _GoogleMobileAdsBannerState();
}

class _GoogleMobileAdsBannerState extends State<GoogleMobileAdsBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (kIsWeb) return;
    final adUnitId = GoogleMobileAdsBannerTestIds.forPlatform(
      defaultTargetPlatform,
    );
    if (adUnitId == null) return;

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );
    _bannerAd = banner;
    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;
    if (!_isLoaded || banner == null) return widget.fallback;

    return SizedBox(
      height: widget.height,
      child: Center(
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}
