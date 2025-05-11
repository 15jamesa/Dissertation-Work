include("../Embedding Cost Functions/Pixel_Weight_Functions.jl")
include("../Least-Bit Stego/LBS.jl")
include("../Syndrome-Trellis Code/STC.jl")
using .PixelWeights
using .LBS
using .STC
using Images, FileIO, Plots, ImageDistances, StatsPlots, Statistics, Faker, DataFrames, CSV
gr()

function lbs_png_embed(test_image_folder)
    image_nums = ["16", "28", "6", "23", "45"]
    upper = 204800
    interval = 10240
    bits = [l for l in 0:interval:upper]
    df = DataFrame()
    df[!, "bits"] = bits

    for i in 1:5
        cd(test_image_folder)
        image = "original_" * image_nums[i] * ".png"
        SSIM = ones(length(bits))
        PSNR = ones(length(bits))
        CIEDE = ones(length(bits))
        filesize = ones(length(bits))
        filesize[1] = stat(image).size
        x = load(image)
        cd("../plotting_data")
        CIEDE[1] = ciede2000(RGB.(x), RGB.(x))
        SSIM[1] = assess_ssim(RGB.(x), RGB.(x))
        PSNR[1] = assess_psnr(RGB.(x), RGB.(x))
        for m in interval:interval:upper
            message = Faker.text(number_chars=div(m,8))
            y = LBS.encode(x, message)
            new_file = "lbs_png_" * image_nums[i] * "_" * string(m) * ".png"
            save(new_file, y)
            CIEDE[div(m,interval)+1] = ciede2000(RGB.(x), RGB.(y))
            SSIM[div(m,interval)+1] = assess_ssim(RGB.(x), RGB.(y))
            PSNR[div(m,interval)+1] = assess_psnr(RGB.(x), RGB.(y))
            filesize[div(m,interval)+1] = stat(new_file).size
        end
        ssim_column = "pic" * image_nums[i] * "_SSIM"
        psnr_column = "pic" * image_nums[i] * "_PSNR"
        ciede_column = "pic" * image_nums[i] * "_CIEDE"
        filesize_column = "pic" * image_nums[i] * "size"
        df[!, ssim_column] = SSIM
        df[!, psnr_column] = PSNR
        df[!, ciede_column] = CIEDE
        df[!, filesize_column] = filesize
    end
    cd("../plotting_data")
    CSV.write("lbs_png_distortion.csv", df)
end

function stc_png_embed(test_image_folder)
    estimating_functions= ["blurred_noise_calculation","colour_sensitivity", "canny_edge_detection", "fourier_hard_cutoff_filtering", "fourier_soft_cutoff_filtering"]
    image_nums = ["16", "28", "6", "23", "45"]
    upper = 204800
    interval = 10240
    bits = [l for l in 0:interval:upper]
    df = DataFrame()
    df[!, "bits"] = bits

    for func in eachindex(estimating_functions)
        for i in 1:5
            cd(test_image_folder)
            image = "original_" * image_nums[i] * ".png"
            SSIM = ones(length(bits))
            PSNR = ones(length(bits))
            CIEDE = ones(length(bits))
            filesize = ones(length(bits))
            filesize[1] = stat(image).size
            x = load(image)
            cd("../plotting_data")
            CIEDE[1] = ciede2000(RGB.(x), RGB.(x))
            SSIM[1] = assess_ssim(RGB.(x), RGB.(x))
            PSNR[1] = assess_psnr(RGB.(x), RGB.(x))
            for m in interval:interval:upper
                message = Faker.text(number_chars=div(m,8))
                y = STC.png_embed(x, message, estimating_functions[func])[2]
                new_file = estimating_functions[func] * "_stc_png_" * image_nums[i] * "_" * string(m) * ".png"
                save(new_file, y)
                CIEDE[div(m,interval)+1] = ciede2000(RGB.(x), RGB.(y))
                SSIM[div(m,interval)+1] = assess_ssim(RGB.(x), RGB.(y))
                PSNR[div(m,interval)+1] = assess_psnr(RGB.(x), RGB.(y))
                filesize[div(m,interval)+1] = stat(new_file).size
            end
            ssim_column = "pic" * image_nums[i] * estimating_functions[func] * "_SSIM"
            psnr_column = "pic" * image_nums[i] * estimating_functions[func] * "_PSNR"
            ciede_column = "pic" * image_nums[i] * estimating_functions[func] * "_CIEDE"
            filesize_column = "pic" * image_nums[i] * estimating_functions[func] * "size"
            df[!, ssim_column] = SSIM
            df[!, psnr_column] = PSNR
            df[!, ciede_column] = CIEDE
            df[!, filesize_column] = filesize
        end
    end
    cd("../plotting_data")
    CSV.write("stc_png_distortion.csv", df)
end

