"""
    Stabilizer state type.

qubits: number of qubits.
stabilizers: set of state stabilizers.
labels: qubit labels.

simulator: stim simulator
"""
mutable struct StabilizerState
    qubits::Int
    stabilizers::Vector{Stabilizer}
    labels::Vector{String} # TODO: might not be needed anymore
    lost::Vector{Int} # TODO: might not be needed anymore
    simulator::Py
    updated::Bool

    StabilizerState(n::Int) = new(n, Stabilizer[], String[], Int[], stim.TableauSimulator(), true)
    StabilizerState() = StabilizerState(0)
end

const Tableau = Matrix{Int}

"""
    ZeroState(n::Int)

Generates a state of n qubits in the +1 Z eigenstate.
"""
function ZeroState(n::Int)
    state = StabilizerState(n)
    for i in 0:n-1
        state.simulator.z(i)
    end
    state.updated = false
    update_tableau(state)
    return state
end

# This function is problematic with the stim integration
# This doesn't seem to affect the simulator state at all
"""
Generate stabilizer from tableau
"""
function TableauToState(tab::AbstractMatrix{Int})::StabilizerState
    qubits = Int((length(@view tab[1, :]) - 1) / 2)
    stabs = Int(length(@view tab[:, 1]))
    state = StabilizerState(qubits)

    for row = 1:stabs
        stab = Stabilizer(@view tab[row, :])
        push!(state.stabilizers, stab)
    end

    for n = 1:qubits
        push!(state.labels, string(n))
    end

    return state
end

"""
    ToTableau(state)

Convert state to tableau form.
"""
function ToTableau(state::StabilizerState)::Tableau
    tab = Int[]
    update_tableau(state)
    for s in state.stabilizers
        tab = vcat(tab, ToTableau(s))
    end

    tab = Array(transpose(reshape(
        tab,
        2 * state.qubits + 1,
        length(state.stabilizers),
    )))

    return tab
end

"""
    string(state)

Convert state to string.
"""
function Base.string(state::StabilizerState)
    str = ""

    for s in state.stabilizers
        str = string(str, string(s), '\n')
    end

    return str
end

"""
    print(state)

Print the full stabilizer set of a state to the terminal.
"""
function Base.print(state::StabilizerState, info::Bool=false, tab::Bool=false)
    update_tableau(state)
    if info == true
        println(
            "Stabilizers (",
            length(state.stabilizers),
            " stabilizers, ",
            state.qubits,
            " qubits):\n")
    end

    if tab == false
        for s in state.stabilizers
            print(s)
        end
    else
        print(ToTableau(state))
    end

    println()

    if info == true
        println("Qubit labels: ", state.labels)
        println("Lost qubits: ", state.lost)
    end
end

"""
    gplot(state)

Plot the graph equivalent of a state.
"""
function gplot(state::StabilizerState; node_dist=5.0)
    graphState = GraphState(state)
    # Creates an anonymous function to allow changing the layout params
    # in gplot. The value of C determines distance between connected nodes.
    layout = (args...) -> spring_layout(args...; C=node_dist)
    gplot(Graph(graphState.A), nodelabel=1:state.qubits, layout=layout)
end


# TODO: This is confusing, as it takes adjacency matrix and not graph.
function GraphToState(A::AbstractMatrix{Int})::StabilizerState
    n = size(A, 1)
    state = ZeroState(n)

    for i = 1:n
        H(state, i)
    end

    for i = 1:n
        for j = (i+1):n
            if A[i, j] == 1
                CZ(state, i, j)
            end
        end
    end
    update_tableau(state)
    return state
end


"""
    isequal(state_1::StabilizerState, state_2::StabilizerState)

Checks if two stabilizer states are equal.
"""
function Base.isequal(state_1::StabilizerState, state_2::StabilizerState)
    # TODO: it seems that we're updating states during the check for equality, which is weird...
    update_tableau(state_1)
    update_tableau(state_2)
    check = []
    for (stab1, stab2) in zip(state_1.stabilizers, state_2.stabilizers)
        push!(check, stab1.X == stab2.X)
        push!(check, stab1.Z == stab2.Z)
        push!(check, stab1.phase == stab2.phase)
    end

    return all(check)
end
