import 'package:lumina/features/categories/data/models/custom_category_model.dart';
import 'package:lumina/l10n/app_localizations.dart';

class CategoryDisplay {
  const CategoryDisplay({required this.name, required this.colorHex});

  final String name;
  final int colorHex;
}

class CategoryDisplayMapper {
  const CategoryDisplayMapper();

  CategoryDisplay resolve({
    required String categoryId,
    required String? storedName,
    required List<CustomCategory> categories,
    required AppLocalizations loc,
  }) {
    CustomCategory? found;

    for (final c in categories) {
      if (c.id == categoryId) {
        found = c;
        break;
      }
    }

    if (found == null && storedName != null && storedName.isNotEmpty) {
      for (final c in categories) {
        if (c.id == storedName ||
            c.name.toLowerCase() == storedName.toLowerCase()) {
          found = c;
          break;
        }
      }
    }

    if (found != null) {
      return CategoryDisplay(
        name: found.localizedName(loc),
        colorHex: _argb(found.colorHex),
      );
    }

    final raw = storedName?.trim() ?? '';
    final looksLikeId =
        categoryId.startsWith('cat_') || raw.startsWith('cat_') || raw.isEmpty;

    return CategoryDisplay(
      name: looksLikeId ? loc.otherCategory : raw,
      colorHex: 0xFF64748B,
    );
  }

  int _argb(int hex) => hex <= 0xFFFFFF ? (0xFF000000 | hex) : hex;
}
