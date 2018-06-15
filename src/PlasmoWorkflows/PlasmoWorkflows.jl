module PlasmoWorkflows

#include("../PlasmoGraphBase/PlasmoGraphBase.jl")
using ..PlasmoGraphBase
import PlasmoGraphBase:create_node,create_edge,add_edge!,addattributes!#,getattribute,getattributes,

import LightGraphs.DiGraph
import DataStructures
import Base:isless,step,==,show,print,string,getindex

#State manager functions
export AbstractSignal,AbstractEvent,SerialExecutor,

StateManager,SignalCoordinator,SignalEvent,

State,Signal,DataSignal,Transition,TransitionAction,

addstate!,addsignal!,addtransition!,addbroadcasttarget!,

setstate,schedulesignal,step,

getsignals,getstates,getinitialsignal,getcurrentstate,gettransitionfunction,gettransitions,gettransition,


#WORKFLOWS

Workflow, DispatchNode, CommunicationEdge,

#Workflow functions

initialize,

add_dispatch_node!,add_continuous_node!,

set_node_task,set_node_task_arguments,set_node_compute_time,

addnodetask!,getnodetask,getnodetasks,

#Attributes
addworkflowattribute!,

getworkflowattribute,setworkflowattribute,

getworkflowattributes,

getlocalvalue,getglobalvalue,getvalue,getnoderesult,

#Workflow
getcurrenttime,getnexttime,getnexteventtime,initialize,execute!,getqueue,

#Dispatch Nodes
set_node_function,set_node_compute_time,set_node_function_arguments,set_node_function_kwargs,
getresult,setinputs,getlocaltime,setinitialsignal,getlabel,addtrigger!,

#Communication Edges
connect!,setdelay,getdelay


abstract type AbstractWorkflow <: AbstractPlasmoGraph end
abstract type AbstractDispatchNode <: AbstractPlasmoNode end
abstract type AbstractCommunicationEdge  <: AbstractPlasmoEdge end
abstract type AbstractChannel  end


abstract type AbstractEvent end
abstract type AbstractSignal end
abstract type AbstractStateManager end
abstract type AbstractSignalCoordinator end

const SignalTarget = AbstractStateManager
# #Events can be: Event, Condition, Delay, Communicate, etc...
# abstract type AbstractWorkflowEvent <: AbstractEvent end   #General Events
# abstract type AbstractNodeEvent <: AbstractEvent end       #Events triggered by nodes
# abstract type AbstractEdgeEvent <: AbstractEvent end

#State Manager and Coordination
include("state_manager/signal_event.jl")
include("state_manager/state_manager.jl")
include("state_manager/signal_coordinator.jl")
include("state_manager/signal_executor.jl")
include("state_manager/signal_print.jl")

#Workflow Graph

#Node Tasks
include("node_task.jl")

#Workflow Attributes
include("attribute.jl")

#Node and Edge Transition Actions
include("actions.jl")

#The workflow Graph
include("workflow_graph.jl")
#
#Edges for communication between nodes
include("communication_edges.jl")
#
#Discrete and continuous dispatch nodes
include("dispatch_nodes.jl")
#
# #Workflow execution
include("workflow_executor.jl")

# function gettransitionactions()
#     return schedule_node,run_node_task
# end

end # module
