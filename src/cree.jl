using Khepri
backend(autocad)

#Função principal

edificio_CREE(p, nl, nc, dl, dc, np, h, vazios_set, nucleos_set) =
    let 
        e_laje = 0.1
        c_tot = dc * nc
        l_tot = dl * nl
        apf = 0.2 # largura dos pilares da fachada
        bpf = 0.3 # profundidade dos pilares da fachada
        cpc = 0.4 # largura e profundidade do pilar de canto
        hvb = 0.5 # Altura da viga de bordadura
        bvb = 0.3 # Largura da viga de bordadura
        hvi = 0.3 # Altura da viga interior
        bvi = 0.3 # Largura da viga interior
        api = 0.3 # largura e profundidade dos pilares interiores
        enb = 0.3 # Espessura do nucleo de betão\
        hvL = 0.3 # Altura das vigas da laje
        bvL = 0.2 # Largura das vigas da laje
        e_fachada = 0.1 # Espessura da fachada

        vazios_set_tot = vcat([vazios_set, nucleos_set]...)

        laje_total(p, dc, nc, dl, nl, np, h, e_laje, bvb, bvi, bvL, hvL, vazios_set, nucleos_set)
        pilares_fachada_total(p, dc, nc, dl, nl, np, h, apf, bpf, cpc, hvb + e_laje, vazios_set_tot)
        pilares_interior_total(p, dc, nc, dl, nl, np, h, hvi + e_laje, api, vazios_set_tot)
        viga_bordadura_total(p, dc, nc, dl, nl, hvb, bvb, h, np, e_laje, vazios_set, nucleos_set)
        viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e_laje, bvb, vazios_set_tot)
        nucleo_total(p, dc, nc, dl, nl, h, np, enb, nucleos_set_count(nucleos_set))
        painel_fachada_total(p, dc, nc, dl, nl, np, h, vazios_set_tot, e_fachada)
    end


#Funções de grelhas de pontos

pts_grelha(p, l_tot, n, c_tot, m) =
    map_division((i,j) -> p + vxy(i, j), 0, l_tot, n, 0, c_tot, m)

grelha_4pts(p, l_tot, n, c_tot, m) = 
    iterate_quads((p1, p2, p3, p4) -> [p1, p2, p3, p4], pts_grelha(p, l_tot, n, c_tot, m))


#Funções de lajes

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
    #vazios_set: conjunto de indices vazios
    #nucleos_set: conjunto de indices de nucleos

#Criação de lajes em todos os pisos
laje_total(p, dc, nc, dl, nl, np, h, e_laje, bvb, bvi, bvL, hvL, vazios_set, nucleos_set) =
    [laje_piso(p + vz(h * i - e_laje/2), dc, nc, dl, nl, e_laje, bvb, bvi, bvL, hvL, vazios_set, nucleos_set)
        for i in 1:np]

#Função que entrega arrays de 4 pontos à função laje_map
laje_piso(p, dc, nc, dl, nl, e_laje, bvb, bvi, bvL, hvL, vazios_set, nucleos_set) =
    [laje_for(
            grelha_4pts(p, dc * nc, nc, dl * nl, nl), e_laje, nc, nl, bvb, bvi, bvL, hvL, vazios_set, nucleos_set)]

#Função que aplica a função laje_singular a cada array de 4 pontos          
laje_for(ptss, e_laje, nc, nl, bvb, bvi, bvL, hvL, vazios_set, nucleos_set) =
    [laje_singular([vcat(ptss[i][j])...], e_laje, nc, nl, bvb, bvi, bvL, hvL, i, j, vazios_set, nucleos_set)
        for i in 1:nc, #i define a coluna inicial e final
            j in 1:nl #j define a linha inicial e final
                if !([i, j] in vcat([vazios_set, nucleos_set]...))] #nao cria laje nos vazios

