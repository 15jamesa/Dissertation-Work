using SparseArrays

#generate h_hat to be shared with sender and receiver
function generate_h_hat(h,w)
    h_hat = rand([0,1],(h,w))
    return h_hat
end

#finds the y most similar to x that satisfies Hy = m
function embed(h_hat, x, m, rho)
    #change matrix to vector implementation
    #reads columns upwards
    #forward step of viterbi
    h,w = size(h_hat)
    n = length(x)
    block_num = div(n, w)
    path = zeros(Bool, n, h^2)
    y = zeros(Int64, n)

    weight = [Inf32 for n in 1:2^h]
    weight[1] = 0
    indx = 1
    indm = 1
    limit = block_num - (h-1)
    for i in 1:block_num
        for j in 1:w
            new_weight = zero(weight)
            for k in 1:(2^h)
                w0 = weight[k] + x[indx]*rho[indx]
                column = i > limit ? reverse(h_hat[1:end-(i-limit),j]) : reverse(h_hat[:,j])
                ind = ((k-1) ⊻ parse(Int, join(column), base=2))+1
                w1 = weight[ind] + (1-x[indx])*rho[indx]
                path[indx, k] = w1 < w0 ? 1 : 0
                new_weight[k] = min(w0,w1)
            end
            indx += 1
            weight=new_weight
        end
        for j in 0:2^(h-1)-1
            weight[j+1] = weight[2*j + m[indm] + 1]
        end
        for n in 2^(h-1):2^h-1; weight[n+1] = Inf; end
        indm += 1
    end
    #backward step of viterbi
    embedding_cost = weight[1]
    state = 0
    indx -= 1
    indm -= 1
    for i in block_num:-1:1
        state = 2*state + m[indm]
        for j in w:-1:1
            y[indx] = path[indx, (state+1)]
            column = i > limit ? reverse(h_hat[1:end-(i-limit),j]) : reverse(h_hat[:,j])
            state = state ⊻ (y[indx]*parse(Int, join(column), base=2))
            indx -= 1
        end
        indm -= 1
    end
    return (embedding_cost, y)
end

#create the sparse matrix
function expand_h_hat(h_hat, y)
    h,w = size(h_hat)
    block_num = div(size(y)[1],w)
    H = spzeros(Int64, block_num, size(y)[1])
    limit = (block_num)-(h-1)
    for i in 1:(size(y)[1])
        o = ceil(Int, i/w)
        j = mod(i-1,w) +1
        column = i/w > limit ? h_hat[1:end-(o-limit),j] : h_hat[:,j]
        cutoff = i/w > limit ? h-(1-limit) : o+h-1
        H[o:cutoff,i] = column
    end
    return H
end

#bitwise matrix multiplication
function extract(h_hat,y)
    H = expand_h_hat(h_hat,y)
    message = zeros(Int64, 0)
    for row in eachrow(H)
        combined = row .& y
        ones = count(i->(i==1), combined)
        message_bit = mod(ones,2)==0 ? 0 : 1
        append!(message, message_bit)
    end
    return(message)
end

#setting up test data
cover = [1,0,0,1,1,0,1,0,1,0,0,1,0,1,0]
message = [0,0,1,0,1]
h_hat = [1 0 0;
         1 1 1;
         1 1 0]
rho = ones(Int, size(cover))

embedding_cost, y = embed(h_hat, cover, message, rho)

println(y)
println(extract(h_hat,y))

