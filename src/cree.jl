using Khepri
backend(autocad)

#Função principal

edificio_CREE(p, nl, nc, dl, dc, np, h, vazios_set) =
    let 
        e_laje = 0.1
        c_tot = dc * nc
        l_tot = dl * nl
        apf = 0.2 # largura dos pilares da fachada
        bpf = 0.3 # profundidade dos pilares da fachada
        cpc = 0.4 # largura e profundidade do pilar de canto
        hvb = 0.4 # Altura da viga de bordadura
        bvb = 0.3 # Largura da viga de bordadura
        hvi = 0.3 # Altura da viga interior
        bvi = 0.3 # Largura da viga interior
        api = 0.3 # largura e profundidade dos pilares interiores
        enb = 0.3 # Espessura do nucleo de betão\
        hvL = 0.3 # Altura das vigas da laje
        bvL = 0.2 # Largura das vigas da laje
        e_fachada = 0.1

        laje_total(p, dc, nc, dl, nl, np, h, e_laje, bvb, bvi, bvL, hvL, vazios_set)
        pilares_fachada_total(p, dc, nc, dl, nl, np, h, apf, bpf, cpc, hvb + e_laje, vazios_set)
        pilares_interior_total(p, dc, nc, dl, nl, np, h, hvi + e_laje, api, vazios_set)
        viga_bordadura_total(p, dc, nc, dl, nl, hvb, bvb, h, np, e_laje, vazios_set)
        viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e_laje, bpf, vazios_set)
        nucleo_total(p, dc, nc, dl, nl, h, np, enb, nucleos_set(vazios_set))
        #painel_fachada_total(p, dc, nc, dl, nl, np, h, vazios_set, e_fachada)
    end


#Funções de grelhas de pontos

pts_grelha(p, l_tot, n, c_tot, m) =
    map_division((i,j) -> p + vxy(i, j), 0, l_tot, n, 0, c_tot, m)

grelha_4pts(p, l_tot, n, c_tot, m) = 
    iterate_quads((p1, p2, p3, p4) -> [p1, p2, p3, p4], pts_grelha(p, l_tot, n, c_tot, m))


#Funções de lajes

#Criação de lajes em todos os pisos
laje_total(p, dc, nc, dl, nl, np, h, e_laje, bvb, bvi, bvL, hvL, vazios_set) =
    [laje_piso(p + vz(h * i - e_laje/2), dc, nc, dl, nl, e_laje, bvb, bvi, bvL, hvL, vazios_set)
        for i in 1:np]

#Função que entrega arrays de 4 pontos à função laje_map
laje_piso(p, dc, nc, dl, nl, e_laje, bvb, bvi, bvL, hvL, vazios_set) =
    [laje_for(
            grelha_4pts(p, dc * nc, nc, dl * nl, nl), e_laje, nc, nl, bvb, bvi, bvL, hvL, vazios_set)]

#Função que aplica a função laje_singular a cada array de 4 pontos          
laje_for(ptss, e_laje, nc, nl, bvb, bvi, bvL, hvL, vazios_set) =
    [laje_singular([vcat(ptss[i][j])...], e_laje, nc, nl, bvb, bvi, bvL, hvL, i, j, vazios_set)
        for i in 1:nc,
            j in 1:nl
                if !([i, j] in vazios_set)]

#Função que cria uma laje untilizando um array de 4 pontos
laje_singular(pts, e_laje, nc, nl, bvb, bvi, bvL, hvL, i, j, vazios_set) =
    let 
        ([i, j - 1] in vazios_set ? offset_1 = 0 : (j==1 ? offset_1 = bvb : offset_1 = bvi/2))
        ([i, j + 1] in vazios_set ? offset_2 = 0 : (j==nl ? offset_2 = bvb : offset_2 = bvi/2))

        [thicken(
            surface_polygon(pts), -e_laje)]

        [(i==1 ? nothing : box(
            pts[1] + vyz(offset_1, -e_laje/2),
            pts[4] + vxyz(bvL, -offset_2, -hvL - e_laje/2))),
         (i==nc ? nothing : box(
            pts[2] + vyz(offset_1, -e_laje/2),
            pts[3] + vxyz(-bvL, -offset_2, -hvL - e_laje/2))),
         box(
            intermediate_loc(pts[1], pts[2]) + vyz(offset_1, -e_laje/2),
            intermediate_loc(pts[3], pts[4]) + vxyz(-bvL, -offset_2, -hvL - e_laje/2)),
         box(
            intermediate_loc(pts[1], pts[2]) + vyz(offset_1, -e_laje/2),
            intermediate_loc(pts[3], pts[4]) + vxyz(bvL, -offset_2, -hvL - e_laje/2))]
    end


#Funções de pilares da fachada