function noise_estimation_plot(image_names)
    categories = repeat(["Border Noise", "Central Noise"], inner=4)
    name = repeat(["Sunflower", "Gerbera", "Nigella", "Sweet William"], outer=2)
    averages = zeros(8)
    stds = zeros(8)
    estimating_functions= ["blurred_noise_calculation","colour_sensitivity", "canny_edge_detection", "fourier_hard_cutoff_filtering", "fourier_soft_cutoff_filtering"]
    plot_array = Array{Plots.Plot{Plots.GRBackend},1}(undef,length(estimating_functions)+1)
    titles = ["Blurred Noise", "Colour Sensitivity", "Edge Detection", "Fourier Hard Cutoff", "Fourier Soft Cutoff"]

    for func in eachindex(estimating_functions)
        for image in eachindex(image_names)
            x = load(image_names[image])
            width,height = div.(size(x),2)
            y = getfield(PixelWeights, Symbol(estimating_functions[func]))(x)
            val1 = y[1:10, 1:10]
            val2 = y[width:(width+10), height:(height+10)]
            averages[image] = mean(val1, dims=(1,2))[1]
            averages[image+4] = mean(val2, dims=(1,2))[1]
            stds[image] = std(val1, dims=(1,2))[1]
            stds[image+4] = std(val2, dims=(1,2))[1]
        end 

        plot_array[func] = groupedbar(name, averages, yerr=stds, group = categories, ylabel = "Average Noise Value",
           title = titles[func], bar_width = 0.67, 
           markerstrokewidth = 1.5, ylims=(0, :auto), legend=false,
           framestyle = :box, grid = false, xrotation=30, guidefont=10, leftmargin=10Plots.mm, rightmargin=10Plots.mm, bottommargin=10Plots.mm)

    end

    temp = [-10 -20; -30 -40 ]
    plot_array[6] = plot(temp, ylims = (0,3), xlims=(0,3), legend=:topleft,
     label = ["Noise at Border" "Noise at Centre"], framestyle=:none, grid=false, legendfontsize=16, markersize = 16)

    plot(plot_array..., layout=(2,3), size=(1200,800))
    savefig("noise_estimate.png")
end

function canny_noise_estimation_plot(image_names)
    categories = repeat(["Border Noise", "Central Noise"], inner=4)
    name = repeat(["Sunflower", "Gerbera", "Nigella", "Sweet William"], outer=2)
    averages = zeros(8)
    stds = zeros(8)

    for image in eachindex(image_names)
        x = load(image_names[image])
        width,height = div.(size(x),2)
        y = PixelWeights.canny_edge_detection(x)
        val1 = y[1:10, 1:10]
        val2 = y[width:(width+10), height:(height+10)]
        averages[image] = mean(val1, dims=(1,2))[1]
        averages[image+4] = mean(val2, dims=(1,2))[1]
        stds[image] = std(val1, dims=(1,2))[1]
        stds[image+4] = std(val2, dims=(1,2))[1]
    end 

    groupedbar(name, averages, yerr=stds, group = categories, ylabel = "Average Noise Value",
        title = "Edge Detection", bar_width = 0.67, 
        markerstrokewidth = 1.5, ylims=(0, :auto), legend=true,
        framestyle = :box, grid = false, xrotation=30, guidefont=10, leftmargin=10Plots.mm, rightmargin=10Plots.mm, bottommargin=10Plots.mm)

    savefig("canny_noise_estimate.png")
end

function lbs_distortion_plot(csv_path, output_plot)
    plot_array = Array{Plots.Plot{Plots.GRBackend},1}(undef,4)
    labels = ["Tree", "Blue Staffie", "Bike Park", "Football", "Ray Dolby"]
    image_nums = ["16", "28", "6", "23", "45"]
    metrics = ["SSIM", "CIEDE", "PSNR"]
    ylimit = [(0.96,1), (0,3*(10^5)), (25, 70)]
    data = DataFrame(CSV.File(csv_path))
    xaxis = data[:, :bits]
    for i in 1:3
        p = plot(title=metrics[i], xlabel="Number of bits Embedded", topmargin=15Plots.mm, ylims=ylimit[i])
        for x in eachindex(image_nums)
            col = "pic" * image_nums[x] * "_" * metrics[i]
            data_column = data[:, col]
            plot!(p, xaxis, data_column, label=labels[x], legend=false)
        end
        plot_array[i] = p
    end
    temp = [-10 -20 -30 -40 -10; -10 -10 -10 -10 -10]
    plot_array[4] = plot(temp, ylims=(0,3), xlims=(0,3), label = ["Tree" "Blue Staffie" "Bike Park" "Football" "Ray Dolby"], legend=:topleft,
     framestyle=:none, grid=false, legendfontsize=16, markersize = 16)
    plot(plot_array..., layout=(1,4), plot_title="LSB Embedding in the Spatial Domain- Distortion Effects", margin=10Plots.mm, size=(1600,500))
    cd("../evaluation")
    savefig(output_plot)
