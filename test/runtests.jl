using FieldDicts
using Documenter: doctest
using Test

@test iterate(FieldDict(nothing)) === nothing

@test first(FieldDict((x=1,))) == Pair(:x, 1)

mutable struct Foo
    x::Int
    y::Float64
    z::Foo

    Foo() = new()
end

x = Foo()
d = FieldDict(x)

d[:x] = 1

@test get!(d, :x, 2) == 1
@test get!(d, :z, x).x == 1

x = Foo()
d = FieldDict(x)

d[:x] = 1

@test get!(() -> 2, d, :x) == 1
@test get(() -> 2, d, :x) == 1
@test get(() -> 2, d, :z) == 2
get!(() -> x, d, :z)
@test x.x == 1

doctest(FieldDicts)

