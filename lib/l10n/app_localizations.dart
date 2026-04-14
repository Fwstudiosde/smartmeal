import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'SmartMeal'**
  String get appTitle;

  /// No description provided for @homeNavLabel.
  ///
  /// In de, this message translates to:
  /// **'Home'**
  String get homeNavLabel;

  /// No description provided for @stockNavLabel.
  ///
  /// In de, this message translates to:
  /// **'Vorrat'**
  String get stockNavLabel;

  /// No description provided for @dealsNavLabel.
  ///
  /// In de, this message translates to:
  /// **'Angebote'**
  String get dealsNavLabel;

  /// No description provided for @settingsNavLabel.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsNavLabel;

  /// No description provided for @morningGreeting.
  ///
  /// In de, this message translates to:
  /// **'Guten Morgen'**
  String get morningGreeting;

  /// No description provided for @afternoonGreeting.
  ///
  /// In de, this message translates to:
  /// **'Guten Tag'**
  String get afternoonGreeting;

  /// No description provided for @eveningGreeting.
  ///
  /// In de, this message translates to:
  /// **'Guten Abend'**
  String get eveningGreeting;

  /// No description provided for @welcomeQuestion.
  ///
  /// In de, this message translates to:
  /// **'Was kochst du heute?'**
  String get welcomeQuestion;

  /// No description provided for @fridgeScannerTitle.
  ///
  /// In de, this message translates to:
  /// **'Kühlschrank Scanner'**
  String get fridgeScannerTitle;

  /// No description provided for @fridgeScannerSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Fotografiere deinen Kühlschrank und erhalte passende Rezepte'**
  String get fridgeScannerSubtitle;

  /// No description provided for @dealsFinderTitle.
  ///
  /// In de, this message translates to:
  /// **'Angebots-Finder'**
  String get dealsFinderTitle;

  /// No description provided for @dealsFinderSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Finde günstige Rezepte aus aktuellen Supermarkt-Angeboten'**
  String get dealsFinderSubtitle;

  /// No description provided for @startButton.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get startButton;

  /// No description provided for @thisWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get thisWeek;

  /// No description provided for @recipePlannedSingular.
  ///
  /// In de, this message translates to:
  /// **'Rezept geplant'**
  String get recipePlannedSingular;

  /// No description provided for @recipesPlannedPlural.
  ///
  /// In de, this message translates to:
  /// **'Rezepte geplant'**
  String get recipesPlannedPlural;

  /// No description provided for @savedLabel.
  ///
  /// In de, this message translates to:
  /// **'gespart'**
  String get savedLabel;

  /// No description provided for @mealCookedSingular.
  ///
  /// In de, this message translates to:
  /// **'Gericht gekocht'**
  String get mealCookedSingular;

  /// No description provided for @mealsCookedPlural.
  ///
  /// In de, this message translates to:
  /// **'Gerichte gekocht'**
  String get mealsCookedPlural;

  /// No description provided for @tipsAndTricks.
  ///
  /// In de, this message translates to:
  /// **'Tipps & Tricks'**
  String get tipsAndTricks;

  /// No description provided for @scanningTipTitle.
  ///
  /// In de, this message translates to:
  /// **'Besser Scannen'**
  String get scanningTipTitle;

  /// No description provided for @scanningTipDescription.
  ///
  /// In de, this message translates to:
  /// **'Fotografiere deinen Kühlschrank bei gutem Licht für beste Ergebnisse.'**
  String get scanningTipDescription;

  /// No description provided for @shoppingTipTitle.
  ///
  /// In de, this message translates to:
  /// **'Clever Einkaufen'**
  String get shoppingTipTitle;

  /// No description provided for @shoppingTipDescription.
  ///
  /// In de, this message translates to:
  /// **'Checke die Angebote bevor du einkaufen gehst und plane deine Mahlzeiten.'**
  String get shoppingTipDescription;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @generalSection.
  ///
  /// In de, this message translates to:
  /// **'Allgemein'**
  String get generalSection;

  /// No description provided for @notificationsSection.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notificationsSection;

  /// No description provided for @supermarketsSection.
  ///
  /// In de, this message translates to:
  /// **'Supermärkte'**
  String get supermarketsSection;

  /// No description provided for @aboutSection.
  ///
  /// In de, this message translates to:
  /// **'Über die App'**
  String get aboutSection;

  /// No description provided for @accountSection.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get accountSection;

  /// No description provided for @editProfileTitle.
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get editProfileTitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get profileNameLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Anzeigename (Community)'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. KochProfi92'**
  String get displayNameHint;

  /// No description provided for @displayNameHelper.
  ///
  /// In de, this message translates to:
  /// **'Wird bei deinen Community-Rezepten angezeigt'**
  String get displayNameHelper;

  /// No description provided for @emailLabel.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get emailLabel;

  /// No description provided for @cancelButton.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get saveButton;

  /// No description provided for @profileUpdated.
  ///
  /// In de, this message translates to:
  /// **'Profil aktualisiert'**
  String get profileUpdated;

  /// No description provided for @darkModeTitle.
  ///
  /// In de, this message translates to:
  /// **'Dunkler Modus'**
  String get darkModeTitle;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Augenschonende Darstellung'**
  String get darkModeSubtitle;

  /// No description provided for @metricUnitsTitle.
  ///
  /// In de, this message translates to:
  /// **'Metrische Einheiten'**
  String get metricUnitsTitle;

  /// No description provided for @metricUnitsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Gramm, Liter, etc.'**
  String get metricUnitsSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get languageTitle;

  /// No description provided for @clearCacheTitle.
  ///
  /// In de, this message translates to:
  /// **'Cache leeren'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Zwischengespeicherte Daten löschen'**
  String get clearCacheSubtitle;

  /// No description provided for @cameraOption.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get cameraOption;

  /// No description provided for @galleryOption.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get galleryOption;

  /// No description provided for @languageDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprache wählen'**
  String get languageDialogTitle;

  /// No description provided for @comingSoonLabel.
  ///
  /// In de, this message translates to:
  /// **'Bald'**
  String get comingSoonLabel;

  /// No description provided for @clearCacheDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Cache leeren'**
  String get clearCacheDialogTitle;

  /// No description provided for @clearCacheDialogMessage.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du alle zwischengespeicherten Daten löschen? Dies kann die App-Leistung vorübergehend beeinträchtigen.'**
  String get clearCacheDialogMessage;

  /// No description provided for @clearButton.
  ///
  /// In de, this message translates to:
  /// **'Leeren'**
  String get clearButton;

  /// No description provided for @cacheClearedMessage.
  ///
  /// In de, this message translates to:
  /// **'Cache wurde geleert'**
  String get cacheClearedMessage;

  /// No description provided for @aboutSmartmeal.
  ///
  /// In de, this message translates to:
  /// **'Über SmartMeal'**
  String get aboutSmartmeal;

  /// No description provided for @versionLabel.
  ///
  /// In de, this message translates to:
  /// **'Version 1.0.0'**
  String get versionLabel;

  /// No description provided for @privacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get privacyTitle;

  /// No description provided for @privacySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung lesen'**
  String get privacySubtitle;

  /// No description provided for @termsTitle.
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen'**
  String get termsTitle;

  /// No description provided for @termsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'AGB lesen'**
  String get termsSubtitle;

  /// No description provided for @helpTitle.
  ///
  /// In de, this message translates to:
  /// **'Hilfe & Support'**
  String get helpTitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In de, this message translates to:
  /// **'FAQ und Kontakt'**
  String get helpSubtitle;

  /// No description provided for @reviewTitle.
  ///
  /// In de, this message translates to:
  /// **'App bewerten'**
  String get reviewTitle;

  /// No description provided for @reviewSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Im App Store bewerten'**
  String get reviewSubtitle;

  /// No description provided for @preferredSupermarkets.
  ///
  /// In de, this message translates to:
  /// **'Bevorzugte Supermärkte'**
  String get preferredSupermarkets;

  /// No description provided for @allSupermarketsActive.
  ///
  /// In de, this message translates to:
  /// **'Alle Supermärkte aktiv'**
  String get allSupermarketsActive;

  /// No description provided for @appDescription.
  ///
  /// In de, this message translates to:
  /// **'Dein intelligenter Küchenassistent.\nScanne deinen Kühlschrank, finde Rezepte und spare mit Angeboten.'**
  String get appDescription;

  /// No description provided for @copyright.
  ///
  /// In de, this message translates to:
  /// **'© 2024 SmartMeal'**
  String get copyright;

  /// No description provided for @closeButton.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get closeButton;

  /// No description provided for @logoutTitle.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get logoutTitle;

  /// No description provided for @logoutSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Von diesem Gerät abmelden'**
  String get logoutSubtitle;

  /// No description provided for @expiryRemindersTitle.
  ///
  /// In de, this message translates to:
  /// **'Ablauf-Erinnerungen'**
  String get expiryRemindersTitle;

  /// No description provided for @expiryRemindersSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigung bei ablaufenden Produkten'**
  String get expiryRemindersSubtitle;

  /// No description provided for @pushNotificationsTitle.
  ///
  /// In de, this message translates to:
  /// **'Push-Benachrichtigungen'**
  String get pushNotificationsTitle;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Über neue Angebote informiert werden'**
  String get pushNotificationsSubtitle;

  /// No description provided for @dealAlertsTitle.
  ///
  /// In de, this message translates to:
  /// **'Angebots-Benachrichtigungen'**
  String get dealAlertsTitle;

  /// No description provided for @dealAlertsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Bei passenden Angeboten benachrichtigen'**
  String get dealAlertsSubtitle;

  /// No description provided for @dealsTitle1.
  ///
  /// In de, this message translates to:
  /// **'Angebots-'**
  String get dealsTitle1;

  /// No description provided for @dealsTitle2.
  ///
  /// In de, this message translates to:
  /// **'Finder'**
  String get dealsTitle2;

  /// No description provided for @dealsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Finde die besten Angebote und spare bei deinen Rezepten.'**
  String get dealsSubtitle;

  /// No description provided for @selectSupermarkets.
  ///
  /// In de, this message translates to:
  /// **'Supermärkte auswählen'**
  String get selectSupermarkets;

  /// No description provided for @loadingDeals.
  ///
  /// In de, this message translates to:
  /// **'Angebote werden geladen...'**
  String get loadingDeals;

  /// No description provided for @noDealsFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Angebote gefunden'**
  String get noDealsFound;

  /// No description provided for @noDealsMessage.
  ///
  /// In de, this message translates to:
  /// **'Wähle andere Supermärkte aus oder versuche es später erneut.'**
  String get noDealsMessage;

  /// No description provided for @errorLoading.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden'**
  String get errorLoading;

  /// No description provided for @retryButton.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retryButton;

  /// No description provided for @creatingRecipes.
  ///
  /// In de, this message translates to:
  /// **'Spar-Rezepte werden erstellt...'**
  String get creatingRecipes;

  /// No description provided for @findRecipesButton.
  ///
  /// In de, this message translates to:
  /// **'Spar-Rezepte finden'**
  String get findRecipesButton;

  /// No description provided for @dealsLabel.
  ///
  /// In de, this message translates to:
  /// **'Angebote'**
  String get dealsLabel;

  /// No description provided for @savingsRecipesTitle.
  ///
  /// In de, this message translates to:
  /// **'Spar-Rezepte'**
  String get savingsRecipesTitle;

  /// No description provided for @allRecipesTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Rezepte'**
  String get allRecipesTitle;

  /// No description provided for @searchRecipesHint.
  ///
  /// In de, this message translates to:
  /// **'Rezepte suchen...'**
  String get searchRecipesHint;

  /// No description provided for @findingRecipes.
  ///
  /// In de, this message translates to:
  /// **'Finde günstige Rezepte...'**
  String get findingRecipes;

  /// No description provided for @analyzingOffers.
  ///
  /// In de, this message translates to:
  /// **'Analysiere Angebote für beste Ersparnisse'**
  String get analyzingOffers;

  /// No description provided for @noSavingsRecipes.
  ///
  /// In de, this message translates to:
  /// **'Keine Spar-Rezepte gefunden'**
  String get noSavingsRecipes;

  /// No description provided for @noRecipesFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Rezepte gefunden'**
  String get noRecipesFound;

  /// No description provided for @selectSupermarketsMessage.
  ///
  /// In de, this message translates to:
  /// **'Wähle mehr Supermärkte aus, um passende Rezepte zu finden'**
  String get selectSupermarketsMessage;

  /// No description provided for @noRecipesDatabase.
  ///
  /// In de, this message translates to:
  /// **'Keine Rezepte in der Datenbank'**
  String get noRecipesDatabase;

  /// No description provided for @scanDealsButton.
  ///
  /// In de, this message translates to:
  /// **'Angebote scannen'**
  String get scanDealsButton;

  /// No description provided for @allFilter.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get allFilter;

  /// No description provided for @communityFilter.
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get communityFilter;

  /// No description provided for @ownFilter.
  ///
  /// In de, this message translates to:
  /// **'Eigene'**
  String get ownFilter;

  /// No description provided for @breakfastCategory.
  ///
  /// In de, this message translates to:
  /// **'Frühstück'**
  String get breakfastCategory;

  /// No description provided for @fitnessCategory.
  ///
  /// In de, this message translates to:
  /// **'Fitness'**
  String get fitnessCategory;

  /// No description provided for @quickCategory.
  ///
  /// In de, this message translates to:
  /// **'Schnell'**
  String get quickCategory;

  /// No description provided for @germanCategory.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get germanCategory;

  /// No description provided for @tryDifferentFilter.
  ///
  /// In de, this message translates to:
  /// **'Versuche einen anderen Filter'**
  String get tryDifferentFilter;

  /// No description provided for @displayNamePromptTitle.
  ///
  /// In de, this message translates to:
  /// **'Anzeigename wählen'**
  String get displayNamePromptTitle;

  /// No description provided for @displayNamePromptMessage.
  ///
  /// In de, this message translates to:
  /// **'Dein Name wird bei Community-Rezepten angezeigt.'**
  String get displayNamePromptMessage;

  /// No description provided for @confirmButton.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirmButton;

  /// No description provided for @dealsUsedLabel.
  ///
  /// In de, this message translates to:
  /// **'Angebote genutzt:'**
  String get dealsUsedLabel;

  /// No description provided for @moreDeals.
  ///
  /// In de, this message translates to:
  /// **'weitere Angebote'**
  String get moreDeals;

  /// No description provided for @totalCostLabel.
  ///
  /// In de, this message translates to:
  /// **'Gesamtkosten'**
  String get totalCostLabel;

  /// No description provided for @viewRecipeButton.
  ///
  /// In de, this message translates to:
  /// **'Rezept ansehen'**
  String get viewRecipeButton;

  /// No description provided for @publicLabel.
  ///
  /// In de, this message translates to:
  /// **'Online'**
  String get publicLabel;

  /// No description provided for @privateLabel.
  ///
  /// In de, this message translates to:
  /// **'Privat'**
  String get privateLabel;

  /// No description provided for @createRecipeTitle.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Rezept erstellen'**
  String get createRecipeTitle;

  /// No description provided for @noIngredientsError.
  ///
  /// In de, this message translates to:
  /// **'Bitte füge mindestens eine Zutat hinzu'**
  String get noIngredientsError;

  /// No description provided for @noInstructionsError.
  ///
  /// In de, this message translates to:
  /// **'Bitte füge mindestens einen Schritt hinzu'**
  String get noInstructionsError;

  /// No description provided for @recipePublished.
  ///
  /// In de, this message translates to:
  /// **'Community-Rezept veröffentlicht!'**
  String get recipePublished;

  /// No description provided for @recipeCreated.
  ///
  /// In de, this message translates to:
  /// **'Rezept erfolgreich erstellt!'**
  String get recipeCreated;

  /// No description provided for @recipeCreationError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Erstellen:'**
  String get recipeCreationError;

  /// No description provided for @recipeNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Rezeptname'**
  String get recipeNameLabel;

  /// No description provided for @recipeNameValidation.
  ///
  /// In de, this message translates to:
  /// **'Bitte Rezeptname eingeben'**
  String get recipeNameValidation;

  /// No description provided for @descriptionLabel.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get descriptionLabel;

  /// No description provided for @descriptionValidation.
  ///
  /// In de, this message translates to:
  /// **'Bitte Beschreibung eingeben'**
  String get descriptionValidation;

  /// No description provided for @prepTimeLabel.
  ///
  /// In de, this message translates to:
  /// **'Vorbereitung (Min)'**
  String get prepTimeLabel;

  /// No description provided for @cookingTimeLabel.
  ///
  /// In de, this message translates to:
  /// **'Kochzeit (Min)'**
  String get cookingTimeLabel;

  /// No description provided for @requiredFieldError.
  ///
  /// In de, this message translates to:
  /// **'Erforderlich'**
  String get requiredFieldError;

  /// No description provided for @numberInputError.
  ///
  /// In de, this message translates to:
  /// **'Zahl eingeben'**
  String get numberInputError;

  /// No description provided for @servingsLabel.
  ///
  /// In de, this message translates to:
  /// **'Portionen'**
  String get servingsLabel;

  /// No description provided for @difficultyLabel.
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit'**
  String get difficultyLabel;

  /// No description provided for @easyDifficulty.
  ///
  /// In de, this message translates to:
  /// **'Einfach'**
  String get easyDifficulty;

  /// No description provided for @mediumDifficulty.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get mediumDifficulty;

  /// No description provided for @hardDifficulty.
  ///
  /// In de, this message translates to:
  /// **'Schwer'**
  String get hardDifficulty;

  /// No description provided for @communityRecipeLabel.
  ///
  /// In de, this message translates to:
  /// **'Community-Rezept'**
  String get communityRecipeLabel;

  /// No description provided for @privateRecipeLabel.
  ///
  /// In de, this message translates to:
  /// **'Privates Rezept'**
  String get privateRecipeLabel;

  /// No description provided for @visibleToAll.
  ///
  /// In de, this message translates to:
  /// **'Sichtbar für alle Nutzer'**
  String get visibleToAll;

  /// No description provided for @visibleToMeOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur für dich sichtbar'**
  String get visibleToMeOnly;

  /// No description provided for @ingredientsSection.
  ///
  /// In de, this message translates to:
  /// **'Zutaten'**
  String get ingredientsSection;

  /// No description provided for @ingredientHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Kartoffeln, Mehl, Butter...'**
  String get ingredientHint;

  /// No description provided for @ingredientValidation.
  ///
  /// In de, this message translates to:
  /// **'Bitte Zutat eingeben'**
  String get ingredientValidation;

  /// No description provided for @quantityLabel.
  ///
  /// In de, this message translates to:
  /// **'Menge'**
  String get quantityLabel;

  /// No description provided for @unitLabel.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get unitLabel;

  /// No description provided for @unitPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Wählen'**
  String get unitPlaceholder;

  /// No description provided for @unitGrams.
  ///
  /// In de, this message translates to:
  /// **'Gramm (g)'**
  String get unitGrams;

  /// No description provided for @unitKilograms.
  ///
  /// In de, this message translates to:
  /// **'Kilogramm (kg)'**
  String get unitKilograms;

  /// No description provided for @unitMilliliters.
  ///
  /// In de, this message translates to:
  /// **'Milliliter (ml)'**
  String get unitMilliliters;

  /// No description provided for @unitLiters.
  ///
  /// In de, this message translates to:
  /// **'Liter (l)'**
  String get unitLiters;

  /// No description provided for @unitPieces.
  ///
  /// In de, this message translates to:
  /// **'Stück'**
  String get unitPieces;

  /// No description provided for @unitTablespoon.
  ///
  /// In de, this message translates to:
  /// **'Esslöffel (EL)'**
  String get unitTablespoon;

  /// No description provided for @unitTeaspoon.
  ///
  /// In de, this message translates to:
  /// **'Teelöffel (TL)'**
  String get unitTeaspoon;

  /// No description provided for @unitPinch.
  ///
  /// In de, this message translates to:
  /// **'Prise'**
  String get unitPinch;

  /// No description provided for @unitBunch.
  ///
  /// In de, this message translates to:
  /// **'Bund'**
  String get unitBunch;

  /// No description provided for @unitCloves.
  ///
  /// In de, this message translates to:
  /// **'Zehe(n)'**
  String get unitCloves;

  /// No description provided for @unitSlices.
  ///
  /// In de, this message translates to:
  /// **'Scheibe(n)'**
  String get unitSlices;

  /// No description provided for @unitCups.
  ///
  /// In de, this message translates to:
  /// **'Tasse(n)'**
  String get unitCups;

  /// No description provided for @unitCup.
  ///
  /// In de, this message translates to:
  /// **'Becher'**
  String get unitCup;

  /// No description provided for @unitPackage.
  ///
  /// In de, this message translates to:
  /// **'Packung'**
  String get unitPackage;

  /// No description provided for @unitCans.
  ///
  /// In de, this message translates to:
  /// **'Dose(n)'**
  String get unitCans;

  /// No description provided for @unitBottles.
  ///
  /// In de, this message translates to:
  /// **'Flasche(n)'**
  String get unitBottles;

  /// No description provided for @unitHandful.
  ///
  /// In de, this message translates to:
  /// **'Handvoll'**
  String get unitHandful;

  /// No description provided for @unitLeaves.
  ///
  /// In de, this message translates to:
  /// **'Blatt/Blätter'**
  String get unitLeaves;

  /// No description provided for @unitStalks.
  ///
  /// In de, this message translates to:
  /// **'Stange(n)'**
  String get unitStalks;

  /// No description provided for @unitToTaste.
  ///
  /// In de, this message translates to:
  /// **'nach Geschmack'**
  String get unitToTaste;

  /// No description provided for @noIngredientsAdded.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Zutaten hinzugefügt'**
  String get noIngredientsAdded;

  /// No description provided for @preparationStepsSection.
  ///
  /// In de, this message translates to:
  /// **'Zubereitungsschritte'**
  String get preparationStepsSection;

  /// No description provided for @stepHint.
  ///
  /// In de, this message translates to:
  /// **'Schritt beschreiben...'**
  String get stepHint;

  /// No description provided for @stepValidation.
  ///
  /// In de, this message translates to:
  /// **'Bitte Schritt beschreiben'**
  String get stepValidation;

  /// No description provided for @noStepsAdded.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Schritte hinzugefügt'**
  String get noStepsAdded;

  /// No description provided for @publishButton.
  ///
  /// In de, this message translates to:
  /// **'Community-Rezept veröffentlichen'**
  String get publishButton;

  /// No description provided for @myPantryLabel.
  ///
  /// In de, this message translates to:
  /// **'Meine'**
  String get myPantryLabel;

  /// No description provided for @pantryLabel.
  ///
  /// In de, this message translates to:
  /// **'Speisekammer'**
  String get pantryLabel;

  /// No description provided for @itemsLabel.
  ///
  /// In de, this message translates to:
  /// **'Artikel'**
  String get itemsLabel;

  /// No description provided for @categoriesLabel.
  ///
  /// In de, this message translates to:
  /// **'Kategorien'**
  String get categoriesLabel;

  /// No description provided for @caloriesPer100g.
  ///
  /// In de, this message translates to:
  /// **'kcal/100g'**
  String get caloriesPer100g;

  /// No description provided for @itemAdded.
  ///
  /// In de, this message translates to:
  /// **'hinzugefügt'**
  String get itemAdded;

  /// No description provided for @productNotFound.
  ///
  /// In de, this message translates to:
  /// **'Produkt nicht gefunden'**
  String get productNotFound;

  /// No description provided for @errorPrefix.
  ///
  /// In de, this message translates to:
  /// **'Fehler:'**
  String get errorPrefix;

  /// No description provided for @addProductTitle.
  ///
  /// In de, this message translates to:
  /// **'Produkt hinzufügen'**
  String get addProductTitle;

  /// No description provided for @requiredFieldsNote.
  ///
  /// In de, this message translates to:
  /// **'* Pflichtfelder'**
  String get requiredFieldsNote;

  /// No description provided for @productNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Produktname *'**
  String get productNameLabel;

  /// No description provided for @productNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Vollmilch'**
  String get productNameHint;

  /// No description provided for @packageSizeLabel.
  ///
  /// In de, this message translates to:
  /// **'Packungsgröße *'**
  String get packageSizeLabel;

  /// No description provided for @packageSizeHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. 1L, 500g'**
  String get packageSizeHint;

  /// No description provided for @brandLabel.
  ///
  /// In de, this message translates to:
  /// **'Marke'**
  String get brandLabel;

  /// No description provided for @brandHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Weihenstephan'**
  String get brandHint;

  /// No description provided for @categoryLabel.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get categoryLabel;

  /// No description provided for @expiryDateLabel.
  ///
  /// In de, this message translates to:
  /// **'Mindesthaltbar bis'**
  String get expiryDateLabel;

  /// No description provided for @dateSelectPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Datum wählen'**
  String get dateSelectPlaceholder;

  /// No description provided for @nutritionSection.
  ///
  /// In de, this message translates to:
  /// **'Nährwerte pro 100g'**
  String get nutritionSection;

  /// No description provided for @caloriesLabel.
  ///
  /// In de, this message translates to:
  /// **'Kalorien'**
  String get caloriesLabel;

  /// No description provided for @caloriesUnit.
  ///
  /// In de, this message translates to:
  /// **'kcal'**
  String get caloriesUnit;

  /// No description provided for @proteinLabel.
  ///
  /// In de, this message translates to:
  /// **'Eiweiß'**
  String get proteinLabel;

  /// No description provided for @gramsUnit.
  ///
  /// In de, this message translates to:
  /// **'g'**
  String get gramsUnit;

  /// No description provided for @carbsLabel.
  ///
  /// In de, this message translates to:
  /// **'Kohlenhydrate'**
  String get carbsLabel;

  /// No description provided for @fatLabel.
  ///
  /// In de, this message translates to:
  /// **'Fett'**
  String get fatLabel;

  /// No description provided for @fiberLabel.
  ///
  /// In de, this message translates to:
  /// **'Ballaststoffe'**
  String get fiberLabel;

  /// No description provided for @addProductValidation.
  ///
  /// In de, this message translates to:
  /// **'Bitte Name, Packungsgröße und Menge ausfüllen'**
  String get addProductValidation;

  /// No description provided for @scanButton.
  ///
  /// In de, this message translates to:
  /// **'Scannen'**
  String get scanButton;

  /// No description provided for @manualButton.
  ///
  /// In de, this message translates to:
  /// **'Manuell'**
  String get manualButton;

  /// No description provided for @barcodeHint.
  ///
  /// In de, this message translates to:
  /// **'Barcode in den Rahmen halten'**
  String get barcodeHint;

  /// No description provided for @emptyPantryTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Speisekammer ist leer'**
  String get emptyPantryTitle;

  /// No description provided for @emptyPantryMessage.
  ///
  /// In de, this message translates to:
  /// **'Scanne einen Barcode oder mache ein Foto\num Produkte hinzuzufügen.'**
  String get emptyPantryMessage;

  /// No description provided for @dairyCategory.
  ///
  /// In de, this message translates to:
  /// **'Milchprodukte'**
  String get dairyCategory;

  /// No description provided for @meatCategory.
  ///
  /// In de, this message translates to:
  /// **'Fleisch'**
  String get meatCategory;

  /// No description provided for @fishCategory.
  ///
  /// In de, this message translates to:
  /// **'Fisch'**
  String get fishCategory;

  /// No description provided for @vegetablesCategory.
  ///
  /// In de, this message translates to:
  /// **'Gemüse'**
  String get vegetablesCategory;

  /// No description provided for @fruitsCategory.
  ///
  /// In de, this message translates to:
  /// **'Obst'**
  String get fruitsCategory;

  /// No description provided for @grainsCategory.
  ///
  /// In de, this message translates to:
  /// **'Getreide'**
  String get grainsCategory;

  /// No description provided for @beveragesCategory.
  ///
  /// In de, this message translates to:
  /// **'Getränke'**
  String get beveragesCategory;

  /// No description provided for @snacksCategory.
  ///
  /// In de, this message translates to:
  /// **'Snacks'**
  String get snacksCategory;

  /// No description provided for @frozenCategory.
  ///
  /// In de, this message translates to:
  /// **'Tiefkühl'**
  String get frozenCategory;

  /// No description provided for @otherCategory.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get otherCategory;

  /// No description provided for @yourIngredients.
  ///
  /// In de, this message translates to:
  /// **'Deine Zutaten'**
  String get yourIngredients;

  /// No description provided for @ingredientsDetected.
  ///
  /// In de, this message translates to:
  /// **'Zutaten erkannt'**
  String get ingredientsDetected;

  /// No description provided for @addIngredientHint.
  ///
  /// In de, this message translates to:
  /// **'Zutat hinzufügen...'**
  String get addIngredientHint;

  /// No description provided for @noIngredients.
  ///
  /// In de, this message translates to:
  /// **'Keine Zutaten'**
  String get noIngredients;

  /// No description provided for @addIngredientsMessage.
  ///
  /// In de, this message translates to:
  /// **'Füge Zutaten hinzu oder scanne deinen Kühlschrank'**
  String get addIngredientsMessage;

  /// No description provided for @generatingRecipes.
  ///
  /// In de, this message translates to:
  /// **'Rezepte werden generiert...'**
  String get generatingRecipes;

  /// No description provided for @generateRecipesButton.
  ///
  /// In de, this message translates to:
  /// **'Rezepte generieren'**
  String get generateRecipesButton;

  /// No description provided for @noIngredientsToGenerate.
  ///
  /// In de, this message translates to:
  /// **'Bitte füge mindestens eine Zutat hinzu'**
  String get noIngredientsToGenerate;

  /// No description provided for @recipeSuggestions.
  ///
  /// In de, this message translates to:
  /// **'Rezept-Vorschläge'**
  String get recipeSuggestions;

  /// No description provided for @recipesFound.
  ///
  /// In de, this message translates to:
  /// **'Rezepte gefunden'**
  String get recipesFound;

  /// No description provided for @quickFilter.
  ///
  /// In de, this message translates to:
  /// **'Schnell'**
  String get quickFilter;

  /// No description provided for @easyFilter.
  ///
  /// In de, this message translates to:
  /// **'Einfach'**
  String get easyFilter;

  /// No description provided for @bestMatchFilter.
  ///
  /// In de, this message translates to:
  /// **'Beste Übereinstimmung'**
  String get bestMatchFilter;

  /// No description provided for @loadingRecipes.
  ///
  /// In de, this message translates to:
  /// **'Rezepte werden geladen...'**
  String get loadingRecipes;

  /// No description provided for @tryDifferentFilterMessage.
  ///
  /// In de, this message translates to:
  /// **'Versuche einen anderen Filter oder füge mehr Zutaten hinzu.'**
  String get tryDifferentFilterMessage;

  /// No description provided for @aiRecognitionSubtitle.
  ///
  /// In de, this message translates to:
  /// **'KI erkennt deine Zutaten'**
  String get aiRecognitionSubtitle;

  /// No description provided for @photographFridgeTitle.
  ///
  /// In de, this message translates to:
  /// **'Fotografiere deinen Kühlschrank'**
  String get photographFridgeTitle;

  /// No description provided for @aiDescription.
  ///
  /// In de, this message translates to:
  /// **'Unsere KI erkennt automatisch alle\nZutaten und findet passende Rezepte.'**
  String get aiDescription;

  /// No description provided for @analyzingImage.
  ///
  /// In de, this message translates to:
  /// **'KI analysiert dein Bild...'**
  String get analyzingImage;

  /// No description provided for @recognizingIngredients.
  ///
  /// In de, this message translates to:
  /// **'Zutaten werden erkannt'**
  String get recognizingIngredients;

  /// No description provided for @takePhotoButton.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get takePhotoButton;

  /// No description provided for @mealPlanTitle.
  ///
  /// In de, this message translates to:
  /// **'Wochenplan'**
  String get mealPlanTitle;

  /// No description provided for @clearWeekTooltip.
  ///
  /// In de, this message translates to:
  /// **'Woche leeren'**
  String get clearWeekTooltip;

  /// No description provided for @weekOverviewTab.
  ///
  /// In de, this message translates to:
  /// **'Wochenübersicht'**
  String get weekOverviewTab;

  /// No description provided for @shoppingListTab.
  ///
  /// In de, this message translates to:
  /// **'Einkaufsliste'**
  String get shoppingListTab;

  /// No description provided for @emptyPlanTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Wochenplan ist leer'**
  String get emptyPlanTitle;

  /// No description provided for @emptyPlanMessage.
  ///
  /// In de, this message translates to:
  /// **'Füge Rezepte aus den Angeboten hinzu, um deinen Wochenplan zu erstellen'**
  String get emptyPlanMessage;

  /// No description provided for @discoverDealsButton.
  ///
  /// In de, this message translates to:
  /// **'Angebote entdecken'**
  String get discoverDealsButton;

  /// No description provided for @noMealsPlanned.
  ///
  /// In de, this message translates to:
  /// **'Keine Mahlzeiten geplant'**
  String get noMealsPlanned;

  /// No description provided for @todayLabel.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get todayLabel;

  /// No description provided for @savingsLabel.
  ///
  /// In de, this message translates to:
  /// **'Ersparnis'**
  String get savingsLabel;

  /// No description provided for @itemsPurchasedLabel.
  ///
  /// In de, this message translates to:
  /// **'Artikel gekauft'**
  String get itemsPurchasedLabel;

  /// No description provided for @addCustomItemHint.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Produkt hinzufügen...'**
  String get addCustomItemHint;

  /// No description provided for @manuallyAddedSection.
  ///
  /// In de, this message translates to:
  /// **'Manuell hinzugefügt'**
  String get manuallyAddedSection;

  /// No description provided for @appTagline.
  ///
  /// In de, this message translates to:
  /// **'Deine smarte Rezept-App mit Kühlschrank-Scanner und Deal-Finder'**
  String get appTagline;

  /// No description provided for @nameOptionalLabel.
  ///
  /// In de, this message translates to:
  /// **'Name (optional)'**
  String get nameOptionalLabel;

  /// No description provided for @emailRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte E-Mail eingeben'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte gültige E-Mail eingeben'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get passwordLabel;

  /// No description provided for @passwordRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte Passwort eingeben'**
  String get passwordRequired;

  /// No description provided for @passwordLengthError.
  ///
  /// In de, this message translates to:
  /// **'Passwort muss mindestens 6 Zeichen lang sein'**
  String get passwordLengthError;

  /// No description provided for @loginButton.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get registerButton;

  /// No description provided for @noAccountMessage.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Konto? Registrieren'**
  String get noAccountMessage;

  /// No description provided for @hasAccountMessage.
  ///
  /// In de, this message translates to:
  /// **'Schon ein Konto? Anmelden'**
  String get hasAccountMessage;

  /// No description provided for @orDivider.
  ///
  /// In de, this message translates to:
  /// **'oder'**
  String get orDivider;

  /// No description provided for @appleSignIn.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple anmelden'**
  String get appleSignIn;

  /// No description provided for @termsAgreement.
  ///
  /// In de, this message translates to:
  /// **'Mit der Anmeldung stimmst du unseren Nutzungsbedingungen und Datenschutzrichtlinien zu.'**
  String get termsAgreement;

  /// No description provided for @myStockTitle.
  ///
  /// In de, this message translates to:
  /// **'Mein Vorrat'**
  String get myStockTitle;

  /// No description provided for @productsLabel.
  ///
  /// In de, this message translates to:
  /// **'Produkte,'**
  String get productsLabel;

  /// No description provided for @emptyStockTitle.
  ///
  /// In de, this message translates to:
  /// **'Vorrat ist leer'**
  String get emptyStockTitle;

  /// No description provided for @emptyStockMessage.
  ///
  /// In de, this message translates to:
  /// **'Scanne Produkte mit dem Barcode-Scanner um deinen Vorrat zu füllen.'**
  String get emptyStockMessage;

  /// No description provided for @communityScreenTitle.
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get communityScreenTitle;

  /// No description provided for @communitySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Rezepte von der Community'**
  String get communitySubtitle;

  /// No description provided for @noPublicRecipes.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Community-Rezepte'**
  String get noPublicRecipes;

  /// No description provided for @beFirstToShare.
  ///
  /// In de, this message translates to:
  /// **'Sei der Erste, der ein Rezept teilt!'**
  String get beFirstToShare;

  /// No description provided for @likesCount.
  ///
  /// In de, this message translates to:
  /// **'Likes'**
  String get likesCount;

  /// No description provided for @sharedBy.
  ///
  /// In de, this message translates to:
  /// **'Geteilt von'**
  String get sharedBy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
