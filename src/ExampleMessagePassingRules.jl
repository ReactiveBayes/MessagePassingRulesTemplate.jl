"""
    ExampleMessagePassingRules

The [`ExampleNormal`](@ref) node and its rules: a normal distribution with a known variance, the
node of MessagePassingRulesBase's tutorial *Your first node*, packaged.

Replace it with your own nodes: declare each with `@define_factor_node`, define its rules with
`@define_message_update_rule`, `@define_marginal_update_rule` and `@define_average_energy`, and
test every rule in `test/`.

# Examples

```jldoctest
julia> using MessagePassingRulesBase, ExponentialFamily, BayesBase

julia> result = @call_message_update_rule(
           node = ExampleNormal, target = :out,
           m = (μ = NormalMeanVariance(1.0, 2.0), v = PointMass(0.5)),
       );

julia> getresult(result) ≈ NormalMeanVariance(1.0, 2.5)
true
```
"""
module ExampleMessagePassingRules

using MessagePassingRulesBase, BayesBase, ExponentialFamily, Distributions

export ExampleNormal

"""
    ExampleNormal(μ, v)

A normal distribution over `out` with mean `μ` and variance `v`, as a stochastic factor node:
`f(out, μ, v) = N(out | μ, v)`. Called with its parameters, it is that distribution, a
`NormalMeanVariance`.

# Interfaces

1. `out`: the variable the distribution is over.
2. `μ`: the mean, also named `mean`.
3. `v`: the variance, a `PointMass`.

# Rules

- belief propagation, towards `out` from `m(μ)` and `m(v)`, and towards `μ` from `m(out)` and
  `m(v)`: the variances add, with log scale 0;
- variational message passing, towards `out` from `q(μ)` and `q(v)`, and towards `μ` from
  `q(out)` and `q(v)`;
- the average energy, from `q(out)`, `q(μ)` and `q(v)`.

The variance must be positive; every rule checks it.

See also [`ExampleMessagePassingRules`](@ref).
"""
struct ExampleNormal end

ExampleNormal(μ, v) = NormalMeanVariance(μ, v)

@define_factor_node(
    node = ExampleNormal, type = Stochastic,
    interfaces = [:out, (:μ, aliases = [:mean]), :v],
)

# A message on the mean or the output, normal or observed.
const NormalOrObserved = Union{PointMass, UnivariateNormalDistributionsFamily}

# Every rule reads the variance as a point mass, so one check serves them all.
positive_variance(v) = mean(v) > 0 || lazy"the variance `v` must be positive; got $(mean(v))"

# m(out) = ∫ N(out | μ, v) m(μ) dμ = N(out | mean(m_μ), var(m_μ) + v): the variances add. A point
# mass has variance zero, so an observed mean gives the node's own density.
@define_message_update_rule(
    node = ExampleNormal, target = :out,
    args = (m[:μ]::NormalOrObserved, m[:v]::PointMass),
    args_check = (args) -> positive_variance(args.m[:v]),
    logscale = 0,
    body = (args) -> NormalMeanVariance(mean(args.m[:μ]), var(args.m[:μ]) + mean(args.m[:v])),
)

# The node is symmetric in `out` and `μ`.
@define_message_update_rule(
    node = ExampleNormal, target = :μ,
    args = (m[:out]::NormalOrObserved, m[:v]::PointMass),
    args_check = (args) -> positive_variance(args.m[:v]),
    logscale = 0,
    body = (args) -> NormalMeanVariance(mean(args.m[:out]), var(args.m[:out]) + mean(args.m[:v])),
)

# exp ⟨log N(out | μ, v)⟩_q(μ) ∝ N(out | E[μ], v).
@define_message_update_rule(
    node = ExampleNormal, target = :out,
    args = (q[:μ]::Any, q[:v]::PointMass),
    args_check = (args) -> positive_variance(args.q[:v]),
    body = (args) -> NormalMeanVariance(mean(args.q[:μ]), mean(args.q[:v])),
)

@define_message_update_rule(
    node = ExampleNormal, target = :μ,
    args = (q[:out]::Any, q[:v]::PointMass),
    args_check = (args) -> positive_variance(args.q[:v]),
    body = (args) -> NormalMeanVariance(mean(args.q[:out]), mean(args.q[:v])),
)

# ⟨-log N(out | μ, v)⟩ = log(2πv) / 2 + E[(out - μ)²] / 2v, with
# E[(out - μ)²] = var(out) + var(μ) + (E[out] - E[μ])² under q(out) q(μ).
@define_average_energy(
    node = ExampleNormal,
    args = (q[:out]::Any, q[:μ]::Any, q[:v]::PointMass),
    args_check = (args) -> positive_variance(args.q[:v]),
    body = (args) -> begin
        v = mean(args.q[:v])
        difference = var(args.q[:out]) + var(args.q[:μ]) + abs2(mean(args.q[:out]) - mean(args.q[:μ]))
        # `2v * π`, not `2π * v`: `2π` is a Float64 and would promote a Float32 energy.
        (log(2v * π) + difference / v) / 2
    end,
)

end
