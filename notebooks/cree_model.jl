### A Pluto.jl notebook ###
# v1.0.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 171da720-3306-453f-9572-83fabd08b3b0
using PlutoUI

# ╔═╡ 3214848e-1df3-41c0-9ae3-039e6615af19
md"# Modelo paramétrico CREE
Versão 5.0.0"

# ╔═╡ e162d689-8acf-417c-ac6e-5ab90933adef
import PlutoUI: combine

# ╔═╡ 4c141db1-e614-4ab7-b659-8a6163d716df
md"## Parãmetros"

# ╔═╡ 359f6b87-837c-43aa-bdd9-05bb7fc95f7f
md"#### Ponto de Origem"

# ╔═╡ 5f88a907-59d9-4df0-a238-f22c590a337f
md"Coordenadas (x, y, z) da origem do modelo paramétrico:"

# ╔═╡ 69a09497-d356-4846-a170-5788c57d8664
@bind param_Ox confirm(NumberField(-100:0.1:100, default=0))

# ╔═╡ fe22bcf5-4a9c-41ba-bfe8-06dec03f2970
@bind param_Oy confirm(NumberField(-100:0.1:100, default=0))

# ╔═╡ c3f7c6f9-21cc-4962-9c21-0a71bb9268d5
@bind param_Oz confirm(NumberField(-100:0.1:100, default=0))

# ╔═╡ ee12c60b-1150-44b8-bc06-62c0ffe55d57
md"#### Grelha CREE"

# ╔═╡ d434c65e-4486-4749-a93d-916b2b842612
md"Número e distância entre linhas do edificio:"

# ╔═╡ 642b906c-d84e-4ba9-abb2-da86fc4b9dd0
@bind param_nl confirm(Slider(1:10; default=2, show_value=true))

# ╔═╡ 58bb6fb5-2ab7-454b-916b-561e80f952e0
@bind param_dl confirm((NumberField(0:0.1:9, default=6)))

# ╔═╡ 2578135e-9bcc-4e78-9db6-0ba0052bfbbd
md"Número e distância entre colunas do edificio:"

# ╔═╡ 337ab607-bad0-4214-9270-f876191bf1ae
@bind param_nc confirm(Slider(1:20; default=7, show_value=true))

# ╔═╡ 1ae0c968-96ad-46cd-ba46-a9aa1020f7b5
@bind param_dc confirm(NumberField(0:0.1:3, default=3))

# ╔═╡ 9865ee32-2958-4374-8a12-ed2d4aa884c5
md"#### Rotação"

# ╔═╡ 69856a4a-573a-48d3-b1e9-889af3a24165
md"Coordenadas (x, y) do ponto de referência para a rotação:"

# ╔═╡ e1ec6715-38b9-4868-b01b-10b4f2eb53d9
@bind param_p0x confirm(NumberField(-100:0.1:100, default=0))

# ╔═╡ 3366660f-365c-4950-bb88-e35c80395f23
@bind param_p0y confirm(NumberField(-100:0.1:100, default=0))

# ╔═╡ eec95f37-f993-44fb-afa8-9f63eead6c67
md"Ângulo de rotação"

# ╔═╡ f3602826-746b-4817-a9f4-cbfdf0d5a333
@bind param_phi0 confirm(Slider([0, pi/6, pi/4, pi/3, pi/2, 2pi/3, 3pi/4, 5pi/6, pi, 7pi/6, 5pi/4, 4pi/3, 3pi/2, 5pi/3, 7pi/4, 11pi/6, 0]; default=0, show_value=true))

# ╔═╡ 7fe5a099-73b3-4056-b05d-fe6c95f04596
md"#### Vazios"

# ╔═╡ 04b9ac26-db56-4f87-b714-a2de622cdd45
md"Número de vazios:"

# ╔═╡ 2d0af683-9b6f-4b20-b9dc-94f961b3155f
@bind n_vazios confirm(NumberField(0:(param_nl * param_nc), default=0))

# ╔═╡ 6e0000e5-9544-4934-9eee-486fc856e988
md"#### Núcleos"

# ╔═╡ a14d4073-433b-40f2-8be0-6d7c3f1d691b
md"Número de núcleos:"

# ╔═╡ a29fc12c-dbe7-4ecd-93fe-c11f022dc059
@bind n_nucleos confirm(NumberField(0:(param_nl * param_nc), default=0))

# ╔═╡ 71a80b2d-e38e-43a5-85e8-d5618a5dfb5f
md"#### Pré-visualização esquemática em planta"

# ╔═╡ 435fe445-5769-4ca2-ab07-065651f36684
md"#### Pisos"

# ╔═╡ e7ee143d-9cad-4a55-b30d-1ce8c6b9fb1b
md"Número de pisos e altura de cada piso:"

# ╔═╡ ee191093-d31e-4ed3-b7ef-607355b67d2f
@bind param_np confirm(NumberField(1:30; default=3))

# ╔═╡ 2eac1150-1588-4e42-874b-5f7cc6f607f5
@bind vazios_data combine() do Child

    inputs = []

    for v in 1:n_vazios
        push!(inputs, md"""
        ##### Vazio $v

        i: $(Child(Slider(1:param_nc, default=1, show_value=true)))

        j: $(Child(Slider(1:param_nl, default=1, show_value=true)))

        Lower level: $(Child(Slider(1:param_np, default=1, show_value=true)))

        """)
    end

    md"""
    $(inputs)
    """
