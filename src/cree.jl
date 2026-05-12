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
        cpc = 0.3 # largura e profundidade do pilar de canto
        hvb = 0.3 # Altura da viga de bordadura
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

        laje_total(p, dc, nc, dl, nl, np, h, e_laje, bvb, bvi, bvL, hvL, vz_set, ncl_set)
        pilares_fachada_total(p, dc, nc, dl, nl, np, h, apf, bpf, cpc, hvb + e_laje, vz_set_tot, vz_set)
        pilares_interior_total(p, dc, nc, dl, nl, np, h, hvi + e_laje, api, vz_set_tot)
        viga_bordadura_total(p, dc, nc, dl, nl, hvb, bvb, h, np, e_laje, vz_set, ncl_set)
        viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e_laje, bvb, vz_set_tot, vz_set)
        nucleo_total(p, dc, nc, dl, nl, h, enb, nucleos_set_count(ncl_set, np))
        painel_fachada_total(p, dc, nc, dl, nl, np, h, vz_set, vz_set_tot, e_fachada)
    end


#Funções auxiliares

#completa a posição [3] do conjunto de indices para incluir todos os pisos
completa_vazios(set_1, np) =
    [
        isempty(x[3]) ? [x[1], x[2], collect(1:np)] : x
        for x in set_1
    ]

#verifica se o indice [i, j, k] pertence ao conjunto
tem_indice(set_1, i, j, k) =
    any(x -> x[1] == i && x[2] == j && k in x[3], set_1)

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
    #vz_set: conjunto de indices vazios
    #ncl_set: conjunto de indices de nucleos

#Criação de lajes em todos os pisos
laje_total(p, dc, nc, dl, nl, np, h, e_laje, bvb, bvi, bvL, hvL, vz_set, ncl_set) =

    [laje_piso(
        p + vz(h * k - e_laje/2), dc, nc, dl, nl, e_laje,
        bvb, bvi, bvL, hvL, vz_set, ncl_set, k)

            for k in 1:np]

#Função que entrega arrays de 4 pontos à função laje_map
laje_piso(p, dc, nc, dl, nl, e_laje, bvb, bvi, bvL, hvL, vz_set, ncl_set, k) =

    [laje_for(
            grelha_4pts(
                p, dc * nc, nc, dl * nl, nl), e_laje, nc, nl,
                bvb, bvi, bvL, hvL, vz_set, ncl_set, k)]

#Função que seleciona os arrays de 4 pontos para criar as lajes          
laje_for(ptss, e_laje, nc, nl, bvb, bvi, bvL, hvL, vz_set, ncl_set, k) =
    let 
        vz_set_tot = vcat([vz_set, ncl_set]...)
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [laje_singular([vcat(ptss[i][j])...], e_laje, nc, nl,
                        bvb, bvi, bvL, hvL, i, j, k, vz_set, ncl_set)

        for i in 1:nc, #i define a coluna inicial e final
            j in 1:nl #j define a linha inicial e final

        if !in_vz_tot(i, j)]
    end

#Função que cria uma laje untilizando um array de 4 pontos
laje_singular(pts, e_laje, nc, nl, bvb, bvi, bvL, hvL, i, j, k, vz_set, ncl_set) =
    let
        in_vazio(ii, jj)  = tem_indice(vz_set, ii, jj, k)
        in_nucleo(ii, jj) = tem_indice(ncl_set, ii, jj, k)

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

            # cria laje
            [thicken(surface_polygon(pts), -e_laje),

            # viga esquerda
            i == 1 || in_vazio(i - 1, j) ? nothing :    #não cria na primeira coluna ou se vazio na coluna anterior
                box(
                    pts[1] + vyz(offset_1, -e_laje / 2),
                    pts[4] + vxyz(bvL, -offset_2, -hvL - e_laje / 2)),

            # viga direita
            i == nc || in_vazio(i + 1, j) ? nothing :    #não cria na ultima coluna ou se vazio na coluna posterior
                box(
                    pts[2] + vyz(offset_1, -e_laje / 2),
                    pts[3] + vxyz(-bvL, -offset_2, -hvL - e_laje / 2)),

            # vigas centrais
            box(
                intermediate_loc(pts[1], pts[2]) + vyz(offset_1, -e_laje / 2),
                intermediate_loc(pts[3], pts[4]) + vxyz(-bvL, -offset_2, -hvL - e_laje / 2)),
            box(
                intermediate_loc(pts[1], pts[2]) + vyz(offset_1, -e_laje / 2),
                intermediate_loc(pts[3], pts[4]) + vxyz(bvL, -offset_2, -hvL - e_laje / 2))]
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
    #vz_set_tot: conjunto de vazios e nucleos
    #vz_set: conjunto de vazios

