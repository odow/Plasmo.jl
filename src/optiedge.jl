"""
    LinkConstraint{F <: JuMP.AbstractJuMPScalar,S <: MOI.AbstractScalarSet} <: AbstractLinkConstraint

Type inherits JuMP.AbstractConstraint.  Contains a func and set used to describe coupling between optinodes.

    LinkConstraint(con::JuMP.ScalarConstraint)

Creates a linking constraint from a JuMP.ScalarConstraint.

    LinkConstraint(ref::LinkConstraintRef)

Retrieves a linking constraint from a LinkConstraintRef.
"""
mutable struct LinkConstraint{F <: JuMP.AbstractJuMPScalar,S <: MOI.AbstractScalarSet} <: AbstractLinkConstraint
    func::F
    set::S
    attached_node::Union{Nothing,OptiNode}
end
LinkConstraint(con::JuMP.ScalarConstraint) = LinkConstraint(con.func,con.set,nothing)

function set_attached_node(con::LinkConstraint,node::OptiNode)
    @assert node in getnodes(con)
    con.attached_node = node
end
##############################################################################
# OptiEdges
# OptiEdges describe connections between model nodes
##############################################################################
"""
    OptiEdge

The `OptiEdge` type.  Typically created from [`@linkconstraint`](@ref).  Contains the set of its supporting optionodes, as well as
references to its underlying linking constraints.
"""
mutable struct OptiEdge <: AbstractOptiEdge
    nodes::OrderedSet{OptiNode}
    dual_values::DefaultDict{Symbol,Dict{Int64,Float64}}

    #Link references
    linkrefs::Vector{AbstractLinkConstraintRef}

    #Link constraints
    linkconstraints::OrderedDict{Int64,LinkConstraint}
    linkconstraint_names::Dict{Int64,String}
    idx_maps::DefaultDict{Symbol,OrderedDict{AbstractLinkConstraintRef,MOI.ConstraintIndex}}

    #Last result id from an optimize!(graph)
    last_solution_id::Union{Nothing,Symbol}

    #TODO Someday
    #Capture nonlinear linking constraints
    #nlp_data::Union{Nothing,JuMP._NLPData}
end

struct LinkConstraintRef <: AbstractLinkConstraintRef
    idx::Int # index in optiedge
    optiedge::OptiEdge
end
LinkConstraint(ref::LinkConstraintRef) = JuMP.owner_model(ref).linkconstraints[ref.idx]

OptiEdge() = OptiEdge(OrderedSet{OptiNode}(),
                DefaultDict{Symbol,Dict{LinkConstraint,Float64}}(Dict{Int64,Float64}()),
                Vector{LinkConstraintRef}(),
                OrderedDict{Int, LinkConstraint}(),
                OrderedDict{Int64,String}(),
                DefaultDict{Symbol,OrderedDict{LinkConstraintRef,MOI.ConstraintIndex}}(OrderedDict{LinkConstraintRef,MOI.ConstraintIndex}()),
                nothing)

function OptiEdge(nodes::Vector{OptiNode})
    optiedge = OptiEdge()
    optiedge.nodes = OrderedSet(nodes)
    return optiedge
end

JuMP.owner_model(cref::LinkConstraintRef) = cref.optiedge
JuMP.jump_function(constraint::LinkConstraint) = constraint.func
JuMP.moi_set(constraint::LinkConstraint) = constraint.set
JuMP.shape(::LinkConstraint) = JuMP.ScalarShape()
function JuMP.constraint_object(cref::LinkConstraintRef, F::Type, S::Type)
   con = cref.optiedge.linkconstraints[cref.idx]
   con.func::F
   con.set::S
   return con
end
JuMP.set_name(cref::LinkConstraintRef, s::String) = JuMP.owner_model(cref).linkconstraint_names[cref.idx] = s
JuMP.name(con::LinkConstraintRef) =  JuMP.owner_model(con).linkconstraint_names[con.idx]

function MOI.delete!(cref::LinkConstraintRef)
    delete!(cref.optiedge.linkconstraints, cref.idx)
    delete!(cref.optiedge.linkconstraint_names, cref.idx)
end
MOI.is_valid(cref::LinkConstraintRef) = haskey(cref.idx,cref.optiedge.linkconstraints)

getnodes(con::JuMP.ScalarConstraint) = [getnode(var) for var in keys(con.func.terms)]
getnodes(con::LinkConstraint) = [getnode(var) for var in keys(con.func.terms)]
getnodes(cref::LinkConstraintRef) = getnodes(cref.optiedge)
num_nodes(con::LinkConstraint) = length(getnodes(con))
getname(cref::LinkConstraintRef) = cref.optiedge.linkconstraint_names[cref.idx]

JuMP.constraint_object(linkref::LinkConstraintRef) = linkref.optiedge.linkconstraints[linkref.idx]

function JuMP.dual(linkref::LinkConstraintRef)
    optiedge = JuMP.owner_model(linkref)
    id = optiedge.last_solution_id
    link_idx = linkref.idx
    return optiedge.dual_values[id][link_idx]
end


num_linkconstraints(edge::OptiEdge) = length(edge.linkconstraints)
getlinkconstraints(edge::OptiEdge) = values(edge.linkconstraints)
getnodes(edge::OptiEdge) = edge.nodes


function Base.string(edge::OptiEdge)
    "OptiEdge w/ $(length(edge.linkconstraints)) Constraint(s)"
end
Base.print(io::IO,edge::OptiEdge) = print(io, string(edge))
Base.show(io::IO,edge::OptiEdge) = print(io,edge)

function Base.string(con::AbstractLinkConstraint)
    "LinkConstraint: $(con.func), $(con.set)"
end
Base.print(io::IO,con::AbstractLinkConstraint) = print(io, string(con))
Base.show(io::IO,con::AbstractLinkConstraint) = print(io,con)

function JuMP.constraint_string(mode::Any,ref::LinkConstraintRef)
    con = JuMP.constraint_object(ref)
    return "$(getname(ref)): $(con.func) $(JuMP.in_set_string(mode,con.set))"
end

function Base.show(io::IO, ref::LinkConstraintRef)
    print(io, JuMP.constraint_string(JuMP.REPLMode, ref))
end
function Base.show(io::IO, ::MIME"text/latex", ref::LinkConstraintRef)
    print(io, JuMP.constraint_string(JuMP.IJuliaMode, ref))
end
