function embed(h_hat, x, m, rho)
    #forward step of viterbi
    h,w = size(h_hat)
    block_num = 4
    path = zeros(Int64, size(cover)[1], h^2)
    y = zeros(Int64, size(cover)[1])

    weight = [Inf for n in 1:2^h]
    weight[1] = 0
    indx = 1
    indm = 1
    limit = block_num - (h-1)
    for i in 1:block_num
        for j in 1:w
            new_weight = zeros(size(weight))
            for k in 1:(2^h)
                w0 = weight[k] + x[indx]*rho[indx]
                column = i > limit ? h_hat[1:end-(i-limit),j] : h_hat[:,j]
                ind = ((k-1) ⊻ parse(Int, join(column), base=2))+1
                w1 = weight[ind] + (1-x[indx])*rho[indx]
                path[indx, k] = w1 < w0 ? 1 : 0
                new_weight[k] = min(w0,w1)
            end
            indx += 1
            weight=new_weight
        end
        for j in 0:2^(h-1)-1
            #problem here??
            weight[j+1] = weight[2*j + m[indm] + 1]
        end
        [weight[n+1] = Inf for n in 2^(h-1):2^h-1]
        indm += 1
    end
    println(path)
    println(weight)

    #backward step of viterbi
    embedding_cost = weight[1]
    state = 0
    indx += -1
    indm += -1
    for i in block_num:-1:1
        for j in w:-1:1
            y[indx] = path[indx, (state+1)]
            column = i > limit ? h_hat[1:end-(i-limit),j] : h_hat[:,j]
            state = state ⊻ (y[indx]*parse(Int, join(column), base=2))
            indx += -1
        end
        state = 2*state + m[indm]
        indm += -1
    end
    println(embedding_cost)
    println(y)
end

#setting up test data
cover = [1,0,1,1,0,0,0,1]
message = [0,1,1,1]
h_hat = [1 0;
         1 1]
rho = ones(Int, size(cover))

embed(h_hat, cover, message, rho)

