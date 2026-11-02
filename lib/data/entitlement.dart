import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 평생 이용권 — Talkverse 계정 이용권(lang 'tr', auth.talkverse.uk) OR 이 기기에서 산·복원한 스토어 구매(2026-11-02).
/// 어떤 화면을 잠글지는 아직 정하지 않았다(사용자 결정 대기) — 지금은 아무것도 잠그지 않는다.
class Entitlement {
  Entitlement._();
  static const lang = 'tr';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
