const ICMGate = Tuple{String, Vector{String}}

function compile(circuit::Vector{ICMGate}, gates_to_decompose::Vector{String})
    qubit_dict = Dict()  # mapping from qubit to it's compiled version
    compiled_circuit = []
    ancilla_num = 0
    for gate in circuit
        compiled_qubits = [get(qubit_dict, qubit, qubit) for qubit in gate[2]]

        if gate[1] in gates_to_decompose
            for qubit in compiled_qubits
                new_qubit_name = "anc_$(ancilla_num)"
                ancilla_num += 1

                qubit_dict[qubit] = new_qubit_name
                push!(compiled_circuit, ("CNOT", [qubit, new_qubit_name]))
                @static if false
                    push!(compiled_circuit, ("$(gate[1])_measurement", [qubit]))
                    push!(compiled_circuit, ("Gate_Conditioned_on_$(qubit)_Measurement",
                                             [new_qubit_name]))
                end
            end
        else
            push!(compiled_circuit, (gate[1], compiled_qubits))
        end
    end
    return compiled_circuit
end
