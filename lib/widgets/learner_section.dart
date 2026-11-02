import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/learner_prefs.dart';

/// 프로필 '학습자' 칸(일본어앱 learner_prefs, 2026-11-02) — 이름 → 회화의 `{name}` 자리, 성별 → 학습자 목소리·장면 그림(새 회화 구조부터).
class LearnerSection extends StatelessWidget {
  const LearnerSection({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: LearnerPrefs.name,
        builder: (context, name, _) => ValueListenableBuilder<String>(
          valueListenable: LearnerPrefs.gender,
          builder: (context, gender, _) => Container(
            decoration: BoxDecoration(
              color: AppColors.washi,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: AppColors.beni),
                  title: Text(tr('이름'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      name.isNotEmpty ? trf('{0} — 회화 속 「나」로 나와요', [name]) : tr('없음 — 회화에서 「○○」로 보여요'),
                      style: const TextStyle(fontSize: 11, color: AppColors.sumiLight)),
                  trailing: const Icon(Icons.edit_outlined, color: AppColors.beni, size: 18),
                  onTap: () => _editName(context),
                ),
                const Divider(height: 1, color: AppColors.line),
                ListTile(
                  leading: Icon(gender == 'female' ? Icons.face_3 : Icons.face, color: AppColors.beni),
                  title: Text(tr('성별'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(gender == 'female' ? tr('여성 — 탭하면 남성') : tr('남성 — 탭하면 여성'),
                      style: const TextStyle(fontSize: 11, color: AppColors.sumiLight)),
                  onTap: () => LearnerPrefs.setGender(gender == 'female' ? 'male' : 'female'),
                ),
              ]),
            ),
          ),
        ),
      );

  Future<void> _editName(BuildContext context) async {
    final c = TextEditingController(text: LearnerPrefs.name.value);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('이름')),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: tr('회화에서 불릴 이름'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('취소'))),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr('저장'))),
        ],
      ),
    );
    if (v != null) await LearnerPrefs.setName(v);
  }
}
