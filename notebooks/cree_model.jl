### A Pluto.jl notebook ###
# v1.1.0

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

# ╔═╡ a1b2c3d4-0001-4000-8000-000000000001
Modelo = include(joinpath(@__DIR__, "..", "src", "CREE.jl"))

# ╔═╡ 3214848e-1df3-41c0-9ae3-039e6615af19

md"# Modelo paramétrico CREE
Versão 5.0.0"

# ╔═╡ e162d689-8acf-417c-ac6e-5ab90933adef

import PlutoUI: combine

# ╔═╡ a1b2c3d4-0002-4000-8000-000000000002
md"""## Modelo

As regras do sistema CREE estão em `src/CREE.jl`; este caderno é apenas a interface. A célula seguinte carrega o módulo e liga-o ao nome `Modelo`.
"""

# ╔═╡ a1b2c3d4-0003-4000-8000-000000000003
md"""## Dimensões do sistema

Secções e espessuras dos componentes CREE, em metros. Não são parâmetros de projeto: nenhuma configuração alcançável pelos cursores abaixo as altera. São o contexto fixo do sistema.

Para estudar uma variante, substituir `Modelo.DIMENSOES_PADRAO` por, por exemplo, `Modelo.DimensoesSistema(hvb = 0.45, e_fachada = 0.12)`.
"""

# ╔═╡ a1b2c3d4-0004-4000-8000-000000000004
dimensoes = Modelo.DIMENSOES_PADRAO

# ╔═╡ a1b2c3d4-0005-4000-8000-000000000005
let
    campos = [c for c in fieldnames(Modelo.DimensoesSistema) if c != :fonte]
    linhas = join(["| `$(c)` | $(getfield(dimensoes, c)) |" for c in campos], "\n")
    Markdown.parse("| dimensão | m |\n|:--|--:|\n" * linhas)
end

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

parametros = Modelo.EdificioParams(
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

# ╔═╡ 42c7c532-3113-48b3-b569-012a8f68f85b

md"
#### Atualizar automáticamente o modelo?
"

# ╔═╡ 19a53dd5-941f-4f84-8610-513916287e24

@bind gerar_modelo Switch(default=true) 

# ╔═╡ b20d5857-bad7-4be3-8cf4-c84103d183ba

begin
    using Khepri
        backend(autocad)

    gerar_modelo == true ? Modelo.generate_model(parametros, dimensoes) : 
    nothing
    print("Geração do edifício concluida")
end

# ╔═╡ 25d16ea8-6780-4e3b-b151-642b8681d77f

md"#### Estado de geração do modelo"

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
# ╟─a1b2c3d4-0002-4000-8000-000000000002
# ╠═a1b2c3d4-0001-4000-8000-000000000001
# ╟─a1b2c3d4-0003-4000-8000-000000000003
# ╠═a1b2c3d4-0004-4000-8000-000000000004
# ╟─a1b2c3d4-0005-4000-8000-000000000005
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
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