end

# ╔═╡ db4734cf-6e53-4d12-bf61-698aa6eeeb44
Vazios = [
    [
        vazios_data[(v - 1) * 3 + 1],
        vazios_data[(v - 1) * 3 + 2],
        collect(vazios_data[(v - 1) * 3 + 3]:param_np
        )
    ]
    for v in 1:n_vazios
]

# ╔═╡ 9f5c50be-1316-496e-8e31-f0da0c7fa74f
@bind nucleos_data combine() do Child

    inputs = []

    for v in 1:n_nucleos
        push!(inputs, md"""
        ##### Núcleo $v

        i: $(Child(Slider(1:param_nc, default=1, show_value=true)))

        j: $(Child(Slider(1:param_nl, default=1, show_value=true)))

        Top level: $(Child(Slider(1:(param_np + 1), default=param_np, show_value=true)))

        """)
    end

    md"""
    $(inputs)
    """
end

# ╔═╡ df9c6c2a-7966-4182-9ffc-d3c857db3d98
Núcleos = [
    [
        nucleos_data[(v - 1) * 3 + 1],
        nucleos_data[(v - 1) * 3 + 2],
        collect(1:nucleos_data[(v - 1) * 3 + 3]
        )
    ]
    for v in 1:n_nucleos
]

# ╔═╡ 81f425be-8905-437f-91f2-220f5d3b4ef2
@bind param_h confirm(NumberField(0:0.1:6; default=3))

# ╔═╡ c81a3b9c-c912-4ebe-9782-813e8ded3759
md"#### Janelas"

# ╔═╡ 3a35359b-56b6-4b61-aa19-d3e192b1c702
md"##### Janelas ao longo das linhas da grelha CREE:"

# ╔═╡ 60d805bb-51e6-4e20-a463-dc4fb73202f3
md"Número de janelas em cada índice da grelha:"

# ╔═╡ 37fd2e79-72e7-49b7-a0af-64d862a46f85
@bind n_janelas_l confirm(NumberField(default=1))

# ╔═╡ 1afcc96b-5563-4af4-b9d0-957e53b711c8
@bind janelas_l_size_data confirm(combine() do Child

    inputs = []

    for v in 1:n_janelas_l
        push!(inputs, md"""
        ###### Janela $v — dimensão

        Largura da janela: $(Child(Slider(0.2:0.1:(param_dc - 0.2), default=1, show_value=true)))

        Altura da janela: $(Child(Slider(0.2:0.1:(param_h - 0.2), default=2, show_value=true)))
        """)
    end

    md"""
    $(inputs)
    """
end)

# ╔═╡ a276cf8c-e62f-4e04-9448-c36963cc956b
janelas_l_size_array = collect(janelas_l_size_data)

# ╔═╡ 0267c873-b290-4c2e-b1db-7ba8bbd25c23
@bind janelas_l_position_data confirm(combine() do Child

    inputs = []

    for v in 1:n_janelas_l

        largura = janelas_l_size_array[(v - 1) * 2 + 1] 
        altura = janelas_l_size_array[(v - 1) * 2 + 2]

        max_pos_horizontal = max(0.2, param_dc - largura - 0.1)
        max_pos_vertical = max(0.2, param_h - altura - 0.1)

        push!(inputs, md"""
        ###### Janela $v — posição

        Posição horizontal relativa na parede: $(Child(Slider(0.1:0.1:max_pos_horizontal, default=1, show_value=true)))

        Posição vertical relativa na parede: $(Child(Slider(0.1:0.1:max_pos_vertical, default=0.5, show_value=true)))
        """)
    end

    md"""
    $(inputs)
    """
end)

# ╔═╡ ad060ee5-3b89-4f8c-a1be-66a628255110
janelas_l_position_array = collect(janelas_l_position_data)

# ╔═╡ 567ef7dd-aefe-41a0-9042-ebd0c6c2f0d1
Janelas_linha = [
    [
        janelas_l_position_array[(v - 1) * 2 + 1], # horizontal position
        janelas_l_position_array[(v - 1) * 2 + 2], # vertical position
        janelas_l_size_array[(v - 1) * 2 + 1],     # width
        janelas_l_size_array[(v - 1) * 2 + 2]      # height
    ]
    for v in 1:n_janelas_l
]

# ╔═╡ 132cbcc7-e28b-4afc-8493-f07884aed795
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ 1d6f077d-4f5e-420e-b362-3bdd818b7567
md"##### Janelas ao longo das colunas da grelha CREE:"

# ╔═╡ bcfbbe2a-51ee-4161-8cd8-17da592d8183
md"Número de janelas em cada índice da grelha:"

# ╔═╡ a68422a8-4f0e-42e4-8130-14cf1af1c23a
@bind n_janelas_c confirm(NumberField(default=1))

