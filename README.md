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
---

The `create_output.R` script will be fully completed, and results will be posted here when available.

### Future Iterations

...
