module FieldDicts

export FieldDict

@static if isdefined(Base, Symbol("@assume_effects"))
    using Base: @assume_effects
else
    macro assume_effects(_, ex)
        :(Base.@pure $(ex))
    end
end

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

@assume_effects :total function _struct_eltype(t::DataType)
    T = Union{}
    for i in 1:fieldcount(t)
        T = Base.promote_typejoin(T, fieldtype(t, i))
    end
    return T
end

Base.parent(@nospecialize(x::FieldDict)) = getfield(x, :parent)

Base.length(x::FieldDict) = length(typeof(x))
Base.length(@nospecialize(T::Type{<:FieldDict})) = fieldcount(fieldtype(T, 1))

@inline function Base.iterate(x::FieldDict{V,P}) where {V,P}
    if fieldcount(P) === 0
        return nothing
    else
        return (Pair{Symbol,V}(fieldname(P, 1), @inbounds(x[1])), 2)
    end
end
@inline function Base.iterate(x::FieldDict{V,P}, state::Int) where {V,P}
    if fieldcount(P) < state
        return nothing
    else
        return (Pair{Symbol,V}(fieldname(P, state), @inbounds(x[state])), state + 1)
    end
end

const FieldValues{V,P} = Base.ValueIterator{FieldDict{V,P}}
@inline function Base.iterate(@nospecialize(x::FieldValues))
    if length(getfield(x, 1)) === 0
        return nothing
    else
        return (getfield(parent(getfield(x, 1)), 1), 2)
    end
end
@inline function Base.iterate(@nospecialize(x::FieldValues), state::Int)
    if length(getfield(x, 1)) < state
        return nothing
    else
        return (getfield(parent(getfield(x, 1)), state), state + 1)
    end
end
Base.keys(x::FieldDict) = keys(typeof(x))
Base.keys(@nospecialize T::Type{<:FieldDict}) = fieldnames(fieldtype(T, 1))

Base.propertynames(x::FieldDict) = keys(x)

@inline Base.getproperty(x::FieldDict, i::Symbol) = getindex(x, i)

@inline Base.setproperty!(x::FieldDict, i::Symbol, v) = setindex!(x, v, i)

Base.@propagate_inbounds Base.getindex(x::FieldDict, i::Union{Symbol,Int}) = getfield(parent(x), i)

Base.@propagate_inbounds Base.setindex!(x::FieldDict, v, i::Union{Int,Symbol}) = setfield!(parent(x), i, v)

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
@inline function Base.get(f::Union{Function,Type}, x::FieldDict{V,P}, s::Symbol) where {V,P}
    p = getfield(x, 1)
    i = Base.fieldindex(P, s, false)
    if isdefined(p, i)
        return getfield(p, i)
    else
        return f()
    end
end
@inline function Base.get!(f::Union{Function,Type}, x::FieldDict{V,P}, s::Symbol) where {V,P}
    p = getfield(x, 1)
    i = Base.fieldindex(P, s, false)
    if isdefined(p, i)
        return getfield(p, i)
    else
        default = f()
        setfield!(p, i, default)
        return default
    end
end

end