# ╔═╡ 5f878a5e-61d9-4a5b-b870-20f0d789cb91
@bind janelas_c_size_data confirm(combine() do Child

    inputs = []

    for v in 1:n_janelas_c
        push!(inputs, md"""
        ###### Janela $v — dimensão

        Largura da janela: $(Child(Slider(0.2:0.1:(param_dl - 0.2), default=3, show_value=true)))

        Altura da janela: $(Child(Slider(0.2:0.1:(param_h - 0.2), default=2, show_value=true)))
        """)
    end

    md"""
    $(inputs)
    """
end)

# ╔═╡ d3b5749f-49e0-41dd-9772-16efdbb7ff88
janelas_c_size_array = collect(janelas_c_size_data)

# ╔═╡ 84345f0a-18b0-4c3b-847b-05f22c6ae731
@bind janelas_c_position_data confirm(combine() do Child

    inputs = []

    for v in 1:n_janelas_c

        largura = janelas_c_size_array[(v - 1) * 2 + 1] 
        altura = janelas_c_size_array[(v - 1) * 2 + 2]

        max_pos_horizontal = max(0.2, param_dl - largura - 0.1)
        max_pos_vertical = max(0.2, param_h - altura - 0.1)

        push!(inputs, md"""
        ###### Janela $v — posição

        Posição horizontal relativa na parede: $(Child(Slider(0.1:0.1:max_pos_horizontal, default=1, show_value=true)))

        Posição vertical relativa na parede: $(Child(Slider(0.1:0.1:max_pos_vertical, default=0.5, show_value=true)))
        """)
    end

    md"""
    $(inputs)
    """
end)

# ╔═╡ 1efc2522-33ca-4736-88c3-9af24f3bd1d7
janelas_c_position_array = collect(janelas_c_position_data)

# ╔═╡ 39563b32-b759-4354-afd8-a77047cbdc09
Janelas_coluna = [
    [
        janelas_c_position_array[(v - 1) * 2 + 1], # horizontal position
        janelas_c_position_array[(v - 1) * 2 + 2], # vertical position
        janelas_c_size_array[(v - 1) * 2 + 1],     # width
        janelas_c_size_array[(v - 1) * 2 + 2]      # height
    ]
    for v in 1:n_janelas_c
]

# ╔═╡ c0316483-9e62-4116-8928-c41fb6325ac1
md"#### Parâmetros atualmente definidos:"

# ╔═╡ 4bb327df-fd7a-4d35-bc35-95d6c74ebb52
begin
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
    parametros = EdificioParams(
        param_Ox, param_Oy, param_Oz,
        param_nl,
        param_dl,
        param_nc,
        param_dc,

        param_p0x,
        param_p0y,
        param_phi0,

        Vazios,
        Núcleos,

        param_np,
        param_h,

        Janelas_linha,
        Janelas_coluna
)
end

# ╔═╡ 42c7c532-3113-48b3-b569-012a8f68f85b
md"
#### Atualizar automáticamente o modelo?
"

# ╔═╡ 19a53dd5-941f-4f84-8610-513916287e24
@bind gerar_modelo Switch(default=true) 

# ╔═╡ 25d16ea8-6780-4e3b-b151-642b8681d77f
md"#### Estado de geração do modelo"

# ╔═╡ ef5312bf-3e15-45e0-a1dd-d4c80b5b5092
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ 368d155f-d465-499a-b1de-7a6fb961628c
md"## Funções auxiliares"

# ╔═╡ d8c553ef-af40-48b1-8955-4152626e2cbd
#completa a posição [3] do conjunto de indices para incluir todos os pisos
function completa_vazios(set_1, np)
    [isempty(x[3]) ? [x[1], x[2], collect(1:np)] : x
        for x in set_1]
end

# ╔═╡ 531574d1-bed0-438d-9096-a656e32604b3
#verifica se o indice [i, j, k] pertence ao conjunto
function tem_indice(set_1, i, j, k)
    any(x -> x[1] == i && x[2] == j && k in x[3], set_1)
end

# ╔═╡ f0a0630d-c9be-4a7d-aa0e-f5d5a3c51aaa
#rotaciona um ponto p1 em relação a outro ponto p0
function p_rotate(p0, p1, phi)
    p0 + vcyl(distance(p0 + vz(p1.z), p1), atan((p1.y - p0.y), (p1.x - p0.x)) + phi, p1.z)
end

# ╔═╡ 615c54e9-3771-40cd-abc9-7aa4ee8cd273
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ 38b27896-dbcd-40b6-a77a-a7fe651b4f4e
md"## Funções de grelhas de pontos"

# ╔═╡ 868f7e8c-4f1b-4843-aaa3-80fbb89aad1d
function pts_grelha(p, l_tot, n, c_tot, m)
    map_division((i,j) -> p + vxy(i, j), 0, l_tot, n, 0, c_tot, m)
end

# ╔═╡ 594260bd-f319-40eb-8141-5560d14149d7
function grelha_4pts(p, l_tot, n, c_tot, m)
    iterate_quads((p1, p2, p3, p4) -> [p1, p2, p3, p4], pts_grelha(p, l_tot, n, c_tot, m))
end

# ╔═╡ 5456cedb-4217-488d-a87e-48c21fe810b5
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ cade3249-2df6-4404-b1c2-8c3a5865839a
md"""## Funções de lajes
Expandir para ver as variaveis"""

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as linhas
    #nl: número de linhas
    #np: número de pisos
    #h: altrura de cada piso
    #e_laje: espessura da laje
    #bvb: largura da viga de bordadura
    #bvi: largura da viga interior
    #bvL: largura das vigas da laje
    #hvL: altura das vigas da laje
    #vz_set: conjunto de indices vazios
    #ncl_set: conjunto de indices de nucleos

