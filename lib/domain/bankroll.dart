class SimBet {
  const SimBet({
    required this.id,
    required this.label,
    required this.stake,
    required this.odds,
    required this.daysAgo,
    this.won,
  });

  final String id;
  final String label;
  final int stake; // FCFA
  final double odds;
  final int daysAgo; // 0 = aujourd'hui
  final bool? won; // null = en cours

  bool get isSettled => won != null;

  int get profit {
    final result = won;
    if (result == null) return 0;
    return result ? (stake * (odds - 1)).round() : -stake;
  }

  SimBet settle(bool result) => SimBet(
        id: id,
        label: label,
        stake: stake,
        odds: odds,
        daysAgo: daysAgo,
        won: result,
      );
}

class BankrollStats {
  const BankrollStats({
    required this.initial,
    required this.profit,
    required this.pendingStake,
    required this.stakedSettled,
    required this.settledCount,
    required this.wins,
    required this.curve,
    required this.lossStreak,
  });

  final int initial;
  final int profit;
  final int pendingStake;
  final int stakedSettled;
  final int settledCount;
  final int wins;
  final List<int> curve;
  final int lossStreak;

  /// Solde simulé : budget + gains nets − mises encore en cours.
  int get balance => initial + profit - pendingStake;

  /// ROI = gain net / budget initial.
  double? get roiPct => initial == 0 ? null : profit * 100 / initial;

  /// Yield = gain net / total misé (paris terminés).
  double? get yieldPct => stakedSettled == 0 ? null : profit * 100 / stakedSettled;

  double? get successPct =>
      settledCount == 0 ? null : wins * 100 / settledCount;
}

BankrollStats computeBankroll(List<SimBet> bets, {required int initial}) {
  var profit = 0;
  var pending = 0;
  var staked = 0;
  var settled = 0;
  var wins = 0;
  var streak = 0;
  final curve = <int>[initial];
  for (final bet in bets) {
    final won = bet.won;
    if (won == null) {
      pending += bet.stake;
      continue;
    }
    settled++;
    staked += bet.stake;
    profit += bet.profit;
    if (won) {
      wins++;
      streak = 0;
    } else {
      streak++;
    }
    curve.add(initial + profit);
  }
  return BankrollStats(
    initial: initial,
    profit: profit,
    pendingStake: pending,
    stakedSettled: staked,
    settledCount: settled,
    wins: wins,
    curve: curve,
    lossStreak: streak,
  );
}

int stakedWithin(List<SimBet> bets, int days) {
  var total = 0;
  for (final bet in bets) {
    if (bet.daysAgo < days) total += bet.stake;
  }
  return total;
}

enum LimitCheck { ok, dailyExceeded, weeklyExceeded }

LimitCheck checkLimits(
  List<SimBet> bets,
  int stake, {
  required int dailyLimit,
  required int weeklyLimit,
}) {
  if (stakedWithin(bets, 1) + stake > dailyLimit) return LimitCheck.dailyExceeded;
  if (stakedWithin(bets, 7) + stake > weeklyLimit) return LimitCheck.weeklyExceeded;
  return LimitCheck.ok;
}
