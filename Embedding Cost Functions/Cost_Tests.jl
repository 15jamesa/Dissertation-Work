include("Pixel_Weight_Functions.jl")
using .PixelWeights
using Test
using Images

@testset "blurred_sunflower" begin
    y = load("sunflower.png")
    x = PixelWeights.blurred_noise_calculation(y)
   @test x[400,600] > x[1,1]
   @test x[400,600] > x[end,end]
end

@testset "sensitive_sunflower" begin
    y = load("sunflower.png")
    x = PixelWeights.colour_sensitivity(y)
   @test x[400,600] > x[1,1]
   @test x[400,600] > x[end,end]
end

@testset "pad" begin
    #odd dimensions
    @test parent(PixelWeights.add_padding([1 1 1; 1 1 1; 1 1 1])) == [1 1 1 1 1 1 1; 1 1 1 1 1 1 1; 1 1 1 1 1 1 1; 1 1 1 1 1 1 1; 1 1 1 1 1 1 1; 1 1 1 1 1 1 1; 1 1 1 1 1 1 1]
    #even dimensions
    @test parent(PixelWeights.add_padding([1 1 1 1; 1 1 1 1; 1 1 1 1; 1 1 1 1])) == [1 1 1 1 1 1 1 1; 1 1 1 1 1 1 1 1; 1 1 1 1 1 1 1 1; 1 1 1 1 1 1 1 1; 1 1 1 1 1 1 1 1; 1 1 1 1 1 1 1 1; 1 1 1 1 1 1 1 1; 1 1 1 1 1 1 1 1]
end

@testset "unpad" begin
    #odd dimensions
    @test PixelWeights.remove_padding(PixelWeights.add_padding([1 1 1; 1 1 1; 1 1 1])) == [1 1 1; 1 1 1; 1 1 1]
    #even dimensions
    @test PixelWeights.remove_padding(PixelWeights.add_padding([1 1 1 1; 1 1 1 1; 1 1 1 1; 1 1 1 1])) == [1 1 1 1; 1 1 1 1; 1 1 1 1; 1 1 1 1]
end