#Criação de pilares da fachada em todos os pisos
pilares_fachada_total(p, dc, nc, dl, nl, np, h, a, b, cpc, hvb, vazios_set) =
    [pilares_fachada_piso(p + vz(h * i - h), dc * nc, nc, dl * nl, nl, dc, dl, h - hvb, a, b, cpc, vazios_set)
        for i in 1:np]

#Criação de pilares da fachada em um piso
pilares_fachada_piso(p, c, n, l, m, dc, dl, h, a, b, cpc, vazios_set) =
    [pilares_for_linha(
        pts_grelha(p, c, n, l - b, m), a, b, h, vazios_set, 2, 1),
     pilares_for_linha(
        pts_grelha(p + vx(dc - a), c, n, l - b, m), a, b, h, vazios_set, 1, 2),
     pilares_for_coluna(
        pts_grelha(p, c - b, n, l, m), b, a, h, vazios_set, 2, 1),
     pilares_for_coluna(
        pts_grelha(p + vy(dl - a), c - b, n, l, m), b, a, h, vazios_set, 1, 2),
     pilares_for_cantos(
        pts_grelha(p, c - cpc, n, l - cpc, m), cpc, h, vazios_set)]

#Função que aplica a função pilar_singular a cada ponto do array        
pilares_for_linha(ptss, a, b, h, vazios_set, k1, k2) =
    [pilar_singular(ptss[i][j], h, a, b)
        for i in k1:(length(ptss)-k2),
            j in 1:(length(ptss[1])-1):length(ptss[1])
                if !([i, j] in vazios_set)
                    && !([i, j-1] in vazios_set)]

pilares_for_coluna(ptss, a, b, h, vazios_set, k1, k2) =
    [pilar_singular(ptss[i][j], h, a, b)
        for i in 1:(length(ptss)-1):length(ptss),
            j in k1:(length(ptss[1])-k2)
                if !([i, j] in vazios_set)
                    && !([i-1, j] in vazios_set)]

pilares_for_cantos(ptss, c, h, vazios_set) =
    [pilar_singular_canto(ptss[i][j], c, h)
        for i in 1:(length(ptss)-1):length(ptss),
            j in 1:(length(ptss[1])-1):length(ptss[1])
                if !([i, j] in vazios_set)
                    && !([i-1, j] in vazios_set)
                    && !([i, j-1] in vazios_set)
                    && !([i-1, j-1] in vazios_set)]

#Função que cria um pilar
pilar_singular(p1, h, a, b) =
    box(p1, p1 + vxyz(a, b, h))

pilar_singular_canto(p, c, h) = 
    box(p, p + vxyz(c, c, h))


#Funções de pilares interiores

#Criação de pilares interiores em todos os pisos
pilares_interior_total(p, dc, nc, dl, nl, np, h, hvi, api, vazios_set) =
    [pilares_interior_piso(p + vz(h * i - h), dc * nc, nc, dl * nl, nl, h - hvi, api, vazios_set)
        for i in 1:np]

pilares_interior_piso(p, c, n, l, m, h, api, vazios_set) =
    [pilares_interiores_for(
        pts_grelha(p, c, n, l, m), h, api, vazios_set)]

pilares_interiores_for(ptss, h, api, vazios_set) =
    [pilar_interior(ptss[i][j], api, h)
        for i in 3:2:(length(ptss)-1),
            j in 2:(length(ptss[1])-1)
                if !([i, j] in vazios_set)
                    && !([i-1, j] in vazios_set)
                    && !([i, j-1] in vazios_set)
                    && !([i-1, j-1] in vazios_set)]

pilar_interior(p, api, h) =
    box(p - vxy(api/2, api/2), p + vxyz(api/2, api/2, h))

    
#Funções de vigas de bordadura

#Criação de vigas de bordadura em todos os pisos
viga_bordadura_total(p, dc, nc, dl, nl, hvb, bvb, h, np, e, vazios_set) =
    [viga_bordadura_piso(p + vz(h * i), dc, nc, dl, nl, hvb, bvb, e, vazios_set) 
        for i in 1:np]

#Criação de vigas de bordadura em um piso
viga_bordadura_piso(p, dc, nc, dl, nl, hvb, bvb, e, vazios_set) =
    [viga_bordadura_for_linha(
        pts_grelha(p - vz(hvb + e), dc * (nc - 1), nc - 1, dl * nl - bvb, nl), hvb, dc, bvb, vazios_set),
     viga_bordadura_for_coluna(
        pts_grelha(p - vz(hvb + e), dc * nc - bvb, nc, dl * (nl - 1), nl -1), hvb, bvb, dl, bvb, vazios_set)
        ]

