module PixelWeights

using ImageCore, Images, ImageFiltering, ColorTypes, ImageEdgeDetection, FFTW, Statistics, DSP

cd("./Embedding Cost Functions/")

function blurred_noise_calculation(rgb)
    grey = Float64.(Gray.(rgb))
    blurred = imfilter(grey, Kernel.gaussian(5))
    noise = abs.(grey - blurred)

    return noise
end

function colour_sensitivity(rgb)
    g = Float64.(green.(rgb))
    b = Float64.(blue.(rgb))
    sensitivity = g - b
    
    return sensitivity
end

function canny_edge_detection(img)
    edges = detect_edges(img, Canny() )
    weighted = Float64.(Gray.(edges))

    return weighted
end

function fourier_hard_cutoff_filtering(img)
    greyscale = Float64.(Gray.(img))
    padded = add_padding(greyscale)
    transformed = fftshift(fft(padded))

    cutoff = 0.3
    rows, cols = size(transformed)
    cy = div(rows,2)
    cx = div(cols,2)

    x = [j - cx for j in 1:cols] 
    y = [i - cy for i in 1:rows]
    radius_matrix = [sqrt(yi^2 + xj^2) for yi in y, xj in x]
    max_radius = maximum(radius_matrix)
    cutoff_value = cutoff * max_radius
    zeroing_mask = radius_matrix .<= cutoff_value
    filtered = transformed .* zeroing_mask

    retransformed = real.(ifft(ifftshift(filtered)))
    unpadded = remove_padding(retransformed)
    noise = abs.(greyscale - unpadded)
    save("noise.png", noise)

    return noise
end

function fourier_soft_cutoff_filtering(img)
    greyscale = Float64.(Gray.(img))
    padded = add_padding(greyscale)
    transformed = fftshift(fft(padded))

    cutoff = 0.3
    rows, cols = size(transformed)
    cy = div(rows,2)
    cx = div(cols,2)

    x = [j - cx for j in 1:cols] 
    y = [i - cy for i in 1:rows]
    radius_matrix = [sqrt(yi^2 + xj^2) for yi in y, xj in x]
    max_radius = maximum(radius_matrix)
    cutoff_value = cutoff * max_radius
    unexponentiated = -(radius_matrix .^2) ./ (2*(cutoff_value^2))
    mask = exp.(unexponentiated)
    filtered = transformed .* mask

    retransformed = real.(ifft(ifftshift(filtered)))
    unpadded = remove_padding(retransformed)
    noise = abs.(greyscale - unpadded)

    save("noise.png", noise)
    return noise
end

function add_padding(img)
    height, width = Int.(ceil.(size(img) ./ 2))
    padded_img = padarray(img, Pad(:symmetric,height,width))
    return padded_img
end

function remove_padding(img)
    img_height, img_width = Int.(floor.(size(img) ./ 2))
    unpadded_image = img[1:img_height,1:img_width]
    return unpadded_image

end

img = load("sunflower.png")
fourier_soft_cutoff_filtering(img)

end