#Função que cria uma laje untilizando um array de 4 pontos
laje_singular(pts, e_laje, nc, nl, bvb, bvi, bvL, hvL, i, j, vazios_set, nucleos_set) =
    let #define o offset inferior em y
        ([i, j - 1] in nucleos_set ? offset_1 = 0 #estende a viga até ao nucleo 
            : (j==1 ? offset_1 = bvb #reduz a viga para encaixar na viga de bordadura inferior
            : ([i, j - 1] in vazios_set ? offset_1 = bvb #reduz a viga para encaixar na viga de bordadura interior
            : offset_1 = bvi/2))) #reduz a viga para encaixar nas vigas interiores
        #define o offset superior em y
        ([i, j + 1] in nucleos_set ? offset_2 = 0 #estende a viga até ao nucleo
            : (j==nl ? offset_2 = bvb #reduz a viga para encaixar na viga de bordadura superior
            : ([i, j + 1] in vazios_set ? offset_2 = bvb #reduz a viga para encaixar na viga de bordadura interior
            : offset_2 = bvi/2))) #reduz a viga para encaixar nas vigas interiores
        #cria laje
        [thicken(
            surface_polygon(pts), -e_laje)]
        #cria as vigas da laje
        [(i==1 ? nothing : ([i-1, j] in vazios_set ? nothing : #nao cria a viga da esquerda se... 
            box(
                pts[1] + vyz(offset_1, -e_laje/2),
                pts[4] + vxyz(bvL, -offset_2, -hvL - e_laje/2)))),
         (i==nc ? nothing : ([i+1, j] in vazios_set ? nothing : #nao cria a viga da direita se...
            box(
                pts[2] + vyz(offset_1, -e_laje/2),
                pts[3] + vxyz(-bvL, -offset_2, -hvL - e_laje/2)))),
            #cria as vigas centrais
            box( 
                intermediate_loc(pts[1], pts[2]) + vyz(offset_1, -e_laje/2),
                intermediate_loc(pts[3], pts[4]) + vxyz(-bvL, -offset_2, -hvL - e_laje/2)),
            box(
                intermediate_loc(pts[1], pts[2]) + vyz(offset_1, -e_laje/2),
                intermediate_loc(pts[3], pts[4]) + vxyz(bvL, -offset_2, -hvL - e_laje/2))]
    end


#Funções de pilares da fachada

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
    #vazios_set: conjunto de vazios

#Criação de pilares da fachada em todos os pisos
pilares_fachada_total(p, dc, nc, dl, nl, np, h, a, b, cpc, hvb, vazios_set) =
    [pilares_fachada_piso(p + vz(h * i - h), dc * nc, nc, dl * nl, nl, dc, dl, h - hvb, a, b, cpc, vazios_set)
        for i in 1:np]

#Criação de pilares da fachada em um piso
pilares_fachada_piso(p, c, n, l, m, dc, dl, h, a, b, cpc, vazios_set) =
    #cria o pilar da esquerda das fachadas horizontais em cada laje
    [pilares_for_linha( 
        pts_grelha(p, c, n, l - b, m), a, b, h, vazios_set,
        2, 1), #define o i inicial e final
     #cria o pilar da direita das fachadas horizontais em cada laje
     pilares_for_linha(
        pts_grelha(p + vx(dc - a), c, n, l - b, m), a, b, h, vazios_set,
        1, 2), #define o i inicial e final
     #cria o pilar inferior das fachadas laterais em cada laje
     pilares_for_coluna(
        pts_grelha(p, c - b, n, l, m), b, a, h, vazios_set,
        2, 1), #define o j inicial e final
     #cria o pilar superior das fachadas laterais em cada laje
     pilares_for_coluna(
        pts_grelha(p + vy(dl - a), c - b, n, l, m), b, a, h, vazios_set,
        1, 2), #define o j inicial e final
     #cria os pilares dos cantos
     pilares_for_cantos(
        pts_grelha(p, c - cpc, n, l - cpc, m), cpc, h, vazios_set)]

