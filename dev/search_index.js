var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = FieldDicts","category":"page"},{"location":"#FieldDicts","page":"Home","title":"FieldDicts","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for FieldDicts.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [FieldDicts]","category":"page"},{"location":"#FieldDicts.FieldDict","page":"Home","title":"FieldDicts.FieldDict","text":"FieldDict{V}(x) <: AbstractDict{Symbol,V}\n\nWraps x and provides access to its fields through a dictionary interface. The resulting key value pairs correspond to x's field names and respective values.\n\nExamples\n\njulia> using FieldDicts\n\njulia> mutable struct Foo\n           x::Int\n           y::Float64\n       end\n\njulia> x = Foo(1, 2);\n\njulia> d = FieldDict(x)\nFieldDict{Real, Foo} with 2 entries:\n  :x => 1\n  :y => 2.0\n\n\nThe keys and properties are the same as the underlying structures field names.\n\njulia> keys(d) == propertynames(d) == (:x, :y)\ntrue\n\n\nThese fields can be accessed via indexing or the dot-property notation.\n\njulia> d[:x] = 1;\n\njulia> d.x == d[:x] == 1\ntrue\n\n\n\n\n\n\n","category":"type"}]
}
