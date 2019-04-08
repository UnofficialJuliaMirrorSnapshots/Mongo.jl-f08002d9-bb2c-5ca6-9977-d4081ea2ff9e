
mutable struct MongoCursor
    _wrap_::Ptr{Void}

    MongoCursor(_wrap_::Ptr{Void}) = begin
        cursor = new(_wrap_)
        finalizer(cursor, destroy)
        return cursor
    end
end
export MongoCursor

# Iterator

Base.start(cursor::MongoCursor) = nothing

Base.next(cursor::MongoCursor, state::Void) =
    (BSONObject(ccall(
        (:mongoc_cursor_current, libmongoc),
        Ptr{Void}, (Ptr{Void},),
        cursor._wrap_
        ), Union{}), state)

function Base.done(cursor::MongoCursor, state::Void)
    return !ccall(
        (:mongoc_cursor_next, libmongoc),
        Bool, (Ptr{Void}, Ptr{Ptr{Void}}),
        cursor._wrap_,
        Array{Ptr{Void}}(1)
        )
end

Base.iteratorsize(::Type{MongoCursor}) = Base.SizeUnknown()
Base.eltype(::Type{MongoCursor}) = BSONObject

destroy(collection::MongoCursor) =
    ccall(
        (:mongoc_cursor_destroy, libmongoc),
        Void, (Ptr{Void},),
        collection._wrap_
        )
