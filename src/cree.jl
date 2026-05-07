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

        laje_total(p, dc, nc, dl, nl, np, h, e_laje, vazios_set)
        pilares_fachada_total(p, dc, nc, dl, nl, np, h, apf, bpf, cpc, hvb + e_laje, vazios_set)
        viga_bordadura_total(p, dc, nc, dl, nl, hvb, bvb, h, np, e_laje, vazios_set)
        viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e_laje, bpf)
    end


#Funções de grelhas de pontos

pts_grelha(p, l_tot, n, c_tot, m) =
    map_division((i,j) -> p + vxy(i, j), 0, l_tot, n, 0, c_tot, m)

grelha_CREE(p, l_tot, n, c_tot, m) = 
    iterate_quads((p1, p2, p3, p4) -> [p1, p2, p3, p4], pts_grelha(p, l_tot, n, c_tot, m))


#Funções de lajes

#Criação de lajes em todos os pisos
laje_total(p, dc, nc, dl, nl, np, h, e_laje, vazios_set) =
    [laje_piso(p + vz(h * i - e_laje/2), dc, nc, dl, nl, e_laje, vazios_set)
        for i in 1:np]

#Função que entrega arrays de 4 pontos à função laje_map
laje_piso(p, dc, nc, dl, nl, e_laje, vazios_set) =
    [laje_for(
            grelha_CREE(p, dc * nc, nc, dl * nl, nl), e_laje, nc, nl, vazios_set)]

#Função que aplica a função laje_singular a cada array de 4 pontos          
laje_for(ptss, e_laje, nc, nl, vazios_set) =
    [laje_singular([vcat(ptss[i][j])...], e_laje, nc, nl, vazios_set)
        for i in 1:nc, j in 1:nl
            if !([i, j] in vazios_set)]

#Função que cria uma laje untilizando um array de 4 pontos
laje_singular(pts, e_laje, nc, nl, vazios_set) =
    [thicken(
        surface_polygon(pts), e_laje)]


#Funções de pilares da fachada

#Criação de pilares da fachada em todos os pisos
pilares_fachada_total(p, dc, nc, dl, nl, np, h, a, b, cpc, hvb, vazios_set) =
    [pilares_fachada_piso(p + vz(h * i), dc * nc, nc, dl * nl, nl, dc, dl, h - hvb, a, b, cpc, vazios_set)
        for i in 0:np-1]

#Criação de pilares da fachada em um piso
pilares_fachada_piso(p, c, n, l, m, dc, dl, h, a, b, cpc, vazios_set) =
    [pilares_for_linha(
        pts_grelha(p, c, n, l - b, m), a, b, h, vazios_set, m, 2, 1),
     pilares_for_linha(
        pts_grelha(p + vx(dc - a), c, n, l - b, m), a, b, h, vazios_set, m, 1, 2),
     pilares_for_coluna(
        pts_grelha(p, c - b, n, l, m), b, a, h, vazios_set, n, 2, 1),
     pilares_for_coluna(
        pts_grelha(p + vy(dl - a), c - b, n, l, m), b, a, h, vazios_set, n, 1, 2),
     pilares_for_cantos(
        pts_grelha(p, c - cpc, n, l - cpc, m), cpc, h, vazios_set, n, m)]

#Função que aplica a função pilar_singular a cada ponto do array        
pilares_for_linha(ptss, a, b, h, vazios_set, m, k1, k2) =
    [pilar_singular(ptss[i][j], ptss[i+1][j], h, a, b, -a, b)
        for i in k1:(length(ptss)-k2), j in 1:m:length(ptss[1])
            if !([i, j] in vazios_set) && !([i, j-1] in vazios_set)]

pilares_for_coluna(ptss, a, b, h, vazios_set, n, k1, k2) =
    [pilar_singular(ptss[i][j], ptss[i][j+1], h, a, b, a, -b)
        for i in 1:n:length(ptss), j in k1:(length(ptss[1])-k2)
            if !([i, j] in vazios_set) && !([i-1, j] in vazios_set)]