#Função que entrega pontos para criar uma viga de bordadura
viga_bordadura_for_linha(ptss, hvb, xvb, yvb, vazios_set) =
    [viga_bordadura_singular(ptss[i][j], hvb, xvb, yvb, 0, 0, vazios_set)
        for i in 1:length(ptss),
            j in 1:(length(ptss[1])-1):length(ptss[1])
                if !([i, j] in vazios_set)
                    && !([i, j - 1] in vazios_set)]

viga_bordadura_for_coluna(ptss, hvb, xvb, yvb, offset, vazios_set) = 
    [viga_bordadura_singular(ptss[i][j], hvb, xvb, yvb, 
        (j==1 ? offset : 0), (j==length(ptss[1]) ? offset : 0), vazios_set)
            for i in 1:(length(ptss) -1):length(ptss),
                j in 1:length(ptss[1])
                    if !([i, j] in vazios_set)
                        && !([i - 1, j] in vazios_set)]

#Função que cria uma viga de bordadura
viga_bordadura_singular(p, hvb, xvb, yvb, offset1, offset2, vazios_set) =
    [box(p + vy(offset1),
         p + vxyz(xvb, yvb - offset2, hvb))] 


#Funções de vigas interiores

#Criação de vigas interiores em todos os pisos
viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e, bpf, vazios_set) =
    [viga_interior_piso(p + vz(h * i), dc, nc, dl, nl, hvi, bvi, e, bpf, vazios_set)
        for i in 1:np]

#Criação de vigas interiores em um piso
viga_interior_piso(p, dc, nc, dl, nl, hvi, bvi, e, bpf, vazios_set) = 
    [viga_interior_for(
        pts_grelha(p + vyz( -bvi/2, -hvi - e), dc * (nc - 1), nc - 1, dl * nl, nl),
                   hvi, dc, bvi, bpf, vazios_set)]

#Função que entrega um array de arrays de pontos à função viga_interior_singular
viga_interior_for(ptss, hvi, xvi, yvi, offset, vazios_set) = 
    [viga_interior_singular(ptss[i][j], hvi, xvi, yvi,
        (i==1 ? offset : 0), (i==length(ptss) ? offset : 0))
            for i in 1:length(ptss),
                j in 2:(length(ptss[1])-1)
                    if !([i, j] in vazios_set)
                        && !([i, j - 1] in vazios_set)]

#Função que cria as vigas interiores
viga_interior_singular(p, hvi, xvi, yvi, offset1, offset2) =
    box(p + vx(offset1), p + vxyz(xvi - offset2, yvi, hvi))


#Funções de núcleos

#Função que entrega um array de arrays de pontos para criar os núcleos
nucleo_total(p, dc, nc, dl, nl, h, np, enb, nucleos_set) =
    nucleo_for(
        pts_grelha(p, dc * nc, nc, dl * nl, nl), dc, dl, h, np, enb, nucleos_set)

#Função que entrega um ponto à função nucleo_singular
nucleo_for(ptss, dc, dl, h, np, enb, nucleos_set) =
    [nucleo_singular(ptss[i][j], dc * kx, dl * ky, h, np, enb)
        for i in 1:length(ptss),
            j in 1:length(ptss[1]),
            kx in 0:length(ptss),
            ky in 0:length(ptss[1])
                if [i, j, kx, ky] in nucleos_set]

#Função que cria um núcleo
nucleo_singular(p, c, l, h, np, enb) =
    subtraction(
        box(p, p + vxyz(c, l, h * np)),
        box(p + vxy(enb, enb), p + vxyz(c - enb, l - enb, h * np - enb)))

#Função que cria um set com as posições e dimensões dos núcleos
nucleos_set(vazios_set) =
    let nucleos_set = Set{Tuple{Int,Int}}((n[1], n[2]) for n in vazios_set if n[1] > 0 && n[2] > 0)
        function count_right(i, j)
            k = 0
            while (i + k + 1, j) in nucleos_set
                k += 1
            end
            k
        end
        
        function count_top(i, j)
            k = 0
            while (i, j + k + 1) in nucleos_set
                k += 1
            end
            k
        end
        
        Set(
            [i, j, count_right(i, j) + 1, count_top(i, j) + 1]
            for (i, j) in nucleos_set
                if !((i - 1, j) in nucleos_set) && !((i, j - 1) in nucleos_set)
        )
    end

nucleos_set = [[n[1], n[2]] for n in vazios_set if n[1] > 0 && n[2] > 0]
#Funções de paineis de fachada

#Criação de paineis de fachada em todos os pisos
painel_fachada_total(p, dc, nc, dl, nl, np, h, vazios_set, e_fachada) =
    [painel_fachada_piso(p + vz(h * i - h), dc * nc, nc, dl * nl, nl, h, vazios_set, e_fachada)
        for i in 1:np]

