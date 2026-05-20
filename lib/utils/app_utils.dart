class AppUtils {
  static String toBengali(String input) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return input.replaceAllMapped(RegExp(r'[0-9]'), (match) {
      return bengaliDigits[int.parse(match.group(0)!)];
    });
  }

  static String getMonthName(int month) {
    const months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    return months[month - 1];
  }

  /// Formats a raw phone number to a clean 11-digit Bangladeshi number.
  static String formatPhoneNumber(String raw) {
    String number = AppUtils.convertBanglaToEnglish(raw.trim());
    number = number.replaceAll(RegExp(r'[^\d]'), '');

    if (number.startsWith('880') && number.length > 11) {
      number = '0${number.substring(3)}';
    }
    if (number.startsWith('00880') && number.length > 13) {
      number = '0${number.substring(5)}';
    }
    if (number.length > 11) {
      final idx = number.indexOf('01');
      if (idx != -1 && number.length - idx >= 11) {
        number = number.substring(idx, idx + 11);
      } else {
        number = number.substring(number.length - 11);
      }
    }
    return number;
  }

  static String convertBanglaToEnglish(String input) {
    const banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String result = input;
    for (int i = 0; i < banglaDigits.length; i++) {
      result = result.replaceAll(banglaDigits[i], '$i');
    }
    return result;
  }
}
