import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 이용권 — Talkverse 계정 이용권(lang 'tr', auth.talkverse.uk) OR 이 기기에서 산·복원한 스토어 구매(lang_tr_*·all_*).
/// 무료/유료 범위 = ~/talkverse/PAYWALL_SPEC.md §2(2026-11-23): 회화 R0·R1(+옛 이야기 L1)·커리큘럼 1단계·문법 1~2스텝·언어감각 1급은 무료.
class Entitlement {
  Entitlement._();
  static const lang = 'tr';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);

  /// 회화 편이 무료인가(레벨 R0·R1·옛 이야기 L1).
  static bool freeRegion(String region) => region == 'L1' || region == 'R0' || region == 'R1';

  /// 잠긴 곳을 누를 때 — 무료거나 이용권이 있으면 true, 아니면 결제 화면을 띄우고 산 뒤에 다시 판정.
  static Future<bool> allow(BuildContext context, bool free) async {
    if (free || premium) return true;
    await showPaywall(context);
    return premium;
  }
}
