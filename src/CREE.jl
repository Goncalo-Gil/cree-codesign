# ─────────────────────────────────────────────────────────────────────────
# CREE
#
# Parametric model of the CREE modular building system.
#
# The module holds the rules of the system and nothing else: no interface, no
# backend selection, no parameter values. Give `generate_model` an
# `EdificioParams` and it emits the configuration through whichever Khepri
# backend the caller has selected.
#
#     Modelo = include(joinpath(@__DIR__, "..", "src", "CREE.jl"))
#     backend(autocad)                   # or another Khepri backend
#     Modelo.generate_model(params)
#
# `include` returns the module, because the module definition is the last
# top-level expression in this file. Keep it that way: it is what lets Pluto
# track the model as an ordinary dependency.
#
# Extracted verbatim from the Pluto notebook at tag v5.0.0. The function bodies
# below are byte-identical to the cells they came from and are deliberately
# left unindented, so that the extraction stays diffable against that tag.
# ─────────────────────────────────────────────────────────────────────────

module CREE

using Khepri

export EdificioParams, DimensoesSistema, DIMENSOES_PADRAO, markdown_dimensoes,
       generate_model

# ─────────────────────────────────────────────────────────────────────────
# Input parameters
#
# Two kinds of input, deliberately kept apart:
#
#   EdificioParams     the design parameters — what varies from one
#                      configuration to the next, and what the architect
#                      manipulates during a session.
#   DimensoesSistema   the dimensions of the system itself — fixed context,
#                      the same for every configuration the system admits.
# ─────────────────────────────────────────────────────────────────────────

struct EdificioParams
    x_Origem::Float64
    y_Origem::Float64
    z_Origem::Float64

    Número_linhas::Int
    Dist_entre_linhas::Float64
    Número_colunas::Int
    Dist_entre_colunas::Float64

    x_rotação_Origem::Float64
    y_rotação_Origem::Float64
    Rotação::Float64

    Vazios
    Núcleos

    Número_pisos::Int
    Altura_piso::Float64

    Janelas_linha
    Janelas_coluna
end

# The cross-sections and thicknesses of the CREE components, in metres.
#
# These are not design parameters: no configuration reachable by moving a
# slider changes them. They are the fixed context of the system, and they are
# collected here — rather than left as literals inside `edificio_CREE` — so
# that the thesis can state in one place which constraints were encoded as
# rules and which were treated as given.
#
# The values are the ones the model has been generating with since v1.0.0.
# They have NOT been checked against CREE's own component documentation; the
# `fonte` field is there to record, per value, where it came from once that
# check is done. The admissible range of each one is likewise still open —
# both belong in §4.1 and §4.2.
#
# Overriding them is a keyword call, and nothing else in the model needs to
# know:
#
#     DimensoesSistema(hvb = 0.45, e_fachada = 0.12)
#
# What each symbol means is recorded once, in DESCRICOES_DIMENSOES below.
Base.@kwdef struct DimensoesSistema
    e_laje::Float64     = 0.1
    apf::Float64        = 0.2
    bpf::Float64        = 0.3
    cpc::Float64        = 0.3
    hvb::Float64        = 0.4
    bvb::Float64        = 0.3
    hvi::Float64        = 0.3
    bvi::Float64        = 0.3
    api::Float64        = 0.3
    enb::Float64        = 0.3
    hvL::Float64        = 0.3
    bvL::Float64        = 0.2
    e_fachada::Float64  = 0.1
    fonte::String       = "valores herdados do modelo; por confirmar com a CREE"
end

# The dimensions every call uses unless told otherwise. Identical to the
# literals that were previously inlined in `edificio_CREE`.
const DIMENSOES_PADRAO = DimensoesSistema()

# The name of every dimension in full, grouped by component and in the order it
# should be presented. This is the only place the symbols are explained, so a
# symbol and its description cannot drift apart; anything that displays the
# dimensions reads this rather than restating them.
const DESCRICOES_DIMENSOES = [
    ("Lajes", [
        (:e_laje,    "Espessura da laje"),
        (:hvL,       "Altura das vigas da laje"),
        (:bvL,       "Largura das vigas da laje"),
    ]),
    ("Pilares", [
        (:apf,       "Largura dos pilares da fachada"),
        (:bpf,       "Profundidade dos pilares da fachada"),
        (:cpc,       "Largura e profundidade do pilar de canto"),
        (:api,       "Largura e profundidade dos pilares interiores"),
    ]),
    ("Vigas", [
        (:hvb,       "Altura da viga de bordadura"),
        (:bvb,       "Largura da viga de bordadura"),
        (:hvi,       "Altura da viga interior"),
        (:bvi,       "Largura da viga interior"),
    ]),
    ("Núcleo", [
        (:enb,       "Espessura do núcleo de betão"),
    ]),
    ("Fachada", [
        (:e_fachada, "Espessura da fachada"),
    ]),
]

# A markdown table of the dimensions, by full name. Returns a String rather than
# a rendered object, so that the model stays free of display dependencies and
# the caller decides how to show it (in Pluto: `Markdown.parse(...)`).
function markdown_dimensoes(dims::DimensoesSistema = DIMENSOES_PADRAO)
    io = IOBuffer()
    println(io, "| componente | símbolo | m |")
    println(io, "|:---|:---|---:|")
    for (grupo, campos) in DESCRICOES_DIMENSOES
        println(io, "| **$(grupo)** | | |")
        for (campo, descricao) in campos
            println(io, "| $(descricao) | `$(campo)` | $(getfield(dims, campo)) |")
        end
    end
    String(take!(io))
end

# ───────────────────────────────────────────────────────────────────────
# ## Funções auxiliares
# ───────────────────────────────────────────────────────────────────────

#completa a posição [3] do conjunto de indices para incluir todos os pisos
function completa_vazios(set_1, np)
    [isempty(x[3]) ? [x[1], x[2], collect(1:np)] : x
        for x in set_1]
end

#verifica se o indice [i, j, k] pertence ao conjunto
function tem_indice(set_1, i, j, k)
    any(x -> x[1] == i && x[2] == j && k in x[3], set_1)
end

#rotaciona um ponto p1 em relação a outro ponto p0
function p_rotate(p0, p1, phi)
    p0 + vcyl(distance(p0 + vz(p1.z), p1), atan((p1.y - p0.y), (p1.x - p0.x)) + phi, p1.z)
end

# ───────────────────────────────────────────────────────────────────────
# ## Funções de grelhas de pontos
# ───────────────────────────────────────────────────────────────────────

function pts_grelha(p, l_tot, n, c_tot, m)
    map_division((i,j) -> p + vxy(i, j), 0, l_tot, n, 0, c_tot, m)
end

function grelha_4pts(p, l_tot, n, c_tot, m)
    iterate_quads((p1, p2, p3, p4) -> [p1, p2, p3, p4], pts_grelha(p, l_tot, n, c_tot, m))
end

