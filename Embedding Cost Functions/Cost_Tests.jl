include("Pixel_Weight_Functions.jl")
using .PixelWeights
using Test

@testset "blurred_sunflower" begin
    x = PixelWeights.blurred_noise_calculation("sunflower.png")
   @test x[400,600] > x[1,1]
   @test x[400,600] > x[end,end]
end

@testset "sensitive_sunflower" begin
    x = PixelWeights.colour_sensitivity("sunflower.png")
   @test x[400,600] > x[1,1]
   @test x[400,600] > x[end,end]
end