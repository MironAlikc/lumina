// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lumina';

  @override
  String get pureBalance => 'Net balance';

  @override
  String get limit => 'Limit';

  @override
  String get overLimit => 'Monthly limit exceeded';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get history => 'History';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get seeAll => 'See all';

  @override
  String get noTransactionsYet => 'No transactions yet — add your first one';

  @override
  String get noExpensesForPeriod => 'No transactions for this period';

  @override
  String get noExpensesForMonth => 'No transactions this month yet';

  @override
  String get total => 'Total';

  @override
  String get day => 'Day';

  @override
  String get allFilter => 'All';

  @override
  String get expenseFilter => 'Expenses';

  @override
  String get incomeFilter => 'Income';

  @override
  String get settingsTitle => 'Profile settings';

  @override
  String get myWallet => 'My wallet';

  @override
  String get localProfile => 'Lumina local profile';

  @override
  String get budgetManagement => 'Budget management';

  @override
  String get monthlyLimit => 'Monthly limit';

  @override
  String get appSection => 'App';

  @override
  String get categoryBudgets => 'Category budgets';

  @override
  String get goalsAndSavings => 'Goals & savings';

  @override
  String get recurringPayments => 'Recurring payments';

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String get interfaceCurrency => 'Currency';

  @override
  String get interfaceLanguage => 'Language';

  @override
  String get transactionDate => 'Transaction date';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get confirm => 'Confirm';

  @override
  String get addNote => 'Add a note…';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get noRecurringPayments =>
      'No recurring payments.\nTap the button below to add one.';

  @override
  String get addTemplate => 'Add template';

  @override
  String get budgetPeriod => 'Period';

  @override
  String get noLimitsThisMonth => 'No limits set for this month yet.';

  @override
  String get setCategoryLimit => 'Set a category limit';

  @override
  String get chooseCategory => 'Choose category';

  @override
  String get monthlyLimitLabel => 'Monthly limit';

  @override
  String get saveLimit => 'Save limit';

  @override
  String get change => 'Change';

  @override
  String get somethingWentWrong => 'Oops, something went wrong…';

  @override
  String get tryAgain => 'Try again';

  @override
  String get newCategory => 'New category';

  @override
  String get create => 'Create';

  @override
  String get categoryAlreadyExists =>
      'A category with this name already exists';

  @override
  String get categoryType => 'Category type';

  @override
  String get expense => 'Expense';

  @override
  String get incomeType => 'Income';

  @override
  String get catFood => 'Food & drinks';

  @override
  String get catTransport => 'Transport';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catHousing => 'Housing';

  @override
  String get catIncome => 'Income';

  @override
  String get catSalary => 'Salary';

  @override
  String get otherCategory => 'Other';

  @override
  String get defaultTransactionName => 'Transaction';

  @override
  String get amountRequired => 'Enter an amount greater than zero';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get monthlyBudgets => 'Monthly budgets';

  @override
  String get establishedLimits => 'Set limits';

  @override
  String get addLimit => 'Add limit';

  @override
  String get selectLanguage => 'Choose language';

  @override
  String get selectCurrency => 'Choose currency';

  @override
  String get limitNotSet => 'Not set';

  @override
  String get exportSuccess => 'Export saved';

  @override
  String get exportFailed => 'Couldn\'t export';

  @override
  String get currencyUah => 'Hryvnia';

  @override
  String get currencyUsd => 'US dollar';

  @override
  String get currencyEur => 'Euro';

  @override
  String get insightNoData => 'No expenses this month.';

  @override
  String insightTopSpend(String category, String percent) {
    return '🔥 You spend the most on \"$category\" ($percent% of expenses).';
  }

  @override
  String get analyticsError => 'Couldn\'t calculate analytics.';

  @override
  String get goalsTitle => 'Goals & savings';

  @override
  String get goalsEmpty =>
      'No active goals yet.\nCreate a jar to start saving.';

  @override
  String goalsSaved(String amount) {
    return 'Saved: $amount';
  }

  @override
  String goalsTarget(String amount) {
    return 'Goal: $amount';
  }

  @override
  String get goalsTopUp => 'Add money';

  @override
  String get goalsNew => 'New goal';

  @override
  String get goalsCreateTitle => 'Create a savings jar';

  @override
  String get goalsNameHint => 'Goal name';

  @override
  String goalsAmountHint(String symbol) {
    return 'Target amount ($symbol)';
  }

  @override
  String get goalsIconLabel => 'Icon';

  @override
  String get goalsCreate => 'Create goal';

  @override
  String get goalsCancel => 'Cancel';

  @override
  String goalsDepositTitle(String title) {
    return 'Add to \"$title\"';
  }

  @override
  String goalsDepositAmount(String symbol) {
    return 'Amount ($symbol)';
  }

  @override
  String get goalsDeposit => 'Add';

  @override
  String get goalsDeleteTitle => 'Delete goal?';

  @override
  String goalsDeleteConfirm(String title) {
    return 'Delete \"$title\" and its progress?';
  }

  @override
  String get goalsDelete => 'Delete';

  @override
  String get exportColId => 'ID';

  @override
  String get exportColDate => 'Date';

  @override
  String get exportColName => 'Name';

  @override
  String get exportColCategory => 'Category';

  @override
  String get exportColAmount => 'Amount';

  @override
  String get exportColType => 'Type';

  @override
  String get exportNoCategory => 'Uncategorized';

  @override
  String exportShareText(String month, String year) {
    return 'Lumina report for $month.$year';
  }

  @override
  String get matrixIncomeTotal => 'Income total';

  @override
  String get matrixExpenseTotal => 'Expense total';

  @override
  String get matrixNet => 'Net';
}
