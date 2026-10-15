# Model prices

What `scripts/feature-cost.sh` multiplies token counts by to estimate what a feature would cost on the API (`harness/SETUP.md` § Retrospective → Feature cost). The figure is an estimate for comparing features, not a bill: it is the same whether the owner pays per call, uses a Pro or Max plan, or runs through another provider.

Prices as of: 2026-10-06

The public Anthropic API list prices, in US dollars per million tokens. Kit updates refresh this table when prices change or a model is added. To use your own rates instead (Amazon Bedrock, Google Cloud, a negotiated discount), edit the numbers and the date above; `/morph-update` keeps your edits when it merges a later price update. A model that isn't listed shows as "unpriced", never as $0. A model cell ending in `(prompt > N)` is the rate for requests whose whole prompt (input plus cache) is above N tokens.

| Model | Input | Output | Cache write 5m | Cache write 1h | Cache read |
|---|---|---|---|---|---|
| claude-fable-5-1 | 10.00 | 50.00 | 12.50 | 20.00 | 0.25 |
| claude-fable-5 | 10.00 | 50.00 | 12.50 | 20.00 | 1.00 |
| claude-opus-5-5 | 4.00 | 20.00 | 5.00 | 8.00 | 0.20 |
| claude-opus-5 | 5.00 | 25.00 | 6.25 | 10.00 | 0.50 |
| claude-opus-4-8 | 5.00 | 25.00 | 6.25 | 10.00 | 0.50 |
| claude-opus-4-7 | 5.00 | 25.00 | 6.25 | 10.00 | 0.50 |
| claude-opus-4-6 | 5.00 | 25.00 | 6.25 | 10.00 | 0.50 |
| claude-sonnet-5-5 | 2.00 | 10.00 | 2.50 | 4.00 | 0.20 |
| claude-sonnet-5 | 2.00 | 10.00 | 2.50 | 4.00 | 0.20 |
| claude-sonnet-4-6 | 3.00 | 15.00 | 3.75 | 6.00 | 0.30 |
| claude-haiku-5-5 | 0.10 | 0.50 | 0.125 | 0.20 | 0.01 |
| claude-haiku-5-5 (prompt > 100000) | 0.50 | 2.50 | 0.625 | 1.00 | 0.05 |
| claude-haiku-4-5 | 1.00 | 5.00 | 1.25 | 2.00 | 0.10 |

Fast mode multiplier: 2

Web search per request: $0.01