# ───────────────────────────────────────────────────────────────────────
# ## Funções de lajes
# Expandir para ver as variaveis"""
#
#     #p: ponto de referência
#     #dc: distância entre as colunas
#     #nc: número de colunas
#     #dl: distância entre as linhas
#     #nl: número de linhas
#     #np: número de pisos
#     #h: altrura de cada piso
#     #e_laje: espessura da laje
#     #bvb: largura da viga de bordadura
#     #bvi: largura da viga interior
#     #bvL: largura das vigas da laje
#     #hvL: altura das vigas da laje
#     #vz_set: conjunto de indices vazios
#     #ncl_set: conjunto de indices de nucleos
# ───────────────────────────────────────────────────────────────────────

#Função que cria uma laje untilizando um array de 4 pontos
function laje_singular(pts, e_laje, nc, nl, bvb, bvi, bvL, hvL, i, j, k, vz_set, ncl_set, p0, phi0)
    let
        in_vazio(ii, jj)    = tem_indice(vz_set, ii, jj, k)
        in_nucleo(ii, jj)   = tem_indice(ncl_set, ii, jj, k)
        p_rot(p)            = p_rotate(p0, p, phi0)

        laje_familia = slab_family_element(
            default_slab_family(), thickness = e_laje)
        viga_laje_famlia = beam_family_element(
            default_beam_family(), profile = top_aligned_rectangular_profile(width = bvL, height = hvL))

        p1 = p_rot(pts[1])
        p2 = p_rot(pts[2])
        p3 = p_rot(pts[3])
        p4 = p_rot(pts[4]) 
        pts_rot = [p1, p2, p3, p4]

        # offset inferior em y das vigas da laje
        offset_1 =
            in_nucleo(i, j - 1) ? 0 :       #estende a viga até ao nucleo
            j == 1             ? bvb :      #reduz a viga para encaixar na viga de bordadura inferior
            in_vazio(i, j - 1) ? bvb :      #reduz a viga para encaixar na viga de bordadura interior
                                  bvi / 2   #reduz a viga para encaixar nas vigas interiores

        # offset superior em y das vigas da laje
        offset_2 =
            in_nucleo(i, j + 1) ? 0 :       #estende a viga até ao nucleo
            j == nl             ? bvb :     #reduz a viga para encaixar na viga de bordadura superior
            in_vazio(i, j + 1)  ? bvb :     #reduz a viga para encaixar na viga de bordadura interior           
                                   bvi / 2  #reduz a viga para encaixar nas vigas interiores

        with(default_beam_family, viga_laje_famlia) do

            # cria laje
            [slab(closed_polygonal_path(pts_rot), level(0), laje_familia),

            # viga esquerda
            i == 1 || in_vazio(i - 1, j) ? nothing :    #não cria na primeira coluna ou se vazio na coluna anterior
                beam(
                    p_rot(pts[1] + vxyz(bvL/2, offset_1, -e_laje)),
                    p_rot(pts[4] + vxyz(bvL/2, -offset_2, - e_laje))),

            # viga direita
            i == nc || in_vazio(i + 1, j) ? nothing :    #não cria na ultima coluna ou se vazio na coluna posterior
                beam(
                    p_rot(pts[2] + vxyz(-bvL/2, offset_1, -e_laje)),
                    p_rot(pts[3] + vxyz(-bvL/2, -offset_2, - e_laje))),

            # vigas centrais
            beam(
                p_rot(intermediate_loc(
                    pts[1], 
                    pts[2]) + vxyz(-bvL/2, offset_1, -e_laje)),
                p_rot(intermediate_loc(
                    pts[3], 
                    pts[4]) + vxyz(-bvL/2, -offset_2, - e_laje))),
            beam(
                p_rot(intermediate_loc(
                    pts[1], 
                    pts[2]) + vxyz(bvL/2, offset_1, -e_laje)),
                p_rot(intermediate_loc(
                    pts[3], 
                    pts[4]) + vxyz(bvL/2, -offset_2, - e_laje)))]
        end
    end
end

#Função que seleciona os arrays de 4 pontos para criar as lajes          
function laje_for(ptss, e_laje, nc, nl, bvb, bvi, bvL, hvL, vz_set, ncl_set, k, p0, phi0) 
    let 
        vz_set_tot = vcat([vz_set, ncl_set]...)
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [laje_singular([vcat(ptss[i][j])...], e_laje, nc, nl,
                        bvb, bvi, bvL, hvL, i, j, k, vz_set, ncl_set, p0, phi0)

        for i in 1:nc, #i define a coluna inicial e final
            j in 1:nl #j define a linha inicial e final

        if !in_vz_tot(i, j)]
    end
end

#Função que entrega arrays de 4 pontos à função laje_map
function laje_piso(p, dc, nc, dl, nl, e_laje, bvb, bvi, bvL, hvL, vz_set, ncl_set, k, p0, phi0) 

    [laje_for(
            grelha_4pts(
                p, dc * nc, nc, dl * nl, nl), e_laje, nc, nl,
                bvb, bvi, bvL, hvL, vz_set, ncl_set, k, p0, phi0)]
end

#Criação de lajes em todos os pisos
function laje_total(p, dc, nc, dl, nl, np, h, e_laje, bvb, bvi, bvL, hvL, vz_set, ncl_set, p0, phi0)

    [laje_piso(
        p + vz(h * k), dc, nc, dl, nl, e_laje,
        bvb, bvi, bvL, hvL, vz_set, ncl_set, k, p0, phi0)

            for k in 1:np]
end

# ───────────────────────────────────────────────────────────────────────
# ## Funções de pilares da fachada
# Expandir para ver as variaveis"""
#
#     #p: ponto de referência
#     #dc: distância entre as colunas
#     #nc: número de colunas
#     #dl: distância entre as lajes
#     #nl: número de lajes
#     #np: número de pisos
#     #h: altura do piso
#     #a: largura do pilar
#     #b: profundidade do pilar
#     #cpc: dimensões dos pilares do canto
#     #hvb: altura da viga de bordadura
#     #vz_set_tot: conjunto de vazios e nucleos
#     #vz_set: conjunto de vazios
# ───────────────────────────────────────────────────────────────────────

#Função que cria um pilar
function pilar_singular(p1, h, a, b, p0, phi0) 
    let
        p = p_rotate(p0, p1, phi0)

        pilar_glulam_familia = column_family_element(
            default_column_family(), profile = rectangular_profile(width = b, height = a))

        free_column(p, p + vz(h), phi0, pilar_glulam_familia)
    end
end

#função que seleciona os pontos para criar os pilares da fachada
function pilares_fachada_for(ptss, x, y, h, vz_set_tot, k, p0, phi0, i1, i2, i3, j1, j2, j3, c1, c2) 
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [pilar_singular(ptss[i][j] + vxy(x/2, y/2), h, x, y, p0, phi0)

            for i in i1:i2:i3,  #i define a coluna inicial e final
                j in j1:j2:j3   #j define a linha inicial e final

            if  !in_vz_tot(i, j) && 
                !in_vz_tot(i + c1, j + c2)]
    end
end

