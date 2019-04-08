
__precompile__(true)
module Mongo

@static if VERSION < v"0.7-"
    const Nothing = Void
    const Cvoid   = Void
end

const deps_script = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(deps_script)
    error("Mongo.jl is not installed properly, run Pkg.build(\"Mongo\") and restart Julia.")
end
include(deps_script)
check_deps()

using LibBSON

ccall(
    (:mongoc_init, libmongoc),
    Cvoid, ()
    )

atexit() do
    ccall((:mongoc_cleanup, libmongoc), Cvoid, ())
end

const NakedDict = Union{Pair,Tuple}

include("MongoClient.jl")
include("MongoCollection.jl")
include("MongoCursor.jl")
include("query.jl")

end