#Função que aplica a função pilar_singular a cada ponto do array        
pilares_for_linha(ptss, a, b, h, vazios_set, k1, k2) =
    [pilar_singular(ptss[i][j], h, a, b)
        for i in k1:(length(ptss)-k2), #i define a coluna inicial e final
            j in 1:(length(ptss[1])-1):length(ptss[1]) #j define a linha inicial e final
                if !([i, j] in vazios_set) #nao cria pilar nos vazios
                && !([i, j-1] in vazios_set)]

pilares_for_coluna(ptss, a, b, h, vazios_set, k1, k2) =
    [pilar_singular(ptss[i][j], h, a, b)
        for i in 1:(length(ptss)-1):length(ptss), #i define a coluna inicial e final
            j in k1:(length(ptss[1])-k2) #j define a linha inicial e final
                if !([i, j] in vazios_set) #nao cria pilar nos vazios
                && !([i-1, j] in vazios_set)]

pilares_for_cantos(ptss, c, h, vazios_set) =
    [pilar_singular(ptss[i][j], h, c, c)
        for i in 1:(length(ptss)-1):length(ptss), #i define a coluna inicial e final
            j in 1:(length(ptss[1])-1):length(ptss[1]) #j define a linha inicial e final
                if !([i, j] in vazios_set) #nao cria pilar nos vazios
                && !([i-1, j] in vazios_set)
                && !([i, j-1] in vazios_set)
                && !([i-1, j-1] in vazios_set)]

#Função que cria um pilar
pilar_singular(p1, h, a, b) =
    box(p1, p1 + vxyz(a, b, h))



#Funções de pilares interiores

    #p: ponto de referência
    #dc: distância entre colunas
    #nc: número de colunas
    #dl: distância entre linhas
    #nl: número de linhas
    #np: número de pisos
    #h: altura do piso
    #hvi: altura da viga interior
    #api: dimensão dos pilares interiores
    #vazios_set: conjunto de indices vazios

#Criação de pilares interiores em todos os pisos
pilares_interior_total(p, dc, nc, dl, nl, np, h, hvi, api, vazios_set) =
    [pilares_interior_piso(p + vz(h * i - h), dc * nc, nc, dl * nl, nl, h - hvi, api, vazios_set)
        for i in 1:np]

#Criação de pilares interiores em um piso 
pilares_interior_piso(p, c, n, l, m, h, api, vazios_set) =
    [pilares_interiores_for(
        pts_grelha(p, c, n, l, m), h, api, vazios_set)]

#Função que aplica a função pilar_interior a cada ponto do array
pilares_interiores_for(ptss, h, api, vazios_set) =
    [pilar_interior(ptss[i][j], api, h)
        for i in 3:2:(length(ptss)-1), #i define a coluna inicial e final
            j in 2:(length(ptss[1])-1) #j define a linha inicial e final
                if !([i, j] in vazios_set) #nao cria pilar nos vazios
                && !([i-1, j] in vazios_set)
                && !([i, j-1] in vazios_set)
                && !([i-1, j-1] in vazios_set)]

#Função que cria um pilar
pilar_interior(p, api, h) =
    box(p - vxy(api/2, api/2), p + vxyz(api/2, api/2, h))

    
#Funções de vigas de bordadura

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
    #vazios_set: conjunto de indices vazios
    #nucleos_set: conjunto de indices dos nucleos
 
#Criação de vigas de bordadura em todos os pisos
viga_bordadura_total(p, dc, nc, dl, nl, hvb, bvb, h, np, e, vazios_set, nucleos_set) =
    [viga_bordadura_piso(p + vz(h * i), dc, nc, dl, nl, hvb, bvb, e, vazios_set, nucleos_set) 
        for i in 1:np]

