using Khepri
backend(autocad)

edificio_CREE(p, nc, nl, np, lg, cg, h, nucleos) =
    let
        # nc: número de linhas da Grelha CREE
        # nl: número de colunas da Grelha CREE
        # np: número de pisos da Grelha CREE
        # lg: largura da grelha CREE
        # cg: comprimento da grelha CREE
        # h: altura de cada piso

        ev = 0.3 # Espessura das vigas de apoio para a laje de betão CREE (pode ser ajustada conforme necessário)
        lv = 0.3 # Largura das vigas de apoio para a laje de betão CREE (pode ser ajustada conforme necessário)
        e = 0.1 # Espessura da laje de betão (pode ser ajustada conforme necessário)
        evb = 0.4 # Espessura da viga de bordadura (pode ser ajustada conforme necessário)
        lvb = 0.3 # Largura da viga de bordadura (pode ser ajustada conforme necessário)
        a = 0.2 # Largura dos pilares (pode ser ajustada conforme necessário)
        b = 0.3 # Comprimento dos pilares (pode ser ajustado conforme necessário)
        c = 0.3 # Largura dos pilares de canto (pode ser ajustada conforme necessário)
        hvc = 0.3 # Altura da viga central (pode ser ajustada conforme necessário)
        bvc = 0.3 # Base da viga central (pode ser ajustada conforme necessário)

        evba = evb - e # Espessura da viga de bordadura ajustada para a espessura da laje
        nucleos_vazios_set = Set{Tuple{Int,Int}}((n[1], n[2]) for n in nucleos if n[1] > 0 && n[2] > 0)

        Laje_total_CREE(p, nc, nl, np, lg, cg, h, evba, lvb, e, ev, lv, bvc, nucleos_vazios_set)
        pilares_CREE(p, nc, nl, np, lg, cg, h, evb, a, b, nucleos_vazios_set)
        pilares_canto_CREE(p, nc, nl, np, lg, cg, h, evb, c, "triple", nucleos_vazios_set)
        viga_central(p, nc, nl, np, lg, cg, h, lvb, hvc, bvc)
        nucleos_betao(p, lg, cg, h, np, nucleos_set(nucleos))
        pilares_internos(p, nc, nl, np, lg, cg, h, evb, a, b, nucleos_vazios_set)
    end

Laje_total_CREE(p, nc, nl, np, lg, cg, h, evba, lvb, e, ev, lv, bvc, nucleos_set) =
    let
        viga_bordadura(p + vz(h - evba - e), nc, nl, np, lg, cg, h, evba, lvb, nucleos_set)

        [laje_CREE(p + vxyz(i * lg - lg, j * cg - cg, k * h - e), lg, cg, e )
        for k in 1:(np)
            for j in 1:(nl)
                for i in 1:(nc)
                    if !( (i, j) in nucleos_set )]

        [vigas_laje_CREE(p + vxyz(i * lg - lg, j * cg - cg, k * h - e), lg, cg, ev, lv, bvc, lvb, i, j, nl, nc )
        for k in 1:(np)
            for j in 1:(nl)
                for i in 1:(nc)
                    if !( (i, j) in nucleos_set )]
    end

laje_CREE(p, lg, cg, e) =
    # Cria a laje de betão da peça CREE
    box(p, p + vxyz(lg, cg, e))

vigas_laje_CREE(p, lg, cg, ev, lv, bvc, lvb, i, j, nl, nc) =
    let
        if lg < cg # Se a largura da grelha for menor que o comprimento
            (j==1 ? offset_inferior = lvb : offset_inferior = bvc/2)
            (j==nl ? offset_superior = lvb : offset_superior = bvc/2)

            [box(p + vxy(lg/2, offset_inferior), p + vxyz(lg/2 - lv, cg - offset_superior, - ev)),
             box(p + vxy(lg/2, offset_inferior), p + vxyz(lg/2 + lv, cg - offset_superior, - ev)),
            (i == 1 ? nothing : box(p + vy(offset_inferior), p + vxyz(lv, cg - offset_superior, - ev))),
            (i == nc ? nothing : box(p + vxy(lg, offset_inferior), p + vxyz(lg - lv, cg - offset_superior, - ev)))]
        else
            (i==1 ? offset_esquerdo = lvb : offset_esquerdo = bvc/2)
            (i==nc ? offset_direito = lvb : offset_direito = bvc/2)

            [box(p + vxy(offset_esquerdo, cg/2), p + vxyz(lg - offset_direito, cg/2 - lv, - ev)),
             box(p + vxy(offset_esquerdo, cg/2), p + vxyz(lg - offset_direito, cg/2 + lv, - ev)),
            (j == 1 ? nothing : box(p + vx(offset_esquerdo), p + vxyz(lg - offset_direito, lv, - ev))),
            (j == nl ? nothing : box(p + vxy(offset_esquerdo, cg), p + vxyz(lg - offset_direito, cg - lv, - ev)))]
        end
    end

