module FieldDicts

export FieldDict

"""
    FieldDicts.FieldsOf(T::Type)

Wrapper around type `T` that treats each of its field as an element in a collection.

```jldoctest
julia> using FieldDicts

julia> fot = FieldDicts.FieldsOf(@NamedTuple{one::Int64, two::String})
FieldDicts.FieldsOf(@NamedTuple{one::Int64, two::String})

julia> propertynames(fot)
(:one, :two)

julia> fot.one
FieldDicts.FieldsOf(@NamedTuple{one::Int64, two::String}).one

julia> fot.one.type
Int64

julia> fot.one.name
:one
```
"""
struct FieldsOf{T}
    function FieldsOf{T}() where {T}
        @assert isstructtype(T)
        new{T}()
    end
    FieldsOf(T::Union{DataType, UnionAll}) = FieldsOf{T}()
end

Base.@assume_effects :nothrow (::FieldsOf{T})() where {T} = T::Union{DataType, UnionAll}

Base.@assume_effects :nothrow Base.length(fot::FieldsOf) = fieldcount(fot())

Base.propertynames(fot::FieldsOf) = fieldnames(fot())

struct FieldIndex{P}
    parent::P
    index::Int

    function Base.getproperty(x::FieldsOf, s::Symbol)
        T = x()
        i = Base.fieldindex(T, s, false)
        @boundscheck (i === 0) && throw(UndefVarError(s))
        new{typeof(x)}(x, i)
    end
    function Base.getproperty(x::FieldsOf, i::Int)
        T = x()
        @boundscheck (1 <= i <= fieldcount(T)) || throw(BoundsError(x, i))
        new{typeof(x)}(x, i)
    end
    function Base.iterate(x::FieldsOf, i::Int=1)
        if length(x) < i
            return nothing
        else
            return (new{typeof(x)}(x, i), i + 1)
        end
    end
end

Base.@propagate_inbounds Base.getindex(x::FieldsOf, i::Union{Int, Symbol}) = getproperty(x, i)

Base.propertynames(@nospecialize(x::FieldIndex)) = (:index, :parent, :name, :type)

@inline function Base.getproperty(x::FieldIndex, s::Symbol)
    if s === :index
        return getfield(x, :index)
    elseif s === :parent
        return getfield(x, :parent)
    elseif s === :name
        return getfield(propertynames(x.parent), x.index, false)
    elseif s === :type
        return getfield(fieldtypes(x.parent()), x.index, false)
    else
        throw(UndefVarError(s))
    end
end

Base.isless(x::FieldIndex{T}, y::FieldIndex{T}) where {T} = isless(x.index, y.index)

Base.@assume_effects :total function _struct_eltype(t::DataType)
    T = Union{}
    for i in 1:fieldcount(t)
        T = Base.promote_typejoin(T, fieldtype(t, i))
    end
    return T
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
struct FieldDict{V, P} <: AbstractDict{Symbol, V}
    parent::P

    FieldDict{V, P}(p) where {V, P} = new{V, P}(p)
    FieldDict{V}(p::P) where {V, P} = FieldDict{V, P}(p)
    FieldDict(p::P) where {P} = FieldDict{_struct_eltype(P)}(p)
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
@inline function Base.iterate(x::FieldDict{V, P}, state::Int) where {V, P}
    if fieldcount(P) < state
        return nothing
    else
        return (Pair{Symbol, V}(fieldname(P, state), @inbounds(x[state])), state + 1)
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
@inline Base.getproperty(x::FieldDict, i::Symbol, o::Symbol) = getindex(x, i, o)

@inline Base.setproperty!(x::FieldDict, i::Symbol, v) = setindex!(x, v, i)
@inline Base.setproperty!(x::FieldDict, i::Symbol, v, o::Symbol) = setindex!(x, v, i, o)

Base.swapproperty!(x::FieldDict, i::Symbol, v) = swapfield!(getfield(x, 1), i, v)
function Base.swapproperty!(x::FieldDict, i::Symbol, v, o::Symbol)
    swapfield!(getfield(x, 1), i, v, o)
end

function Base.modifyproperty!(x::FieldDict, i::Symbol, op, v)
    modifyfield!(getfield(x, 1), i, op, v)
end
function Base.modifyproperty!(x::FieldDict, i::Symbol, op, v, o::Symbol)
    modifyfield!(getfield(x, 1), i, op, v, o)
end

function Base.replaceproperty!(x::FieldDict, i::Symbol, e, d)
    replacefield!(getfield(x, 1), i, e, d)
end
function Base.replaceproperty!(x::FieldDict, i::Symbol, e, d, so::Symbol, fo::Symbol)
    replacefield!(getfield(x, 1), i, e, d, so, fo)
end

Base.@propagate_inbounds function Base.getindex(x::FieldDict, i::Union{Symbol,Int})
    getfield(parent(x), i)
end

Base.@propagate_inbounds function Base.setindex!(x::FieldDict, v, i::Union{Int,Symbol})
    setfield!(parent(x), i, v)
end

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

@nospecialize
function Base.showarg(io::IO, fot::FieldsOf, toplevel)
    print(io, FieldsOf)
    print(io, "(")
    print(io, fot())
    print(io, ")")
end
Base.show(io::IO, ::MIME"text/plain", fot::FieldsOf) = Base.showarg(io, fot, true)
function Base.show(io::IO, m::MIME"text/plain", idx::FieldIndex)
    Base.showarg(io, idx.parent, false)
    name = idx.name
    if name isa Int
        print(io, ".:")
    else
        print(io, ".")
    end
    print(io, name)
end
@specialize

end