#função que seleciona os pontos para criar os pilares dos cantos
function pilares_cantos_for(ptss, c, h, vz_set_tot, k, p0, phi0) 
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)
    
        [pilar_singular(ptss[i][j] + vxy(c/2, c/2), h, c, c, p0, phi0)
            
            for i in 1:(length(ptss)-1):length(ptss),       #i define a coluna inicial e final
                j in 1:(length(ptss[1])-1):length(ptss[1])  #j define a linha inicial e final

            #não cria pilar nos vazios e nucleos nos canto    
            if  !in_vz_tot(i, j) && 
                !in_vz_tot(i-1, j) && 
                !in_vz_tot(i, j-1) && 
                !in_vz_tot(i-1, j-1)]
    end
end

#Criação de pilares da fachada em um piso
function pilares_fachada_piso(p, c, nc, l, nl, dc, dl, h, a, b, cpc, vz_set_tot, k, p0, phi0) 

    #cria o pilar da esquerda das fachadas horizontais em cada laje
    [pilares_fachada_for( 
        pts_grelha(
            p, c, nc, l - b, nl),
        a, b, h, vz_set_tot, k, p0, phi0,
        2, 1, nc,               #define o i inicial, incremento e final
        1, nl, nl + 1,          #define o j inicial, incremento e final
        0, -1),                 #não cria pilar se a linha inferior ou posterior for vazio

     #cria o pilar da direita das fachadas horizontais em cada laje
     pilares_fachada_for(
        pts_grelha(
            p + vx(dc - a), c, nc, l - b, nl),
        a, b, h, vz_set_tot, k, p0, phi0,
        1, 1, nc -1,            #define o i inicial, incremento e final
        1, nl, nl + 1,          #define o j inicial, incremento e final
        0, -1),                 #não cria pilar se a linha inferior ou posterior for vazio

     #cria o pilar inferior das fachadas laterais em cada laje
     pilares_fachada_for(
        pts_grelha(
            p, c - b, nc, l, nl),
        b, a, h, vz_set_tot, k, p0, phi0,
        1, nc, nc + 1,          #define o i inicial, incremento e final
        2, 1, nl,               #define o j inicial, incremento e final
        -1, 0),                 #não cria pilar se a coluna esquerda ou direita for vazio

     #cria o pilar superior das fachadas laterais em cada laje
     pilares_fachada_for(
        pts_grelha(
            p + vy(dl - a), c - b, nc, l, nl),
        b, a, h, vz_set_tot, k, p0, phi0,
        1, nc, nc + 1,          #define o i inicial, incremento e final
        1, 1, nl - 1,           #define o j inicial, incremento e final
        -1, 0),                 #não cria pilar se a coluna esquerda ou direita for vazio

     #cria os pilares dos cantos
     pilares_cantos_for(
        pts_grelha(
            p, c - cpc, nc, l - cpc, nl),
        cpc, h, vz_set_tot, k, p0, phi0)]
end

#função que seleciona os pontos para criar os pilares da fachada interiores
function pilares_fachada_interior_for(ptss, x, y, h, vz_set_tot, vz_set, k, p0, phi0, i1, i2, j1, j2, c1, c2, c3) 
    let 
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)
        in_vz(ii, jj) = tem_indice(vz_set, ii, jj, k)
    
    [pilar_singular(ptss[i][j] + vxy(x/2, y/2), h, x, y, p0, phi0)

        for i in i1:i2,                 #i define a coluna inicial e final
            j in j1:j2                  #j define a linha inicial e final

        if  !in_vz_tot(i, j) &&            #não cria nos vazios e nucleos
            in_vz(i + c1, j + c2) &&      #apenas cria se tiver certos vazios adjacentes
            !in_vz(i, j + c3)]           #não cria se tiver um vazio superior ou inferior (sobreposição)
    end
end

#Criação de pilares da fachada interior em um piso        
function pilares_fachada_interior_piso(p, c, nc, l, nl, dc, dl, h, a, b, vz_set_tot, vz_set, k, p0, phi0) 

    #cria os pilares da esquerda da linha superior das fachadas interiores
    [pilares_fachada_interior_for(
        pts_grelha(
            p, c, nc, l, nl),
        a, b, h, vz_set_tot, vz_set, k, p0, phi0,
        2, nc,                              #i: define a coluna inicial e final
        2, nl,                              #j: define a linha inicial e final
        0, -1, 1000000),                    #define os indices adjacentes onde criar os pilares

    #cria os pilares da direita da linha superior das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vx(dc - a), c, nc, l, nl),
        a, b, h, vz_set_tot, vz_set, k, p0, phi0,
        1, nc - 1,                          #i: define a coluna inicial e final    
        2, nl,                              #j: define a linha inicial e final
        0, -1, 1000000),                    #define os indices adjacentes onde criar os pilares

    #cria os pilares da esquerda da linha inferior das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vy(dl - b), c, nc, l, nl),
        a, b, h, vz_set_tot, vz_set, k, p0, phi0,    
        2, nc,                              #i: define a coluna inicial e final
        1, nl - 1,                          #j: define a linha inicial e final
        0, 1, 1000000),                     #define os indices adjacentes onde criar os pilares

    #cria os pilares da direita da linha inferior das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vxy(dc - a, dl - b), c, nc, l, nl),
        a, b, h, vz_set_tot, vz_set, k, p0, phi0,
        1, nc - 1,                          #i: define a coluna inicial e final
        1, nl - 1,                          #j: define a linha inicial e final
        0, 1, 1000000),                     #define os indices adjacentes onde criar os pilares

    #cria os pilares inferiores da coluna direita das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p, c, nc, l, nl),
        b, a, h, vz_set_tot, vz_set, k, p0, phi0,
        2, nc - 1,                          #i: define a coluna inicial e final
        2, nl,                              #j: define a linha inicial e final
        -1, 0, -1),                         #define os indices adjacentes onde criar os pilares

    #cria os pilares superiores da coluna direita das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vy(dl - a), c, nc, l, nl),
        b, a, h, vz_set_tot, vz_set, k, p0, phi0,
        2, nc - 1,                          #i: define a coluna inicial e final
        1, nl - 1,                          #j: define a linha inicial e final
        -1, 0, 1),                          #define os indices adjacentes onde criar os pilares

    #cria os pilares inferioes da coluna esquerda das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vx(dc - b), c, nc, l, nl),
        b, a, h, vz_set_tot, vz_set, k, p0, phi0,
        1, nc - 1,                          #i: define a coluna inicial e final
        2, nl,                              #j: define a linha inicial e final
        1, 0, -1),                          #define os indices adjacentes onde criar os pilares

    #cria os pilares superiores da coluna esquerda das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vxy(dc - b, dl - a), c, nc, l, nl),
        b, a, h, vz_set_tot, vz_set, k, p0, phi0,
        1, nc - 1,                          #i: define a coluna inicial e final
        1, nl - 1,                          #j: define a linha inicial e final
        1, 0, 1)]                           #define os indices adjacentes onde criar os pilares
end

