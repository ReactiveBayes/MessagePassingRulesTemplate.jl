# ExampleMessagePassingRules

The [`ExampleNormal`](@ref) node is a normal distribution with a known variance, with its
[belief propagation](@extref MessagePassingRulesBase glossary-belief-propagation) and
[variational](@extref MessagePassingRulesBase glossary-vmp) rules and its
[average energy](@extref MessagePassingRulesBase glossary-average-energy). It is the node of
MessagePassingRulesBase's tutorial
[Your first node](@extref MessagePassingRulesBase tutorial-first-node), packaged.

!!! tip "Replace this page"
    This page follows the layout every node page of a rule package follows: overview, definition,
    interfaces, algorithm, supported rules, example, limitations and API. Keep the sections and
    replace their content with your node's.

```@docs
ExampleMessagePassingRules
```

!!! info "Where these rules run"
    The [ReactiveMP](https://reactivebayes.github.io/ReactiveMP.jl/dev/) engine runs these rules on
    a factor graph, which [RxInfer](https://github.com/ReactiveBayes/RxInfer.jl) builds from a model.
    The examples here call the rules directly.

## Overview

Use the node for an observation or a latent variable with a normal distribution whose variance is
known. Its mean can be another variable of the model, observed or not.

## Definition

```math
f(\mathrm{out}, \mu, v) = \mathcal{N}(\mathrm{out} \mid \mu, v)
```

## Interfaces

```@example example-normal
using ExampleMessagePassingRules, MessagePassingRulesBase, ExponentialFamily, BayesBase
MessagePassingRulesBase.nodespec(ExampleNormal)
```

| name | aliases | meaning | messages and marginals its rules take |
|:---|:---|:---|:---|
| `out` | none | the variable the distribution is over | normal or observed messages, any marginal |
| `μ` | `mean` | the mean | normal or observed messages, any marginal |
| `v` | none | the variance, positive | a `PointMass` |

## Algorithm

The node uses [`DefaultAlgorithm`](@extref MessagePassingRulesBase.DefaultAlgorithm), which has
no parameters, so a model names none. It declares no dependencies of its own: its rules take what
the [default scheme](@extref MessagePassingRulesBase glossary-default-scheme) delivers.

## Supported rules

```@example example-normal
MessagePassingRulesBase.rule_coverage(ExampleNormal)
```

- Belief propagation, towards `out` from the messages on `μ` and `v`, and towards `μ` from the
  messages on `out` and `v`: the variances add. The log scale is 0.
- Variational message passing, towards `out` from the marginals `q(μ)` and `q(v)`, and towards
  `μ` from `q(out)` and `q(v)`: only the mean of the other marginal counts.
- The average energy, from `q(out)`, `q(μ)` and `q(v)`.

## Example

The message towards `out` from a normal message on the mean:

```@example example-normal
@call_message_update_rule(
    node = ExampleNormal, target = :out,
    m = (μ = NormalMeanVariance(1.0, 2.0), v = PointMass(0.5)),
)
```

The variance of the message on `μ`, 2, and the variance of the node, 0.5, add to 2.5. A
variance that is not positive raises a
[`RuleInputError`](@extref MessagePassingRulesBase.RuleInputError):

```@example example-normal
try
    @call_message_update_rule(node = ExampleNormal, target = :out, m = (μ = PointMass(1.0), v = PointMass(-1.0)))
catch err
    print(first(split(sprint(showerror, err), "\n  rule at")))
end
```

## Limitations

- The variance must be a `PointMass`: there are no rules for a random variance.
- Univariate only.
- The variational rules declare no [log scale](@extref MessagePassingRulesBase glossary-log-scale).

## API

```@docs
ExampleNormal
```
