# Scale
0–100 scale for every stat

# Stats Definition (what players manage)

- Portfolio / Financial stats
- Volatility (risk taken)
- Diversification
- Sharpe Ratio (risk-adjusted return)
- Cost Drag (fees impact) (note: lower is better)
- Liquidity Ratio
- Tax Drag (lower is better)
- Capital (portfolio growth)
- Behavioral stats
- Emotional Control
- Knowledge
- Investment Horizon
- Saving Rate
- Behavioral Bias (lower = better)

3) Normalize “bad” variables

Some metrics are better when low.

Convert them to positive scores:

Adjusted Score = 100 - Raw Value

Apply to:
- Cost Drag
- Tax Drag
- Behavioral Bias

4) Ideal Profiles (Target Values)
🔴 Risky Guy
Stat	Ideal
Volatility	90
Diversification	20
Sharpe	60
Cost Drag	30
Liquidity	40
Tax Drag	50
Capital	85
Emotional Control	40
Knowledge	60
Horizon	70
Saving Rate	50
Bias	70
🔵 Diversifier
Stat	Ideal
Volatility	50
Diversification	90
Sharpe	80
Cost Drag	40
Liquidity	60
Tax Drag	40
Capital	75
Emotional Control	70
Knowledge	70
Horizon	80
Saving Rate	60
Bias	30
🟢 Conservative
Stat	Ideal
Volatility	20
Diversification	70
Sharpe	70
Cost Drag	30
Liquidity	80
Tax Drag	30
Capital	60
Emotional Control	85
Knowledge	60
Horizon	70
Saving Rate	70
Bias	20
🟡 Young Investor
Stat	Ideal
Volatility	75
Diversification	60
Sharpe	70
Cost Drag	40
Liquidity	30
Tax Drag	50
Capital	80
Emotional Control	50
Knowledge	50
Horizon	95
Saving Rate	80
Bias	50
🟣 Veteran
Stat	Ideal
Volatility	40
Diversification	80
Sharpe	85
Cost Drag	30
Liquidity	70
Tax Drag	30
Capital	70
Emotional Control	90
Knowledge	90
Horizon	50
Saving Rate	50
Bias	20
⚖️ Balanced
Stat	Ideal
Volatility	50
Diversification	70
Sharpe	75
Cost Drag	30
Liquidity	60
Tax Drag	40
Capital	75
Emotional Control	75
Knowledge	70
Horizon	75
Saving Rate	65
Bias	30
5) Initial Values (Starting Point)

Give all characters a baseline + identity bias:

Base template (everyone starts here)
All stats = 50
Capital = 50
Then apply character modifiers
Risky Guy

Volatility +30

Diversification -20

Emotional Control -15

Bias +20

Diversifier

Diversification +30

Volatility -10

Knowledge +10

Conservative

Volatility -25

Liquidity +20

Emotional Control +20

Young Investor

Horizon +30

Saving Rate +20

Knowledge -10

Veteran

Knowledge +30

Emotional Control +25

Horizon -20

Balanced

Small boosts everywhere (+5 to all except bias -5)

6) Scoring System (the key part)

You want to measure:

👉 “How close is the player to the ideal behavior?”

Step 1: Distance per stat
Distance_i = | Player_i - Ideal_i |
Step 2: Convert to score (0–100)
Score_i = 100 - Distance_i
Step 3: Weighted total score

Not all stats matter equally.

Example weights:

Category	Weight
Capital	20%
Sharpe	15%
Volatility	10%
Diversification	10%
Cost Drag	5%
Tax Drag	5%
Liquidity	5%
Emotional Control	10%
Knowledge	5%
Horizon	5%
Saving Rate	5%
Bias	5%
Final Score:
Final Score = Σ (Score_i × Weight_i)
7) Bonus: Behavioral Penalties (makes it fun)

Add penalties for contradictions:

High volatility + low emotional control → -10

Long horizon + high liquidity → -5 (inconsistent)

Low diversification + high volatility → -10

8) Simple Example

If Risky Guy ends with:

Volatility = 80 (ideal 90)

Distance = 10
Score = 90

Do this for all stats → weighted sum → final score.