end

function stc_distortion_plot(csv_path)
    funcs = ["blurred_noise_calculation","colour_sensitivity", "canny_edge_detection", "fourier_hard_cutoff_filtering", "fourier_soft_cutoff_filtering"]
    p_titles = ["STC Embedding w/ Blurred Noise Calculation", "STC Embedding w/ Colour Sensitivity", "STC Embedding w/ Canny Edge Detection", "STC Embedding w/ Fourier Hard Filtering", "STC Embedding w/ Fourier Soft Filtering"]
    outputs = ["stc_png_blur_plot.png", "stc_png_colour_plot.png", "stc_png_canny_plot.png", "stc_png_hardfourier_plot.png", "stc_png_softfourier_plot.png"]
    for f in eachindex(funcs)
        plot_array = Array{Plots.Plot{Plots.GRBackend},1}(undef,4)
        labels = ["Tree", "Blue Staffie", "Bike Park", "Football", "Ray Dolby"]
        image_nums = ["16", "28", "6", "23", "45"]
        metrics = ["SSIM", "CIEDE", "PSNR"]
        ylimit = [(0.96,1), (0,3*(10^5)), (25, 70)]
        cd("../plotting_data")
        data = DataFrame(CSV.File(csv_path))
        xaxis = data[:, :bits]
        for i in 1:3
            p = plot(title=metrics[i], xlabel="Number of bits Embedded", topmargin=15Plots.mm, ylims=ylimit[i])
            for x in eachindex(image_nums)
                col = "pic" * image_nums[x] * funcs[f] * "_" * metrics[i]
                data_column = data[:, col]
                plot!(p, xaxis, data_column, label=labels[x], legend=false)
            end
            plot_array[i] = p
        end
        temp = [-10 -20 -30 -40 -10; -10 -10 -10 -10 -10]
        plot_array[4] = plot(temp, ylims=(0,3), xlims=(0,3), label = ["Tree" "Blue Staffie" "Bike Park" "Football" "Ray Dolby"], legend=:topleft,
        framestyle=:none, grid=false, legendfontsize=16, markersize = 16)
        t = p_titles[f] * " in the Spatial Domain- Distortion Effects"
        plot(plot_array..., layout=(1,4), plot_title=t, margin=10Plots.mm, size=(1600,500))
        cd("../evaluation")
        savefig(outputs[f])
    end
end

function lbs_filesize_plot(csv_path, output_plot)
    labels = ["Tree", "Blue Staffie", "Bike Park", "Football", "Ray Dolby"]
    image_nums = ["16", "28", "6", "23", "45"]
    data = DataFrame(CSV.File(csv_path))
    xaxis = data[:, :bits]

    p = plot(title="LSB Embedding in the Spatial Domain- Filesize", xlabel="Number of bits Embedded", ylabel="Filesize", margin=10Plots.mm, legend=true)
    for i in eachindex(image_nums)
        col = "pic" * image_nums[i] * "size"
        yaxis = data[:, col]
        plot!(p, xaxis, yaxis, label=labels[i])
    end
    cd("../evaluation")
    savefig(output_plot)
end

function stc_filesize_plot(csv_path)
    funcs = ["blurred_noise_calculation","colour_sensitivity", "canny_edge_detection", "fourier_hard_cutoff_filtering", "fourier_soft_cutoff_filtering"]
    p_titles = ["STC Embedding w/ Blurred Noise Calculation", "STC Embedding w/ Colour Sensitivity", "STC Embedding w/ Canny Edge Detection", "STC Embedding w/ Fourier Hard Filtering", "STC Embedding w/ Fourier Soft Filtering"]
    outputs = ["stc_png_blur_size_plot.png", "stc_png_colour_size_plot.png", "stc_png_canny_size_plot.png", "stc_png_hardfourier_size_plot.png", "stc_png_softfourier_size_plot.png"]
    labels = ["Tree", "Blue Staffie", "Bike Park", "Football", "Ray Dolby"]
    image_nums = ["16", "28", "6", "23", "45"]
    data = DataFrame(CSV.File(csv_path))
    xaxis = data[:, :bits]

    for f in eachindex(funcs)
        t = p_titles[f] *  " \nin the Spatial Domain- Filesize"
        p = plot(title=t, xlabel="Number of bits Embedded", ylabel="Filesize", margin=10Plots.mm, legend=true)
        for i in eachindex(image_nums)
            col = "pic" * image_nums[i] * funcs[f] * "size"
            yaxis = data[:, col]
            plot!(p, xaxis, yaxis, label=labels[i])
        end
        cd("../evaluation")
        savefig(outputs[f])
    end
end

println(pwd())
cd("plotting_data")
stc_filesize_plot("stc_png_distortion.csv")