#função que seleciona os pontos para criar os pilares dos cantos interiores
function pilares_cantos_interiores_for(ptss, x, y, h, vz_set_tot, vz_set, k, p0, phi0, i1, i2, j1, j2, c1, c2, c3, c4) 
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)
        in_vz(ii, jj) = tem_indice(vz_set, ii, jj, k)

        [pilar_singular(ptss[i][j] + vxy(x/2, y/2), h, x, y, p0, phi0)

        for i in i1:i2,                     #i define a coluna inicial e final
            j in j1:j2                      #j define a linha inicial e final

        if  in_vz(i, j) &&                  #apenas cria nos vazios
            !in_vz_tot(i + c1, j + c2) &&   #cria apenas se não tiver certos vazios adjacentes
            !in_vz_tot(i + c3, j + c4) && 
            !in_vz_tot(i + c1, j + c4)]
    end
end

#Criação de pilares dos cantos interiores em um piso
function pilares_cantos_interiores_piso(p, c, nc, l, nl, dc, dl, h, cpc, vz_set_tot, vz_set, k, p0, phi0) 

    #cria os pilares dos cantos inferiores esquerdos interiores
    [pilares_cantos_interiores_for(
        pts_grelha(
            p, c, nc, l, nl),
        -cpc, -cpc, h, vz_set_tot, vz_set, k, p0, phi0,
        2, nc,                                  #i: define a coluna inicial e final
        2, nl,                                  #j: define a linha inicial e final
        -1, 0,                                  #indice adjacente que não pode ser vazio
        0, -1),                                 #indice adjacente que não pode ser vazio

    #cria os pilares dos cantos superiores esquerdos interiores
     pilares_cantos_interiores_for(
        pts_grelha(
            p + vy(dl), c, nc, l, nl),
        -cpc, cpc, h, vz_set_tot, vz_set, k, p0, phi0,
        2, nc,                                  #i: define a coluna inicial e final
        1, nl - 1,                              #j: define a linha inicial e final
        -1, 0,                                  #indice adjacente que não pode ser vazio
        0, 1),                                  #indice adjacente que não pode ser vazio

    #cria os pilares dos cantos inferiores direitos interiores
     pilares_cantos_interiores_for(
        pts_grelha(
            p + vx(dc), c, nc, l, nl),
        cpc, -cpc, h, vz_set_tot, vz_set, k, p0, phi0,
        1, nc - 1,                              #i: define a coluna inicial e final
        2 , nl,                                 #j: define a linha inicial e final
        1, 0,                                   #indice adjacente que não pode ser vazio
        0, -1),                                 #indice adjacente que não pode ser vazio

    #cria os pilares dos cantos superiores direitos interiores
     pilares_cantos_interiores_for(
        pts_grelha(
            p + vxy(dc, dl), c, nc, l, nl),
        cpc, cpc, h, vz_set_tot, vz_set, k, p0, phi0,
        1, nc - 1,                              #i: define a coluna inicial e final
        1, nl - 1,                              #j: define a linha inicial e final
        1, 0,                                   #indice adjacente que não pode ser vazio
        0, 1)]                                  #indice adjacente que não pode ser vazio
end

#Criação de pilares da fachada em todos os pisos
function pilares_fachada_total(p, dc, nc, dl, nl, np, h, a, b, cpc, hvb, vz_set_tot, vz_set, p0, phi0) 

    #Criação de pilares da fachada em todos os pisos
    [[pilares_fachada_piso(
        p + vz(h * k - h),
        dc * nc, nc, dl * nl, nl, dc, dl,
        h - hvb, a, b, cpc, vz_set_tot, k, p0, phi0)

            for k in 1:np],

    #Criação de pilares da fachada interior em todos os pisos
     [pilares_fachada_interior_piso(
        p + vz(h * k - h),
        dc * nc, nc, dl * nl, nl, dc, dl,
        h - hvb, a, b, vz_set_tot, vz_set, k, p0, phi0)

            for k in 1:np],

    #Criação de pilares de cantos interiores em todos os pisos
     [pilares_cantos_interiores_piso(
        p + vz(h * k - h),
        dc * nc, nc, dl * nl, nl, dc, dl,
        h - hvb, cpc, vz_set_tot, vz_set, k, p0, phi0)

            for k in 1:np]]
end

# ───────────────────────────────────────────────────────────────────────
# ## Funções de pilares interiores
# Expandir para ver as variaveis"""
#
#     #p: ponto de referência
#     #dc: distância entre colunas
#     #nc: número de colunas
#     #dl: distância entre linhas
#     #nl: número de linhas
#     #np: número de pisos
#     #h: altura do piso
#     #hvi: altura da viga interior
#     #api: dimensão dos pilares interiores
#     #vz_set: conjunto de indices vazios
# ───────────────────────────────────────────────────────────────────────

#Função que cria um pilar
function pilar_interior(p1, api, h, p0, phi0) 
    let
        p = p_rotate(p0, p1, phi0)

        pilar_betao_familia = column_family_element(
            default_column_family(), profile = rectangular_profile(width = api, height = api))

        free_column(p, p + vz(h), phi0, pilar_betao_familia)
    end
end

#Função que seleciona os pontos para criar os pilares interiores
function pilares_interiores_for(ptss, h, api, vz_set_tot, k, p0, phi0) 
    let 
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [pilar_interior(ptss[i][j], api, h, p0, phi0)

        for i in 3:2:(length(ptss)-1),      #i define a coluna inicial e final
            j in 2:(length(ptss[1])-1)      #j define a linha inicial e final

        if !in_vz_tot(i, j) &&              #não cria pilar nos vazios e cantos dos nucleos
           !in_vz_tot(i-1, j) && 
           !in_vz_tot(i, j-1) && 
           !in_vz_tot(i-1, j-1)]
    end
end

#Criação de pilares interiores em um piso 
function pilares_interior_piso(p, c, n, l, m, h, api, vz_set_tot, k, p0, phi0) 

    [pilares_interiores_for(
        pts_grelha(
            p, c, n, l, m),
        h, api, vz_set_tot, k, p0, phi0)]
end

#Criação de pilares interiores em todos os pisos
function pilares_interior_total(p, dc, nc, dl, nl, np, h, hvi, api, vz_set_tot, p0, phi0) 

    [pilares_interior_piso(
        p + vz(h * k - h), dc * nc, nc, dl * nl, nl, h - hvi, api, vz_set_tot, k, p0, phi0)

    for k in 1:np]
end

# ───────────────────────────────────────────────────────────────────────
# ## Funções de vigas de bordadura
# Expandir para ver as variaveis"""
#
#     #p: ponto de referência
#     #dc: distância entre as colunas
#     #nc: número de colunas
#     #dl: distância entre as linhas
#     #nl: número de linhas
#     #hvb: altura das vigas de bordadura
#     #bvb: largura das vigas de bordadura
#     #h: altrura de cada piso
#     #np: número de pisos
#     #e: espessura da laje
#     #vz_set: conjunto de indices vazios
#     #ncl_set: conjunto de indices dos nucleos
# ───────────────────────────────────────────────────────────────────────