#Criação de pilares da fachada em todos os pisos
pilares_fachada_total(p, dc, nc, dl, nl, np, h, a, b, cpc, hvb, vz_set_tot, vz_set) =

    #Criação de pilares da fachada em todos os pisos
    [[pilares_fachada_piso(
        p + vz(h * k - h),
        dc * nc, nc, dl * nl, nl, dc, dl,
        h - hvb, a, b, cpc, vz_set_tot, k)

            for k in 1:np],

    #Criação de pilares da fachada interior em todos os pisos
     [pilares_fachada_interior_piso(
        p + vz(h * k - h),
        dc * nc, nc, dl * nl, nl, dc, dl,
        h - hvb, a, b, vz_set_tot, vz_set, k)

            for k in 1:np],

    #Criação de pilares de cantos interiores em todos os pisos
     [pilares_cantos_interiores_piso(
        p + vz(h * k - h),
        dc * nc, nc, dl * nl, nl, dc, dl,
        h - hvb, cpc, vz_set_tot, vz_set, k)

            for k in 1:np]]

#Criação de pilares da fachada em um piso
pilares_fachada_piso(p, c, nc, l, nl, dc, dl, h, a, b, cpc, vz_set_tot, k) =

    #cria o pilar da esquerda das fachadas horizontais em cada laje
    [pilares_fachada_for( 
        pts_grelha(
            p, c, nc, l - b, nl),
        a, b, h, vz_set_tot, k,
        2, 1, nc,               #define o i inicial, incremento e final
        1, nl, nl + 1,          #define o j inicial, incremento e final
        0, -1),                 #não cria pilar se a linha inferior ou posterior for vazio

     #cria o pilar da direita das fachadas horizontais em cada laje
     pilares_fachada_for(
        pts_grelha(
            p + vx(dc - a), c, nc, l - b, nl),
        a, b, h, vz_set_tot, k,
        1, 1, nc -1,            #define o i inicial, incremento e final
        1, nl, nl + 1,          #define o j inicial, incremento e final
        0, -1),                 #não cria pilar se a linha inferior ou posterior for vazio

     #cria o pilar inferior das fachadas laterais em cada laje
     pilares_fachada_for(
        pts_grelha(
            p, c - b, nc, l, nl),
        b, a, h, vz_set_tot, k,
        1, nc, nc + 1,          #define o i inicial, incremento e final
        2, 1, nl,               #define o j inicial, incremento e final
        -1, 0),                 #não cria pilar se a coluna esquerda ou direita for vazio

     #cria o pilar superior das fachadas laterais em cada laje
     pilares_fachada_for(
        pts_grelha(
            p + vy(dl - a), c - b, nc, l, nl),
        b, a, h, vz_set_tot, k,
        1, nc, nc + 1,          #define o i inicial, incremento e final
        1, 1, nl - 1,           #define o j inicial, incremento e final
        -1, 0),                 #não cria pilar se a coluna esquerda ou direita for vazio

     #cria os pilares dos cantos
     pilares_cantos_for(
        pts_grelha(
            p, c - cpc, nc, l - cpc, nl),
        cpc, h, vz_set_tot, k)]

#função que seleciona os pontos para criar os pilares da fachada
pilares_fachada_for(ptss, x, y, h, vz_set_tot, k, i1, i2, i3, j1, j2, j3, c1, c2) =
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [pilar_singular(ptss[i][j], h, x, y)

            for i in i1:i2:i3,  #i define a coluna inicial e final
                j in j1:j2:j3   #j define a linha inicial e final

            if  !in_vz_tot(i, j) && 
                !in_vz_tot(i + c1, j + c2)]
    end

#função que seleciona os pontos para criar os pilares dos cantos
pilares_cantos_for(ptss, c, h, vz_set_tot, k) =
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)
    
        [pilar_singular(ptss[i][j], h, c, c)
            
            for i in 1:(length(ptss)-1):length(ptss),       #i define a coluna inicial e final
                j in 1:(length(ptss[1])-1):length(ptss[1])  #j define a linha inicial e final

            #não cria pilar nos vazios e nucleos nos canto    
            if  !in_vz_tot(i, j) && 
                !in_vz_tot(i-1, j) && 
                !in_vz_tot(i, j-1) && 
                !in_vz_tot(i-1, j-1)]
    end

