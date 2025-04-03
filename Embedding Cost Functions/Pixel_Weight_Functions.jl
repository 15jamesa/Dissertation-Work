module PixelWeights

using ImageCore, Images, ImageFiltering, ColorTypes
cd("./Embedding Cost Functions/")

function blurred_noise_calculation(image_path)
    rgb = load(image_path)
    grey = Gray.(rgb)
    blurred = imfilter(grey, Kernel.gaussian(5))
    noise = abs.(Float64.(grey - blurred))

    return noise
end

function colour_sensitivity(image_path)
    rgb = load(image_path)
    g = Float64.(green.(rgb))
    b = Float64.(blue.(rgb))
    sensitivity = g - b
    
    return sensitivity
end

println(colour_sensitivity("sunflower.png"))
end