viga_bordadura(p, nc, nl, np, lg, cg, h, evba, lvb, nucleos_set) =
    let
        a = lvb
        # Cria a viga inferior
        [box(p + vxz(i * lg, k * h),
             p + vxyz(i * lg + lg, lvb, k * h + evba))
             for k in 0:(np-1)
                for i in 0:(nc-1)
                    if !( (i + 1, 1) in nucleos_set )]

        # Cria a viga superior
        [box(p + vxyz(i * lg, nl * cg - lvb, k * h),
             p + vxyz(i * lg + lg, nl * cg, k * h + evba))
             for k in 0:(np-1)
                for i in 0:(nc-1)
                    if !( (i + 1, nl) in nucleos_set )]

        # Cria a viga lateral esquerda
        [box(p + vyz(j * cg + (j==0 ? lvb : 0), k * h),
             p + vxyz(lvb, j * cg + cg - (j==nl-1 ? lvb : 0), k * h + evba))
             for k in 0:(np-1)
                for j in 0:(nl-1)
                    if !( (1, j + 1) in nucleos_set )]

        # Cria a viga lateral direita
        [box(p + vxyz(lg * nc - lvb, j * cg + (j==0 ? lvb : 0), k * h),
             p + vxyz(lg * nc, j * cg + cg - (j==nl-1 ? lvb : 0), k * h + evba))
             for k in 0:(np-1)
                for j in 0:(nl-1)
                    if !( (nc, j + 1) in nucleos_set )]
    end

pilares_CREE(p, nc, nl, np, lg, cg, h, evb, a, b, nucleos_set) =
    let 
        # Cria os pilares horizontais
            # Cria o pilar esquerdo da dupla de pilares horizontais
        [box(p + vxyz(i * lg - a, j * (nl * cg - b), k * h),
             p + vxyz(i * lg, j * (nl * cg - b) + b, k * h + h - evb))
             for k in 0:(np-1)
                for i in 1:(nc-1)
                    for j in 0:1
                        if !( (i, j==0 ? 1 : nl) in nucleos_set )]

            # Cria o pilar direito da dupla de pilares horizontais
        [box(p + vxyz(i * lg, j * (nl * cg - b), k * h),
             p + vxyz(i * lg + a, j * (nl * cg - b) + b, k * h + h - evb))
             for k in 0:(np-1)
                for i in 1:(nc-1)
                    for j in 0:1
                        if !( (i + 1, j==0 ? 1 : nl) in nucleos_set )]

        # Cria os pilares laterais
            # Cria o pilar inferior da dupla de pilares laterais 
        [box(p + vxyz(i * (nc * lg - b), j * cg - a, k * h),
             p + vxyz(i * (nc * lg - b) + b, j * cg, k * h + h - evb))
             for k in 0:(np-1)
                for j in 1:(nl-1)
                    for i in 0:1
                        if !( (i==0 ? 1 : nc, j) in nucleos_set )]

            # Cria o pilar superior da dupla de pilares laterais
        [box(p + vxyz(i * (nc * lg - b), j * cg, k * h),
             p + vxyz(i * (nc * lg - b) + b, j * cg + a, k * h + h - evb))
             for k in 0:(np-1)
                for j in 1:(nl-1)
                    for i in 0:1
                        if !( (i==0 ? 1 : nc, j + 1) in nucleos_set )]
    end

pilares_canto_CREE(p1, nc, nl, np, lg, cg, h, evb, c, tipo, nucleos_set) =
    if tipo == "triple"
        let
            # p1 = Ponto de referência para os pilares do canto inferior esquerdo
            p2 = p1 + vx(lg * nc - 2c)                  # Ponto de referência para os pilares do canto inferior direito
            p3 = p1 + vy(cg * nl - 2c)                  # Ponto de referência para os pilares do canto superior esquerdo
            p4 = p1 + vxy(lg * nc - 2c, cg * nl - 2c)   # Ponto de referência para os pilares do canto superior direito

            # Cria o pilare do canto inferior esquerdo
            [pilar_glulam_canto(
                p1 + vz(k * h), pts_pilar(p1 + vz(k * h), c)[2], pts_pilar(p1 + vz(k * h), c)[3], h, evb, c)
                for k in 0:(np-1)
                    if !((1, 1) in nucleos_set)]

            # Cria o pilare do canto inferior direito
            [pilar_glulam_canto(
                p2 + vz(k * h), pts_pilar(p2 + vz(k * h), c)[2], pts_pilar(p2 + vz(k * h), c)[4], h, evb, c)
                for k in 0:(np-1)
                    if !((nc, 1) in nucleos_set)]

            # Cria o pilare do canto superior esquerdo
            [pilar_glulam_canto(
                p3 + vz(k * h), pts_pilar(p3 + vz(k * h), c)[3], pts_pilar(p3 + vz(k * h), c)[4], h, evb, c)
                for k in 0:(np-1)
                    if !((1, nl) in nucleos_set)]

            # Cria o pilare do canto superior direito
            [pilar_glulam_canto(
                pts_pilar(p4 + vz(k * h), c)[4], pts_pilar(p4 + vz(k * h), c)[2], pts_pilar(p4 + vz(k * h), c)[3], h, evb, c)
                for k in 0:(np-1)
                    if !((nc, nl) in nucleos_set)]
        end
    else
        [box(p1 + vxyz(i * (nc * lg - c), j * (nl * cg - c), k * h),
             p1 + vxyz(i * (nc * lg - c) + c, j * (nl * cg - c) + c, k * h + h - evb))
             for k in 0:(np-1)
                for i in 0:1
                    for j in 0:1
                        if !( ((i==0 ? 1 : nc), (j==0 ? 1 : nl)) in nucleos_set )]
    end