pilares_for_cantos(ptss, c, h, vazios_set, n, m) =
    [pilar_singular_canto(ptss[i][j], c, h)
        for i in 1:n:length(ptss), j in 1:m:length(ptss[1])
            if !([i, j] in vazios_set)
                && !([i-1, j] in vazios_set)
                && !([i, j-1] in vazios_set)
                && !([i-1, j-1] in vazios_set)]

#Função que cria um pilar
pilar_singular(p1, p2, h, a, b, c, d) =
    box(p1, p1 + vxyz(a, b, h))

pilar_singular_canto(p, c, h) = 
    box(p, p + vxyz(c, c, h))


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
        for i in 1:length(ptss), j in 1:(length(ptss[1])-1):length(ptss[1])
            if !([i, j] in vazios_set)
                && !([i, j - 1] in vazios_set)]

viga_bordadura_for_coluna(ptss, hvb, xvb, yvb, offset, vazios_set) = 
    [viga_bordadura_singular(ptss[i][j], hvb, xvb, yvb, 
        (j==1 ? offset : 0), (j==length(ptss[1]) ? offset : 0), vazios_set)
            for i in 1:(length(ptss)-1):length(ptss), j in 1:length(ptss[1])
                if !([i, j] in vazios_set)
                    && !([i - 1, j] in vazios_set)]

#Função que cria uma viga de bordadura
viga_bordadura_singular(p, hvb, xvb, yvb, offset1, offset2, vazios_set) =
    [box(p + vy(offset1),
         p + vxyz(xvb, yvb - offset2, hvb))] 


#Funções de vigas interiores

#Criação de vigas interiores em todos os pisos
viga_interior_total(p, dc, nc, dl, nl, h, np, hvi, bvi, e, bpf) =
    [viga_interior_piso(p + vz(h * i), dc, nc, dl, nl, hvi, bvi, e, bpf)
        for i in 1:np]

#Criação de vigas interiores em um piso
viga_interior_piso(p, dc, nc, dl, nl, hvi, bvi, e, bpf) = 
    [viga_interior_grelha(p + vyz( dl - bvi/2, -hvi - e), dc * (nc - 1), nc - 1, dl * (nl - 2), nl - 2, hvi, dc, bvi, bpf)]

#Função que entrega um array de arrays de pontos à função viga_interior_singular
viga_interior_grelha(p, l_tot, n, c_tot, m, hvi, xvi, yvi, offset) = 
    viga_interior_singular(
        pts_grelha(p, l_tot, n, c_tot, m), hvi, xvi, yvi, offset)

#Função que cria as vigas interiores
viga_interior_singular(ptss, hvi, xvi, yvi, offset) =
    [box(ptss[i][j] + vx((i==1 ? offset : 0)), ptss[i][j] + vxyz(xvi - (i==length(ptss) ? offset : 0), yvi, hvi)) 
        for i in 1:length(ptss)
            for j in 1:length(ptss[i])]


#Testes de funções
delete_all_shapes()

edificio_CREE(xyz(0, 0, 0), 4, 7, 6.0, 3.0, 3, 3.0,
    [[1, 1], [1, 3], [2, 3], [3, 1], [4, 1], [6, 1], [5, 4], [7, 2], [7, 4], [2, 2], [3, 2], [4, 2]])

edificio_CREE(xyz(28, 0, 0), 3, 5, 6.0, 3.0, 5, 3.0, [[2, 2], [3, 2], [4, 2]])

edificio_CREE(xyz(50, 0, 0), 3, 5, 6.0, 3.0, 5, 3.0,
    [[1, 1], [1, 3], [5, 1], [5, 3], [3, 2]])

grelha = pts_grelha(xyz(0, 0, 0), 18.0, 3, 21.0, 7)
grelha_CREE(xyz(0, 0, 0), 18.0, 3, 21.0, 7)
vcat(grelha_CREE(xyz(0, 0, 0), 18.0, 3, 21.0, 7)...)

viga_interior_grelha(xyz(0, 0, 0), 18.0, 7, 21.0, 3, 3.0, 3.0, 3.0, 0.0)

grelha[2][1]

vazios_set = [[1, 1], [2, 3]]
vazios_set[1]
