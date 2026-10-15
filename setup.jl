# Makes your rule package from this template. Run it once, from the repository's root, right after
# creating the repository from the template:
#
#     julia setup.jl FooMessagePassingRules [--owner ReactiveBayes] [--author "Name <email>"]
#
# It renames the package and its files, gives it a new UUID, points every link at
# github.com/<owner>/FooMessagePassingRules.jl, resets the changelog and the licence's copyright,
# removes what only the template needs, this script included, and prints what is left to do.
# It uses only Julia's standard library.

using UUIDs, Dates

const TEMPLATE_NAME = "ExampleMessagePassingRules"
const TEMPLATE_REPOSITORY = "MessagePassingRulesTemplate"
const TEMPLATE_OWNER = "ReactiveBayes"
const TEMPLATE_UUID = "f8284307-013f-4268-b681-58725be9a29a"
const ROOT = @__DIR__

function usage(message)
    println(stderr, message)
    println(stderr, "usage: julia setup.jl <PackageName> [--owner <GitHub owner>] [--author \"Name <email>\"]")
    return exit(1)
end

function parse_arguments(arguments)
    name, owner, author = nothing, TEMPLATE_OWNER, nothing
    index = 1
    while index <= length(arguments)
        argument = arguments[index]
        if argument in ("--owner", "--author")
            index < length(arguments) || usage("$(argument) needs a value")
            argument == "--owner" ? (owner = arguments[index + 1]) : (author = arguments[index + 1])
            index += 2
        elseif startswith(argument, "--")
            usage("unknown option $(argument)")
        else
            name === nothing || usage("one package name only")
            name = endswith(argument, ".jl") ? argument[1:(end - 3)] : argument
            index += 1
        end
    end
    name === nothing && usage("the package name is missing")
    Base.isidentifier(name) || usage("`$(name)` is not a valid Julia identifier")
    name == TEMPLATE_NAME && usage("choose a name of your own")
    endswith(name, "MessagePassingRules") ||
        @warn "Rule packages are named `<Node>MessagePassingRules`, `$(name)` is not; continuing"
    return name, owner, author
end

# Every file the template tracks, as git would list it, without the build output.
function text_files()
    files = String[]
    for (directory, subdirectories, names) in walkdir(ROOT)
        filter!(subdirectory -> !(subdirectory in (".git", "build")), subdirectories)
        for name in names
            path = joinpath(directory, name)
            path == joinpath(ROOT, "setup.jl") && continue
            content = read(path, String)
            isvalid(content) && push!(files, path)
        end
    end
    return files
end

# Removes every block between a `template:start` and a `template:end` line, both included, with
# the blank line after it, and ends the file with one newline.
remove_template_blocks(content) =
    rstrip(replace(content, r"[^\n]*template:start.*?template:end[^\n]*\n\n?"s => "")) * "\n"

function main(arguments)
    name, owner, author = parse_arguments(arguments)
    isfile(joinpath(ROOT, "src", "$(TEMPLATE_NAME).jl")) || usage("the template has already been set up")

    replacements = [
        "$(TEMPLATE_OWNER)/$(TEMPLATE_REPOSITORY).jl" => "$(owner)/$(name).jl",
        "$(lowercase(TEMPLATE_OWNER)).github.io/$(TEMPLATE_REPOSITORY).jl" => "$(lowercase(owner)).github.io/$(name).jl",
        TEMPLATE_NAME => name,
        TEMPLATE_UUID => string(uuid4()),
    ]
    for path in text_files()
        content = read(path, String)
        updated = remove_template_blocks(replace(content, replacements...))
        updated == content || write(path, updated)
    end

    mv(joinpath(ROOT, "src", "$(TEMPLATE_NAME).jl"), joinpath(ROOT, "src", "$(name).jl"))

    holder = something(author, "$(owner) and contributors")
    project = joinpath(ROOT, "Project.toml")
    write(project, replace(read(project, String), r"^authors = .*$"m => "authors = [$(repr(holder))]"))
    license = joinpath(ROOT, "LICENSE")
    write(license, replace(read(license, String), r"^Copyright \(c\) .*$"m => "Copyright (c) $(year(today())) $(holder)"))

    rm(joinpath(ROOT, "setup.jl"))

    println(
        """
        $(name) is ready. What is left:

        1. Replace the example node, `ExampleNormal`, with your own: src/$(name).jl,
           test/rules/, docs/src/index.md and the README. Run `make test` and `make docs`.
        2. Commit and push to github.com/$(owner)/$(name).jl.
        3. Give the repository a `DOCUMENTER_KEY` secret, a deploy key with write access, so the
           documentation deploys and CompatHelper's pull requests run CI:
           `julia -e 'using DocumenterTools; DocumenterTools.genkeys(user = "$(owner)", repo = "$(name).jl")'`.
        4. Settings → Pages: deploy from the `gh-pages` branch, once the first build has made it.
        5. Register a release by commenting `@JuliaRegistrator register` on its commit, with the
           JuliaRegistrator app installed for the repository; TagBot then tags it.
        """
    )
    return nothing
end

main(ARGS)
