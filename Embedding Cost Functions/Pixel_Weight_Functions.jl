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
    transformed = fftshift(fft(greyscale))

    cutoff = real(mean(transformed, dims=(1,2))[1])
    rows, cols = size(transformed)
    cy = div(rows,2)
    cx = div(cols,2)

    x = [j - cx for j in 1:cols] 
    y = [i - cy for i in 1:rows]
    radius_matrix = [sqrt(yi^2 + xj^2) for yi in y, xj in x]
    max_radius = maximum(radius_matrix)
    cutoff_ratio = cutoff * max_radius
    zeroing_mask = radius_matrix .<= cutoff_ratio
    filtered = transformed .* zeroing_mask

    retransformed = real.(ifft(ifftshift(filtered)))
    noise = abs.(greyscale - retransformed)

    return noise
end

function fourier_highpass_filtering(image_path)
    img = load(image_path)
    greyscale = Float64.(Gray.(img))
    transformed = fft(greyscale)

    #Struggling with filter parameters
    x = real(mean(transformed, dims=(1,2))[1])
    response = Highpass(x)
    design = FIRWindow(hanning(64))
    filt(digitalfilter(response, design; fs=1), transformed)

    retransformed = real.(ifft(transformed))

    return retransformed
end

fourier_lowpass_filtering("sunflower.png")

end