#Criação de pilares da fachada interior em um piso        
pilares_fachada_interior_piso(p, c, nc, l, nl, dc, dl, h, a, b, vz_set_tot, vz_set, k) =

    #cria os pilares da esquerda da linha superior das fachadas interiores
    [pilares_fachada_interior_for(
        pts_grelha(
            p, c, nc, l, nl),
        a, b, h, vz_set_tot, vz_set, k,
        2, nc,                              #i: define a coluna inicial e final
        2, nl,                              #j: define a linha inicial e final
        0, -1, 1000000),                    #define os indices adjacentes onde criar os pilares

    #cria os pilares da direita da linha superior das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vx(dc - a), c, nc, l, nl),
        a, b, h, vz_set_tot, vz_set, k,
        1, nc - 1,                          #i: define a coluna inicial e final    
        2, nl,                              #j: define a linha inicial e final
        0, -1, 1000000),                    #define os indices adjacentes onde criar os pilares

    #cria os pilares da esquerda da linha inferior das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vy(dl - b), c, nc, l, nl),
        a, b, h, vz_set_tot, vz_set, k,    
        2, nc,                              #i: define a coluna inicial e final
        1, nl - 1,                          #j: define a linha inicial e final
        0, 1, 1000000),                     #define os indices adjacentes onde criar os pilares

    #cria os pilares da direita da linha inferior das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vxy(dc - a, dl - b), c, nc, l, nl),
        a, b, h, vz_set_tot, vz_set, k,
        1, nc - 1,                          #i: define a coluna inicial e final
        1, nl - 1,                          #j: define a linha inicial e final
        0, 1, 1000000),                     #define os indices adjacentes onde criar os pilares

    #cria os pilares inferiores da coluna direita das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p, c, nc, l, nl),
        b, a, h, vz_set_tot, vz_set, k,
        2, nc - 1,                          #i: define a coluna inicial e final
        2, nl,                              #j: define a linha inicial e final
        -1, 0, -1),                         #define os indices adjacentes onde criar os pilares

    #cria os pilares superiores da coluna direita das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vy(dl - a), c, nc, l, nl),
        b, a, h, vz_set_tot, vz_set, k,
        2, nc - 1,                          #i: define a coluna inicial e final
        1, nl - 1,                          #j: define a linha inicial e final
        -1, 0, 1),                          #define os indices adjacentes onde criar os pilares

    #cria os pilares inferioes da coluna esquerda das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vx(dc - b), c, nc, l, nl),
        b, a, h, vz_set_tot, vz_set, k,
        1, nc - 1,                          #i: define a coluna inicial e final
        2, nl,                              #j: define a linha inicial e final
        1, 0, -1),                          #define os indices adjacentes onde criar os pilares

    #cria os pilares superiores da coluna esquerda das fachadas interiores
     pilares_fachada_interior_for(
        pts_grelha(
            p + vxy(dc - b, dl - a), c, nc, l, nl),
        b, a, h, vz_set_tot, vz_set, k,
        1, nc - 1,                          #i: define a coluna inicial e final
        1, nl - 1,                          #j: define a linha inicial e final
        1, 0, 1)]                           #define os indices adjacentes onde criar os pilares

#função que seleciona os pontos para criar os pilares da fachada interiores
pilares_fachada_interior_for(ptss, x, y, h, vz_set_tot, vz_set, k, i1, i2, j1, j2, c1, c2, c3) =
    let 
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)
        in_vz(ii, jj) = tem_indice(vz_set, ii, jj, k)
    
    [pilar_singular(ptss[i][j], h, x, y)

        for i in i1:i2,                 #i define a coluna inicial e final
            j in j1:j2                  #j define a linha inicial e final

        if  !in_vz_tot(i, j) &&            #não cria nos vazios e nucleos
            in_vz(i + c1, j + c2) &&      #apenas cria se tiver certos vazios adjacentes
            !in_vz(i, j + c3)]           #não cria se tiver um vazio superior ou inferior (sobreposição)
    end

