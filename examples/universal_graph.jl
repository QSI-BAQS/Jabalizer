using Revise
using Jabalizer
using Graphs
using GraphPlot
using PythonCall
import Graphs.SimpleGraphs

mbqc_scheduling = pyimport("mbqc_scheduling")
SpacialGraph = pyimport("mbqc_scheduling").SpacialGraph
PartialOrderGraph = pyimport("mbqc_scheduling").PartialOrderGraph

source_filename = "examples/toffoli.qasm"
gates_to_decompose  = ["T", "T_Dagger"]

# Some commented code accessing internal functions that gcompile uses.
# uncomment to play with these methods. 

# qubits, inp_circ = load_icm_circuit_from_qasm(source_filename)
# data = compile(
#     inp_circ,
#     qubits,
#     gates_to_decompose;
#     ptrack=false
# )

# icm_circuit, data_qubits, mseq, frames, frame_flags  = data

# icm_q = Jabalizer.count_qubits(icm_circuit)
# state = zero_state(icm_q)
# Jabalizer.execute_circuit(state, icm_circuit)



data = gcompile(
    source_filename,
    gates_to_decompose;
    universal=true,
    ptrack=true
    )

graph, loc_corr, mseq, input_nodes, output_nodes, frames, frame_flags= data

# graph plot (requires plotting backend)
index = 1
gplot(graph, nodelabel=0:nv(graph)-index)

sparse_rep = SimpleGraphs.adj(graph)

# shift indices for mbqc_scheduling
sparse_rep = [e.-1 for e in sparse_rep]

sparse_rep = SpacialGraph(sparse_rep)

order = frames.get_py_order(frame_flags)
order = PartialOrderGraph(order)
paths = mbqc_scheduling.run(sparse_rep, order)
AcceptFunc = pyimport("mbqc_scheduling.probabilistic").AcceptFunc


# Time optimal path
for path in paths.into_py_paths()
    println("time: $(path.time); space: $(path.space); steps: $(path.steps)")
end



# Full search
full_search_path = mbqc_scheduling.run(
    sparse_rep,
    order; 
    do_search=true, 
    nthreads=3,
    # ,timeout=0
    timeout=1,
    probabilistic = (AcceptFunc(), nothing)
)


for path in full_search_path.into_py_paths()
    println("time: $(path.time); space: $(path.space); steps: $(path.steps)")
end

# println("Input Nodes")
# println(input_nodes)

# println("Output Nodes")
# println(output_nodes)

# println("Local Corrections to internal nodes")
# println(loc_corr)

# println("Measurement order")
# println(mseq[1])

# println("Measurement basis")
# println(mseq[2])
