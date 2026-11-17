# Tests for src/CREE.jl, run from the repository root with:
#
#     julia test/runtests.jl
#
# Nothing here needs Pluto or a running CAD application. The model is loaded
# the same way the notebook loads it, and the full-model tests run with no
# Khepri backend active, so shapes are constructed but never sent anywhere.

using Test
using Khepri

const Modelo = include(joinpath(@__DIR__, "..", "src", "CREE.jl"))

# Run `f` with no backend active: geometry is built as Khepri shapes but not
# realized, so the tests never touch AutoCAD (or whatever is the default).
sem_backend(f) = with(f, current_backends, ())

params_base(; vazios = [], nucleos = [], pisos = 3) =
    Modelo.EdificioParams(0, 0, 0, 2, 6.0, 7, 3.0, 0, 0, 0,
                          vazios, nucleos, pisos, 3.0, [], [])

@testset "CREE" begin

    @testset "DimensoesSistema" begin
        d = Modelo.DimensoesSistema()
        @test d == Modelo.DIMENSOES_PADRAO
        @test d.hvb == 0.4
        @test d.e_fachada == 0.1

        v = Modelo.DimensoesSistema(hvb = 0.45)
        @test v.hvb == 0.45
        @test v.bvb == d.bvb                      # the rest keep their defaults
    end

    @testset "DESCRICOES_DIMENSOES covers every dimension exactly once" begin
        descritos = [campo for (_, campos) in Modelo.DESCRICOES_DIMENSOES
                           for (campo, _) in campos]
        numericos = [f for f in fieldnames(Modelo.DimensoesSistema) if f != :fonte]
        @test allunique(descritos)
        @test Set(descritos) == Set(numericos)
    end

    @testset "markdown_dimensoes" begin
        md = Modelo.markdown_dimensoes()
        @test startswith(md, "| componente | símbolo | m |")
        @test occursin("| Altura da viga de bordadura | `hvb` | 0.4 |", md)
        @test occursin("`hvb` | 0.45 |",
                       Modelo.markdown_dimensoes(Modelo.DimensoesSistema(hvb = 0.45)))
    end

    @testset "completa_vazios" begin
        @test Modelo.completa_vazios([[1, 1, []]], 3) == [[1, 1, [1, 2, 3]]]
        @test Modelo.completa_vazios([[2, 2, [1]]], 3) == [[2, 2, [1]]]
        @test isempty(Modelo.completa_vazios([], 3))
    end

    @testset "tem_indice" begin
        s = [[1, 1, [1, 2]], [3, 2, [4]]]
        @test Modelo.tem_indice(s, 1, 1, 2)
        @test !Modelo.tem_indice(s, 1, 1, 3)
        @test Modelo.tem_indice(s, 3, 2, 4)
        @test !Modelo.tem_indice(s, 2, 1, 1)
        @test !Modelo.tem_indice([], 1, 1, 1)
    end

    @testset "p_rotate" begin
        p = Modelo.p_rotate(xyz(0, 0, 0), xyz(1, 0, 0), π / 2)
        @test isapprox(p.x, 0; atol = 1e-12)
        @test isapprox(p.y, 1; atol = 1e-12)
        q = Modelo.p_rotate(xyz(1, 1, 0), xyz(2, 1, 5), π)   # keeps z, rotates about p0
        @test isapprox(q.x, 0; atol = 1e-12)
        @test isapprox(q.y, 1; atol = 1e-12)
        @test q.z == 5
    end

    @testset "grids" begin
        g = Modelo.pts_grelha(xyz(0, 0, 0), 12.0, 2, 21.0, 7)
        @test length(g) == 3 && all(length.(g) .== 8)       # (n+1) × (m+1) points
        ultimo = g[end][end]                                # Khepri points don't define ==
        @test (ultimo.x, ultimo.y, ultimo.z) == (12.0, 21.0, 0.0)
        q = Modelo.grelha_4pts(xyz(0, 0, 0), 12.0, 2, 21.0, 7)
        @test length(q) == 2 && all(length.(q) .== 7)       # n × m cells
        @test all(length(c) == 4 for row in q for c in row)
    end

    @testset "nucleos_set_count" begin
        # Two adjacent cores in i and one above: grouped into one 2×2 block,
        # height = the tallest explicit height among them.
        ncl = Modelo.completa_vazios([[1, 1, []], [2, 1, []], [1, 2, [2]]], 3)
        @test Modelo.nucleos_set_count(ncl, 3) == [[1, 1, 2, 2, 3]]
        # A single isolated core with no explicit height spans all storeys.
        @test Modelo.nucleos_set_count([[4, 4, []]], 5) == [[4, 4, 1, 1, 5]]
        # Two separate cores stay separate.
        @test length(Modelo.nucleos_set_count([[1, 1, [1]], [5, 5, [1]]], 2)) == 2
    end

    @testset "generate_model runs end to end (no backend)" begin
        sem_backend() do
            @test Modelo.generate_model(params_base()) isa AbstractVector
            @test Modelo.generate_model(params_base(vazios = [[1, 1, []]],
                                                    nucleos = [[2, 3, []]])) isa AbstractVector
            @test Modelo.generate_model(params_base(pisos = 1),
                                        Modelo.DimensoesSistema(hvb = 0.45)) isa AbstractVector
        end
    end
end