#Criação de pilares dos cantos interiores em um piso
pilares_cantos_interiores_piso(p, c, nc, l, nl, dc, dl, h, cpc, vz_set_tot, vz_set, k) =

    #cria os pilares dos cantos inferiores esquerdos interiores
    [pilares_cantos_interiores_for(
        pts_grelha(
            p, c, nc, l, nl),
        -cpc, -cpc, h, vz_set_tot, vz_set, k,
        2, nc,                                  #i: define a coluna inicial e final
        2, nl,                                  #j: define a linha inicial e final
        -1, 0,                                  #indice adjacente que não pode ser vazio
        0, -1),                                 #indice adjacente que não pode ser vazio

    #cria os pilares dos cantos superiores esquerdos interiores
     pilares_cantos_interiores_for(
        pts_grelha(
            p + vy(dl), c, nc, l, nl),
        -cpc, cpc, h, vz_set_tot, vz_set, k,
        2, nc,                                  #i: define a coluna inicial e final
        1, nl - 1,                              #j: define a linha inicial e final
        -1, 0,                                  #indice adjacente que não pode ser vazio
        0, 1),                                  #indice adjacente que não pode ser vazio

    #cria os pilares dos cantos inferiores direitos interiores
     pilares_cantos_interiores_for(
        pts_grelha(
            p + vx(dc), c, nc, l, nl),
        cpc, -cpc, h, vz_set_tot, vz_set, k,
        1, nc - 1,                              #i: define a coluna inicial e final
        2 , nl,                                 #j: define a linha inicial e final
        1, 0,                                   #indice adjacente que não pode ser vazio
        0, -1),                                 #indice adjacente que não pode ser vazio

    #cria os pilares dos cantos superiores direitos interiores
     pilares_cantos_interiores_for(
        pts_grelha(
            p + vxy(dc, dl), c, nc, l, nl),
        cpc, cpc, h, vz_set_tot, vz_set, k,
        1, nc - 1,                              #i: define a coluna inicial e final
        1, nl - 1,                              #j: define a linha inicial e final
        1, 0,                                   #indice adjacente que não pode ser vazio
        0, 1)]                                  #indice adjacente que não pode ser vazio

#função que seleciona os pontos para criar os pilares dos cantos interiores
pilares_cantos_interiores_for(ptss, x, y, h, vz_set_tot, vz_set, k, i1, i2, j1, j2, c1, c2, c3, c4) =
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)
        in_vz(ii, jj) = tem_indice(vz_set, ii, jj, k)

        [pilar_singular(ptss[i][j], h, x, y)

        for i in i1:i2,                     #i define a coluna inicial e final
            j in j1:j2                      #j define a linha inicial e final

        if  in_vz(i, j) &&                  #apenas cria nos vazios
            !in_vz_tot(i + c1, j + c2) &&   #cria apenas se não tiver certos vazios adjacentes
            !in_vz_tot(i + c3, j + c4) && 
            !in_vz_tot(i + c1, j + c4)]
    end

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
    #vz_set: conjunto de indices vazios

#Criação de pilares interiores em todos os pisos
pilares_interior_total(p, dc, nc, dl, nl, np, h, hvi, api, vz_set_tot) =

    [pilares_interior_piso(
        p + vz(h * k - h), dc * nc, nc, dl * nl, nl, h - hvi, api, vz_set_tot, k)

    for k in 1:np]

#Criação de pilares interiores em um piso 
pilares_interior_piso(p, c, n, l, m, h, api, vz_set_tot, k) =

    [pilares_interiores_for(
        pts_grelha(
            p, c, n, l, m),
        h, api, vz_set_tot, k)]

#Função que seleciona os pontos para criar os pilares interiores
pilares_interiores_for(ptss, h, api, vz_set_tot, k) =
    let 
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [pilar_interior(ptss[i][j], api, h)

        for i in 3:2:(length(ptss)-1),      #i define a coluna inicial e final
            j in 2:(length(ptss[1])-1)      #j define a linha inicial e final

        if !in_vz_tot(i, j) &&              #não cria pilar nos vazios e cantos dos nucleos
           !in_vz_tot(i-1, j) && 
           !in_vz_tot(i, j-1) && 
           !in_vz_tot(i-1, j-1)]
    end

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
    #vz_set: conjunto de indices vazios
    #ncl_set: conjunto de indices dos nucleos
 
#Criação de vigas de bordadura em todos os pisos
viga_bordadura_total(p, dc, nc, dl, nl, hvb, bvb, h, np, e, vz_set, ncl_set) =

    [[viga_bordadura_piso(
        p + vz(h * k), dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k)

            for k in 1:np],

     [viga_bordadura_interior_piso(
        p + vz(h * k), dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k)

            for k in 1:np]]

