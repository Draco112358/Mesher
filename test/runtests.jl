using Test

@testset "Mesher Tests" begin

    @testset "Grids Generation Tests" begin
        include("./gridsGen.jl")
    end

    # @testset "AWS Load And Storage Tests" begin
    #     include("./aws_load_storage.jl")
    # end
end