# ╔═╡ f6e930d9-7e9f-4b33-bc5f-5095d7bfe74a
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

# ╔═╡ aebdbad7-d11e-4b52-8749-81c76e8fcb1b
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

# ╔═╡ c5638f6b-8abf-45b6-ac7a-8cf9e4b6687f
#Função que entrega arrays de 4 pontos à função laje_map
function laje_piso(p, dc, nc, dl, nl, e_laje, bvb, bvi, bvL, hvL, vz_set, ncl_set, k, p0, phi0) 

    [laje_for(
            grelha_4pts(
                p, dc * nc, nc, dl * nl, nl), e_laje, nc, nl,
                bvb, bvi, bvL, hvL, vz_set, ncl_set, k, p0, phi0)]
end

# ╔═╡ 2267b4e9-2d13-40b8-9dc7-3e23d180f7ed
#Criação de lajes em todos os pisos
function laje_total(p, dc, nc, dl, nl, np, h, e_laje, bvb, bvi, bvL, hvL, vz_set, ncl_set, p0, phi0)

    [laje_piso(
        p + vz(h * k), dc, nc, dl, nl, e_laje,
        bvb, bvi, bvL, hvL, vz_set, ncl_set, k, p0, phi0)

            for k in 1:np]
end

# ╔═╡ 00c284c9-203b-4b47-b764-bad28d506c78
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ ebb4e590-d7bf-43ab-b103-4df8e45a6833
md"""## Funções de pilares da fachada
Expandir para ver as variaveis"""

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as lajes
    #nl: número de lajes
    #np: número de pisos
    #h: altura do piso
    #a: largura do pilar
    #b: profundidade do pilar
    #cpc: dimensões dos pilares do canto
    #hvb: altura da viga de bordadura
    #vz_set_tot: conjunto de vazios e nucleos
    #vz_set: conjunto de vazios

# ╔═╡ ed885338-c90b-4257-8c05-668c29862dfc
#Função que cria um pilar
function pilar_singular(p1, h, a, b, p0, phi0) 
    let
        p = p_rotate(p0, p1, phi0)

        pilar_glulam_familia = column_family_element(
            default_column_family(), profile = rectangular_profile(width = b, height = a))

        free_column(p, p + vz(h), phi0, pilar_glulam_familia)
    end
end

# ╔═╡ 5a00b99f-c404-4011-80e1-1ecd8c058dc2
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

# ╔═╡ 03f8b8ca-5975-427e-bb93-fac6c111c290
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

# ╔═╡ e2163d48-0ec9-4ba1-b602-d4483784fc46
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

# ╔═╡ 7dcf227a-8a5b-498a-9a7d-1a614e55419f
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

# ╔═╡ fcb8c52d-c161-4131-a4fa-5ace6cf28746
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

# ╔═╡ 22605c70-60a5-48d9-97bb-a32571caa348
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

# ╔═╡ 943978c8-6c06-4e71-bb03-3bcb072c3686
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

# ╔═╡ 5f0ba93f-8622-4aa5-b9df-ba403f9c6ebc
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

# ╔═╡ 9b98ba53-79aa-4cd3-905e-ed15d6bb6c42
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ f2b7bb39-cc35-4867-815e-78bcc08bde61
md"""## Funções de pilares interiores
Expandir para ver as variaveis"""

    #p: ponto de referência
    #dc: distância entre colunas
    #nc: número de colunas
    #dl: distância entre linhas
    #nl: número de linhas
    #np: número de pisos
    #h: altura do piso
    #hvi: altura da viga interior
    #api: dimensão dos pilares interiores
    #vz_set: conjunto de indices vazios

# ╔═╡ ca37984c-f965-4f67-9c02-8b94f5735749
#Função que cria um pilar
function pilar_interior(p1, api, h, p0, phi0) 
    let
        p = p_rotate(p0, p1, phi0)

        pilar_betao_familia = column_family_element(
            default_column_family(), profile = rectangular_profile(width = api, height = api))

        free_column(p, p + vz(h), phi0, pilar_betao_familia)
    end
end

# ╔═╡ 0632d1b2-9680-4038-a822-d51214314229
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

# ╔═╡ 01fcd29a-d7dc-4b22-a66f-0676351f0b78
#Criação de pilares interiores em um piso 
function pilares_interior_piso(p, c, n, l, m, h, api, vz_set_tot, k, p0, phi0) 

    [pilares_interiores_for(
        pts_grelha(
            p, c, n, l, m),
        h, api, vz_set_tot, k, p0, phi0)]
end

# ╔═╡ bafa745b-efe7-4cd7-bfba-721c88da83b6
#Criação de pilares interiores em todos os pisos
function pilares_interior_total(p, dc, nc, dl, nl, np, h, hvi, api, vz_set_tot, p0, phi0) 

    [pilares_interior_piso(
        p + vz(h * k - h), dc * nc, nc, dl * nl, nl, h - hvi, api, vz_set_tot, k, p0, phi0)

    for k in 1:np]
