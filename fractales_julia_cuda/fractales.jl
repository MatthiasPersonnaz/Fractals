# définition du polynôme utilisé
using Polynomials
x = variable(Polynomial{Rational{Int}})
p = Polynomial([1,0,3,4], :x);
∂p = derivative(p);
p,∂p


using CUDA;
function newton_fractal!(t::CuDeviceVector{ComplexF32}, α::ComplexF32, ϵ::Float32, maxiter::Int32, colors::CuDeviceVector{Float32})
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    if i <= length(t)
        ind = Int32(0);
        iterexp = 0.f0;
        step = 1.f0;
        while (ind<maxiter && step>ϵ);
            step = α*(1.f0+3.f0*t[i]+4.f0*t[i])/(6.f0*t[i]+12.f0*t[i]);
            iterexp = iterexp + CUDA.exp(-CUDA.abs(t[i])-0.5f0/(CUDA.abs(step)))
            t[i] = t[i] - step;
            ind += 1;
        end
        colors[i] = iterexp;
    end
    return nothing
end

function construct_meshgrid(Nx::Int64, Ny::Int64, x_min::Float64, x_max::Float64, y_min::Float64, y_max::Float64)
    δx = (x_max-x_min)/(Nx-1);
    δy = (y_max-y_min)/(Ny-1);
    xs = Vector(x_min:δx:x_max);
    ys = Vector(y_min:δy:y_max);
    @assert length(xs) == Nx;
    @assert length(ys) == Ny;
    xg = ones(Ny)' .* xs;
    yg = ys' .* ones(Nx);
    xg + 1im*yg
end




elty = ComplexF32; # pour la conversion des types de complexes manipulés sur GPU

α = elty(.5+.4im);
ϵ = Float32(1e-6);

# définition des paramètres
Nx = 1000; Ny = 1000;
x_min = -1.55; x_max = 1.55;
y_min = -1.; y_max = 1.;

# construction de la grille
meshgrid = reshape(construct_meshgrid(Nx, Ny, x_min, x_max, y_min, y_max), Nx*Ny);
meshgrid = CuArray{elty}(meshgrid);


maxiter = Int32(50);

# allouer la matrice de renvoi
colors = CuArray{Float32}(undef, Nx*Ny);

# plus petit entier supérieur ou égal à length(A_d)/threads
numthreads = 256;
numblocks = cld(length(meshgrid), 256);

# exécuter en utilisant 256 threads
CUDA.@time (@cuda threads=numthreads blocks=numblocks newton_fractal!(meshgrid, α, ϵ, maxiter, colors));