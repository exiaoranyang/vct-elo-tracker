# VCT Elo Tracker
---
## Introduction

This is an experimental, configurable design for tracking elo points for the Valorant Champions Tour (VCT) circuit from 2021-2026. This repo uses [Valorant Champion Tour 2021-2026 Data](https://www.kaggle.com/datasets/ryanluong1/valorant-champion-tour-2021-2023-data/data), scraped and formatted by Ryan Luong.

### Repository Contents

```text
vct-elo-tracker/
├── Scripts/
│   ├── clean_matches.R
│   ├── run_elo.R
│   └── create_output.R
├── R/
│   └── functions.R
├── input/
├── output/
├── .gitattributes.txt
├── .gitignore
├── config.yaml

```

**Content notes:**

- `Scripts/`: to be run in the order listed above. A `makefile` is planned to be integrated.
- `input/`: to run the code, paste the datasets from Ryan Luong's kaggle page. The `archive` folder should be pasted as a subfolder in  `input/`.
- `config.yaml`: sets the parameters for how the elo calculations are run, and sets path options. I encourage exploring how the elo calculations run with different settings.

## Elo Calculation

### Formula

The calculations use a basic formula as the foundation:
1. First expected elo is calculated, where:

```math
E_A = \frac{1}{1+10^{(S_A - S_B)/400}}
```
Where $E_A$ refers to expected probability for a team A win. $S_A$ and $S_B$ refer to the starting elos for each respective team.

2. Secondly, the elo calculation is run as so:

```math
N_A = S_A + K \times (1-E_A) 
```
Where $N_A$ is the new elo of Team A, and $K$ is some arbitrary multiplier.

### Configurable Settings

The elo calculations currently has the following configurable variables as per the `.yaml` file, with the default variables:

```text
start: 1000
K_below_1200: 192
K_below_1600: 96
K_below_2000: 96
K_above: 64
floor: 0
C_low: 0.5
C_medium: 1.0
C_high: 1.5
G_1: 1.0
G_2: 1.25
Compression: 0.35
```

The `C` value is a modifer that adjusts for match severity at three levels: low (VCT open qualifiers or other matches that lead up to the main circuit), medium (regular VCT regional circuit matches), and high (VCT playoffs or qualifiers to internationals, and all international tournament mathces).

The `G` value is a modifier for game differential per series (BO1 not included), where 2-0, 3-1, or 3-0 victories can have a slight increase in ELO modification versus other results.

The `Compression` value, if set to <1.0, creates a season reset effect, where all present elos can be adjusted towards the base `start` elo value.

## Results

### Cumulative Elos

**Cumulative Elo (Pre-franchising, 2021-2022):**

$$

\begin{array}{lrr}
\textbf{Team}   & \textbf{Team ID} & \textbf{Elo} \\ \hline
\text{Loud}            & 6961             & 2147.888     \\
\text{OpTic Gaming}    & 8127             & 2020.019     \\
\text{FunPlus Phoenix} & 628              & 1990.904     \\
\text{DRX}             & 8185             & 1986.760     \\
\text{Paper Rex}       & 624              & 1949.689     \\
\text{XSET}            & 533              & 1854.863     \\
\text{ONIC G}          & 2032             & 1763.558     \\
\text{LEVIAT\'{A}N}        & 2359             & 1748.057     \\
\text{Team Secret}     & 6199             & 1742.170     \\
\text{FNATIC}          & 2593             & 1736.493     \\
\text{KR\"U Esports}     & 2355             & 1672.762     \\
\text{ZETA DIVISION}   & 5448             & 1643.337     \\
\text{Alter Ego}       & 1110             & 1628.061     \\
\text{Guild Esports}   & 1209             & 1625.080     \\
\text{Team Liquid}     & 474              & 1601.180    
\end{array}

$$

**Cumulative Elo (Post-franchising, 2023-End of Masters London 2026):**

$$

\begin{array}{lrr}
\textbf{Team}   & \textbf{Team ID} & \textbf{Elo} \\ \hline
\text{LEVIAT\'AN}            & 2359             & 1851.250     \\
\text{Paper Rex}    & 624             & 1760.459     \\
\text{Team Vitality} & 2059              & 1586.110     \\
\text{EDward Gaming}             & 1120             & 1576.3246     \\
\text{Xi Lai Gaming}       & 13581              & 1462.064     \\
\text{Team Heretics}            & 1001              & 1461.451     \\
\text{FUT Esports}          & 1184             & 1428.325     \\
\text{Nongshim RedForce}        & 11060             & 1424.146     \\
\text{G2 Esports}     & 11058             & 1404.030     \\
\text{T1}          & 14             & 1363.058     \\
\text{Eternal Fire}     & 6392             & 1359.869     \\
\text{NRG}   & 1034             & 1350.183     \\
\text{Global Esports}       & 918             & 1333.570     \\
\text{DRX / KIWOOM DRX}   & 8185             & 1326.775     \\
\text{FULL SENSE}     & 4050              & 1306.825    
\end{array}

$$

### Elo Peaks

**Peak Elos (Pre-franchising):**

<div style="overflow-x: auto; width: 100%;">

$$

\begin{array}{rlrll}
\textbf{Team.ID} & \textbf{Team} & \textbf{Elo} & \textbf{Peak Match} & \textbf{Peak Tournament}\\ \hline
6961 & \text{LOUD} & 2147.888 & \text{LOUD vs OpTic Gaming} & \text{Valorant Champions 2022}\\
624 & \text{Paper Rex} & 2146.148 & \text{Paper Rex vs OpTic Gaming} & \text{Valorant Champions Tour Stage 2: Masters Copenhagen}\\
628 & \text{FunPlus Phoenix} & 2097.173 & \text{FunPlus Phoenix vs KRÜ Esports} & \text{Valorant Champions 2022}\\
3531 & \text{Acend} & 2087.084 & \text{Acend vs Gambit Esports} & \text{Valorant Champions 2021}\\
682 & \text{Gambit Esports} & 2083.351 & \text{Gambit Esports vs KRÜ Esports} & \text{Valorant Champions 2021}\\
8127 & \text{OpTic Gaming} & 2067.390 & \text{OpTic Gaming vs DRX} & \text{Valorant Champions 2022}\\
474 & \text{Team Liquid} & 2037.775 & \text{Team Liquid vs Cloud9} & \text{Valorant Champions 2021}\\
8185 & \text{DRX} & 2033.103 & \text{FunPlus Phoenix vs DRX} & \text{Valorant Champions 2022}\\
2 & \text{Sentinels} & 2031.264 & \text{F4Q vs Sentinels} & \text{Valorant Champions Tour Stage 3: Masters Berlin}\\
427 & \text{Envy} & 1969.833 & \text{100 Thieves vs Envy} & \text{Valorant Champions Tour Stage 3: Masters Berlin}\\
533 & \text{XSET} & 1953.565 & \text{XSET vs FNATIC} & \text{Valorant Champions 2022}\\
7397 & \text{XERXIA Esports} & 1947.982 & \text{Team Secret vs XERXIA Esports} & \text{Champions Tour Asia-Pacific Stage 2: Challengers Playoffs}\\
2593 & \text{FNATIC} & 1913.136 & \text{FNATIC vs LEVIATÁN} & \text{Valorant Champions Tour Stage 2: Masters Copenhagen}\\
257 & \text{G2 Esports} & 1890.565 & \text{G2 Esports vs FUT Esports} & \text{Champions Tour EMEA: Last Chance Qualifier}\\
2355 & \text{KRÜ Esports} & 1888.220 & \text{FNATIC vs KRÜ Esports} & \text{Valorant Champions 2021}\\
\end{array}

$$

</div>

**Peak Elos (Post-franchising):**

<div style="overflow-x: auto; width: 100%;">

$$

\begin{array}{rlrll}
\text.bf{Team.ID} & \text.bf{Team} & \text.bf{Elo} & \text.bf{Peak Match} & \text.bf{Peak Tournament}\\ \hline
624 & \text{Paper Rex} & 1901.247 & \text{Paper Rex vs G2 Esports} & \text{Valorant Champions 2025}\\
1034 & \text{NRG} & 1867.404 & \text{NRG vs FNATIC} & \text{Valorant Champions 2025}\\
17 & \text{Gen.G} & 1862.180 & \text{Gen.G vs Sentinels} & \text{Valorant Champions 2024}\\
1120 & \text{EDward Gaming} & 1857.934 & \text{EDward Gaming vs Team Heretics} & \text{Valorant Champions 2024}\\
5248 & \text{Evil Geniuses} & 1855.613 & \text{Paper Rex vs Evil Geniuses} & \text{Valorant Champions 2023}\\
2359 & \text{LEVIATÁN} & 1851.250 & \text{Paper Rex vs LEVIATÁN} & \text{Valorant Masters London 2026}\\
2593 & \text{FNATIC} & 1845.388 & \text{FNATIC vs Bilibili Gaming} & \text{Valorant Champions 2023}\\
1001 & \text{Team Heretics} & 1812.189 & \text{LEVIATÁN vs Team Heretics} & \text{Valorant Champions 2024}\\
11060 & \text{Nongshim RedForce} & 1774.405 & \text{Nongshim RedForce vs Paper Rex} & \text{Valorant Masters Santiago 2026}\\
8185 & \text{DRX} & 1757.851 & \text{DRX vs Paper Rex} & \text{Valorant Champions 2025}\\
11058 & \text{G2 Esports} & 1739.179 & \text{G2 Esports vs NRG} & \text{VCT 2025: Americas Stage 2}\\
2 & \text{Sentinels} & 1729.398 & \text{Sentinels vs 100 Thieves} & \text{Champions Tour 2024: Americas Stage 1}\\
6961 & \text{LOUD} & 1724.340 & \text{FNATIC vs LOUD} & \text{Valorant Champions 2023}\\
14 & \text{T1} & 1675.111 & \text{T1 vs Team Secret} & \text{VCT 2025: Pacific Stage 1}\\
13790 & \text{Wolves Esports} & 1655.034 & \text{Wolves Esports vs Gen.G} & \text{Valorant Masters Toronto 2025}\\
\end{array}

$$

</div>

### Notes

- Note that cumulative elo represents the strenght of teams at the **very moment** calculations stop. This means cumulative elos for pre-franchising are the strongest teams (as rated by the calculations) as of the **end** of **Champs 2022**. And, post-franchising cumulative elo is the strongest teams as of the **end of Masters London 2026**.
- Because of the difference in sheer match numbers between pre and post franchising, elo values are not really comparable across pre and post franchised teams. 
- Due to the design of the elo calculation, playing more matches typically results in higher elos, which means winners of early tournaments in the season are rated less (see FNATIC with a peak of 1845.388 despite winning back to back masters.)

### Future Iterations

- More explorations with different config values. Perhaps a separate `k` value for pre and post franchising matches.
- Potential integration of EWC matches, which would be manually scraped. Additionally, I intend to maintain the code to be compatible as Ryan Luong updates the data.
- Exploration of alternate elo calculation methods, with more intentional note of elo distributions
- Potential integration of core changes, where resets would happen when teams change core rather than when a new season starts.