end

# ╔═╡ 89d3c45a-69af-4d1a-8e32-d9ab13b3c8ed
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ d9e3cb22-373e-4abb-aa8f-1e73c81566ec
md"""## Funções de vigas de bordadura
Expandir para ver as variaveis"""

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as linhas
    #nl: número de linhas
    #hvb: altura das vigas de bordadura
    #bvb: largura das vigas de bordadura
    #h: altrura de cada piso
    #np: número de pisos
    #e: espessura da laje
    #vz_set: conjunto de indices vazios
    #ncl_set: conjunto de indices dos nucleos

# ╔═╡ 5007dad8-516e-43b7-a560-6e1c40508ca1
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

# ╔═╡ 7438fd50-84f0-4340-9c72-3fa792cc595f
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

# ╔═╡ 6631bbf5-3109-45ff-a4f1-b976e86bf0c6
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

# ╔═╡ 6ce03dd8-2247-4bab-91d1-79799bad1e19
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

# ╔═╡ 6442fe6e-13df-4803-acc1-e8e5b351c8c6
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

# ╔═╡ 7a810441-a2d2-4864-ae8d-71b11f023267
#Criação de vigas de bordadura em todos os pisos
function viga_bordadura_total(p, dc, nc, dl, nl, hvb, bvb, h, np, e, vz_set, ncl_set, p0, phi0) 

    [[viga_bordadura_piso(
        p + vz(h * k), dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k, p0, phi0)

            for k in 1:np],

     [viga_bordadura_interior_piso(
        p + vz(h * k), dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k, p0, phi0)

            for k in 1:np]]
end

# ╔═╡ 21e98834-77dd-4847-b1df-6acc23e4444e
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ f9cd911c-7197-41b1-9640-69dffbe8bc53
md"""## Funções de vigas interiores
Expandir para ver as variaveis"""

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as linhas
    #nl: número de linhas
    #h: altura de cada piso
    #np: número de pisos
    #hvi: altura das vigas interiores
    #bvi: largura das vigas interiores
    #e: espessura da laje de betão
    #bvb: largura da viga de bordadura
    #vz_set: conjunto de indices vazias

# ╔═╡ 8072a203-c9be-47d3-9730-7889237c583f
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

# ╔═╡ 3986f980-39fa-4c3b-84b2-93419eb24f7c
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

# ╔═╡ 0978afa2-d036-4cba-a5e9-6bb0bee1f692
#Criação de vigas interiores em um piso
function viga_interior_piso(p, dc, nc, dl, nl, hvi, bvi, e, bvb, vz_set_tot, vz_set, k, p0, phi0) 

    [viga_interior_for(
        pts_grelha(
            p + vz(- e), dc * nc, nc, dl * nl, nl),
        hvi, dc, bvi, bvb, vz_set_tot, vz_set, k, p0, phi0)]
end

# ╔═╡ 4b0c5a0a-b753-4a82-9855-15f72fc3916a
#Criação de vigas interiores em todos os pisos
function viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e, bvb, vz_set_tot, vz_set, p0, phi0) 

    [viga_interior_piso(
        p + vz(h * k), dc, nc, dl, nl, hvi, bvi, e, bvb, vz_set_tot, vz_set, k, p0, phi0)

            for k in 1:np]
end

# ╔═╡ 24433313-fb45-4c4a-b454-2d7b0a3e1bb6
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ fc757a4a-be4c-4547-9266-409daa36149d
md"""## Funções de núcleos
Expandir para ver as variaveis"""

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as linhas
    #nl: número de linhas
    #h: altura de cada piso
    #enb: espessura do núcleo de betão
    #ncl_set: conjunto de indices de núcleos vazios

# ╔═╡ bac8bf32-4a41-4d2e-9a38-81a96b2ac8f1
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

# ╔═╡ 784ba088-543a-4fd5-ae5d-b146ce7cd4d0
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

# ╔═╡ 95431f05-1ace-4245-9607-542a6f49a2c0
#Função que entrega um array de arrays de pontos para criar os núcleos
function nucleo_total(p, dc, nc, dl, nl, h, enb, ncl_set, p0, phi0) 

    nucleo_for(
        pts_grelha(
            p, dc * nc, nc, dl * nl, nl),
        dc, dl, h, enb, ncl_set, p0, phi0)
end

# ╔═╡ d5891c9a-f8b7-4066-9653-db9ad7d079d5
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

# ╔═╡ e0a8df0d-4895-4d42-b22c-a0ebb1e9899d
# ╠═╡ disabled = true
#=╠═╡

  ╠═╡ =#

# ╔═╡ 718b6566-8416-4245-b1ee-58f0b74602dc
md"""## Funções de paineis de fachada
Expandir para ver as variaveis"""

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as linhas
    #nl: número de linhas
    #h: altura de cada piso
    #np: número de pisos
    #e_fachada: espessura do painel de fachada
    #vz_set: conjunto de indices vazios
    #vz_set_tot: conjunto de indices vazios e nucleos

# ╔═╡ efb53a86-9ebf-4fd3-b1b1-2efa13b5488d
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

# ╔═╡ 4e938027-b89b-4c73-a73a-0a446041ef0f
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

