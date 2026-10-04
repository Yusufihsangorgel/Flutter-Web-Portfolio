import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

extension LanguageStringsContext on BuildContext {
  AppStrings get strings => watch<LanguageCubit>().strings;
}
