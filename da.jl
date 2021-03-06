module DA

export etkf, ensrf, gaspari_cohn

using Statistics
using LinearAlgebra
using Distributions

function gaspari_cohn(r)
    if 0 <= r < 1
        G = 1 - 5/3*r^2 + 5/8*r^3 + 1/2*r^4 - 1/4*r^5
    elseif 1 <= r < 2
        G = 4 - 5*r + 5/3*r^2 + 5/8*r^3 - 1/2*r^4 + 1/12*r^5 - 2/(3*r)
    elseif r >= 2
        G = 0
    end
    return G
end

function gaspari_cohn_localization(c, D; cyclic=false)
    localization = zeros(D, D)
    for i=1:D
        for j=1:i
            if cyclic
                r = min(mod(i - j, 0:D), mod(j - i, 0:D))/c
            else
                r = abs(i - j)
            end
            localization[i, j] = DA.gaspari_cohn(r)
        end
    end
    return Symmetric(localization, :L)
end

"""
Ensemble transform Kalman filter (ETKF)
"""
function etkf(; E::AbstractMatrix{float_type}, R::Symmetric{float_type},
                R_inv::Symmetric{float_type},
                inflation::float_type=1.0, H::AbstractMatrix,
                y::AbstractVector{float_type}) where {float_type<:AbstractFloat}
    D, m = size(E)

    x_m = mean(E, dims=2)
    X = (E .- x_m)/sqrt(m - 1)

    X = sqrt(inflation)*X

    y_m = H*x_m
    Y = (H*E .- y_m)/sqrt(m - 1)
    Ω = inv(Symmetric(I + Y'*R_inv*Y))
    w = Ω*Y'*R_inv*(y - y_m)

    E = x_m .+ X*(w .+ sqrt(m - 1)*sqrt(Ω))

    return E
end

function ensrf(; E::AbstractMatrix{float_type}, R::Symmetric{float_type},
                 R_inv::Symmetric{float_type},
                 inflation::float_type=1.0, H::AbstractMatrix,
                 y::AbstractVector{float_type},
                 localization=nothing) where {float_type<:AbstractFloat}
    D, m = size(E)

    x_m = mean(E, dims=2)
    A = E .- x_m

    if localization === nothing
        P = inflation*A*A'/(m - 1)
    else
        P = inflation*localization.*(A*A')/(m - 1)
    end

    K = P*H'*inv(H*P*H' + R)
    x_m .+= K*(y - H*x_m)

    E = x_m .+ real((I + P*H'*R_inv*H)^(-1/2))*A

    return E
end

end