#Criação de vigas de bordadura em um piso
viga_bordadura_piso(p, dc, nc, dl, nl, hvb, bvb, e, vazios_set, nucleos_set) =
    let
        vazios_set_tot = vcat([vazios_set, nucleos_set]...)
        #Cria a linha inferior
        [viga_bordadura_for(
            pts_grelha(
                p - vz(hvb + e), dc * nc, nc, dl * nl - bvb, nl),
                hvb, dc, bvb, vazios_set_tot,
                0, 0, #offset em x da viga incial e final
                0, 0, #offset em y da viga incial e final
                1, nc, #i define a coluna inicial e final
                1, 1,  #j define a linha inicial e final
                0, 0), #(i, j) se j=0 no vaios_set_tot, não cria viga                                                   
        #Cria a linha superior
        viga_bordadura_for( 
            pts_grelha(
                p - vz(hvb + e), dc * nc, nc, dl * nl, nl),
                hvb, dc, -bvb, vazios_set_tot,
                0, 0, #offset em x da viga incial e final
                0, 0, #offset em y da viga incial e final
                1, nc, #i define a coluna inicial e final
                nl + 1, nl + 1, #j define a linha inicial e final
                0, -1), #(i, j) se j=nl no vaios_set_tot, não cria viga
        #cria a coluna esquerda
        viga_bordadura_for(
            pts_grelha(
                p - vz(hvb + e), dc * nc, nc, dl * nl, nl),
                hvb, bvb, dl, vazios_set_tot,
                0, 0, #offset em x da viga incial e final
                bvb, bvb, #offset em y da viga incial e final
                1, 1, #i define a coluna inicial e final
                1, nl, #j define a linha inicial e final
                0, 0), #(i, j) se i=0 no vaios_set_tot, não cria viga
        #cria a coluna direita
        viga_bordadura_for(
            pts_grelha(
                p - vz(hvb + e), dc * nc, nc, dl * nl, nl),
                hvb, -bvb, dl, vazios_set_tot,
                0, 0, #offset em x da viga incial e final
                bvb, bvb, #offset em y da viga incial e final
                nc + 1, nc + 1, #i define a coluna inicial e final
                1, nl, #j define a linha inicial e final
                -1, 0), #(i, j) se i=nc no vaios_set_tot, não cria viga
        #cria as linhas de vigas de bordadura interiores
        viga_bordadura_for_l_interior(
            pts_grelha(
                p - vz(hvb + e), dc * nc, nc, dl * nl, nl),
                hvb, dc, bvb, vazios_set, vazios_set_tot),
        #cria as colunas de vigas de bordadura interiores
        viga_bordadura_for_c_interior(
            pts_grelha(
                p - vz(hvb + e), dc * nc, nc, dl * nl, nl),
                hvb, bvb, dl, vazios_set, vazios_set_tot)
        ]
    end

#Função que entrega pontos para criar uma viga de bordadura_linha na fachada do ediifico
viga_bordadura_for(ptss, hvb, xvb, yvb, set_1, offset1x, offset2x, offset1y, offset2y, c1, c2, c3, c4, i1, j1) =
    [viga_bordadura_singular(ptss[i][j], hvb, xvb, yvb,
        (i==1 ? offset1x : 0), (i==(length(ptss)-1) ? offset2x : 0), #define o offset em x
        (j==1 ? offset1y : 0), j==(length(ptss[1])-1) ? offset2y : 0) #define o offset em y                                
            for i in c1:c2, #i define a coluna inicial e final
                j in c3:c4  #j define a linha inicial e final
                    if !([i + i1, j + j1] in set_1)] #se i + i1, j + j1 estiverem no set_1, nao cria viga