#Função que cria uma viga de bordadura
function viga_bordadura_singular(p1, bvb, hvb, xvb, yvb, p0, phi0, offset1x, offset2x, offset1y, offset2y) 
    let
        p_rot(p) = p_rotate(p0, p, phi0)

        viga_bordadura_familia = beam_family_element(
            default_beam_family(), profile = top_aligned_rectangular_profile(width = bvb, height = hvb))

        [beam(
            p_rot(
                p1 + vxy(offset1x, offset1y)),
            p_rot(
                p1 + vxy(xvb - offset2x, yvb - offset2y)),
            0, viga_bordadura_familia)] 
    end
end

#Função que seleciona pontos para criar uma viga de bordadura_linha na fachada do ediifico
function viga_bordadura_for(ptss, bvb, hvb, xvb, yvb, vz_set_tot, k, p0, phi0, offsetx, offsety, c1, c2, c3, c4, i1, j1) 
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [viga_bordadura_singular(ptss[i][j], bvb, hvb, xvb, yvb, p0, phi0,

            #define o offset em x
            i == 1 ? offsetx : 0,                         #aplica offset se for a primeira coluna
            i == length(ptss) - 1 ? offsetx : 0,          #aplica offset se for a ultima coluna 

            #define o offset em y
            j == 1 ? offsety : 0,                         #aplica offset se for a primeira linha
            j == length(ptss[1]) - 1 ? offsety : 0)       #aplica offset se for a ultima linha   

            for i in c1:c2,                             #i define a coluna inicial e final
                j in c3:c4                              #j define a linha inicial e final

            if !in_vz_tot(i + i1, j + j1)]      #se i + i1, j + j1 estiverem no set_1, nao cria viga
    end
end

#Criação de vigas de bordadura em um piso
function viga_bordadura_piso(p, dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k, p0, phi0) 
    let
        vz_set_tot = vcat([vz_set, ncl_set]...)

        #Cria a linha inferior
        [viga_bordadura_for(
            pts_grelha(
                p + vyz(bvb/2, -e),
            dc * nc, nc, dl * nl - bvb, nl),
            bvb, hvb, dc, 0, vz_set_tot, k, p0, phi0,
            0, 0,                           #offset em (x, y) da viga incial e final
            1, nc,                          #i define a coluna inicial e final
            1, 1,                           #j define a linha inicial e final
            0, 0),                          #(i, j) se j=0 no vaios_set_tot, não cria viga   

        #Cria a linha superior
        viga_bordadura_for( 
            pts_grelha(
                p + vyz(-bvb/2, -e),
            dc * nc, nc, dl * nl, nl),
            bvb, hvb, dc, 0, vz_set_tot, k, p0, phi0,
            0, 0,                           #offset em (x, y) da viga incial e final
            1, nc,                          #i define a coluna inicial e final
            nl + 1, nl + 1,                 #j define a linha inicial e final
            0, -1),                         #(i, j) se j=nl no vaios_set_tot, não cria viga

        #cria a coluna esquerda
        viga_bordadura_for(
            pts_grelha(
                p + vxz(bvb/2, -e),
            dc * nc, nc, dl * nl, nl),
            bvb, hvb, 0, dl, vz_set_tot, k, p0, phi0,
            0, bvb,                         #offset em (x, y) da viga incial e final
            1, 1,                           #i define a coluna inicial e final
            1, nl,                          #j define a linha inicial e final
            0, 0),                          #(i, j) se i=0 no vaios_set_tot, não cria viga

        #cria a coluna direita
        viga_bordadura_for(
            pts_grelha(
                p + vxz(-bvb/2, -e),
            dc * nc, nc, dl * nl, nl),
            bvb, hvb, 0, dl, vz_set_tot, k, p0, phi0,
            0, bvb,                         #offset em (x, y) da viga incial e final
            nc + 1, nc + 1,                 #i define a coluna inicial e final
            1, nl,                          #j define a linha inicial e final
            -1, 0)]                         #(i, j) se i=nc no vaios_set_tot, não cria viga
    end
end

#função que seleciona os pontos para criar as vigas de bordadura interiores
function viga_bordadura_for_interior(ptss, bvb, hvb, xvb, yvb, vz_set, vz_set_tot, ncl_set, k, p0, phi0, i0, j0, offsetx, offsety, i1, i2, i3, i4, j1, j2, c1, c2) 
    let
        in_vz(ii, jj)       = tem_indice(vz_set, ii, jj, k)
        in_vz_tot(ii, jj)   = tem_indice(vz_set_tot, ii, jj, k)
        in_ncl(ii, jj)      = tem_indice(ncl_set, ii, jj, k)

        [viga_bordadura_singular(
            ptss[i + i0][j + j0], bvb, hvb, xvb, yvb, p0, phi0,

            #define o offset em x
            i == 1 ? offsetx : 0,                   #aplica offset se for a primeira coluna
            i == length(ptss) - 1 ? offsetx : 0,  #aplica offset se for a ultima coluna

            #define of offset em y inferior
            j == 1 ? offsety :                      #aplica offset se for a primeira linha
            in_ncl(i, j - 1) ? 0 :                  #não aplica offset se a linha anterior tiver nucleo
            in_vz(i, j - 1) ? offsety :             #aplica offset se a linha anterior tiver vazio
            !in_vz(i + i1, j - 1) ? -offsety :      #extende a viga se for a primeira do vazio
            0,

            #define o offset em y superior
            j == length(ptss[1]) - 1 ? offsety :    #aplica offset se for a ultima linha
            in_ncl(i, j + 1) ? 0 :                  #não aplica offset se a linha posterior tiver nucleo
            in_vz(i, j + 1) ? offsety :             #aplica offset se a linha posterior tiver vazio
            !in_vz(i + i2, j + 1) ? -offsety :      #extende a viga se for a ultima do vazio
            0)
                
        for i in i3:i4,                             #i define a coluna inicial e final
            j in j1:j2                              #j define a linha inicial e final

        if in_vz(i + c1, j + c2) &&                 #apenas cria viga se i+ c1, j + c2 estiver no vz_set
           !in_vz_tot(i, j)]                        #não cria viga se i, j estiver no vz_set_tot
    end
end

