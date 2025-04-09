module PixelWeights

using ImageCore, Images, ImageFiltering, ColorTypes, ImageEdgeDetection, FFTW, Statistics, DSP

cd("./Embedding Cost Functions/")

function blurred_noise_calculation(image_path)
    rgb = load(image_path)
    grey = Float64.(Gray.(rgb))
    blurred = imfilter(grey, Kernel.gaussian(5))
    noise = abs.(grey - blurred)

    return noise
end

function colour_sensitivity(image_path)
    rgb = load(image_path)
    g = Float64.(green.(rgb))
    b = Float64.(blue.(rgb))
    sensitivity = g - b
    
    return sensitivity
end

function canny_edge_detection(image_path)
    img = load(image_path)
    edges = detect_edges(img, Canny() )
    weighted = Float64.(Gray.(edges))

    return weighted
end

#need to pad with mirroring for fft?
function fourier_lowpass_filtering(image_path)
    img = load(image_path)
    greyscale = Float64.(Gray.(img))
    transformed = fft(greyscale)

    #Struggling with filter parameters
    response = Lowpass(0.5)
    design = FIRWindow(hanning(64))
    filtered = zeros(Complex{Float64},size(transformed))
    filt!(filtered, digitalfilter(response, design; fs=1), transformed)

    retransformed = real.(ifft(filtered))
    noise = abs.(greyscale - retransformed)

    return noise
end

function fourier_highpass_filtering(image_path)
    img = load(image_path)
    greyscale = Float64.(Gray.(img))
    transformed = fft(greyscale)

    #Struggling with filter parameters
    response = Highpass(0.4)
    design = FIRWindow(hanning(64))
    filtered = zeros(Complex{Float64},size(transformed))
    filt!(filtered, digitalfilter(response, design; fs=1), transformed)

    retransformed = real.(ifft(filtered))

    save("output.png", floor.(retransformed))
    return retransformed
end

end