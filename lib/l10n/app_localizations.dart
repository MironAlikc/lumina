import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

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
    Locale('en'),
    Locale('ru'),
    Locale('uk')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lumina'**
  String get appName;

  /// No description provided for @pureBalance.
  ///
  /// In en, this message translates to:
  /// **'Net balance'**
  String get pureBalance;

  /// No description provided for @limit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limit;

  /// No description provided for @overLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit exceeded'**
  String get overLimit;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet — add your first one'**
  String get noTransactionsYet;

  /// No description provided for @noExpensesForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No transactions for this period'**
  String get noExpensesForPeriod;

  /// No description provided for @noExpensesForMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month yet'**
  String get noExpensesForMonth;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @expenseFilter.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenseFilter;

  /// No description provided for @incomeFilter.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeFilter;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile settings'**
  String get settingsTitle;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My wallet'**
  String get myWallet;

  /// No description provided for @localProfile.
  ///
  /// In en, this message translates to:
  /// **'Lumina local profile'**
  String get localProfile;

  /// No description provided for @myAccounts.
  ///
  /// In en, this message translates to:
  /// **'My accounts'**
  String get myAccounts;

  /// No description provided for @budgetManagement.
  ///
  /// In en, this message translates to:
  /// **'Budget management'**
  String get budgetManagement;

  /// No description provided for @monthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get monthlyLimit;

  /// No description provided for @monthlyLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly expense limit to control your budget'**
  String get monthlyLimitLabel;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appSection;

  /// No description provided for @categoryBudgets.
  ///
  /// In en, this message translates to:
  /// **'Category budgets'**
  String get categoryBudgets;

  /// No description provided for @goalsAndSavings.
  ///
  /// In en, this message translates to:
  /// **'Goals & savings'**
  String get goalsAndSavings;

  /// No description provided for @recurringPayments.
  ///
  /// In en, this message translates to:
  /// **'Recurring payments'**
  String get recurringPayments;

  /// No description provided for @exportToExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcel;

  /// No description provided for @interfaceCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get interfaceCurrency;

  /// No description provided for @interfaceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get interfaceLanguage;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Transaction date'**
  String get transactionDate;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note…'**
  String get addNote;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noRecurringPayments.
  ///
  /// In en, this message translates to:
  /// **'No recurring payments.\nTap the button below to add one.'**
  String get noRecurringPayments;

  /// No description provided for @addTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add template'**
  String get addTemplate;

  /// No description provided for @budgetPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get budgetPeriod;

  /// No description provided for @noLimitsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No limits set for this month yet.'**
  String get noLimitsThisMonth;

  /// No description provided for @setCategoryLimit.
  ///
  /// In en, this message translates to:
  /// **'Set a category limit'**
  String get setCategoryLimit;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get chooseCategory;

  /// No description provided for @saveLimit.
  ///
  /// In en, this message translates to:
  /// **'Save limit'**
  String get saveLimit;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops, something went wrong…'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @categoryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists'**
  String get categoryAlreadyExists;

  /// No description provided for @categoryType.
  ///
  /// In en, this message translates to:
  /// **'Category type'**
  String get categoryType;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @incomeType.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeType;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food & drinks'**
  String get catFood;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get catHousing;

  /// No description provided for @catIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get catIncome;

  /// No description provided for @catSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get catSalary;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @defaultTransactionName.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get defaultTransactionName;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get amountRequired;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @monthlyBudgets.
  ///
  /// In en, this message translates to:
  /// **'Monthly budgets'**
  String get monthlyBudgets;

  /// No description provided for @establishedLimits.
  ///
  /// In en, this message translates to:
  /// **'Set limits'**
  String get establishedLimits;

  /// No description provided for @addLimit.
  ///
  /// In en, this message translates to:
  /// **'Add limit'**
  String get addLimit;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get selectLanguage;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose currency'**
  String get selectCurrency;

  /// No description provided for @limitNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get limitNotSet;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export saved'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export'**
  String get exportFailed;

  /// No description provided for @currencyUah.
  ///
  /// In en, this message translates to:
  /// **'Hryvnia'**
  String get currencyUah;

  /// No description provided for @currencyUsd.
  ///
  /// In en, this message translates to:
  /// **'US dollar'**
  String get currencyUsd;

  /// No description provided for @currencyEur.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currencyEur;

  /// No description provided for @insightNoData.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month.'**
  String get insightNoData;

  /// No description provided for @insightTopSpend.
  ///
  /// In en, this message translates to:
  /// **'🔥 You spend the most on «{category}» ({percent}% of expenses).'**
  String insightTopSpend(String category, String percent);

  /// No description provided for @analyticsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t calculate analytics.'**
  String get analyticsError;

  /// No description provided for @analyticsCategoriesTab.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get analyticsCategoriesTab;

  /// No description provided for @analyticsTrendTab.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get analyticsTrendTab;

  /// No description provided for @tapToViewTransactions.
  ///
  /// In en, this message translates to:
  /// **'Tap to view transactions'**
  String get tapToViewTransactions;

  /// No description provided for @moreThanLastMonth.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% vs last month'**
  String moreThanLastMonth(String percent);

  /// No description provided for @lessThanLastMonth.
  ///
  /// In en, this message translates to:
  /// **'-{percent}% vs last month'**
  String lessThanLastMonth(String percent);

  /// No description provided for @topTransactions.
  ///
  /// In en, this message translates to:
  /// **'Top transactions'**
  String get topTransactions;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals & savings'**
  String get goalsTitle;

  /// No description provided for @goalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active goals yet.\nCreate a jar to start saving.'**
  String get goalsEmpty;

  /// No description provided for @goalsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {amount}'**
  String goalsSaved(String amount);

  /// No description provided for @goalsTarget.
  ///
  /// In en, this message translates to:
  /// **'Goal: {amount}'**
  String goalsTarget(String amount);

  /// No description provided for @goalsTopUp.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get goalsTopUp;

  /// No description provided for @goalsNew.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalsNew;

  /// No description provided for @goalsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a savings jar'**
  String get goalsCreateTitle;

  /// No description provided for @goalsNameHint.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalsNameHint;

  /// No description provided for @goalsAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Target amount ({symbol})'**
  String goalsAmountHint(String symbol);

  /// No description provided for @goalsIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get goalsIconLabel;

  /// No description provided for @goalsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get goalsCreate;

  /// No description provided for @goalsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get goalsCancel;

  /// No description provided for @goalsDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to «{title}»'**
  String goalsDepositTitle(String title);

  /// No description provided for @goalsDepositAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol})'**
  String goalsDepositAmount(String symbol);

  /// No description provided for @goalsDeposit.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get goalsDeposit;

  /// No description provided for @goalsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal?'**
  String get goalsDeleteTitle;

  /// No description provided for @goalsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete «{title}» and its progress?'**
  String goalsDeleteConfirm(String title);

  /// No description provided for @goalsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get goalsDelete;

  /// No description provided for @exportColId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get exportColId;

  /// No description provided for @exportColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportColDate;

  /// No description provided for @exportColName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get exportColName;

  /// No description provided for @exportColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get exportColCategory;

  /// No description provided for @exportColAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get exportColAmount;

  /// No description provided for @exportColType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get exportColType;

  /// No description provided for @exportNoCategory.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get exportNoCategory;

  /// No description provided for @exportShareText.
  ///
  /// In en, this message translates to:
  /// **'Lumina report for {month}.{year}'**
  String exportShareText(String month, String year);

  /// No description provided for @matrixIncomeTotal.
  ///
  /// In en, this message translates to:
  /// **'Income total'**
  String get matrixIncomeTotal;

  /// No description provided for @matrixExpenseTotal.
  ///
  /// In en, this message translates to:
  /// **'Expense total'**
  String get matrixExpenseTotal;

  /// No description provided for @matrixNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get matrixNet;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceipt;

  /// No description provided for @scanFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanFromCamera;

  /// No description provided for @scanFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get scanFromGallery;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan fiscal QR'**
  String get scanQrCode;

  /// No description provided for @scanReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get scanReceiptTitle;

  /// No description provided for @confirmReceipt.
  ///
  /// In en, this message translates to:
  /// **'Add to history'**
  String get confirmReceipt;

  /// No description provided for @merchantHint.
  ///
  /// In en, this message translates to:
  /// **'Store or note'**
  String get merchantHint;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the receipt. Try a clearer photo.'**
  String get scanFailed;

  /// No description provided for @scanNothingFound.
  ///
  /// In en, this message translates to:
  /// **'No amount found. Enter it manually.'**
  String get scanNothingFound;

  /// No description provided for @receiptLines.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get receiptLines;

  /// No description provided for @permissionCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required to scan receipts'**
  String get permissionCameraDenied;

  /// No description provided for @scanningReceipt.
  ///
  /// In en, this message translates to:
  /// **'Reading receipt…'**
  String get scanningReceipt;

  /// No description provided for @scanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Receipt recognition isn\'t available on this device'**
  String get scanUnavailable;

  /// No description provided for @qrNotFiscal.
  ///
  /// In en, this message translates to:
  /// **'This QR code isn\'t a supported fiscal receipt'**
  String get qrNotFiscal;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetails;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @accountsTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get accountsTotalBalance;

  /// No description provided for @accountsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsSectionTitle;

  /// No description provided for @noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet.\nTap + to add one.'**
  String get noAccounts;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @accountNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get accountNameRequired;

  /// No description provided for @accountBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get accountBalance;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @accountInUse.
  ///
  /// In en, this message translates to:
  /// **'This account has transactions and can\'t be deleted'**
  String get accountInUse;

  /// No description provided for @accountSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the account'**
  String get accountSaveFailed;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete «{name}»?'**
  String deleteAccountConfirm(String name);

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @targetAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination account'**
  String get targetAccountLabel;

  /// No description provided for @createAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Create an account first'**
  String get createAccountFirst;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get saveFailed;

  /// No description provided for @budgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String budgetRemaining(String amount);

  /// No description provided for @budgetOver.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String budgetOver(String amount);

  /// No description provided for @spentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent this month: {amount}'**
  String spentThisMonth(String amount);

  /// No description provided for @budgetsSummary.
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {limit}'**
  String budgetsSummary(String spent, String limit);

  /// No description provided for @copyFromPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Copy limits from previous month'**
  String get copyFromPreviousMonth;

  /// No description provided for @limitsCopied.
  ///
  /// In en, this message translates to:
  /// **'Limits copied'**
  String get limitsCopied;

  /// No description provided for @nothingToCopy.
  ///
  /// In en, this message translates to:
  /// **'No new limits to copy'**
  String get nothingToCopy;

  /// No description provided for @limitDeleted.
  ///
  /// In en, this message translates to:
  /// **'Limit deleted'**
  String get limitDeleted;

  /// No description provided for @noExpenseCategories.
  ///
  /// In en, this message translates to:
  /// **'No expense categories yet'**
  String get noExpenseCategories;

  /// No description provided for @currencyChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Amounts are not converted: only the currency symbol changes.'**
  String get currencyChangeNote;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get search;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask for Face ID, fingerprint or device passcode when opening the app'**
  String get appLockSubtitle;

  /// No description provided for @appLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Set up a screen lock or biometrics on your device first'**
  String get appLockUnavailable;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Lumina'**
  String get unlockReason;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @editRecurring.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring payment'**
  String get editRecurring;

  /// No description provided for @recurringDeleted.
  ///
  /// In en, this message translates to:
  /// **'Recurring payment deleted'**
  String get recurringDeleted;

  /// No description provided for @recurringShortMonthNote.
  ///
  /// In en, this message translates to:
  /// **'In shorter months it is charged on the last day'**
  String get recurringShortMonthNote;

  /// No description provided for @recurringMonthlyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Monthly expenses: {amount}'**
  String recurringMonthlyExpenses(String amount);

  /// No description provided for @recurringMonthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly income: {amount}'**
  String recurringMonthlyIncome(String amount);
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
      <String>['en', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
