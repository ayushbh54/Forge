import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nirmaan_app/core/localization/app_localizations.dart';
import 'package:nirmaan_app/core/localization/language_controller.dart';
import 'package:nirmaan_app/providers/app_provider.dart';
import 'package:nirmaan_app/screens/settings/settings_screen.dart';

void main() {
  group('Localization Audit Tests', () {
    test('Verify all 15 Indian languages are supported in AppLocalizations', () {
      final expectedCodes = [
        'en', // English
        'hi', // Hindi
        'te', // Telugu
        'ta', // Tamil
        'kn', // Kannada
        'ml', // Malayalam
        'mr', // Marathi
        'bn', // Bengali
        'gu', // Gujarati
        'as', // Assamese
        'pa', // Punjabi
        'or', // Odia
        'ur', // Urdu
        'mai', // Maithili
        'sa', // Sanskrit
      ];

      expect(AppLocalizations.supportedLanguages.length, 15);
      final supportedCodes = AppLocalizations.supportedLanguages.map((l) => l.code).toList();
      for (final code in expectedCodes) {
        expect(supportedCodes.contains(code), isTrue, reason: 'Language $code must be supported');
      }
    });

    test('Verify all 10 languages have translation entries for all 51 English keys', () {
      const allKeys = [
        // Base project keys
        'app_title',
        'tagline',
        'project_workspace',
        'unique_id',
        'expected_completion',
        'original_finish',
        'variance',
        'budget_tracking',
        'total_budget',
        'spent_budget',
        'remaining_budget',
        'daily_update',
        'schedule_forecast',
        'hr_workforce',
        'labour_attendance',
        'supervisor_visit',
        'voice_assistant',
        'pdf_intelligence',
        'gemini_brain',
        'clock_in',
        'mark_presence',
        'review_and_confirm',
        'speak_now',
        'tender_summary',
        'convert_to_hindi',
        'materials_stores',
        'conflicts_disputes',
        // Newly added section keys
        'fidic_variations',
        'fidic_variations_subtitle',
        'variation_orders',
        'clause_13_variations',
        'claims_dab',
        'claims_dab_subtitle',
        'extension_of_time',
        'dispute_adjudication',
        'pipeline_ndt',
        'pipeline_ndt_subtitle',
        'weld_integrity',
        'ndt_clearance',
        'digital_twin',
        'digital_twin_subtitle',
        'gis_site_map',
        'chainage_tracking',
        'executive_reports',
        'executive_reports_subtitle',
        'health_index',
        'dossier_export',
        'stakeholder_portal',
        'stakeholder_portal_subtitle',
        'contractor_hub',
        'hold_point_approvals',
      ];

      expect(allKeys.length, 51);

      for (final lang in AppLocalizations.supportedLanguages) {
        for (final key in allKeys) {
          final translated = AppLocalizations.text(key, lang.code);
          expect(
            translated,
            isNotEmpty,
            reason: 'Key "$key" in "${lang.name}" (${lang.code}) must not be empty',
          );
          // For non-English languages, ensure it doesn't just fallback to the key itself
          if (lang.code != 'en') {
            expect(
              translated,
              isNot(equals(key)),
              reason: 'Key "$key" in "${lang.name}" (${lang.code}) was not translated',
            );
          }
        }
      }
    });

    test('Verify all 10 languages have distinct translations for newly added sections', () {
      const newlyAddedSections = [
        'fidic_variations',
        'claims_dab',
        'pipeline_ndt',
        'digital_twin',
        'executive_reports',
        'stakeholder_portal',
      ];

      for (final lang in AppLocalizations.supportedLanguages) {
        for (final secKey in newlyAddedSections) {
          final translated = AppLocalizations.text(secKey, lang.code);
          expect(translated, isNotEmpty, reason: '$secKey in ${lang.code} should not be empty');
          if (lang.code != 'en') {
            expect(translated, isNot(equals(secKey)), reason: '$secKey in ${lang.code} should be translated');
          }
        }
      }
    });

    test('Verify Upper Assam (Duliajan) Field Operations Assamese (অসমীয়া) translations', () {
      const asCode = 'as';

      // 1. FIDIC Variations
      expect(AppLocalizations.text('fidic_variations', asCode), 'এফআইডিআইচি পৰিৱৰ্তন (FIDIC Variations)');
      expect(AppLocalizations.text('variation_orders', asCode), 'পৰিৱৰ্তন আদেশ আৰু পৰিসৰ সালসলনি');
      expect(AppLocalizations.text('clause_13_variations', asCode), 'এফআইডিআইচি ক্লজ ১৩ পৰিৱৰ্তন পঞ্জী');

      // 2. Claims & DAB
      expect(AppLocalizations.text('claims_dab', asCode), 'দাবী আৰু ডি.এ.বি. (Claims & DAB)');
      expect(AppLocalizations.text('extension_of_time', asCode), 'সময় বৃদ্ধিৰ দাবী (EOT)');
      expect(AppLocalizations.text('dispute_adjudication', asCode), 'বিবাদ নিষ্পত্তি ব’ৰ্ড (DAB)');

      // 3. Pipeline NDT
      expect(AppLocalizations.text('pipeline_ndt', asCode), 'পাইপলাইন এন.ডি.টি. (Pipeline NDT)');
      expect(AppLocalizations.text('weld_integrity', asCode), 'ৱেল্ড অখণ্ডতা আৰু ৰেডিঅ’গ্ৰাফী');
      expect(AppLocalizations.text('ndt_clearance', asCode), 'পাইপলাইন এনডিটি অনুমোদন');

      // 4. Digital Twin - Oil India Duliajan spread
      expect(AppLocalizations.text('digital_twin', asCode), 'ডিজিটেল টুইন ৩ডি (Digital Twin)');
      expect(AppLocalizations.text('digital_twin_subtitle', asCode), contains('দুলীয়াজান'));
      expect(AppLocalizations.text('gis_site_map', asCode), '৩ডি জিআইএছ ডিজিটেল টুইন মানচিত্ৰ');
      expect(AppLocalizations.text('chainage_tracking', asCode), 'পাইপলাইন চেইনেজ অনুসৰণ');

      // 5. Executive Reports
      expect(AppLocalizations.text('executive_reports', asCode), 'কাৰ্যবাহী প্ৰতিবেদন (Executive Reports)');
      expect(AppLocalizations.text('health_index', asCode), 'প্ৰকল্প স্বাস্থ্য সূচক');
      expect(AppLocalizations.text('dossier_export', asCode), 'কাৰ্যবাহী অগ্ৰগতি নথিপত্ৰ ৰপ্তানি');

      // 6. Stakeholder Portal
      expect(AppLocalizations.text('stakeholder_portal', asCode), 'অংশীদাৰ পৰ্টেল (Stakeholder Portal)');
      expect(AppLocalizations.text('contractor_hub', asCode), 'ইপিচি আৰু ঠিকাদাৰ কেন্দ্ৰ');
      expect(AppLocalizations.text('hold_point_approvals', asCode), 'গুণমান নিশ্চিতকৰণ অনুমোদন (Hold Points)');
    });

    test('Verify dynamic language switching via LanguageController without app restart', () {
      final controller = LanguageController.instance;

      // Default should be 'en'
      controller.changeLanguage('en');
      expect(controller.currentLanguageCode, 'en');
      expect(AppLocalizations.text('app_title'), 'Nirmaan OS');
      expect(AppLocalizations.text('fidic_variations'), 'FIDIC Variations');
      expect(AppLocalizations.text('claims_dab'), 'Claims & DAB');
      expect(AppLocalizations.text('pipeline_ndt'), 'Pipeline NDT');
      expect(AppLocalizations.text('digital_twin'), 'Digital Twin');
      expect(AppLocalizations.text('executive_reports'), 'Executive Reports');
      expect(AppLocalizations.text('stakeholder_portal'), 'Stakeholder Portal');

      // Change to Hindi
      bool notified = false;
      void listener() {
        notified = true;
      }
      controller.addListener(listener);

      controller.changeLanguage('hi');
      expect(controller.currentLanguageCode, 'hi');
      expect(notified, isTrue);
      expect(AppLocalizations.text('app_title'), 'निर्माण ओएस');
      expect(AppLocalizations.text('fidic_variations'), 'एफआईडीआईसी बदलाव (FIDIC Variations)');
      expect(AppLocalizations.text('claims_dab'), 'दावे एवं डीएबी (Claims & DAB)');
      expect(AppLocalizations.text('pipeline_ndt'), 'पाइपलाइन एनडीटी (Pipeline NDT)');
      expect(AppLocalizations.text('digital_twin'), 'डिजिटल ट्विन 3D (Digital Twin)');
      expect(AppLocalizations.text('executive_reports'), 'कार्यकारी रिपोर्ट (Executive Reports)');
      expect(AppLocalizations.text('stakeholder_portal'), 'स्टेकहोल्डर पोर्टल (Stakeholder Portal)');

      // Change to Assamese (Field operations language in Upper Assam)
      controller.changeLanguage('as');
      expect(controller.currentLanguageCode, 'as');
      expect(AppLocalizations.text('app_title'), 'নিৰ্মাণ ওএছ');
      expect(AppLocalizations.text('fidic_variations'), 'এফআইডিআইচি পৰিৱৰ্তন (FIDIC Variations)');
      expect(AppLocalizations.text('claims_dab'), 'দাবী আৰু ডি.এ.বি. (Claims & DAB)');
      expect(AppLocalizations.text('pipeline_ndt'), 'পাইপলাইন এন.ডি.টি. (Pipeline NDT)');
      expect(AppLocalizations.text('digital_twin'), 'ডিজিটেল টুইন ৩ডি (Digital Twin)');
      expect(AppLocalizations.text('executive_reports'), 'কাৰ্যবাহী প্ৰতিবেদন (Executive Reports)');
      expect(AppLocalizations.text('stakeholder_portal'), 'অংশীদাৰ পৰ্টেল (Stakeholder Portal)');

      // Change to Telugu
      controller.changeLanguage('te');
      expect(controller.currentLanguageCode, 'te');
      expect(AppLocalizations.text('app_title'), 'నిర్మాణ్ ఓఎస్');
      expect(AppLocalizations.text('fidic_variations'), 'FIDIC మార్పులు (FIDIC Variations)');

      // Change to Tamil
      controller.changeLanguage('ta');
      expect(controller.currentLanguageCode, 'ta');
      expect(AppLocalizations.text('app_title'), 'நிர்மான் ஓஎஸ்');
      expect(AppLocalizations.text('fidic_variations'), 'FIDIC மாற்றங்கள் (FIDIC Variations)');

      // Change to Kannada
      controller.changeLanguage('kn');
      expect(controller.currentLanguageCode, 'kn');
      expect(AppLocalizations.text('app_title'), 'ನಿರ್ಮಾಣ್ ಓಎಸ್');
      expect(AppLocalizations.text('fidic_variations'), 'FIDIC ಬದಲಾವಣೆಗಳು (FIDIC Variations)');

      // Change to Malayalam
      controller.changeLanguage('ml');
      expect(controller.currentLanguageCode, 'ml');
      expect(AppLocalizations.text('app_title'), 'നിർമ്മാൺ ഒഎസ്');
      expect(AppLocalizations.text('fidic_variations'), 'FIDIC വ്യതിയാനങ്ങൾ (FIDIC Variations)');

      // Change to Marathi
      controller.changeLanguage('mr');
      expect(controller.currentLanguageCode, 'mr');
      expect(AppLocalizations.text('app_title'), 'निर्माण ओएस');
      expect(AppLocalizations.text('fidic_variations'), 'FIDIC बदल (FIDIC Variations)');

      // Change to Bengali
      controller.changeLanguage('bn');
      expect(controller.currentLanguageCode, 'bn');
      expect(AppLocalizations.text('app_title'), 'নির্মাণ ওএস');
      expect(AppLocalizations.text('fidic_variations'), 'এফআইডিআইসি পরিবর্তন (FIDIC Variations)');

      // Change to Gujarati
      controller.changeLanguage('gu');
      expect(controller.currentLanguageCode, 'gu');
      expect(AppLocalizations.text('app_title'), 'નિર્માણ ઓએસ');
      expect(AppLocalizations.text('fidic_variations'), 'FIDIC ફેરફારો (FIDIC Variations)');

      // Cleanup
      controller.removeListener(listener);
      controller.changeLanguage('en');
    });

    testWidgets('Verify SettingsScreen renders all 10 language choices and switches dynamically', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      LanguageController.instance.changeLanguage('en');

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 10 languages are present in the settings UI
      for (final lang in AppLocalizations.supportedLanguages) {
        expect(
          find.text('${lang.nativeName} (${lang.name})'),
          findsOneWidget,
          reason: 'Language chip for ${lang.name} should be visible',
        );
      }

      // Verify initial preview shows English title and sections
      expect(find.text('Nirmaan OS'), findsWidgets);
      expect(find.text('FIDIC Variations'), findsWidgets);

      // Tap Hindi chip
      final hindiChip = find.text('हिन्दी (Hindi)');
      await tester.tap(hindiChip);
      await tester.pumpAndSettle();

      // Controller must now be in Hindi
      expect(LanguageController.instance.currentLanguageCode, 'hi');
      // Live preview must now show Hindi title & sections
      expect(find.text('निर्माण ओएस'), findsWidgets);
      expect(find.text('एफआईडीआईसी बदलाव (FIDIC Variations)'), findsWidgets);

      // Tap Assamese chip (Primary field operations language in Duliajan)
      final assameseChip = find.text('অসমীয়া (Assamese)');
      await tester.tap(assameseChip);
      await tester.pumpAndSettle();

      // Controller must now be in Assamese
      expect(LanguageController.instance.currentLanguageCode, 'as');
      // Live preview must now show Assamese title & sections
      expect(find.text('নিৰ্মাণ ওএছ'), findsWidgets);
      expect(find.text('এফআইডিআইচি পৰিৱৰ্তন (FIDIC Variations)'), findsWidgets);

      // Tap Bengali chip
      final bengaliChip = find.text('বাংলা (Bengali)');
      await tester.tap(bengaliChip);
      await tester.pumpAndSettle();

      // Controller must now be in Bengali
      expect(LanguageController.instance.currentLanguageCode, 'bn');
      // Live preview must now show Bengali title
      expect(find.text('নির্মাণ ওএস'), findsWidgets);
      expect(find.text('এফআইডিআইসি পরিবর্তন (FIDIC Variations)'), findsWidgets);

      // Reset back to English
      LanguageController.instance.changeLanguage('en');
    });
  });
}
