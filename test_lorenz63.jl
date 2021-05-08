using Statistics
using LinearAlgebra
using Random

using Distributions

include("etkf.jl")
import .ETKF

include("ens_forecast.jl")
import .ens_forecast

include("models.jl")
import .Models

include("integrators.jl")
import .Integrators

Random.seed!(1)

models = [Models.lorenz63_err.func, Models.lorenz63_err4.func]
model_true = Models.lorenz63_true.func
n_models = length(models)
D = 3
obs_ops = [I(D), I(D), I(D)]
H = I(D)
ens_sizes = [20, 20, 20]
model_sizes = [D, D, D]
integrator = Integrators.rk4
x0 = rand(D)
t0 = 0.0
Δt = 0.05
outfreq = 1
window = 1
transient = 2000
x0 = integrator(models[1], x0, t0, transient*outfreq*Δt, Δt, inplace=false)
R = diagm(0=>(0.1*std(x0, dims=1)[:]).^2)
x0 = x0[end, :]
#ensembles = [ens_forecast.init_ens(model=models[model], integrator=integrator,
#                                   x0=x0, t0=t0, outfreq=outfreq, Δt=Δt,
#                                   ens_size=ens_sizes[model]) for model=1:n_models]
#x0 = ensembles[1][:, end]
n_cycles = 500
spinup = 250
ρ = 0.8

#model_errs = [ens_forecast.model_err(model_true=model_true, model_err=models[model],
#                                     integrator=integrator, x0=x0, t0=t0,
#                                     outfreq=outfreq, Δt=Δt, window=window,
#                                     n_samples=100)[1] for model=1:n_models]

ensembles = [x0 .+ rand(MvNormal(R), ens_sizes[model]) for model=1:n_models]

model_errs = Vector{Matrix{Float64}}(undef, n_models)
#biases = [nothing, nothing]
biases = [zeros(3), zeros(3)]

α = 1.0
inflations = [1.0]

info1, ensembles, x0 = ens_forecast.mmda(x0=x0, ensembles=ensembles, models=[models[1]],
                         model_true=model_true, obs_ops=obs_ops, H=H,
                         model_errs=model_errs, biases=biases, integrator=integrator,
                         ens_sizes=ens_sizes, Δt=Δt, window=window,
                         n_cycles=spinup, outfreq=outfreq,
                         model_sizes=model_sizes, R=R, ρ=ρ, inflations=inflations,
                         α=α)

ensembles = [x0 .+ rand(MvNormal(R), ens_sizes[model]) for model=1:n_models]
inflations = [1.0]

info2, ensembles, x0 = ens_forecast.mmda(x0=x0, ensembles=ensembles, models=[models[2]],
                        model_true=model_true, obs_ops=obs_ops, H=H,
                        model_errs=model_errs, biases=biases, integrator=integrator,
                        ens_sizes=ens_sizes, Δt=Δt, window=window,
                        n_cycles=spinup, outfreq=outfreq,
                        model_sizes=model_sizes, R=R, ρ=ρ, inflations=inflations,
                        α=α)

incs1 = hcat(info1.increments...)
incs2 = hcat(info2.increments...)
#model_errs = [cov(incs1'), cov(incs2')]
#biases = [mean(incs1, dims=2)[:], mean(incs2, dims=2)[:]]
#biases = [zeros(3), zeros(3)]

inflations = [1.0, 1.0]
ensembles = [x0 .+ rand(MvNormal(R), ens_sizes[model]) for model=1:n_models]

info, _, _ = ens_forecast.mmda(x0=x0, ensembles=ensembles, models=models,
                         model_true=model_true, obs_ops=obs_ops, H=H,
                         model_errs=model_errs, biases=biases, integrator=integrator,
                         ens_sizes=ens_sizes, Δt=Δt, window=window,
                         n_cycles=n_cycles, outfreq=outfreq,
                         model_sizes=model_sizes, R=R, ρ=ρ, inflations=inflations,
                         α=α)