#Função que entrega pontos para criar uma viga de bordadura_linha no interior do ediifico
viga_bordadura_for_l_interior(ptss, hvb, xvb, yvb, vazios_set, vazios_set_tot) =
    [[viga_bordadura_singular(ptss[i][j], hvb, xvb, yvb,
        (i==1 ? yvb : 0), (i==(length(ptss)-1) ? yvb : 0), #define o offset em x
        0, 0) #define o offset em y
            for i in 1:(length(ptss)-1), #i define a coluna inicial e final
                j in 2:(length(ptss[1])-1) #j define a linha inicial e final
                    if ([i, j - 1] in vazios_set) #apenas cria viga se i, j-1 estiver no vazios_set
                    && !([i, j] in vazios_set_tot)], #não cria viga se i, j estiver no vazios_set_tot
     [viga_bordadura_singular(ptss[i][j + 1], hvb, xvb, -yvb,
        (i==1 ? yvb : 0), (i==(length(ptss)-1) ? yvb : 0), #define o offset em x
        0, 0) #define o offset em y
            for i in 1:(length(ptss)-1), #i define a coluna inicial e final
                j in 1:(length(ptss[1])-2) #j define a linha inicial e final
                    if ([i, j + 1] in vazios_set) #apenas cria viga se i, j+1 estiver no vazios_set
                    && !([i, j] in vazios_set_tot)]] #não cria viga se i, j estiver no vazios_set_tot

#Função que entrega pontos para criar uma viga de bordadura_coluna no interior do ediifico
viga_bordadura_for_c_interior(ptss, hvb, xvb, yvb, vazios_set, vazios_set_tot) =
    [[viga_bordadura_singular(ptss[i][j], hvb, xvb, yvb,
        0, 0, #define o offset em x
        (j==1 ? xvb : 0), j==(length(ptss[1])-1) ? xvb : 0) #define o offset em y
            for i in 2:(length(ptss)-1), #i define a coluna inicial e final
                j in 1:(length(ptss[1])-1) #j define a linha inicial e final
                    if ([i - 1, j] in vazios_set) #apenas cria viga se i-1, j estiver no vazios_set
                    && !([i, j] in vazios_set_tot)], #não cria viga se i, j estiver no vazios_set_tot
      [viga_bordadura_singular(ptss[i + 1][j], hvb, -xvb, yvb,
        0, 0, #define o offset em x
        (j==1 ? xvb : 0), j==(length(ptss[1])-1) ? xvb : 0) #define o offset em y
            for i in 1:(length(ptss)-2), #i define a coluna inicial e final
                j in 1:(length(ptss[1])-1) #j define a linha inicial e final
                    if ([i + 1, j] in vazios_set) #apenas cria viga se i+1, j estiver no vazios_set
                    && !([i, j] in vazios_set_tot)]] #não cria viga se i, j estiver no vazios_set_tot

#Função que cria uma viga de bordadura
viga_bordadura_singular(p, hvb, xvb, yvb, offset1x, offset2x, offset1y, offset2y) =
    [box(p + vxy(offset1x, offset1y),
         p + vxyz(xvb - offset2x, yvb - offset2y, hvb))] 


#Funções de vigas interiores

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
    #vazios_set: conjunto de indices vazias

#Criação de vigas interiores em todos os pisos
viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e, bvb, vazios_set) =
    [viga_interior_piso(p + vz(h * i), dc, nc, dl, nl, hvi, bvi, e, bvb, vazios_set)
        for i in 1:np]

#Criação de vigas interiores em um piso
viga_interior_piso(p, dc, nc, dl, nl, hvi, bvi, e, bvb, vazios_set) = 
    [viga_interior_for(
        pts_grelha(p + vyz( -bvi/2, -hvi - e), dc * (nc - 1), nc - 1, dl * nl, nl),
                   hvi, dc, bvi, bvb, vazios_set)]

#Função que entrega um array de arrays de pontos à função viga_interior_singular
viga_interior_for(ptss, hvi, xvi, yvi, offset, vazios_set) = 
    [viga_interior_singular(ptss[i][j], hvi, xvi, yvi,
        (i==1 ? offset : 0), (i==length(ptss) ? offset : 0)) #define o offset em x para alinhar com a viga de bordadura 
            for i in 1:length(ptss), #i define a coluna
                j in 2:(length(ptss[1])-1) #j define a linha
                    if !([i, j] in vazios_set) #não cria viga se i, j estiver no vazios_set 
                        && !([i, j - 1] in vazios_set)] #não cria viga se i, j-1 estiver no vazios_set