pts_pilar(p, c) =
    let
        # p: ponto de referência para o pilar
        # c: largura dos pilares de canto

        # Calcula os pontos para os pilares de canto
        [p, p + vx(c), p + vy(c), p + vxy(c, c)]
    end 


pilar_glulam_canto(p1, p2, p3, h, e, c) =
    let
        # h: altura de cada piso
        # e: espessura das lajes (para posicionar os pilares corretamente)
        # c: largura dos pilares de canto

        # Cria os pilares de canto da peça CREE
        [box(p1, p1 + vxyz(c, c, h - e)),
        box(p2, p2 + vxyz(c, c, h - e)),
        box(p3, p3 + vxyz(c, c, h - e))]
    end

viga_central(p, nc, nl, np, lg, cg, h, lvb, hvc, bvc) =
    let 

        if lg < cg # Se a largura da grelha for menor que o comprimento, a viga central será orientada ao longo do comprimento
            [box(p + vxyz(lvb, j * cg - bvc/2, k * h - 0.1),
                 p + vxyz(lg * nc - lvb, j *cg + bvc/2, k * h -0.1 - hvc))
                 for k in 1:(np)
                    for j in 1:(nl-1)]
        else
            [box(p + vxyz(i * lg - bvc/2, lvb, k * h - 0.1),
                 p + vxyz(i * lg + bvc/2, cg * nl - lvb, k * h - 0.1 - hvc))
                 for k in 1:(np)
                    for i in 1:(nc-1)]
        end
    end

nucleos_set(nucleos) =
    let nucleos_set = Set{Tuple{Int,Int}}((n[1], n[2]) for n in nucleos if n[1] > 0 && n[2] > 0)
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
            (i - 1, j - 1, count_right(i, j), count_top(i, j))
            for (i, j) in nucleos_set
                if !((i - 1, j) in nucleos_set) && !((i, j - 1) in nucleos_set)
        )
    end

nucleos_betao(p, lg, cg, h, np, nucleos_adjacentes_set) =
    let
        en = 0.3 # Espessura dos núcleos de betão (pode ser ajustada conforme necessário)

        # Cria os núcleos de betão tendo em conta os núcleos adjacentes para evitar sobreposição
        [subtraction(
        box(p + vxyz(i * lg, j * cg, 0),
            p + vxyz(i * lg + (right + 1) * lg, j * cg + (top + 1) * cg, h * np)),
        box(p + vxyz(i * lg + en, j * cg + en, 0),
            p + vxyz(i * lg + (right + 1) * lg - en, j * cg + (top + 1) * cg - en, h * np)))
            for (i, j, right, top) in nucleos_adjacentes_set]
    end

pilares_internos(p, nc, nl, np, lg, cg, h, evb, a, b, nucleos_vazios_set) =
    let
         # Ajusta a largura e comprimento dos pilares internos com base na orientação da grelha
        
        # Cria os pilares internos da peça CREE
        [box(p + vxyz(i * lg - a/2, j * cg - b/2, k * h),
             p + vxyz(i * lg + a/2, j * cg + b/2, k * h + h - evb))
             for k in 0:(np-1)
                for j in 1:(nl-1)
                    for i in 1:(nc-1)
                        if !( (i + 1, j + 1) in nucleos_vazios_set )
                            && !( (i, j) in nucleos_vazios_set )
                            && !( (i + 1, j) in nucleos_vazios_set )
                            && !( (i, j + 1) in nucleos_vazios_set )]
    end

# Teste da função
delete_all_shapes()

edificio_CREE(xyz(0, 0, 0), 5, 3, 5, 3.0, 6.0, 3.0, [[1, 3], [5, 1], [5, 3], [4, 1]])


edificio_CREE(xyz(30, 0, 0), 2, 10, 3, 6.0, 3.0, 3.0,[[1, 3], [2, 10]])
edificio_CREE(xyz(50, 0, 0), 5, 2, 3, 3.0, 6.0, 3.0,[[0, 0]])

nucleos_set = Set{Tuple{Int,Int}}((n[1], n[2]) for n in [[1, 3], [5, 1], [5, 3], [4, 1]])