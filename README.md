# ExampleMessagePassingRules

[![CI](https://github.com/ReactiveBayes/MessagePassingRulesTemplate.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ReactiveBayes/MessagePassingRulesTemplate.jl/actions/workflows/CI.yml)
[![Docs: dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://reactivebayes.github.io/MessagePassingRulesTemplate.jl/dev/)
[![Coverage](https://codecov.io/gh/ReactiveBayes/MessagePassingRulesTemplate.jl/graph/badge.svg)](https://codecov.io/gh/ReactiveBayes/MessagePassingRulesTemplate.jl)
[![Code style: Runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)

<!-- template:start -->
> **This is the template for a message passing rule package.** It is a working package, with one
> example node, laid out as every ReactiveBayes rule package is: rules written with
> [MessagePassingRulesBase](https://github.com/ReactiveBayes/MessagePassingRulesBase.jl), tested
> with [MessagePassingRulesTestUtils](https://github.com/ReactiveBayes/MessagePassingRulesTestUtils.jl)
> down to a gate that fails when a rule has no test, documented with one page per node, and CI,
> documentation, formatting and releases set up.
>
> 1. **Use this template** → *Create a new repository*, named `<Node>MessagePassingRules.jl`.
> 2. Clone it and run, from its root, `julia setup.jl <Node>MessagePassingRules`
>    (`--owner <GitHub owner>`, default `ReactiveBayes`; `--author "Name <email>"`). It renames the
>    package, gives it a new UUID and links, and prints the steps left: replacing the example
>    node, the documentation key, GitHub Pages and registration.
> 3. Write your node and its rules in `src/`, a table of cases for every rule in `test/rules/`, and
>    the node's page in `docs/src/`. `make test` and `make docs` check them as CI does.
>
> MessagePassingRulesBase's guide
> [Your own rule package](https://reactivebayes.github.io/MessagePassingRulesBase.jl/stable/package/)
> walks through each part. Everything between these lines disappears with `setup.jl`.
<!-- template:end -->

The `ExampleNormal` node, a normal distribution with a known variance, `f(out, μ, v) = N(out | μ,
v)`, and its belief propagation and variational rules and average energy. Rules are found by
dispatch, so loading the package is enough for an engine such as
[ReactiveMP](https://github.com/ReactiveBayes/ReactiveMP.jl) to run them.

```julia
using ExampleMessagePassingRules, MessagePassingRulesBase, ExponentialFamily, BayesBase

result = @call_message_update_rule(
    node = ExampleNormal, target = :out,
    m = (μ = NormalMeanVariance(1.0, 2.0), v = PointMass(0.5)),
)
getresult(result)   # NormalMeanVariance(1.0, 2.5): the variances add
```

```julia
import Pkg; Pkg.add("ExampleMessagePassingRules")
```

- Documentation: <https://reactivebayes.github.io/MessagePassingRulesTemplate.jl/dev/>. `make docs`
  builds it locally, into `docs/build`.
- Tests: `make test` runs the suite as CI does, ending with the rule-coverage gate: every rule
  must be selected by some test. `make test test_args="name:rules"` selects items by tag, by
  name or by file; `make help` lists the other targets.
- Julia 1.10 or later. MIT licence.