# ╔═╡ d41882f6-1b4a-474c-9048-28d74e3d30cd
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

# ╔═╡ 6afec66f-9507-4e53-ba2d-a177051225c0
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

# ╔═╡ 702f1adc-f475-480f-8897-5148324736c0
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

# ╔═╡ 33227bc4-281c-4daf-843d-c0640213e6cb
#Criação de paineis de fachada em todos os pisos
function painel_fachada_total(p, dc, nc, dl, nl, np, h, vz_set, vz_set_tot, jan_set_l, jan_set_c, e_fachada, p0, phi0) 

    [[painel_fachada_piso(
        p + vz(h * k - h), dc * nc, nc, dl * nl, nl, h, vz_set_tot, jan_set_l, jan_set_c, e_fachada, k, p0, phi0)

            for k in 1:np],

     [painel_fachada_interior_piso(
        p + vz(h * k - h), dc * nc, nc, dl * nl, nl, dc, dl, h, vz_set, vz_set_tot, jan_set_l, jan_set_c, e_fachada, k, p0, phi0) 
            
            for k in 1:np]]
end

# ╔═╡ 1ae510a0-6745-11f1-8976-b99da2f9b2e7
edificio_CREE(p, nl, nc, dl, dc, np, h, p0, phi0, janelas_set_l, janelas_set_c, vazios_set, nucleos_set) =
    let 
        e_laje = 0.1
        apf = 0.2 # largura dos pilares da fachada
        bpf = 0.3 # profundidade dos pilares da fachada
        cpc = 0.3 # largura e profundidade do pilar de canto
        hvb = 0.4 # Altura da viga de bordadura
        bvb = 0.3 # Largura da viga de bordadura
        hvi = 0.3 # Altura da viga interior
        bvi = 0.3 # Largura da viga interior
        api = 0.3 # largura e profundidade dos pilares interiores
        enb = 0.3 # Espessura do nucleo de betão\
        hvL = 0.3 # Altura das vigas da laje
        bvL = 0.2 # Largura das vigas da laje
        e_fachada = 0.1 # Espessura da fachada

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

# ╔═╡ b6b391b9-38ae-4a39-8c24-da11b55afc92
generate_model(params::EdificioParams) =
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
            params.Núcleos
        )
    end

# ╔═╡ b20d5857-bad7-4be3-8cf4-c84103d183ba
begin
    using Khepri
        backend(autocad)

    gerar_modelo == true ? generate_model(parametros) : 
    nothing
    print("Geração do edifício concluida")
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Khepri = "59ceddad-2dad-55ad-af66-072f48a109d0"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Khepri = "~1.3.0"
PlutoUI = "~0.7.83"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.5"
manifest_format = "2.0"
project_hash = "b9d7e4a11a47f3b6ee6350ae116aa73a4854e11e"

[[deps.AbstractPlutoDingetjes]]
git-tree-sha1 = "6c3913f4e9bdf6ba3c08041a446fb1332716cbc2"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "362a287c3aa50601b0bc359053d5c2468f0e7ce0"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.11"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "21d088c496ea22914fe80906eb5bce65755e5ec8"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.5.1"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Dierckx]]
deps = ["Dierckx_jll"]
git-tree-sha1 = "7da4b14cc4c3443a1afc64abee17f4fcb45ad837"
uuid = "39dd38d3-220a-591b-8e3c-4c3a8c710a94"
version = "0.5.4"

[[deps.Dierckx_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3251f44b3cac6fec4cec8db45d3ab0bfed51c4d8"
uuid = "cd4c43a9-7502-52ba-aa6d-59fb2a88580b"
version = "0.2.0+0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "7ea1aa5869e2626ccae84480e4f37185bc6f41d3"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.2.3"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "51059d23c8bb67911a2e6fd5130229113735fc7e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.11.0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "0533e564aae234aff59ab625543145446d8b6ec2"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.1"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.Khepri]]
deps = ["ColorTypes", "Colors", "Dates", "KhepriAutoCAD", "Reexport"]
git-tree-sha1 = "a1294b893420e96d9ebadc7704393d9e3955482b"
uuid = "59ceddad-2dad-55ad-af66-072f48a109d0"
version = "1.3.0"

[[deps.KhepriAutoCAD]]
deps = ["ColorTypes", "Dates", "EzXML", "KhepriBase", "Reexport", "Sockets"]
git-tree-sha1 = "deb3d470c1355bac9d89e561e2dc7d8cbc86b82a"
uuid = "84eb9a3b-232b-4081-b917-cfea549d0d83"
version = "1.3.0"

