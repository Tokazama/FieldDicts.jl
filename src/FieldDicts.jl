module FieldDicts

export FieldDict

"""
    FieldDict{V}(x) <: AbstractDict{Symbol,V}

Wraps `x` and provides access to its fields through a dictionary interface. The resulting
key value pairs correspond to `x`'s field names and respective values.

# Examples

```jldoctest fielddict_docstring
julia> using FieldDicts

julia> mutable struct Foo
           x::Int
           y::Float64
       end

julia> x = Foo(1, 2);

julia> d = FieldDict(x)
FieldDict{Real, Foo} with 2 entries:
  :x => 1
  :y => 2.0

```

The keys and properties are the same as the underlying structures field names.
```jldoctest fielddict_docstring
julia> keys(d) == propertynames(d) == (:x, :y)
true

```

The values are similarly accessible through the dictionary interface.
```jldoctest fielddict_docstring
julia> collect(values(d)) == [1, 2]
true

```

These fields can be accessed via traditional dictionary-like access or the dot-property notation.
```jldoctest fielddict_docstring
julia> d[:x] = 1;

julia> d.x == d[:x] == 1
true

julia> get(d, :y, 3)
2.0

julia> get(d, :z, 3)
3

```

"""
struct FieldDict{V,P} <: AbstractDict{Symbol,V}
    parent::P

    FieldDict{V,P}(p) where {V,P} = new{V,P}(p)
    FieldDict{V}(p::P) where {V,P} = FieldDict{V,P}(p)
    FieldDict(p::P) where {P} = FieldDict{_struct_eltype(P)}(p)
end

Base.parent(x::FieldDict) = getfield(x, :parent)

Base.length(x::FieldDict{V,P}) where {V,P} = fieldcount(P)

_struct_eltype(::Type{T}) where {T} = __struct_eltype(T, Val(fieldcount(T)))
@generated function __struct_eltype(T::DataType, ::Val{N}) where {N}
    if N === 0
        return :Any
    elseif N === 1
        return :(fieldtype(T, 1))
    else
        out = :(fieldtype(T, 1))
        for i in 2:N
            out = :(typejoin($out, fieldtype(T, $i)))
        end
        return Expr(:block, Expr(:meta, :inline), out)
    end
end

@inline function Base.iterate(x::FieldDict{V,P}) where {V,P}
    if fieldcount(P) === 0
        return nothing
    else
        return (Pair{Symbol,V}(fieldname(P, 1), getfield(getfield(x, :parent), 1)), 2)
    end
end
@inline function Base.iterate(x::FieldDict{V,P}, state::Int) where {V,P}
    if fieldcount(P) < state
        return nothing
    else
        return (Pair{Symbol,V}(fieldname(P, state), getfield(getfield(x, :parent), state)), state + 1)
    end
end

const FieldValues{V,P} = Base.ValueIterator{FieldDict{V,P}}
@inline function Base.iterate(x::FieldValues{V,P}) where {V,P}
    if fieldcount(P) === 0
        return nothing
    else
        return (getfield(getfield(getfield(x, :dict), :parent), 1), 2)
    end
end
@inline function Base.iterate(x::FieldValues{V,P}, state::Int) where {V,P}
    if fieldcount(P) < state
        return nothing
    else
        return (getfield(getfield(getfield(x, :dict), :parent), state), state + 1)
    end
end

Base.keys(x::FieldDict{V,P}) where {V,P} = fieldnames(P)

Base.propertynames(x::FieldDict) = keys(x)

@inline Base.getproperty(x::FieldDict, s::Symbol) = getfield(getfield(x, :parent), s)

@inline Base.setproperty!(x::FieldDict, s::Symbol, v) = setfield!(getfield(x, :parent), s, v)

@inline Base.getindex(x::FieldDict, s::Symbol) = getproperty(x, s)

@inline Base.setindex!(x::FieldDict, v, s::Symbol) = setproperty!(x, s, v)

@inline function Base.get(x::FieldDict{V,P}, s::Symbol, default) where {V,P}
    p = getfield(x, 1)
    i = Base.fieldindex(P, s, false)
    if isdefined(p, i)
        return getfield(p, i)
    else
        return default
    end
end
@inline function Base.get!(x::FieldDict{V,P}, s::Symbol, default) where {V,P}
    p = getfield(x, 1)
    i = Base.fieldindex(P, s, false)
    if isdefined(p, i)
        return getfield(p, i)
    else
        setfield!(p, i, default)
        return default
    end
end

end