#cria as vigas de bordadura internas    
function viga_bordadura_interior_piso(p, dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k, p0, phi0) 
    let
        vz_set_tot = vcat([vz_set, ncl_set]...)

        #cria as linhas superiores de vigas de bordadura
        [viga_bordadura_for_interior(
            pts_grelha(
                p + vyz(bvb/2, -e), 
            dc * nc, nc, dl * nl, nl),
            bvb, hvb, dc, 0, vz_set, vz_set_tot, ncl_set, k, p0, phi0,
            0, 0,                                       #i0, j0
            bvb, 0,                                     #offset em (x, y) da viga incial e final
            0, 0,                                       #i1, i2
            1, nc,                                      #i3, i4: define a coluna inicial e final
            2, nl,                                      #j1, j2: define a linha inicial e final
            0, -1),                                     #cria a viga se a linha anterior for vazia

        #cria as linhas inferiores de vigas de bordadura
         viga_bordadura_for_interior(
            pts_grelha(
                p + vyz(-bvb/2, -e), 
            dc * nc, nc, dl * nl, nl),
            bvb, hvb, dc, 0, vz_set, vz_set_tot, ncl_set, k, p0, phi0,
            0, 1,                                       #i0, j0
            bvb, 0,                                     #offset em (x, y) da viga incial e final
            0, 0,                                       #i1, i2
            1, nc,                                      #i3, i4: define a coluna inicial e final
            1, nl - 1,                                  #j1, j2: define a linha inicial e final
            0, 1),                                      #cria a viga se a linha posterior for vazia

        #cria as colunas direitas de vigas de bordadura
         viga_bordadura_for_interior(
            pts_grelha(
                p + vxz(bvb/2, -e), 
            dc * nc, nc, dl * nl, nl),
            bvb, hvb, 0, dl, vz_set, vz_set_tot, ncl_set, k, p0, phi0,
            0, 0,                                       #i0, j0
            0, bvb,                                     #offset em (x, y) da viga incial e final
            -1, -1,                                     #i1, i2
            2, nc,                                      #i3, i4: define a coluna inicial e final
            1, nl,                                      #j1, j2: define a linha inicial e final
            -1, 0),                                     #cria a viga se a coluna anterior for vazia

        #cria as colunas esquerdas de vigas de bordadura
         viga_bordadura_for_interior(
            pts_grelha(
                p + vxz(-bvb/2, -e), 
            dc * nc, nc, dl * nl, nl),
            bvb, hvb, 0, dl, vz_set, vz_set_tot, ncl_set, k, p0, phi0,
            1, 0,                                       #i0, j0
            0, bvb,                                     #offset em (x, y) da viga incial e final
            1, 1,                                       #i1, i2
            1, nc - 1,                                  #i3, i4: define a coluna inicial e final
            1, nl,                                      #j1, j2: define a linha inicial e final
            1, 0)]                                      #cria a viga se a coluna posterior for vazia
    end
end

#Criação de vigas de bordadura em todos os pisos
function viga_bordadura_total(p, dc, nc, dl, nl, hvb, bvb, h, np, e, vz_set, ncl_set, p0, phi0) 

    [[viga_bordadura_piso(
        p + vz(h * k), dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k, p0, phi0)

            for k in 1:np],

     [viga_bordadura_interior_piso(
        p + vz(h * k), dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k, p0, phi0)

            for k in 1:np]]
end

# ───────────────────────────────────────────────────────────────────────
# ## Funções de vigas interiores
# Expandir para ver as variaveis"""
#
#     #p: ponto de referência
#     #dc: distância entre as colunas
#     #nc: número de colunas
#     #dl: distância entre as linhas
#     #nl: número de linhas
#     #h: altura de cada piso
#     #np: número de pisos
#     #hvi: altura das vigas interiores
#     #bvi: largura das vigas interiores
#     #e: espessura da laje de betão
#     #bvb: largura da viga de bordadura
#     #vz_set: conjunto de indices vazias
# ───────────────────────────────────────────────────────────────────────

#Função que cria as vigas interiores
function viga_interior_singular(p1, hvi, L, bvi, p0, phi0, offset1, offset2) 
    let 
        p_rot(p) = p_rotate(p0, p, phi0)

        viga_interior_familia = beam_family_element(
            default_beam_family(), profile = top_aligned_rectangular_profile(width = bvi, height = hvi))

        beam(
            p_rot(
                p1 + vx(offset1)),
            p_rot(
                p1 + vx(L - offset2)),
            0, viga_interior_familia)
    end
end

#Função que seleciona os pontos para criar as vigas interiores
function viga_interior_for(ptss, hvi, L, bvi, offset, vz_set_tot, vz_set, k, p0, phi0) 
    let
        in_vz_tot(ii, jj)   = tem_indice(vz_set_tot, ii, jj, k)
        in_vz(ii, jj)       = tem_indice(vz_set, ii, jj, k)

        [viga_interior_singular(ptss[i][j], hvi, L, bvi, p0, phi0,

        #define o offset em x à esquerda
        i == 1 ? offset :                   #aplica offset na primieira coluna
        in_vz(i - 1, j) ? offset :          #aplica offset se as colunas anteriores tiverem vazio
        in_vz(i - 1, j - 1) ? offset :
        0,

        #define o offset em x à direita
        i == length(ptss) ? offset :        #aplica offset na ultima coluna
        in_vz(i + 1, j) ? offset :          #aplica offset se as colunas posteriores tiverem vazio
        in_vz(i + 1, j - 1) ? offset :
        0) 

        for i in 1:length(ptss)-1,          #i define a coluna
            j in 2:(length(ptss[1])-1)      #j define a linha

        if  !in_vz_tot(i, j) &&             #não cria viga se i, j estiver no vz_set 
            !in_vz_tot(i, j - 1)]           #não cria viga se i, j-1 estiver no vz_set
    end
end

#Criação de vigas interiores em um piso
function viga_interior_piso(p, dc, nc, dl, nl, hvi, bvi, e, bvb, vz_set_tot, vz_set, k, p0, phi0) 

    [viga_interior_for(
        pts_grelha(
            p + vz(- e), dc * nc, nc, dl * nl, nl),
        hvi, dc, bvi, bvb, vz_set_tot, vz_set, k, p0, phi0)]
end

#Criação de vigas interiores em todos os pisos
function viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e, bvb, vz_set_tot, vz_set, p0, phi0) 

    [viga_interior_piso(
        p + vz(h * k), dc, nc, dl, nl, hvi, bvi, e, bvb, vz_set_tot, vz_set, k, p0, phi0)

            for k in 1:np]
end

# ───────────────────────────────────────────────────────────────────────
# ## Funções de núcleos
# Expandir para ver as variaveis"""
#
#     #p: ponto de referência
#     #dc: distância entre as colunas
#     #nc: número de colunas
#     #dl: distância entre as linhas
#     #nl: número de linhas
#     #h: altura de cada piso
#     #enb: espessura do núcleo de betão
#     #ncl_set: conjunto de indices de núcleos vazios
# ───────────────────────────────────────────────────────────────────────

#Função que cria um núcleo
function nucleo_singular(p01, c, l, h_tot, enb, p0, phi0) 
    let
        p_rot(p) = p_rotate(p0, p, phi0)

        p1 = p_rot(p01)
        p2 = p_rot(p01 + vxy(c, 0))
        p3 = p_rot(p01 + vxy(c, l))
        p4 = p_rot(p01 + vxy(0, l))
        pts = [p1, p2, p3, p4]

        parede_nucleo_familia = wall_family_element(
            default_wall_family(), thickness = enb)
        
        roof_nucleo_familia = roof_family_element(
            default_roof_family(), thickness = enb)

        wall(closed_polygonal_path(pts), level(0), level(h_tot - enb), parede_nucleo_familia)
        roof(closed_polygonal_path(pts), level(h_tot - enb), roof_nucleo_familia)
    end
end

#Função que seleciona os pontos para criar os núcleos
function nucleo_for(ptss, dc, dl, h, enb, ncl_set, p0, phi0) 

    [nucleo_singular(
        ptss[ncl[1]][ncl[2]],   #coluna e a linha iniciais do núcleo
        dc * ncl[3],            #número de núcleos consecutivos em x * dc
        dl * ncl[4],            #número de núcleos consecutivos em y * dl
        h * ncl[5],              #número de pisos e a altura de cada piso
        enb, p0, phi0)                   #espessura do núcleo

    for ncl in ncl_set]