#Função que cria as vigas interiores
viga_interior_singular(p, hvi, xvi, yvi, offset1, offset2) =
    box(p + vx(offset1), p + vxyz(xvi - offset2, yvi, hvi))


#Funções de núcleos

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as linhas
    #nl: número de linhas
    #h: altura de cada piso
    #np: número de pisos
    #enb: espessura do núcleo de betão
    #nucleos_set: conjunto de indices de núcleos vazios

#Função que entrega um array de arrays de pontos para criar os núcleos
nucleo_total(p, dc, nc, dl, nl, h, np, enb, nucleos_set) =
    nucleo_for(
        pts_grelha(p, dc * nc, nc, dl * nl, nl), dc, dl, h, np, enb, nucleos_set)

#Função que entrega um ponto à função nucleo_singular
nucleo_for(ptss, dc, dl, h, np, enb, nucleos_set) =
    [nucleo_singular(ptss[i][j], dc * kx, dl * ky, h, np, enb)
        for i in 1:length(ptss), #i define a coluna
            j in 1:length(ptss[1]), #j define a linha
            kx in 0:length(ptss), #kx define o número de nucleos consecutivos em x
            ky in 0:length(ptss[1]) #ky define o número de nucleos consecutivos em y
                if [i, j, kx, ky] in nucleos_set]

#Função que cria um núcleo
nucleo_singular(p, c, l, h, np, enb) =
    subtraction(
        box(p, p + vxyz(c, l, h * np)),
        box(p + vxy(enb, enb), p + vxyz(c - enb, l - enb, h * np - enb)))

#Função que cria um set com as posições e dimensões dos núcleos
nucleos_set_count(nucleos_set) =
    let nucleos_set_count = Set{Tuple{Int,Int}}((n[1], n[2]) for n in nucleos_set if n[1] > 0 && n[2] > 0)
        function count_right(i, j)
            k = 0
            while (i + k + 1, j) in nucleos_set_count
                k += 1
            end
            k
        end
        
        function count_top(i, j)
            k = 0
            while (i, j + k + 1) in nucleos_set_count
                k += 1
            end
            k
        end
        
        [[i, j, count_right(i, j) + 1, count_top(i, j) + 1]
            for (i, j) in nucleos_set_count
                if !((i - 1, j) in nucleos_set_count)
                    && !((i, j - 1) in nucleos_set_count)]
    end


#Funções de paineis de fachada

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as linhas
    #nl: número de linhas
    #h: altura de cada piso
    #np: número de pisos
    #e_fachada: espessura do painel de fachada
    #vazios_set: conjunto de indices de paineis de fachada vazios

#Criação de paineis de fachada em todos os pisos
painel_fachada_total(p, dc, nc, dl, nl, np, h, vazios_set, e_fachada) =
    [painel_fachada_piso(p + vz(h * i - h), dc * nc, nc, dl * nl, nl, h, vazios_set, e_fachada)
        for i in 1:np]