#Criação de vigas de bordadura em um piso
viga_bordadura_piso(p, dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k) =
    let
        vz_set_tot = vcat([vz_set, ncl_set]...)

        #Cria a linha inferior
        [viga_bordadura_for(
            pts_grelha(
                p - vz(hvb + e),
            dc * nc, nc, dl * nl - bvb, nl),
            hvb, dc, bvb, vz_set_tot, k,
            0, 0,                           #offset em (x, y) da viga incial e final
            1, nc,                          #i define a coluna inicial e final
            1, 1,                           #j define a linha inicial e final
            0, 0),                          #(i, j) se j=0 no vaios_set_tot, não cria viga   

        #Cria a linha superior
        viga_bordadura_for( 
            pts_grelha(
                p - vz(hvb + e),
            dc * nc, nc, dl * nl, nl),
            hvb, dc, -bvb, vz_set_tot, k,
            0, 0,                           #offset em (x, y) da viga incial e final
            1, nc,                          #i define a coluna inicial e final
            nl + 1, nl + 1,                 #j define a linha inicial e final
            0, -1),                         #(i, j) se j=nl no vaios_set_tot, não cria viga

        #cria a coluna esquerda
        viga_bordadura_for(
            pts_grelha(
                p - vz(hvb + e),
            dc * nc, nc, dl * nl, nl),
            hvb, bvb, dl, vz_set_tot, k,
            0, bvb,                         #offset em (x, y) da viga incial e final
            1, 1,                           #i define a coluna inicial e final
            1, nl,                          #j define a linha inicial e final
            0, 0),                          #(i, j) se i=0 no vaios_set_tot, não cria viga

        #cria a coluna direita
        viga_bordadura_for(
            pts_grelha(
                p - vz(hvb + e),
            dc * nc, nc, dl * nl, nl),
            hvb, -bvb, dl, vz_set_tot, k,
            0, bvb,                         #offset em (x, y) da viga incial e final
            nc + 1, nc + 1,                 #i define a coluna inicial e final
            1, nl,                          #j define a linha inicial e final
            -1, 0)]                         #(i, j) se i=nc no vaios_set_tot, não cria viga
    end