end

#Função que entrega um array de arrays de pontos para criar os núcleos
function nucleo_total(p, dc, nc, dl, nl, h, enb, ncl_set, p0, phi0) 

    nucleo_for(
        pts_grelha(
            p, dc * nc, nc, dl * nl, nl),
        dc, dl, h, enb, ncl_set, p0, phi0)
end

#Função que cria um set com as posições e dimensões dos núcleos
function nucleos_set_count(ncl_set, np)
    let
        #verifica se o núcleo existe
        tem_nucleo(i, j) =                                          
            any(n -> n[1] == i && n[2] == j, ncl_set)

        #retorna o núcleo completo
        pega_nucleo(i, j) =                                        
            first(n for n in ncl_set if n[1] == i && n[2] == j)

        #conta os núcleos consecutivos para a direita
        function conta_direita(i, j)
            c = 0
            while tem_nucleo(i + c + 1, j)
                c += 1
            end
            c
        end

        #conta os núcleos consecutivos para cima
        function conta_cima(i, j)
            c = 0
            while tem_nucleo(i, j + c + 1)
                c += 1
            end
            c
        end

        #retorna o núcleo com maior altura dos nucleos consecutivos
        function core_value(i, j, w, h)
            cores = [                       #cria um array dos núcleos consecutivos
                pega_nucleo(ii, jj)
                for ii in i:(i + w - 1),
                    jj in j:(j + h - 1)
                if tem_nucleo(ii, jj)]
            
            #cria um array com as alturas dos núcleos consecutivos se o input não for vazio
            nums = vcat([n[3] for n in cores if !isempty(n[3])]...) 
            
            #se o array de alturas estiver vazio, retorna o número de pisos, se não, retorna a maior altura
            isempty(nums) ? np : maximum(nums)
        end

        [
            begin
                w = conta_direita(i, j) + 1
                h = conta_cima(i, j) + 1

                #cria um array com nucleo, nº de adjacente para cima e direita e a altura do núcleo
                [i, j, w, h, core_value(i, j, w, h)]
            end

            for n in ncl_set                #repete para todos os arrays do input set
                for i = n[1], j = n[2]      #i é o primeiro elemento do array e j o segundo

            if i > 0 && j > 0 &&            
               !tem_nucleo(i - 1, j) &&     #não repete se tiver um núcleo ao lado esquerdo
               !tem_nucleo(i, j - 1)        #não repete se tiver um núcleo abaixo
        ]
    end
end

# ───────────────────────────────────────────────────────────────────────
# ## Funções de paineis de fachada
# Expandir para ver as variaveis"""
#
#     #p: ponto de referência
#     #dc: distância entre as colunas
#     #nc: número de colunas
#     #dl: distância entre as linhas
#     #nl: número de linhas
#     #h: altura de cada piso
#     #np: número de pisos
#     #e_fachada: espessura do painel de fachada
#     #vz_set: conjunto de indices vazios
#     #vz_set_tot: conjunto de indices vazios e nucleos
# ───────────────────────────────────────────────────────────────────────

#Função que cria um painel de fachada
function painel_fachada_singular(p1, p2, h, e, p0, phi0, janelas_set) 
    let
        p11 = p_rotate(p0, p1, phi0)
        p22 = p_rotate(p0, p2, phi0)

        painel_fachada_familia = wall_family_element(
            default_wall_family(), thickness = e)

        painel_fachada = wall(polygonal_path(p11, p22), level(0), level(h), painel_fachada_familia)

        if janelas_set == [] 
            nothing
        else
            for i in 1:length(janelas_set)

                janela_familia = window_family_element(
                    default_window_family(), 
                        width       = janelas_set[i][3], 
                        height      = janelas_set[i][4], 
                        thickness   = 0.05)

                add_window(
                    painel_fachada,
                    xy(janelas_set[i][1], janelas_set[i][2]), janela_familia)
            end
        end
    end
end

#Função que seleciona os pontos para criar paineis de fachada
function painel_fachada_for(ptss, h, vz_set_tot, janelas_set, k, p0, phi0, i00, j00, i01, j01, i1, i2, j1, j2, c1, c2, c3, c4, e) 
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [painel_fachada_singular(
            ptss[i + i00][j + j00], ptss[i + i01][j + j01], h, e, p0, phi0, janelas_set)

        for i in i1:i2, #i define a coluna inicial e final
            j in j1:j2 #j define a linha inicial e final

        if  !in_vz_tot(i + c1, j + c2) && 
            !in_vz_tot(i + c3, j + c4)]
    end
end

#Criação de paineis de fachada em um piso
function painel_fachada_piso(p, c, nc, l, nl, h, vz_set_tot, jan_set_l, jan_set_c, e_fachada, k, p0, phi0) 

    #cria a linha inferior de paineis de fachada
    [painel_fachada_for(
        pts_grelha(
            p + vy(-e_fachada/2), c, nc, l, nl), 
        h, vz_set_tot, jan_set_l, k, p0, phi0,
        0, 0,
        1, 0,                   #posição (x,y) do p2 relativamente ao p1
        1, nc,                  #i define a coluna inicial e final
        1, 1,                   #j define a linha inicial e final
        0, 0,                   #c1, c2 definem o primeiro indice de vazios
        0, -1,                  #c3, c4 definem o segundo indice de vazios
        e_fachada),         
    
    #cria a linha superior de paineis de fachada
     painel_fachada_for(
        pts_grelha(
            p + vy(e_fachada/2), c, nc, l, nl), 
        h, vz_set_tot, jan_set_l, k, p0, phi0,
        1, 0,
        0, 0,                   #posição (x,y) do p2 relativamente ao p1
        1, nc,                  #i define a coluna inicial e final
        nl + 1, nl + 1,         #j define a linha inicial e final
        0, -1,                  #c1, c2 definem o primeiro indice de vazios
        0, 0,                   #c3, c4 definem o segundo indice de vazios
        e_fachada),          

    #cria a coluna esquerda de paineis de fachada
     painel_fachada_for(
        pts_grelha(
            p + vx(-e_fachada/2), c, nc, l, nl), 
        h, vz_set_tot, jan_set_c, k, p0, phi0,
        0, 1,
        0, 0,                   #posição (x,y) do p2 relativamente ao p1
        1, 1,                   #i define a coluna inicial e final
        1, nl,                  #j define a linha inicial e final
        0, 0,                   #c1, c2 definem o primeiro indice de vazios
        -1, 0,                  #c3, c4 definem o segundo indice de vazios
        e_fachada),         

    #cria a coluna direita de paineis de fachada
     painel_fachada_for(
        pts_grelha(
            p + vx(e_fachada/2), c, nc, l, nl), 
        h, vz_set_tot, jan_set_c, k, p0, phi0,
        0, 0,
        0, 1,                   #posição (x,y) do p2 relativamente ao p1
        nc + 1, nc + 1,         #i define a coluna inicial e final
        1, nl,                  #j define a linha inicial e final
        -1, 0,                  #c1, c2 definem o primeiro indice de vazios
        0, 0,                   #c3, c4 definem o segundo indice de vazios
        e_fachada)] 
