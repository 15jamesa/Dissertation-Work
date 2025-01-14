using ImageIO, FileIO, ColorTypes, ImageView, Pkg, Images

function encode(input_image, secret_message, output_image)
    img = load(input_image)
    message = secret_message
    message_bin = parse.(Int, collect(join(bitstring.(Int8.(collect(message))))))

    width = size(img)[1]
    height = size(img)[2]

    #reshape image into 1D + isolate blue channel
    reshape(img, (1, (width*height)))
    b = UInt8.(reinterpret.(blue.(img)))

    #change last bit
    for i in 1:length(message_bin)
        last = mod(b[i],2)

        if last ≠ message_bin[i]
            b[i]  = b[i] ⊻ 1
        end
        
    end

    #add blue channel back 
    for j in 1:length(b)
        pixel = img[j]
        img[j] = RGBA(red(pixel), green(pixel), reinterpret(N0f8,b[j]), alpha(pixel))
    end

    #reshape to image shape
    reshape(img, (height, width))
    save(output_image, img)
end

function decode(image)
    #load in image
    img = load(image)
    width = size(img)[1]
    height = size(img)[2]
    reshape(img, (1, (width*height)))

    #extract data
    b = UInt8.(reinterpret.(blue.(img)))

    extracted = zeros(Int8, length(b))
    for i in 1:length(b)
        extracted[i] = mod(b[i],2)
    end

    #make sense of extracted data
    characters = join(Char.(parse.(Int, (join.(collect(Iterators.partition(extracted, 8)))); base=2)))
    print(characters)

end

encode("dice.png", "this is my super secret message", "secret_dice.png")
decode("secret_dice.png")