#Função que seleciona pontos para criar uma viga de bordadura_linha na fachada do ediifico
viga_bordadura_for(ptss, hvb, xvb, yvb, vz_set_tot, k, offsetx, offsety, c1, c2, c3, c4, i1, j1) =
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [viga_bordadura_singular(ptss[i][j], hvb, xvb, yvb,

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

#cria as vigas de bordadura internas    
viga_bordadura_interior_piso(p, dc, nc, dl, nl, hvb, bvb, e, vz_set, ncl_set, k) =
    let
        vz_set_tot = vcat([vz_set, ncl_set]...)

        #cria as linhas superiores de vigas de bordadura
        [viga_bordadura_for_interior(
            pts_grelha(
                p - vz(hvb + e), 
            dc * nc, nc, dl * nl, nl),
            hvb, dc, bvb, vz_set, vz_set_tot, ncl_set, k,
            0, 0,                                       #i0, j0
            bvb, 0,                                     #offset em (x, y) da viga incial e final
            0, 0,                                       #i1, i2
            1, nc,                                      #i3, i4: define a coluna inicial e final
            2, nl,                                      #j1, j2: define a linha inicial e final
            0, -1),                                     #cria a viga se a linha anterior for vazia

        #cria as linhas inferiores de vigas de bordadura
         viga_bordadura_for_interior(
            pts_grelha(
                p - vz(hvb + e), 
            dc * nc, nc, dl * nl, nl),
            hvb, dc, -bvb, vz_set, vz_set_tot, ncl_set, k,
            0, 1,                                       #i0, j0
            bvb, 0,                                     #offset em (x, y) da viga incial e final
            0, 0,                                       #i1, i2
            1, nc,                                      #i3, i4: define a coluna inicial e final
            1, nl - 1,                                  #j1, j2: define a linha inicial e final
            0, 1),                                      #cria a viga se a linha posterior for vazia

        #cria as colunas direitas de vigas de bordadura
         viga_bordadura_for_interior(
            pts_grelha(
                p - vz(hvb + e), 
            dc * nc, nc, dl * nl, nl),
            hvb, bvb, dl, vz_set, vz_set_tot, ncl_set, k,
            0, 0,                                       #i0, j0
            0, bvb,                                     #offset em (x, y) da viga incial e final
            -1, -1,                                     #i1, i2
            2, nc,                                      #i3, i4: define a coluna inicial e final
            1, nl,                                      #j1, j2: define a linha inicial e final
            -1, 0),                                     #cria a viga se a coluna anterior for vazia

        #cria as colunas esquerdas de vigas de bordadura
         viga_bordadura_for_interior(
            pts_grelha(
                p - vz(hvb + e), 
            dc * nc, nc, dl * nl, nl),
            hvb, -bvb, dl, vz_set, vz_set_tot, ncl_set, k,
            1, 0,                                       #i0, j0
            0, bvb,                                     #offset em (x, y) da viga incial e final
            1, 1,                                       #i1, i2
            1, nc - 1,                                  #i3, i4: define a coluna inicial e final
            1, nl,                                      #j1, j2: define a linha inicial e final
            1, 0)]                                      #cria a viga se a coluna posterior for vazia
    end

#função que seleciona os pontos para criar as vigas de bordadura interiores
viga_bordadura_for_interior(ptss, hvb, xvb, yvb, vz_set, vz_set_tot, ncl_set, k, i0, j0, offsetx, offsety, i1, i2, i3, i4, j1, j2, c1, c2) =
    let
        in_vz(ii, jj)       = tem_indice(vz_set, ii, jj, k)
        in_vz_tot(ii, jj)   = tem_indice(vz_set_tot, ii, jj, k)
        in_ncl(ii, jj)      = tem_indice(ncl_set, ii, jj, k)

        [viga_bordadura_singular(
            ptss[i + i0][j + j0], hvb, xvb, yvb,

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
    #vz_set: conjunto de indices vazias

#Criação de vigas interiores em todos os pisos
viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e, bvb, vz_set_tot, vz_set) =

    [viga_interior_piso(
        p + vz(h * k), dc, nc, dl, nl, hvi, bvi, e, bvb, vz_set_tot, vz_set, k)

            for k in 1:np]

#Criação de vigas interiores em um piso
viga_interior_piso(p, dc, nc, dl, nl, hvi, bvi, e, bvb, vz_set_tot, vz_set, k) = 

    [viga_interior_for(
        pts_grelha(
            p + vyz( -bvi/2, -hvi - e),
        dc * nc, nc, dl * nl, nl),
        hvi, dc, bvi, bvb, vz_set_tot, vz_set, k)]

#Função que seleciona os pontos para criar as vigas interiores
viga_interior_for(ptss, hvi, xvi, yvi, offset, vz_set_tot, vz_set, k) =
    let
        in_vz_tot(ii, jj)   = tem_indice(vz_set_tot, ii, jj, k)
        in_vz(ii, jj)       = tem_indice(vz_set, ii, jj, k)

        [viga_interior_singular(ptss[i][j], hvi, xvi, yvi,

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

#Função que cria as vigas interiores
viga_interior_singular(p, hvi, xvi, yvi, offset1, offset2) =
    box(
        p + vx(offset1),
        p + vxyz(xvi - offset2, yvi, hvi))


#Funções de núcleos

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as linhas
    #nl: número de linhas
    #h: altura de cada piso
    #np: número de pisos
    #enb: espessura do núcleo de betão
    #ncl_set: conjunto de indices de núcleos vazios

#Função que entrega um array de arrays de pontos para criar os núcleos
nucleo_total(p, dc, nc, dl, nl, h, enb, ncl_set) =

    nucleo_for(
        pts_grelha(
            p, dc * nc, nc, dl * nl, nl),
        dc, dl, h, enb, ncl_set)

#Função que seleciona os pontos para criar os núcleos
nucleo_for(ptss, dc, dl, h, enb, ncl_set) =

    [nucleo_singular(
        ptss[ncl[1]][ncl[2]],   #coluna e a linha iniciais do núcleo
        dc * ncl[3],            #número de núcleos consecutivos em x
        dl * ncl[4],            #número de núcleos consecutivos em y
        h, ncl[5],              #número de pisos e a altura de cada piso
        enb)                   #espessura do núcleo

    for ncl in ncl_set]
    
#Função que cria um núcleo
nucleo_singular(p, c, l, h, np, enb) =
    subtraction(
        box(p, p + vxyz(c, l, h * np)),
        box(p + vxy(enb, enb), p + vxyz(c - enb, l - enb, h * np - enb)))

#Função que cria um set com as posições e dimensões dos núcleos
nucleos_set_count(ncl_set, np) =
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


#Funções de paineis de fachada

    #p: ponto de referência
    #dc: distância entre as colunas
    #nc: número de colunas
    #dl: distância entre as linhas
    #nl: número de linhas
    #h: altura de cada piso
    #np: número de pisos
    #e_fachada: espessura do painel de fachada
    #vz_set: conjunto de indices de paineis de fachada vazios

#Criação de paineis de fachada em todos os pisos
painel_fachada_total(p, dc, nc, dl, nl, np, h, vz_set, vz_set_tot, e_fachada) =

    [[painel_fachada_piso(
        p + vz(h * k - h), dc * nc, nc, dl * nl, nl, h, vz_set_tot, e_fachada, k)

            for k in 1:np],

     [painel_fachada_interior_piso(
        p + vz(h * k - h), dc * nc, nc, dl * nl, nl, dc, dl, h, vz_set, vz_set_tot, e_fachada, k) 
            
            for k in 1:np]]

#Criação de paineis de fachada em um piso
painel_fachada_piso(p, c, nc, l, nl, h, vz_set_tot, e_fachada, k) =

    #cria a linha inferior de paineis de fachada
    [painel_fachada_for(
        pts_grelha(
            p, c, nc, l, nl), 
        h, vz_set_tot, k,
        1, 0,                   #posição (x,y) do p2 relativamente ao p1
        1, nc,                  #i define a coluna inicial e final
        1, 1,                   #j define a linha inicial e final
        0, 0,                   #c1, c2 definem o primeiro indice de vazios
        0, -1,                  #c3, c4 definem o segundo indice de vazios
        0, -e_fachada),         #define a oreintação da espessura da fachada
    
    #cria a linha superior de paineis de fachada
     painel_fachada_for(
        pts_grelha(
            p, c, nc, l, nl), 
        h, vz_set_tot, k,
        1, 0,                   #posição (x,y) do p2 relativamente ao p1
        1, nc,                  #i define a coluna inicial e final
        nl + 1, nl + 1,         #j define a linha inicial e final
        0, -1,                  #c1, c2 definem o primeiro indice de vazios
        0, 0,                   #c3, c4 definem o segundo indice de vazios
        0, e_fachada),          #define a oreintação da espessura da fachada

    #cria a coluna esquerda de paineis de fachada
     painel_fachada_for(
        pts_grelha(
            p, c, nc, l, nl), 
        h, vz_set_tot, k,
        0, 1,                   #posição (x,y) do p2 relativamente ao p1
        1, 1,                   #i define a coluna inicial e final
        1, nl,                  #j define a linha inicial e final
        0, 0,                   #c1, c2 definem o primeiro indice de vazios
        -1, 0,                  #c3, c4 definem o segundo indice de vazios
        -e_fachada, 0),         #define a oreintação da espessura da fachada

    #cria a coluna direita de paineis de fachada
     painel_fachada_for(
        pts_grelha(
            p, c, nc, l, nl), 
        h, vz_set_tot, k,
        0, 1,                   #posição (x,y) do p2 relativamente ao p1
        nc + 1, nc + 1,         #i define a coluna inicial e final
        1, nl,                  #j define a linha inicial e final
        -1, 0,                  #c1, c2 definem o primeiro indice de vazios
        0, 0,                   #c3, c4 definem o segundo indice de vazios
        e_fachada, 0)]          #define a oreintação da espessura da fachada

#Função que seleciona os pontos para criar paineis de fachada
painel_fachada_for(ptss, h, vz_set_tot, k, i0, j0, i1, i2, j1, j2, c1, c2, c3, c4, ex, ey) =
    let
        in_vz_tot(ii, jj) = tem_indice(vz_set_tot, ii, jj, k)

        [painel_fachada_singular(
            ptss[i][j], ptss[i + i0][j + j0], h, ex, ey)

        for i in i1:i2, #i define a coluna inicial e final
            j in j1:j2 #j define a linha inicial e final

        if  !in_vz_tot(i + c1, j + c2) && 
            !in_vz_tot(i + c3, j + c4)]
    end

#Cria os paineis de fachada interiores em um piso
painel_fachada_interior_piso(p, c, nc, l, nl, dc, dl, h, vz_set, vz_set_tot, e_fachada, k) =

    #cria a linha superior das fachadas interiores
    [painel_fachada_interior_for(
        pts_grelha(
            p + vy(dl), c, nc, l, nl),
        h, vz_set, vz_set_tot, k,
        1, 0, #posição (x,y) do p2 relativamente ao p1
        1, nc,
        1, nl - 1,
        0, 1,
        0, -e_fachada, 0),

    #cria a linha inferior das fachadas interiores
     painel_fachada_interior_for(
        pts_grelha(
            p, c, nc, l, nl), 
        h, vz_set, vz_set_tot, k,
        1, 0, #posição (x,y) do p2 relativamente ao p1
        1, nc,
        2, nl,
        0, -1,
        0, e_fachada, 0),

    #cria a coluna esquerda das fachadas interiores
     painel_fachada_interior_for(
        pts_grelha(
            p, c, nc, l, nl), 
        h, vz_set, vz_set_tot, k,
        0, 1, #posição (x,y) do p2 relativamente ao p1
        2, nc,
        1, nl,
        -1, 0,
        e_fachada, 0, e_fachada),

    #cria a coluna direita das fachadas interiores
     painel_fachada_interior_for(
        pts_grelha(
            p + vx(dc), c, nc, l, nl), 
        h, vz_set, vz_set_tot, k,
        0, 1, #posição (x,y) do p2 relativamente ao p1
        1, nc - 1,
        1, nl,
        1, 0,
        -e_fachada, 0, e_fachada)]

#Função que seleciona os pontos para criar paineis de fachada interiores
painel_fachada_interior_for(ptss, h, vz_set, vz_set_tot, k, i0, j0, i1, i2, j1, j2, c1, c2, ex, ey, offset) =
    let
        in_vz(ii, jj)       = tem_indice(vz_set, ii, jj, k)
        in_vz_tot(ii, jj)   = tem_indice(vz_set_tot, ii, jj, k)

        [painel_fachada_singular(
            ptss[i][j] + vy(
                j == 1 ? 0 :
                !in_vz(i, j - 1) ? offset :     #offset para evitar sobreposição de paineis nos cantos
                0),

            ptss[i + i0][j + j0] - vy(
                j == length(ptss[1]) - 1 ? 0 :  #offset para evitar sobreposição de paineis nos cantos
                !in_vz(i, j + 1) ? offset : 
                0),

            h, ex, ey)

        for i in i1:i2,                     #i define a coluna inicial e final
            j in j1:j2                      #j define a linha inicial e final

        if  in_vz(i, j) &&                  #apenas cria nos vazios
            !in_vz_tot(i + c1, j + c2)]     #não cria se tiver certos vazios adjacentes
    end

#Função que cria um painel de fachada
painel_fachada_singular(p1, p2, h, ex, ey) =
    box(p1, p2 + vxyz(ex, ey, h/2))


#Testes de funções
delete_all_shapes()

edificio_CREE(
    xyz(0, 0, 0), 4, 7, 6.0, 3.0, 3, 3.0,
    [
        [1, 1, []]
    ],[
        [2, 3, [(1:4)...]], [3, 1, [()...]], [4, 1, [(1:5)...]], [6, 1, [(1:2)...]], [5, 4, [()...]], 
        [7, 2, [1]], [7, 4, [(1:4)...]], [2, 4, [()...]], [3, 2, [()...]], [4, 2, [()...]]
    ])

edificio_CREE(
    xyz(0, 50, 0), 2, 20, 6.0, 3.0, 3, 3.0,
    [
        [1, 1, [2, 3]], [5, 1, []], [6, 1, []], [8, 1, []], [12, 2, []], [13, 2, []], [15, 1, []], 
        [17, 2, []], [20, 2, []], [10, 1, [3]], [11, 1, [3]], [12, 1,[2, 3]], [19, 1,[3]], [20, 1,[2, 3]]
    ],[
        [5, 2, [()...]], [6, 2, [()...]], [15, 2, [()...]], [16, 2, [()...]]
    ])

edificio_CREE(
    xyz(32, 0, 0), 6, 8, 6.0, 3.0, 2, 3.0,
    [
        [3, 3, []], [3, 4, []], [4, 3, []], [4, 4, []], [5, 3, []], [5, 4, []], [6, 3, []], [6, 4, []],
        [3, 2,[2]], [4, 2,[2]], [5, 2,[2]], [6, 2,[2]], [3, 5,[2]], [4, 5,[2]], [5, 5,[2]], [6, 5,[2]]
    ], [
        [2, 2, [()...]], [2, 5, [()...]], [7, 2, [()...]], [7, 5, [()...]]
    ])

edificio_CREE(
    xyz(65, 0, 0), 3, 5, 6.0, 3.0, 10, 3.0,
    [
        [1, 1.,[]], [1, 3, []], [5, 1, []], [5, 3, []], [2, 1,[(5:10)...]], [4, 1,[(5:10)...]],
        [2, 3,[(5:10)...]], [4, 3,[(5:10)...]], [1, 2,[(8:10)...]], [5, 2,[(8:10)...]]
    ],[
        [3, 2, [(1:12)...]]
    ])

grelha = pts_grelha(xyz(0, 0, 0), 18.0, 3, 21.0, 7)
grelha_4pts(xyz(0, 0, 0), 18.0, 3, 21.0, 7)
vcat(grelha_4pts(xyz(0, 0, 0), 18.0, 3, 21.0, 7)...)

viga_interior_grelha(xyz(0, 0, 0), 18.0, 7, 21.0, 3, 3.0, 3.0, 3.0, 0.0)

grelha[2][1]

vz_set = [[1, 1], [2, 3]]
vz_set[1]

ncl_set([[1, 1], [2, 3], [3, 1], [4, 1], [6, 1], [5, 4], [7, 2], [7, 4], [2, 4], [3, 2], [4, 2]])



wall()


i = [1, 1, [max((1:10)...)]]