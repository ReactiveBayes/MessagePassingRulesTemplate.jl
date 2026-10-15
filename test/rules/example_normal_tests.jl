# ExampleNormal: one file of test items per node. Each rule has a table of cases with the result
# it must return; the belief propagation rules are also verified against the node's density, and
# one rule's derivatives against finite differences. `test/runtests.jl` then checks that every
# rule was selected by some test.

@testitem "rules:ExampleNormal:out" tags = [:rules] begin
    using ExampleMessagePassingRules, MessagePassingRulesTestUtils, MessagePassingRulesBase, ExponentialFamily, BayesBase

    # Belief propagation: the variances add.
    @test_message_update_rule(
        node = ExampleNormal, target = :out,
        cases = [
            (m = (μ = NormalMeanVariance(1.0, 2.0), v = PointMass(0.5)),) => NormalMeanVariance(1.0, 2.5),
            (m = (μ = NormalMeanPrecision(-1.0, 4.0), v = PointMass(1.0)),) => NormalMeanVariance(-1.0, 1.25),
            # An observed mean gives the node's own density.
            (m = (μ = PointMass(3.0), v = PointMass(2.0)),) => NormalMeanVariance(3.0, 2.0),
        ],
    )

    # Variational message passing: only the mean of q(μ) counts.
    @test_message_update_rule(
        node = ExampleNormal, target = :out,
        cases = [
            (q = (μ = NormalMeanVariance(1.0, 2.0), v = PointMass(0.5)),) => NormalMeanVariance(1.0, 0.5),
            (q = (μ = PointMass(-2.0), v = PointMass(3.0)),) => NormalMeanVariance(-2.0, 3.0),
        ],
    )

    # The rule's message against the node's density, integrated numerically.
    @verify_message_update_rule(node = ExampleNormal, target = :out, m = (μ = NormalMeanVariance(1.0, 2.0), v = PointMass(0.5)))

    # A model differentiating through the rule gets the right derivatives.
    @test_rule_derivatives(
        node = ExampleNormal, target = :out,
        inputs = θ -> (m = (μ = NormalMeanVariance(θ, 1.0), v = PointMass(θ^2)),),
        at = 1.5, summary = d -> mean(d) + var(d),
    )
end

@testitem "rules:ExampleNormal:μ" tags = [:rules] begin
    using ExampleMessagePassingRules, MessagePassingRulesTestUtils, MessagePassingRulesBase, ExponentialFamily, BayesBase

    @test_message_update_rule(
        node = ExampleNormal, target = :μ,
        cases = [
            (m = (out = PointMass(2.0), v = PointMass(0.5)),) => NormalMeanVariance(2.0, 0.5),
            (m = (out = NormalMeanVariance(0.0, 1.0), v = PointMass(1.0)),) => NormalMeanVariance(0.0, 2.0),
        ],
    )

    @test_message_update_rule(
        node = ExampleNormal, target = :μ,
        cases = [
            (q = (out = NormalMeanVariance(4.0, 9.0), v = PointMass(2.0)),) => NormalMeanVariance(4.0, 2.0),
        ],
    )

    @verify_message_update_rule(node = ExampleNormal, target = :μ, m = (out = PointMass(3.0), v = PointMass(0.5)))
end

@testitem "rules:ExampleNormal:energy" tags = [:rules] begin
    using ExampleMessagePassingRules, MessagePassingRulesTestUtils, MessagePassingRulesBase, ExponentialFamily, BayesBase

    # ⟨-log N(out | μ, v)⟩ = log(2πv) / 2 + (var(out) + var(μ) + (E[out] - E[μ])²) / 2v.
    @test_average_energy(
        node = ExampleNormal,
        cases = [
            (q = (out = PointMass(1.0), μ = PointMass(1.0), v = PointMass(1.0)),) => log(2π) / 2,
            (q = (out = NormalMeanVariance(1.0, 1.0), μ = NormalMeanVariance(0.0, 2.0), v = PointMass(2.0)),) => (log(4π) + 4 / 2) / 2,
        ],
    )
end

@testitem "rules:ExampleNormal:checks" tags = [:rules] begin
    using ExampleMessagePassingRules, MessagePassingRulesBase, ExponentialFamily, BayesBase

    # A rule's `args_check` raises a `RuleInputError` naming the problem.
    @test_throws MessagePassingRulesBase.RuleInputError call_message_update_rule(ExampleNormal, :out; m = (μ = NormalMeanVariance(0.0, 1.0), v = PointMass(-1.0)))
end
