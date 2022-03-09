using FieldDicts
using Documenter

DocMeta.setdocmeta!(FieldDicts, :DocTestSetup, :(using FieldDicts); recursive=true)

makedocs(;
    modules=[FieldDicts],
    authors="Zachary P. Christensen <zchristensen7@gmail.com> and contributors",
    repo="https://github.com/Tokazama/FieldDicts.jl/blob/{commit}{path}#{line}",
    sitename="FieldDicts.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Tokazama.github.io/FieldDicts.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Tokazama/FieldDicts.jl",
)
