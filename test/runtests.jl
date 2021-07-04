using PlasmoPlots
using Test

@testset "PlasmoPlots.jl" begin
    @testset "$(file)" for file in filter(f -> endswith(f, ".jl"), readdir(@__DIR__))
        if file == "runtests.jl"
            continue
        end
        include(file)
    end
end
