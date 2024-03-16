using Jabalizer

# input_file = "examples/mwe.qasm"
input_file = "examples/toffoli.qasm"
outfile = "examples/qasm_out.qasm"

graph, loc_corr, mseq, data_qubits, frames_array = gcompile(input_file;
                                                        universal=true,
                                                         ptracking=true
)

frames, frame_flags = frames_array
outqubits =  data_qubits[:output] .- 1
qubits = [q for q in frame_flags]
# we want to find pauli corrections for measured and output qubits
append!(qubits, outqubits)

# pauli_corrections translates frame information
# into pauli correction information for the specified qubits
pc = Jabalizer.pauli_corrections(frames, frame_flags, qubits);
display(pc)


# qasm_instruction generates a qasm file which generates the graph
# state, applies local corrections, applies pauli corrections and
# measurements and writes it to outfile. 
qasm_instruction(outfile, graph, loc_corr, mseq, data_qubits, frames_array);