end

#Função que seleciona os pontos para criar paineis de fachada interiores
function painel_fachada_interior_for(ptss, h, vz_set, vz_set_tot, janelas_set, k, p0, phi0, i00, j00, i01, j01, i1, i2, j1, j2, c1, c2, e, offset) 
    let
        in_vz(ii, jj)       = tem_indice(vz_set, ii, jj, k)
        in_vz_tot(ii, jj)   = tem_indice(vz_set_tot, ii, jj, k)

        [painel_fachada_singular(
            ptss[i + i00][j + j00] + vy(
                j == 1 ? 0 :
                !in_vz(i, j - 1) ? offset :     #offset para evitar sobreposição de paineis nos cantos
                0),

            ptss[i + i01][j + j01] - vy(
                j == length(ptss[1]) - 1 ? 0 :  #offset para evitar sobreposição de paineis nos cantos
                !in_vz(i, j + 1) ? offset : 
                0),
            h, e, p0, phi0, janelas_set)

        for i in i1:i2,                     #i define a coluna inicial e final
            j in j1:j2                      #j define a linha inicial e final

        if  in_vz(i, j) &&                  #apenas cria nos vazios
            !in_vz_tot(i + c1, j + c2)]     #não cria se tiver certos vazios adjacentes
    end
end

#Cria os paineis de fachada interiores em um piso
function painel_fachada_interior_piso(p, c, nc, l, nl, dc, dl, h, vz_set, vz_set_tot, jan_set_l, jan_set_c, e_fachada, k, p0, phi0) 

    #cria a linha superior das fachadas interiores
    [painel_fachada_interior_for(
        pts_grelha(
            p + vy(dl - e_fachada/2), c, nc, l, nl),
        h, vz_set, vz_set_tot, jan_set_l, k, p0, phi0,
        0, 0, #posição (x,y) do p1 relativamente ao p
        1, 0, #posição (x,y) do p2 relativamente ao p
        1, nc,
        1, nl - 1,
        0, 1,
        e_fachada, 0),

    #cria a linha inferior das fachadas interiores
     painel_fachada_interior_for(
        pts_grelha(
            p + vy(e_fachada/2), c, nc, l, nl), 
        h, vz_set, vz_set_tot, jan_set_l, k, p0, phi0,
        1, 0, #posição (x,y) do p1 relativamente ao p
        0, 0, #posição (x,y) do p2 relativamente ao p
        1, nc,
        2, nl,
        0, -1,
        e_fachada, 0),

    #cria a coluna esquerda das fachadas interiores
     painel_fachada_interior_for(
        pts_grelha(
            p + vx(e_fachada/2), c, nc, l, nl), 
        h, vz_set, vz_set_tot, jan_set_c, k, p0, phi0,
        0, 0, #posição (x,y) do p1 relativamente ao p
        0, 1, #posição (x,y) do p2 relativamente ao p
        2, nc,
        1, nl,
        -1, 0,
        e_fachada, e_fachada),

    #cria a coluna direita das fachadas interiores
     painel_fachada_interior_for(
        pts_grelha(
            p + vx(dc - e_fachada/2), c, nc, l, nl), 
        h, vz_set, vz_set_tot, jan_set_c, k, p0, phi0,
        0, 1, #posição (x,y) do p1 relativamente ao p
        0, 0, #posição (x,y) do p2 relativamente ao p
        1, nc - 1,
        1, nl,
        1, 0,
        e_fachada, e_fachada)]
end

#Criação de paineis de fachada em todos os pisos
function painel_fachada_total(p, dc, nc, dl, nl, np, h, vz_set, vz_set_tot, jan_set_l, jan_set_c, e_fachada, p0, phi0) 

    [[painel_fachada_piso(
        p + vz(h * k - h), dc * nc, nc, dl * nl, nl, h, vz_set_tot, jan_set_l, jan_set_c, e_fachada, k, p0, phi0)

            for k in 1:np],

     [painel_fachada_interior_piso(
        p + vz(h * k - h), dc * nc, nc, dl * nl, nl, dc, dl, h, vz_set, vz_set_tot, jan_set_l, jan_set_c, e_fachada, k, p0, phi0) 
            
            for k in 1:np]]
end

# ───────────────────────────────────────────────────────────────────────
# Top level: assemble the building, and the entry point
# ───────────────────────────────────────────────────────────────────────

edificio_CREE(p, nl, nc, dl, dc, np, h, p0, phi0, janelas_set_l, janelas_set_c, vazios_set, nucleos_set,
              dims::DimensoesSistema = DIMENSOES_PADRAO) =
    let
        e_laje    = dims.e_laje
        apf       = dims.apf
        bpf       = dims.bpf
        cpc       = dims.cpc
        hvb       = dims.hvb
        bvb       = dims.bvb
        hvi       = dims.hvi
        bvi       = dims.bvi
        api       = dims.api
        enb       = dims.enb
        hvL       = dims.hvL
        bvL       = dims.bvL
        e_fachada = dims.e_fachada

        vz_set = completa_vazios(vazios_set, np)
        ncl_set = completa_vazios(nucleos_set, np)
        vz_set_tot = vcat([vz_set, ncl_set]...)

        laje_total(
            p, dc, nc, dl, nl, np, h, e_laje, bvb, bvi, bvL, hvL, vz_set, ncl_set, p0, phi0)
        pilares_fachada_total(
            p, dc, nc, dl, nl, np, h, apf, bpf, cpc, hvb + e_laje, vz_set_tot, vz_set, p0, phi0)
        pilares_interior_total(
            p, dc, nc, dl, nl, np, h, hvi + e_laje, api, vz_set_tot, p0, phi0)
        viga_bordadura_total(
            p, dc, nc, dl, nl, hvb, bvb, h, np, e_laje, vz_set, ncl_set, p0, phi0)
        viga_interior_total(
            p, dc, nc, dl, nl, h, np, hvi, bvi, e_laje, bvb, vz_set_tot, vz_set, p0, phi0)
        nucleo_total(
                p, dc, nc, dl, nl, h, enb, nucleos_set_count(ncl_set, np), p0, phi0)
        painel_fachada_total(
            p, dc, nc, dl, nl, np, h, vz_set, vz_set_tot, janelas_set_l, janelas_set_c, e_fachada, p0, phi0)
    end

generate_model(params::EdificioParams, dims::DimensoesSistema = DIMENSOES_PADRAO) =
    begin
        delete_all_shapes()

        edificio_CREE(
            xyz(params.x_Origem, params.y_Origem, params.z_Origem),      

            params.Número_linhas,
            params.Número_colunas,
            params.Dist_entre_linhas,
            params.Dist_entre_colunas,
            params.Número_pisos,
            params.Altura_piso,

            xyz(params.x_rotação_Origem, params.y_rotação_Origem, 0),
            params.Rotação,

            params.Janelas_linha,
            params.Janelas_coluna,
            params.Vazios,
            params.Núcleos,

            dims
        )
    end

end # module CREE