#Criação de paineis de fachada em um piso
painel_fachada_piso(p, c, n, l, m, h, vazios_set, e_fachada) =
    [painel_fachada_for_linha_inferior(
        pts_grelha(p, c, n, l, m), h, vazios_set, e_fachada),
    painel_fachada_for_linha_superior(
        pts_grelha(p, c, n, l, m), h, vazios_set, e_fachada),
    painel_fachada_for_coluna_esq(
        pts_grelha(p, c, n, l, m), h, vazios_set, e_fachada),
    painel_fachada_for_coluna_dir(
        pts_grelha(p, c, n, l, m), h, vazios_set, e_fachada)]

#Funções que entregam os pontos para criar os paineis na direção x da fachada
painel_fachada_for_linha_inferior(ptss, h, vazios_set, e_fachada) =
    [painel_fachada_singular_linha(ptss[i][j], ptss[i + 1][j], h, e_fachada)
        for i in 1:(length(ptss) -1),
            j in 1:1
                if !([i, j] in vazios_set)
                    && !([i, j-1] in vazios_set)]

painel_fachada_for_linha_superior(ptss, h, vazios_set, e_fachada) =
    [painel_fachada_singular_linha(ptss[i][j], ptss[i + 1][j], h, -e_fachada)
        for i in 1:(length(ptss) -1),
            j in (length(ptss[1])):(length(ptss[1]))
                if !([i, j-1] in vazios_set)
                    && !([i, j] in vazios_set)]

#Função que cria um painel de fachada na direção x
painel_fachada_singular_linha(p1, p2, h, e_fachada) =
    subtraction(
        box(p1, p2 + vyz(-e_fachada, h)),
        box(p1 + vxz(0.5, 0.5), p2 + vxyz(-0.5, -e_fachada, h - 0.5)))

#Funções que entregam os pontos para criar os paineis na direção y da fachada
painel_fachada_for_coluna_esq(ptss, h, vazios_set, e_fachada) =
    [painel_fachada_singular_coluna(ptss[i][j], ptss[i][j + 1], h, e_fachada)
        for i in 1:1,
            j in 1:(length(ptss[1]) -1)
                if !([i, j] in vazios_set)
                    && !([i-1, j] in vazios_set)]

painel_fachada_for_coluna_dir(ptss, h, vazios_set, e_fachada) =
    [painel_fachada_singular_coluna(ptss[i][j], ptss[i][j + 1], h, -e_fachada)
        for i in (length(ptss)):length(ptss),
            j in 1:(length(ptss[1]) -1)
                if !([i-1, j] in vazios_set)
                    && !([i, j] in vazios_set)]

#Função que cria um painel de fachada na direção y
painel_fachada_singular_coluna(p1, p2, h, e_fachada) =
    subtraction(
        box(p1, p2 + vxz(-e_fachada, h)),
        box(p1 + vyz(0.5, 0.5), p2 + vxyz(-e_fachada, -0.5, h - 0.5)))

#Testes de funções
delete_all_shapes()

edificio_CREE(xyz(0, 0, 0), 4, 7, 6.0, 3.0, 3, 3.0,
    [[1, 1], [2, 3], [3, 1], [4, 1], [6, 1], [5, 4], [7, 2], [7, 4], [2, 4], [3, 2], [4, 2]])

edificio_CREE(xyz(28, 0, 0), 6, 8, 6.0, 3.0, 5, 3.0, [[3, 3], [3, 4], [4, 3], [4, 4], [5, 3], [5, 4], [6, 3], [6, 4]])

edificio_CREE(xyz(28, 0, 0), 3, 5, 6.0, 3.0, 5, 3.0, [[2, 2], [3, 2], [4, 2]])

edificio_CREE(xyz(50, 0, 0), 3, 5, 6.0, 3.0, 5, 3.0,
    [[1, 1], [1, 3], [5, 1], [5, 3], [3, 2]])

edificio_CREE(xyz(0, 40, 0), 3, 20, 6.0, 3.0, 3, 3.0,
    [[5, 2], [6, 2], [15, 2], [16, 2], [5, 4], [6, 4], [0,2], [21, 2], [10, 0]])

grelha = pts_grelha(xyz(0, 0, 0), 18.0, 3, 21.0, 7)
grelha_4pts(xyz(0, 0, 0), 18.0, 3, 21.0, 7)
vcat(grelha_4pts(xyz(0, 0, 0), 18.0, 3, 21.0, 7)...)

viga_interior_grelha(xyz(0, 0, 0), 18.0, 7, 21.0, 3, 3.0, 3.0, 3.0, 0.0)

grelha[2][1]

vazios_set = [[1, 1], [2, 3]]
vazios_set[1]

nucleos_set([[1, 1], [2, 3], [3, 1], [4, 1], [6, 1], [5, 4], [7, 2], [7, 4], [2, 4], [3, 2], [4, 2]])
