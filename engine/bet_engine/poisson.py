"""Modèle de buts Poisson / Dixon-Coles, en bibliothèque standard uniquement.

Principe : chaque équipe a une force d'attaque et une faiblesse de défense,
estimées sur les résultats passés (les matchs récents pèsent davantage). Les
équipes à petit échantillon sont ramenées vers la moyenne. De la matrice des
scores on déduit tous les marchés de buts, de façon cohérente entre eux.
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import datetime

MAX_GOALS = 10
MODEL_VERSION = "poisson-dc-0.1"


@dataclass(frozen=True)
class Result:
    home: str
    away: str
    home_goals: int
    away_goals: int
    when: datetime  # UTC
    ht_home: int | None = None
    ht_away: int | None = None


@dataclass
class Ratings:
    attack: dict[str, float]
    defence: dict[str, float]  # plus grand = défense plus fragile
    home_adv: float
    rho: float
    weight: dict[str, float]  # poids cumulé de matchs par équipe
    first_half_share: float


def _tau(x: int, y: int, lam: float, mu: float, rho: float) -> float:
    if x == 0 and y == 0:
        return 1 - lam * mu * rho
    if x == 0 and y == 1:
        return 1 + lam * rho
    if x == 1 and y == 0:
        return 1 + mu * rho
    if x == 1 and y == 1:
        return 1 - rho
    return 1.0


def fit_ratings(
    results: list[Result],
    now: datetime,
    xi: float = 0.003,
    iterations: int = 60,
    shrink: float = 4.0,
) -> Ratings:
    teams = sorted({r.home for r in results} | {r.away for r in results})
    if len(results) < 10 or len(teams) < 4:
        raise ValueError("échantillon insuffisant pour estimer les forces")

    weights = [
        math.exp(-xi * max((now - r.when).total_seconds() / 86400.0, 0.0))
        for r in results
    ]
    attack = {t: 1.0 for t in teams}
    defence = {t: 1.0 for t in teams}
    gamma = 1.3

    for _ in range(iterations):
        num = {t: 0.0 for t in teams}
        den = {t: 0.0 for t in teams}
        for w, r in zip(weights, results):
            num[r.home] += w * r.home_goals
            den[r.home] += w * defence[r.away] * gamma
            num[r.away] += w * r.away_goals
            den[r.away] += w * defence[r.home]
        for t in teams:
            attack[t] = num[t] / den[t] if den[t] > 0 else 1.0
        mean_attack = sum(attack.values()) / len(teams)
        for t in teams:
            attack[t] /= mean_attack

        num = {t: 0.0 for t in teams}
        den = {t: 0.0 for t in teams}
        for w, r in zip(weights, results):
            num[r.home] += w * r.away_goals
            den[r.home] += w * attack[r.away]
            num[r.away] += w * r.home_goals
            den[r.away] += w * attack[r.home] * gamma
        for t in teams:
            defence[t] = num[t] / den[t] if den[t] > 0 else 1.0

        g_num = sum(w * r.home_goals for w, r in zip(weights, results))
        g_den = sum(
            w * attack[r.home] * defence[r.away] for w, r in zip(weights, results)
        )
        gamma = g_num / g_den if g_den > 0 else 1.3

    weight = {t: 0.0 for t in teams}
    for w, r in zip(weights, results):
        weight[r.home] += w
        weight[r.away] += w

    # Rétrécissement vers la moyenne pour les équipes à faible échantillon.
    mean_def = sum(defence.values()) / len(teams)
    for t in teams:
        n = weight[t]
        attack[t] = (n * attack[t] + shrink * 1.0) / (n + shrink)
        defence[t] = (n * defence[t] + shrink * mean_def) / (n + shrink)

    # Corrélation des petits scores (Dixon-Coles) : recherche sur une grille.
    best_rho, best_ll = 0.0, -1e18
    for step in range(-10, 1):  # ρ entre -0,20 et 0 (valeurs plausibles)
        rho = step * 0.02
        ll = 0.0
        valid = True
        for w, r in zip(weights, results):
            if r.home_goals > 1 or r.away_goals > 1:
                continue
            lam = attack[r.home] * defence[r.away] * gamma
            mu = attack[r.away] * defence[r.home]
            t = _tau(r.home_goals, r.away_goals, lam, mu, rho)
            if t <= 0:
                valid = False
                break
            ll += w * math.log(t)
        if valid and ll > best_ll:
            best_rho, best_ll = rho, ll

    ht_num = ht_den = 0.0
    for w, r in zip(weights, results):
        if r.ht_home is not None and r.ht_away is not None:
            ht_num += w * (r.ht_home + r.ht_away)
            ht_den += w * (r.home_goals + r.away_goals)
    share = ht_num / ht_den if ht_den > 0 and ht_den > 30 else 0.45
    share = min(max(share, 0.35), 0.55)

    return Ratings(attack, defence, gamma, best_rho, weight, share)


def expected_goals(r: Ratings, home: str, away: str) -> tuple[float, float]:
    lam_h = r.attack[home] * r.defence[away] * r.home_adv
    lam_a = r.attack[away] * r.defence[home]
    return lam_h, lam_a


def _pmf(lam: float, n: int) -> list[float]:
    out = [math.exp(-lam)]
    for k in range(1, n):
        out.append(out[-1] * lam / k)
    return out


def score_matrix(lam_h: float, lam_a: float, rho: float) -> list[list[float]]:
    n = MAX_GOALS + 1
    ph, pa = _pmf(lam_h, n), _pmf(lam_a, n)
    m = [[ph[i] * pa[j] for j in range(n)] for i in range(n)]
    for (i, j) in ((0, 0), (0, 1), (1, 0), (1, 1)):
        m[i][j] *= max(_tau(i, j, lam_h, lam_a, rho), 0.0)
    total = sum(sum(row) for row in m)
    return [[v / total for v in row] for row in m]


def markets(m: list[list[float]]) -> dict[str, float]:
    n = len(m)
    home = sum(m[i][j] for i in range(n) for j in range(n) if i > j)
    draw = sum(m[i][i] for i in range(n))
    away = 1.0 - home - draw

    def over(line: float) -> float:
        return sum(m[i][j] for i in range(n) for j in range(n) if i + j > line)

    btts = sum(m[i][j] for i in range(1, n) for j in range(1, n))
    out = {
        "home": home,
        "draw": draw,
        "away": away,
        "dc_1x": home + draw,
        "dc_x2": draw + away,
        "dc_12": home + away,
        "dnb_home": home / (home + away),
        "dnb_away": away / (home + away),
        "btts_yes": btts,
        "btts_no": 1.0 - btts,
    }
    for line in (1.5, 2.5, 3.5):
        key = str(line).replace(".", "_")
        out[f"over_{key}"] = over(line)
        out[f"under_{key}"] = 1.0 - over(line)
    return out


def top_scores(m: list[list[float]], count: int = 3) -> list[tuple[str, float]]:
    cells = [
        (f"{i}-{j}", m[i][j]) for i in range(len(m)) for j in range(len(m))
    ]
    cells.sort(key=lambda c: c[1], reverse=True)
    return cells[:count]


def _outcome(diff: int) -> int:
    return 0 if diff > 0 else (1 if diff == 0 else 2)


def htft_matrix(
    lam_h: float, lam_a: float, share: float, ft_probs: tuple[float, float, float]
) -> list[list[float]]:
    """Probabilités (mi-temps, fin de match), cohérentes avec le 1X2 final.

    Deux mi-temps indépendantes (Poisson) donnent la probabilité de la
    mi-temps conditionnelle au résultat final ; on la recompose avec le 1X2
    final du modèle complet pour que les marges concordent exactement.
    """
    n = 7
    p1h = _pmf(lam_h * share, n)
    p1a = _pmf(lam_a * share, n)
    p2h = _pmf(lam_h * (1 - share), n)
    p2a = _pmf(lam_a * (1 - share), n)
    joint = [[0.0] * 3 for _ in range(3)]
    for a in range(n):
        for b in range(n):
            pa_b = p1h[a] * p1a[b]
            ht = _outcome(a - b)
            for c in range(n):
                for d in range(n):
                    joint[ht][_outcome(a + c - b - d)] += pa_b * p2h[c] * p2a[d]
    out = [[0.0] * 3 for _ in range(3)]
    for ft in range(3):
        col = sum(joint[ht][ft] for ht in range(3))
        for ht in range(3):
            out[ht][ft] = (joint[ht][ft] / col if col > 0 else 0.0) * ft_probs[ft]
    return out


def round_pcts(values: list[float]) -> list[int]:
    """Arrondit en pourcentages entiers dont la somme fait exactement 100."""
    total = sum(values)
    raw = [v / total * 100 for v in values]
    floors = [int(x) for x in raw]
    order = sorted(range(len(raw)), key=lambda i: raw[i] - floors[i], reverse=True)
    for i in order[: 100 - sum(floors)]:
        floors[i] += 1
    return floors
