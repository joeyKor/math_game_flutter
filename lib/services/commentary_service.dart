import 'dart:math';

class CommentaryService {
  static final Random _random = Random();

  static String getHitPhrase(String name, {String? target, String? formula}) {
    final List<String> phrases = [
      "Boom! Nails it!",
      "Incredible shot!",
      "Right on target! Scores!",
      "That's how it's done!",
      "Sensational! Finds the mark!",
      "Direct hit! On fire!",
      "Oh, what a play!",
    ];

    String base = phrases[_random.nextInt(phrases.length)];
    if (target != null && formula != null) {
      base += " Target $target cleared with $formula.";
    }
    return base;
  }

  static String getEfficientPhrase(String name) {
    final List<String> phrases = [
      "Sensational efficiency!",
      "Pure genius! Uses every number perfectly!",
      "A calculated masterpiece!",
      "Wait, look at that! Minimum resources used!",
      "Absolute brilliance in the arena!",
    ];
    return phrases[_random.nextInt(phrases.length)];
  }

  static String getSniperPhrase(String name) {
    final List<String> phrases = [
      "Unbelievable! A complete resource shutdown!",
      "The Sniper has arrived! Every number used perfectly!",
      "Clinical precision! That is absolute mastery!",
      "Total domination! Not a single number wasted!",
      "That's a mathematical sniper shot!",
    ];
    return phrases[_random.nextInt(phrases.length)];
  }

  static String getGoldenHitPhrase(String name) {
    final List<String> phrases = [
      "JACKPOT! The 50-point target goes down!",
      "Massive hit! A gold mine for the challenger!",
      "Unstoppable force! Takes the big prize!",
      "Mega points! The golden target is conquered!",
      "Boom! That's the one we were waiting for!",
    ];
    return phrases[_random.nextInt(phrases.length)];
  }

  static String getMissPhrase(String name, {String? result}) {
    final List<String> phrases = [
      "Ooh, just missed! Better luck next time.",
      "Just a bit outside! Close, but not quite there.",
      "A tough break for the challenger! Keep trying!",
      "No! Misses the target. Focus up!",
      "A swing and a miss! Tension is rising!",
    ];

    String base = phrases[_random.nextInt(phrases.length)];
    if (result != null) {
      base += " Calculation resulted in $result.";
    }
    return base;
  }

  static String getWinPhrase(String name) {
    final List<String> phrases = [
      "Ladies and gentlemen, we have a winner! Done it!",
      "An absolute masterclass! Victory is achieved!",
      "A legendary performance! Conquers the board!",
      "History in the making! Takes the crown!",
      "Unstoppable! Completes the mission!",
    ];
    return phrases[_random.nextInt(phrases.length)];
  }

  static String getGameOverPhrase(String name) {
    final List<String> phrases = [
      "The mission ends here.",
      "Tough luck! Run out of chances.",
      "Game over! But the journey continues.",
      "The challenger is defeated! A brave effort today.",
      "And that is the final strike! Mission failed.",
    ];
    return phrases[_random.nextInt(phrases.length)];
  }
}