[[deps.KhepriBase]]
deps = ["ColorTypes", "Dates", "Dierckx", "HTTP", "LinearAlgebra", "Sockets", "StaticArrays"]
git-tree-sha1 = "68f1ebf3413f56a30f84ec5750e61dced6355193"
uuid = "4cc0fe96-1163-46f3-ba32-de1e65d9548f"
version = "0.7.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f00544d95982ea270145636c181ceda21c4e2575"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.2.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "8785729fa736197687541f7053f6d8ab7fc44f92"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.10"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ff69a2b1330bcb730b9ac1ab7dd680176f5896b8"
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.1010+0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "NetworkOptions", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "1d1aaa7d449b58415f97d2839c318b70ffb525a0"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.6.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e189d0623e7ce9c37389bac17e80aac3b0302e75"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.83"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "07a921781cab75691315adc645096ed5e370cb77"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.3"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "8b770b60760d4451834fe79dd483e318eee709c4"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "246a8bb2e6667f832eea063c3a56aef96429a3db"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.18"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6ab403037779dae8c514bad259f32a447262455a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.4"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "5c959b708667b34cb758e8d7c6f8e69b94c32deb"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.15.1+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"
"""

# ╔═╡ Cell order:
# ╟─3214848e-1df3-41c0-9ae3-039e6615af19
# ╠═171da720-3306-453f-9572-83fabd08b3b0
# ╠═e162d689-8acf-417c-ac6e-5ab90933adef
# ╟─4c141db1-e614-4ab7-b659-8a6163d716df
# ╟─359f6b87-837c-43aa-bdd9-05bb7fc95f7f
# ╟─5f88a907-59d9-4df0-a238-f22c590a337f
# ╟─69a09497-d356-4846-a170-5788c57d8664
# ╟─fe22bcf5-4a9c-41ba-bfe8-06dec03f2970
# ╟─c3f7c6f9-21cc-4962-9c21-0a71bb9268d5
# ╟─ee12c60b-1150-44b8-bc06-62c0ffe55d57
# ╟─d434c65e-4486-4749-a93d-916b2b842612
# ╟─642b906c-d84e-4ba9-abb2-da86fc4b9dd0
# ╟─58bb6fb5-2ab7-454b-916b-561e80f952e0
# ╟─2578135e-9bcc-4e78-9db6-0ba0052bfbbd
# ╟─337ab607-bad0-4214-9270-f876191bf1ae
# ╟─1ae0c968-96ad-46cd-ba46-a9aa1020f7b5
# ╟─9865ee32-2958-4374-8a12-ed2d4aa884c5
# ╟─69856a4a-573a-48d3-b1e9-889af3a24165
# ╟─e1ec6715-38b9-4868-b01b-10b4f2eb53d9
# ╟─3366660f-365c-4950-bb88-e35c80395f23
# ╟─eec95f37-f993-44fb-afa8-9f63eead6c67
# ╟─f3602826-746b-4817-a9f4-cbfdf0d5a333
# ╟─7fe5a099-73b3-4056-b05d-fe6c95f04596
# ╟─04b9ac26-db56-4f87-b714-a2de622cdd45
# ╟─2d0af683-9b6f-4b20-b9dc-94f961b3155f
# ╟─2eac1150-1588-4e42-874b-5f7cc6f607f5
# ╟─db4734cf-6e53-4d12-bf61-698aa6eeeb44
# ╟─6e0000e5-9544-4934-9eee-486fc856e988
# ╟─a14d4073-433b-40f2-8be0-6d7c3f1d691b
# ╟─a29fc12c-dbe7-4ecd-93fe-c11f022dc059
# ╟─9f5c50be-1316-496e-8e31-f0da0c7fa74f
# ╟─df9c6c2a-7966-4182-9ffc-d3c857db3d98
# ╟─71a80b2d-e38e-43a5-85e8-d5618a5dfb5f
# ╟─435fe445-5769-4ca2-ab07-065651f36684
# ╟─e7ee143d-9cad-4a55-b30d-1ce8c6b9fb1b
# ╟─ee191093-d31e-4ed3-b7ef-607355b67d2f
# ╟─81f425be-8905-437f-91f2-220f5d3b4ef2
# ╟─c81a3b9c-c912-4ebe-9782-813e8ded3759
# ╟─3a35359b-56b6-4b61-aa19-d3e192b1c702
# ╟─60d805bb-51e6-4e20-a463-dc4fb73202f3
# ╟─37fd2e79-72e7-49b7-a0af-64d862a46f85
# ╟─1afcc96b-5563-4af4-b9d0-957e53b711c8
# ╟─a276cf8c-e62f-4e04-9448-c36963cc956b
# ╟─0267c873-b290-4c2e-b1db-7ba8bbd25c23
# ╟─ad060ee5-3b89-4f8c-a1be-66a628255110
# ╟─567ef7dd-aefe-41a0-9042-ebd0c6c2f0d1
# ╟─132cbcc7-e28b-4afc-8493-f07884aed795
# ╟─1d6f077d-4f5e-420e-b362-3bdd818b7567
# ╟─bcfbbe2a-51ee-4161-8cd8-17da592d8183
# ╟─a68422a8-4f0e-42e4-8130-14cf1af1c23a
# ╟─5f878a5e-61d9-4a5b-b870-20f0d789cb91
# ╟─d3b5749f-49e0-41dd-9772-16efdbb7ff88
# ╟─84345f0a-18b0-4c3b-847b-05f22c6ae731
# ╟─1efc2522-33ca-4736-88c3-9af24f3bd1d7
# ╟─39563b32-b759-4354-afd8-a77047cbdc09
# ╟─c0316483-9e62-4116-8928-c41fb6325ac1
# ╟─4bb327df-fd7a-4d35-bc35-95d6c74ebb52
# ╟─42c7c532-3113-48b3-b569-012a8f68f85b
# ╟─19a53dd5-941f-4f84-8610-513916287e24
# ╟─25d16ea8-6780-4e3b-b151-642b8681d77f
# ╟─b20d5857-bad7-4be3-8cf4-c84103d183ba
# ╟─b6b391b9-38ae-4a39-8c24-da11b55afc92
# ╟─1ae510a0-6745-11f1-8976-b99da2f9b2e7
# ╟─ef5312bf-3e15-45e0-a1dd-d4c80b5b5092
# ╟─368d155f-d465-499a-b1de-7a6fb961628c
# ╟─d8c553ef-af40-48b1-8955-4152626e2cbd
# ╟─531574d1-bed0-438d-9096-a656e32604b3
# ╟─f0a0630d-c9be-4a7d-aa0e-f5d5a3c51aaa
# ╟─615c54e9-3771-40cd-abc9-7aa4ee8cd273
# ╟─38b27896-dbcd-40b6-a77a-a7fe651b4f4e
# ╟─868f7e8c-4f1b-4843-aaa3-80fbb89aad1d
# ╟─594260bd-f319-40eb-8141-5560d14149d7
# ╟─5456cedb-4217-488d-a87e-48c21fe810b5
# ╟─cade3249-2df6-4404-b1c2-8c3a5865839a
# ╟─2267b4e9-2d13-40b8-9dc7-3e23d180f7ed
# ╟─c5638f6b-8abf-45b6-ac7a-8cf9e4b6687f
# ╟─aebdbad7-d11e-4b52-8749-81c76e8fcb1b
# ╟─f6e930d9-7e9f-4b33-bc5f-5095d7bfe74a
# ╟─00c284c9-203b-4b47-b764-bad28d506c78
# ╟─ebb4e590-d7bf-43ab-b103-4df8e45a6833
# ╟─5f0ba93f-8622-4aa5-b9df-ba403f9c6ebc
# ╟─e2163d48-0ec9-4ba1-b602-d4483784fc46
# ╟─5a00b99f-c404-4011-80e1-1ecd8c058dc2
# ╟─03f8b8ca-5975-427e-bb93-fac6c111c290
# ╟─fcb8c52d-c161-4131-a4fa-5ace6cf28746
# ╟─7dcf227a-8a5b-498a-9a7d-1a614e55419f
# ╟─943978c8-6c06-4e71-bb03-3bcb072c3686
# ╟─22605c70-60a5-48d9-97bb-a32571caa348
# ╟─ed885338-c90b-4257-8c05-668c29862dfc
# ╟─9b98ba53-79aa-4cd3-905e-ed15d6bb6c42
# ╟─f2b7bb39-cc35-4867-815e-78bcc08bde61
# ╟─bafa745b-efe7-4cd7-bfba-721c88da83b6
# ╟─01fcd29a-d7dc-4b22-a66f-0676351f0b78
# ╟─0632d1b2-9680-4038-a822-d51214314229
# ╟─ca37984c-f965-4f67-9c02-8b94f5735749
# ╟─89d3c45a-69af-4d1a-8e32-d9ab13b3c8ed
# ╟─d9e3cb22-373e-4abb-aa8f-1e73c81566ec
# ╟─7a810441-a2d2-4864-ae8d-71b11f023267
# ╟─6631bbf5-3109-45ff-a4f1-b976e86bf0c6
# ╟─7438fd50-84f0-4340-9c72-3fa792cc595f
# ╟─6442fe6e-13df-4803-acc1-e8e5b351c8c6
# ╟─6ce03dd8-2247-4bab-91d1-79799bad1e19
# ╟─5007dad8-516e-43b7-a560-6e1c40508ca1
# ╟─21e98834-77dd-4847-b1df-6acc23e4444e
# ╟─f9cd911c-7197-41b1-9640-69dffbe8bc53
# ╟─4b0c5a0a-b753-4a82-9855-15f72fc3916a
# ╟─0978afa2-d036-4cba-a5e9-6bb0bee1f692
# ╟─3986f980-39fa-4c3b-84b2-93419eb24f7c
# ╟─8072a203-c9be-47d3-9730-7889237c583f
# ╟─24433313-fb45-4c4a-b454-2d7b0a3e1bb6
# ╟─fc757a4a-be4c-4547-9266-409daa36149d
# ╟─95431f05-1ace-4245-9607-542a6f49a2c0
# ╟─784ba088-543a-4fd5-ae5d-b146ce7cd4d0
# ╟─bac8bf32-4a41-4d2e-9a38-81a96b2ac8f1
# ╟─d5891c9a-f8b7-4066-9653-db9ad7d079d5
# ╟─e0a8df0d-4895-4d42-b22c-a0ebb1e9899d
# ╟─718b6566-8416-4245-b1ee-58f0b74602dc
# ╟─33227bc4-281c-4daf-843d-c0640213e6cb
# ╟─d41882f6-1b4a-474c-9048-28d74e3d30cd
# ╟─4e938027-b89b-4c73-a73a-0a446041ef0f
# ╟─702f1adc-f475-480f-8897-5148324736c0
# ╟─6afec66f-9507-4e53-ba2d-a177051225c0
# ╟─efb53a86-9ebf-4fd3-b1b1-2efa13b5488d
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
