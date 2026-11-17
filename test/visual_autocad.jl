# Visual check: draws a set of full CREE models side by side in AutoCAD, each
# labelled, so the geometry can be inspected by eye.
#
# This is NOT part of `julia test/runtests.jl` — it needs AutoCAD running with
# the Khepri plugin loaded, and it CLEARS THE CURRENT DRAWING first. Open an
# empty drawing before running it. From the repository root:
#
#     julia test/visual_autocad.jl            # draw every case
#     julia test/visual_autocad.jl 3 5        # draw only cases 3 and 5
#     julia test/visual_autocad.jl --dry-run  # build everything, draw nothing
#                                             # (checks the cases still run)
#
# The cases are laid out in a row along x, left to right in the order below,
# with each label just in front of its building (negative y).

using Khepri

const Modelo = include(joinpath(@__DIR__, "..", "src", "CREE.jl"))

# Grid indices: i runs along the columns (1..nc, along x), j along the lines
# (1..nl, along y). Voids and cores are [i, j, storeys]; an empty storey list
# means every storey. Windows are [horizontal position, vertical position,
# width, height] and are applied to every facade panel in that direction.
caso(nome; nl = 2, dl = 6.0, nc = 7, dc = 3.0, np = 3, h = 3.0,
     rotacao = 0.0, vazios = [], nucleos = [],
     janelas_linha = [], janelas_coluna = [],
     dims = Modelo.DIMENSOES_PADRAO) =
    (; nome, nl, dl, nc, dc, np, h, rotacao, vazios, nucleos,
       janelas_linha, janelas_coluna, dims)

const CASOS = [
    caso("1 Base (notebook defaults)"),

    caso("2 Vazios: canto total + interior a partir do piso 2";
         nl = 3, vazios = [[1, 1, []], [4, 2, [2, 3]]]),

    caso("3 Nucleos: bloco 2x2 ate cobertura + nucleo isolado 2 pisos";
         nl = 3, nucleos = [[3, 1, 1:4], [4, 1, 1:4], [3, 2, 1:4], [4, 2, 1:4],
                            [7, 3, 1:2]]),

    caso("4 Janelas nas linhas e nas colunas";
         janelas_linha  = [[0.9, 0.5, 1.2, 2.0]],
         janelas_coluna = [[1.0, 0.5, 1.5, 2.0], [3.5, 0.5, 1.5, 2.0]]),

    caso("5 Rotacao 30 graus"; rotacao = π / 6),

    caso("6 Combinado: vazios + nucleos + janelas, 5 pisos";
         nl = 4, nc = 8, np = 5,
         vazios  = [[1, 4, []], [6, 2, [3, 4, 5]]],
         nucleos = [[3, 2, 1:6], [3, 3, 1:6]],
         janelas_linha  = [[0.9, 0.5, 1.2, 2.0]],
         janelas_coluna = [[2.0, 0.5, 2.0, 2.0]]),

    caso("7 Dimensoes alternativas (vigas, pilares e fachada maiores)";
         dims = Modelo.DimensoesSistema(hvb = 0.6, bvb = 0.4, hvi = 0.5,
                                        api = 0.5, cpc = 0.5, e_fachada = 0.25)),

    caso("8 Minimo: 1x1, 1 piso"; nl = 1, nc = 1, np = 1),
]

const AFASTAMENTO = 10.0   # gap between buildings, m

function desenhar(casos)
    delete_all_shapes()
    x = 0.0
    for c in casos
        largura     = c.nc * c.dc
        profundidade = c.nl * c.dl
        origem = xyz(x, 0, 0)
        println("  ", c.nome, "  @ x = ", round(x; digits = 1))
        text(c.nome, xyz(x, -3, 0), 0.6)
        # Called directly rather than through generate_model, because
        # generate_model clears the drawing and would leave only the last case.
        # Rotation is about each building's own origin.
        Modelo.edificio_CREE(origem, c.nl, c.nc, c.dl, c.dc, c.np, c.h,
                             origem, c.rotacao,
                             c.janelas_linha, c.janelas_coluna,
                             c.vazios, c.nucleos, c.dims)
        # Leave room for the rotated footprint as well as the label.
        x += max(hypot(largura, profundidade), length(c.nome) * 0.55) + AFASTAMENTO
    end
end

let args = copy(ARGS)
    dry = "--dry-run" in args
    filter!(!=("--dry-run"), args)
    casos = isempty(args) ? CASOS : CASOS[parse.(Int, args)]

    if dry
        println("Dry run — building ", length(casos), " case(s) with no backend:")
        with(() -> desenhar(casos), current_backends, ())
    else
        backend(autocad)
        println("Drawing ", length(casos), " case(s) in AutoCAD:")
        desenhar(casos)
    end
    println("Done.")
end