#Criação de paineis de fachada em um piso
painel_fachada_piso(p, c, nc, l, nl, h, vazios_set, e_fachada) =
    #cria a linha inferior de paineis de fachada
    [painel_fachada_for(
        pts_grelha(p, c, nc, l, nl), h, vazios_set,
        1, 0, #posição (x,y) do p2 relativamente ao p1
        1, nc, #i define a coluna inicial e final
        1, 1, #j define a linha inicial e final
        0, 0, #c1, c2 definem o primeiro indice de vazios
        0, -1, #c3, c4 definem o segundo indice de vazios
        0, -e_fachada), #define a oreintação da espessura da fachada
    #cria a linha superior de paineis de fachada
     painel_fachada_for(
        pts_grelha(p, c, nc, l, nl), h, vazios_set,
        1, 0, #posição (x,y) do p2 relativamente ao p1
        1, nc, #i define a coluna inicial e final
        nl + 1, nl + 1, #j define a linha inicial e final
        0, -1, #c1, c2 definem o primeiro indice de vazios
        0, 0, #c3, c4 definem o segundo indice de vazios
        0, e_fachada), #define a oreintação da espessura da fachada
    #cria a coluna esquerda de paineis de fachada
     painel_fachada_for(
        pts_grelha(p, c, nc, l, nl), h, vazios_set,
        0, 1, #posição (x,y) do p2 relativamente ao p1
        1, 1, #i define a coluna inicial e final
        1, nl, #j define a linha inicial e final
        0, 0, #c1, c2 definem o primeiro indice de vazios
        -1, 0, #c3, c4 definem o segundo indice de vazios
        -e_fachada, 0), #define a oreintação da espessura da fachada
    #cria a coluna direita de paineis de fachada
     painel_fachada_for(
        pts_grelha(p, c, nc, l, nl), h, vazios_set,
        0, 1, #posição (x,y) do p2 relativamente ao p1
        nc + 1, nc + 1, #i define a coluna inicial e final
        1, nl, #j define a linha inicial e final
        -1, 0, #c1, c2 definem o primeiro indice de vazios
        0, 0, #c3, c4 definem o segundo indice de vazios
        e_fachada, 0)] #define a oreintação da espessura da fachada

#Função que entrega os pontos para criar os paineis da fachada
painel_fachada_for(ptss, h, vazios_set, i0, j0, i1, i2, j1, j2, c1, c2, c3, c4, ex, ey) =
    [painel_fachada_singular(ptss[i][j], ptss[i + i0][j + j0], h, ex, ey)
        for i in i1:i2,
            j in j1:j2
                if !([i + c1, j + c2] in vazios_set)
                    && !([i + c3, j + c4] in vazios_set)]

#Função que cria um painel de fachada
painel_fachada_singular(p1, p2, h, ex, ey) =
    box(p1, p2 + vxyz(ex, ey, h/2))


#Testes de funções
delete_all_shapes()

edificio_CREE(xyz(0, 0, 0), 4, 7, 6.0, 3.0, 3, 3.0,
    [[1, 1]],
    [ [2, 3], [3, 1], [4, 1], [6, 1], [5, 4], [7, 2], [7, 4], [2, 4], [3, 2], [4, 2]])

edificio_CREE(xyz(28, 0, 0), 6, 8, 6.0, 3.0, 3, 3.0,
    [[3, 3], [3, 4], [4, 3], [4, 4], [5, 3], [5, 4], [6, 3], [6, 4]], 
    [[2, 2], [2, 5], [7, 2], [7, 5]])

edificio_CREE(xyz(55, 0, 0), 3, 5, 6.0, 3.0, 5, 3.0,
    [[1, 3], [5, 1], [5, 3], [3, 2]],
    [[1, 1]])

edificio_CREE(xyz(0, 50, 0), 3, 20, 6.0, 3.0, 3, 3.0,
    [[5, 4], [6, 4], [0,2], [21, 2], [10, 0], [5, 1], [15, 3], [4, 2], [7, 2]],
    [[5, 2], [6, 2], [15, 2], [16, 2]])

grelha = pts_grelha(xyz(0, 0, 0), 18.0, 3, 21.0, 7)
grelha_4pts(xyz(0, 0, 0), 18.0, 3, 21.0, 7)
vcat(grelha_4pts(xyz(0, 0, 0), 18.0, 3, 21.0, 7)...)

viga_interior_grelha(xyz(0, 0, 0), 18.0, 7, 21.0, 3, 3.0, 3.0, 3.0, 0.0)

grelha[2][1]

vazios_set = [[1, 1], [2, 3]]
vazios_set[1]

nucleos_set([[1, 1], [2, 3], [3, 1], [4, 1], [6, 1], [5, 4], [7, 2], [7, 4], [2, 4], [3, 2], [4, 2]])
