using Khepri
backend(autocad)

edificio_CREE(p, nl, nc, np, lg, cg, h) =
    let
        # nl: número de linhas da Grelha CREE
        # nc: número de colunas da Grelha CREE
        # np: número de pisos da Grelha CREE
        # lg: largura da grelha CREE
        # cg: comprimento da grelha CREE
        # h: altura de cada piso

        ev = 0.4 # Espessura da viga de bordadura (pode ser ajustada conforme necessário)
        lvb = 0.3 # Largura da viga de bordadura (pode ser ajustada conforme necessário)
        a = 0.3 # Largura dos pilares (pode ser ajustada conforme necessário)
        b = 0.3 # Comprimento dos pilares (pode ser ajustado conforme necessário)
        c = 0.3 # Largura dos pilares de canto (pode ser ajustada conforme necessário)
        e = 0.1 # Espessura da laje de betão (pode ser ajustada conforme necessário)
        

        Laje_total_CREE(p, nl, nc, np, lg, cg, h, ev, lvb, e)
        pilares_CREE(p, nl, nc, np, lg, cg, h, ev, a, b)
        pilares_canto_CREE(p, nl, nc, np, lg, cg, h, ev, c, "single")
        viga_central(p, nl, nc, np, lg, cg, h, lvb)
    end

Laje_total_CREE(p, nl, nc, np, lg, cg, h, ev, lvb, e) =
    let
        evb = ev - e # Espessura da viga de bordadura ajustada para a espessura da laje
        
        [viga_bordadura(p + vz(i * h - ev), nl, nc, lg, cg, lvb, evb) for i in 1:(np)]
        [laje_CREE(p + vxyz(k * lg, j * cg, i * h - e), lg, cg, e) for i in 1:(np) for j in 0:(nc-1) for k in 0:(nl-1) ]
    end

laje_CREE(p, lg, cg, e) =
    # Cria a laje de betão da peça CREE
    box(p, xyz(p.x + lg, p.y + cg, p.z + e))

viga_bordadura(p, nl, nc, lg, cg, lvb, evb) =
    # Cria a viga inferior
    [box(p, xyz(p.x + lg * nl, p.y + lvb, p.z + evb)),
        # Cria a viga lateral esquerda
    box(xyz(p.x, p.y + lvb, p.z), xyz(p.x + lvb, p.y + cg * nc, p.z + evb)),
        # Cria a viga lateral direita
    box(xyz(p.x + lg * nl - lvb, p.y + lvb, p.z), xyz(p.x + lg * nl, p.y + cg * nc, p.z + evb)),
    # Cria a viga superior
    box(xyz(p.x + lvb, p.y + cg * nc - lvb, p.z), xyz(p.x + lg * nl - lvb, p.y + cg * nc, p.z + evb))]

pilares_CREE(p, nl, nc, np, lg, cg, h, e, a, b) =
    let 
        # Cria os pilares horizontais
        [pilar_glulam(p + vxyz(i * lg, j * (nc * cg - b), k * h), h, e, a, b, a, b) for k in 0:(np-1) for i in 1:(nl-1) for j in 0:1]
        # Cria os pilares laterais
        [pilar_glulam(p + vxyz(i * (nl * lg - b), j * cg, k * h), h, e, b, a, -b, -a) for k in 0:(np-1) for j in 1:(nc-1) for i in 0:1]
    end

pilares_canto_CREE(p1, nl, nc, np, lg, cg, h, e, c, tipo) =
    if tipo == "triple"
        let                                
                                                        # p1 = Ponto de referência para os pilares do canto inferior esquerdo
            p2 = p1 + vx(lg * nl - 2c)                  # Ponto de referência para os pilares do canto inferior direito
            p3 = p1 + vy(cg * nc - 2c)                  # Ponto de referência para os pilares do canto superior esquerdo
            p4 = p1 + vxy(lg * nl - 2c, cg * nc - 2c)   # Ponto de referência para os pilares do canto superior direito

            # Cria os pilares de canto
            [pilar_glulam_canto(p1 + vz(k * h), pts_pilar(p1 + vz(k * h), c)[2], pts_pilar(p1 + vz(k * h), c)[3], h, e, c) for k in 0:(np-1)]
            [pilar_glulam_canto(p2 + vz(k * h), pts_pilar(p2 + vz(k * h), c)[2], pts_pilar(p2 + vz(k * h), c)[4], h, e, c) for k in 0:(np-1)]
            [pilar_glulam_canto(p3 + vz(k * h), pts_pilar(p3 + vz(k * h), c)[3], pts_pilar(p3 + vz(k * h), c)[4], h, e, c) for k in 0:(np-1)]
            [pilar_glulam_canto(pts_pilar(p4 + vz(k * h), c)[4], pts_pilar(p4 + vz(k * h), c)[2], pts_pilar(p4 + vz(k * h), c)[3], h, e, c) for k in 0:(np-1)]
        end
    else
        [box(p1 + vxyz(i * (nl * lg - c), j * (nc * cg - c), k * h), p1 + vxyz(i * (nl * lg - c) + c, j * (nc * cg - c) + c, k * h + h - e)) for k in 0:(np-1) for i in 0:1 for j in 0:1]
    end

pts_pilar(p, c) =
    let
        # p: ponto de referência para o pilar
        # c: largura dos pilares de canto

        # Calcula os pontos para os pilares de canto
        [p, p + vx(c), p + vy(c), p + vxy(c, c)]
    end 

pilar_glulam(p, h, e, a, b, c, d) =
    let
        # p: de referência para os pilares
        # h: altura de cada piso
        # e: espessura das lajes (para posicionar os pilares corretamente)
        # a: largura do pilar 1 em relação ao ponto de referência
        # b: comprimento do pilar 1 em relação ao ponto de referência
        # c: largura do pilar 2 em relação ao ponto de referência
        # d: comprimento do pilar 2 em relação ao ponto de referência

        # Cria os pilares da peça CREE
        [box(p, xyz(p.x + a, p.y + b, p.z + h - e)),
        box(p, xyz(p.x - c, p.y + d, p.z + h - e))]
    end

pilar_glulam_canto(p1, p2, p3, h, e, c) =
    let
        # p: de referência para o pilar
        # h: altura de cada piso
        # e: espessura das lajes (para posicionar os pilares corretamente)
        # c: largura dos pilares de canto

        # Cria os pilares de canto da peça CREE
        [box(p1, p1 + vxyz(c, c, h - e)),
        box(p2, p2 + vxyz(c, c, h - e)),
        box(p3, p3 + vxyz(c, c, h - e))]
    end

viga_central(p, nl, nc, np, lg, cg, h, lvb) =
    let 
        hvc = 0.3 # Altura da viga central (pode ser ajustada conforme necessário)
        bvc = 0.3 # Base da viga central (pode ser ajustada conforme necessário)
        if lg < cg
            [box(p + vxyz(lvb, j * cg - bvc/2, k * h - 0.1), p + vxyz(lg * nl - lvb, j *cg + bvc/2, k * h -0.1 - hvc)) for k in 1:(np) for j in 1:(nc-1)]
        else
            [box(p + vxyz(i * lg - bvc/2, lvb, k * h - 0.1), p + vxyz(i * lg + bvc/2, cg * nc - lvb, k * h - 0.1 - hvc)) for k in 1:(np) for i in 1:(nl-1)]
        end
    end

    # Teste da função
delete_all_shapes()

edificio_CREE(xyz(0, 0, 0), 5, 3, 5, 3.0, 6.0, 3.0)
edificio_CREE(xyz(30, 0, 0), 2, 10, 3, 6.0, 3.0, 3.0)