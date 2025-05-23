import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revitool/extensions.dart';

import 'package:revitool/shared/settings/app_settings_notifier.dart';
import 'package:revitool/shared/settings/tool_update_service.dart';
import 'package:revitool/utils.dart';
import 'package:revitool/utils_gui.dart';
import 'package:revitool/shared/win_registry_service.dart';
import 'package:revitool/shared/widgets/card_highlight.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;

const languageList = [
  ComboBoxItem(value: 'en_US', child: Text('English')),
  ComboBoxItem(value: 'pt_BR', child: Text('Portuguese (Brazil)')),
  ComboBoxItem(value: 'zh_CN', child: Text('Chinese (Simplified)')),
  ComboBoxItem(value: 'zh_TW', child: Text('Chinese (Traditional)')),
  ComboBoxItem(value: 'de_DE', child: Text('German')),
  ComboBoxItem(value: 'fr_FR', child: Text('French')),
  ComboBoxItem(value: 'ru_RU', child: Text('Russian')),
  ComboBoxItem(value: 'uk_UA', child: Text('Ukrainian')),
  ComboBoxItem(value: 'hu_HU', child: Text('Hungarian')),
  ComboBoxItem(value: 'tr_TR', child: Text('Turkish')),
  ComboBoxItem(value: 'ar_SA', child: Text('Arabic')),
  ComboBoxItem(value: 'it_IT', child: Text('Italian')),
];

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late ThemeMode theme;
  final _toolUpdateService = ToolUpdateService();
  final _updateTitle = ValueNotifier<String>("Check for Updates");

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsNotifierProvider);

    return ScaffoldPage.scrollable(
      padding: kScaffoldPagePadding,
      header: PageHeader(title: Text(context.l10n.pageSettings)),
      children: [
        CardHighlight(
          icon: msicons.FluentIcons.paint_brush_20_regular,
          label: context.l10n.settingsCTLabel,
          description: context.l10n.settingsCTDescription,
          child: ComboBox(
            value: appSettings.themeMode,
            onChanged:
                ref.read(appSettingsNotifierProvider.notifier).updateThemeMode,
            items: [
              ComboBoxItem(
                value: ThemeMode.system,
                child: Text(ThemeMode.system.name.uppercaseFirst()),
              ),
              ComboBoxItem(
                value: ThemeMode.light,
                child: Text(ThemeMode.light.name.uppercaseFirst()),
              ),
              ComboBoxItem(
                value: ThemeMode.dark,
                child: Text(ThemeMode.dark.name.uppercaseFirst()),
              ),
            ],
          ),
        ),
        CardHighlightSwitch(
          icon: msicons.FluentIcons.warning_20_regular,
          label: context.l10n.settingsEPTLabel,
          // description: context.l10n.settingsEPTDescription,
          switchBool: expBool,
          function: (value) {
            WinRegistryService.writeRegistryValue(
              Registry.localMachine,
              r'SOFTWARE\Revision\Revision Tool',
              'Experimental',
              value ? 1 : 0,
            );
            expBool.value = value;
          },
        ),
        CardHighlight(
          label: context.l10n.settingsUpdateLabel,
          icon: msicons.FluentIcons.arrow_clockwise_20_regular,
          child: ValueListenableBuilder(
            valueListenable: _updateTitle,
            builder:
                (context, value, child) => FilledButton(
                  child: Text(_updateTitle.value),
                  onPressed: () async {
                    await _toolUpdateService.fetchData();
                    final currentVersion = _toolUpdateService.getCurrentVersion;
                    final latestVersion = _toolUpdateService.getLatestVersion;
                    final data = _toolUpdateService.data;

                    if (latestVersion > currentVersion) {
                      if (!context.mounted) return;
                      _updateTitle.value = context.l10n.settingsUpdateButton;

                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder:
                            (context) => ContentDialog(
                              title: Text(
                                context.l10n.settingsUpdateButtonAvailable,
                              ),
                              content: Text(
                                "${context.l10n.settingsUpdateButtonAvailablePrompt} ${data["tag_name"]}?",
                              ),
                              actions: [
                                FilledButton(
                                  child: Text(context.l10n.okButton),
                                  onPressed: () async {
                                    _updateTitle.value =
                                        "${context.l10n.settingsUpdatingStatus}...";

                                    context.pop();
                                    await _toolUpdateService
                                        .downloadNewVersion();
                                    await _toolUpdateService.installUpdate();

                                    if (!context.mounted) return;
                                    _updateTitle.value =
                                        context
                                            .l10n
                                            .settingsUpdatingStatusSuccess;
                                  },
                                ),
                                Button(
                                  child: Text(context.l10n.notNowButton),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                      );
                    } else {
                      if (!context.mounted) return;
                      _updateTitle.value =
                          context.l10n.settingsUpdatingStatusNotFound;
                    }
                  },
                ),
          ),
        ),
        CardHighlight(
          icon: msicons.FluentIcons.local_language_20_regular,
          label: context.l10n.settingsLanguageLabel,
          description: context.l10n.settingsLanguageDescription,
          child: ComboBox(
            value: appLanguage,
            onChanged: (value) {
              setState(() {
                appLanguage = value ?? 'en_US';
                WinRegistryService.writeRegistryValue(
                  Registry.localMachine,
                  r'SOFTWARE\Revision\Revision Tool',
                  'Language',
                  appLanguage,
                );
                ref
                    .read(appSettingsNotifierProvider.notifier)
                    .updateLocale(appLanguage);
              });
            },
            items: languageList,
          ),
        ),
      ],
    );
  }
}
