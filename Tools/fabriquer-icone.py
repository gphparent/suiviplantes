"""Icône : une feuille sous un ciel de gelée.

L'application ne fait qu'une chose, au fond : dire qu'une nuit sera trop froide
pour cette plante-là. L'icône dit la même chose sans un mot.

Le ciel est dégagé et la lune haute — ce sont précisément les conditions du
refroidissement par rayonnement, celui que le moteur corrige et que les
prévisions sous-estiment. Le givre ne tombe pas du ciel : il se forme par le
bas, au ras du sol, comme dans la réalité, et c'est pour cela qu'il gagne la
feuille par la pointe inférieure et non par le haut.

La feuille est tracée comme une *vesica* — l'intersection de deux disques de
même rayon — qui est la façon la plus économique d'obtenir une amande
parfaitement symétrique sans bibliothèque de dessin. Le reste est une affaire
de distances : chaque point demande son appartenance à chaque forme, et les
couleurs se superposent dans l'ordre. Quatre échantillons par pixel suffisent à
adoucir les bords.
"""
import math
import struct
import zlib

SIZE = 1024
SAMPLES = 2                     # 2×2 échantillons par pixel

# --- Ciel ------------------------------------------------------------------
# Un bleu qui se refroidit vers le bas : c'est au ras du sol qu'il gèle.
SKY_TOP = (14, 28, 52)
SKY_BOTTOM = (26, 58, 74)

# --- Lune ------------------------------------------------------------------
MOON_CX, MOON_CY, MOON_R = 762.0, 252.0, 96.0
MOON_MASK_DX, MOON_MASK_DY, MOON_MASK_R = -54.0, -40.0, 92.0
SILVER = (232, 238, 250)
SILVER_DIM = (176, 188, 214)

# --- Feuille ---------------------------------------------------------------
LEAF_CX, LEAF_CY = 476.0, 566.0
LEAF_ANGLE = math.radians(38.0)    # pointe vers le haut à droite
LEAF_HALF_LEN = 300.0
LEAF_HALF_WID = 148.0
GREEN = (86, 152, 96)
GREEN_LIGHT = (132, 196, 124)
GREEN_DARK = (44, 96, 62)
RIB = (52, 108, 70)

# --- Givre -----------------------------------------------------------------
FROST = (214, 238, 246)
FROST_DIM = (168, 206, 224)
# Hauteur, en pixels depuis le bas, jusqu'ou le givre gagne la feuille.
FROST_FROM = 470.0

# Le rayon de la vesica, deduit de la demi-longueur et de la demi-largeur.
LEAF_R = (LEAF_HALF_LEN ** 2 + LEAF_HALF_WID ** 2) / (2 * LEAF_HALF_WID)
LEAF_OFF = LEAF_R - LEAF_HALF_WID


def melange(bas, haut, alpha):
    """Superpose `haut` sur `bas` avec l'opacite donnee."""
    if alpha <= 0:
        return bas
    if alpha >= 1:
        return haut
    return tuple(bas[i] + (haut[i] - bas[i]) * alpha for i in range(3))


def couverture(distance, bord=1.5):
    """Passe d'une distance signee a une opacite, pour adoucir les bords."""
    return min(max(0.5 - distance / bord, 0.0), 1.0)


def segment(px, py, ax, ay, bx, by):
    """Distance d'un point au segment [a, b]."""
    vx, vy = bx - ax, by - ay
    wx, wy = px - ax, py - ay
    long2 = vx * vx + vy * vy
    t = 0.0 if long2 == 0 else min(max((wx * vx + wy * vy) / long2, 0.0), 1.0)
    return math.hypot(wx - t * vx, wy - t * vy)


def echantillon(x, y):
    # Ciel
    t = y / SIZE
    couleur = tuple(SKY_TOP[i] + (SKY_BOTTOM[i] - SKY_TOP[i]) * t for i in range(3))

    # Quelques etoiles, discretes : le ciel degage est le sujet, pas le decor.
    for sx, sy, sr in ((196, 188, 5.0), (322, 316, 3.4), (868, 470, 4.2),
                       (150, 402, 3.0), (612, 152, 3.6), (912, 152, 3.0)):
        d = math.hypot(x - sx, y - sy) - sr
        couleur = melange(couleur, SILVER, couverture(d, 2.2) * 0.85)

    # Lune : un disque moins un disque decale.
    d_lune = math.hypot(x - MOON_CX, y - MOON_CY) - MOON_R
    d_masque = math.hypot(x - (MOON_CX + MOON_MASK_DX),
                          y - (MOON_CY + MOON_MASK_DY)) - MOON_MASK_R
    croissant = couverture(d_lune) * (1.0 - couverture(d_masque))
    if croissant > 0:
        # Le limbe s'assombrit vers l'interieur du croissant.
        teinte = melange(SILVER_DIM, SILVER, min(max(-d_masque / 46.0, 0.0), 1.0))
        couleur = melange(couleur, teinte, croissant)

    # Feuille : repere local, longueur sur u, largeur sur v.
    dx, dy = x - LEAF_CX, y - LEAF_CY
    cos_a, sin_a = math.cos(LEAF_ANGLE), math.sin(LEAF_ANGLE)
    u = dx * cos_a - dy * sin_a
    v = dx * sin_a + dy * cos_a

    d_haut = math.hypot(u, v + LEAF_OFF) - LEAF_R
    d_bas = math.hypot(u, v - LEAF_OFF) - LEAF_R
    d_feuille = max(d_haut, d_bas)
    dans = couverture(d_feuille)

    # Petiole : trace avant la feuille, et seulement au-dela de sa base, pour
    # qu'il s'y attache au lieu de la traverser.
    d_tige = segment(u, v, -LEAF_HALF_LEN - 132.0, 0.0, -LEAF_HALF_LEN + 18.0, 0.0)
    couleur = melange(couleur, GREEN_DARK, couverture(d_tige - 9.0, 2.0))

    if dans > 0:
        # Un degrade le long de la nervure donne du volume sans ombre portee.
        k = min(max((u / LEAF_HALF_LEN + 1.0) / 2.0, 0.0), 1.0)
        vert = melange(GREEN_DARK, GREEN_LIGHT, k)
        vert = melange(vert, GREEN, 0.35)

        # Nervure centrale, jusqu'a la pointe.
        vert = melange(vert, RIB, couverture(abs(v) - 5.0, 2.0) * 0.7)

        # Nervures secondaires : depuis la nervure centrale, obliquement vers la
        # pointe, de part et d'autre.
        for depart in (-200.0, -122.0, -44.0, 34.0, 112.0):
            for sens in (1.0, -1.0):
                bout_u = depart + 104.0
                bout_v = sens * 96.0
                d = segment(u, v, depart, 0.0, bout_u, bout_v)
                vert = melange(vert, RIB, couverture(d - 2.6, 1.8) * 0.4)

        # Le givre monte du sol : il se mesure en hauteur reelle, pas le long de
        # la feuille. C'est bien par le bas que l'air froid s'accumule.
        if y > FROST_FROM:
            prise = min(max((y - FROST_FROM) / 240.0, 0.0), 1.0)
            vert = melange(vert, FROST, prise * 0.9)

        couleur = melange(couleur, vert, dans)

        # Liseré clair sur le bord, pour detacher la feuille du ciel.
        liseré = couverture(d_feuille + 4.0) - couverture(d_feuille)
        couleur = melange(couleur, GREEN_LIGHT, max(liseré, 0.0) * 0.45)

    # Cristaux de givre au sol, sous la feuille.
    for cx, cy, cr in ((214, 858, 46.0), (500, 924, 34.0), (806, 830, 40.0)):
        for k in range(6):
            a = math.pi * k / 3.0
            bx, by = math.cos(a), math.sin(a)
            proj = (x - cx) * bx + (y - cy) * by
            perp = -(x - cx) * by + (y - cy) * bx
            if -cr <= proj <= cr:
                couleur = melange(couleur, FROST,
                                  couverture(abs(perp) - 3.2, 1.8) * 0.9)
        d_coeur = math.hypot(x - cx, y - cy) - 7.0
        couleur = melange(couleur, FROST_DIM, couverture(d_coeur, 2.0))

    return couleur


def fabriquer():
    lignes = []
    inv = 1.0 / (SAMPLES * SAMPLES)
    for py in range(SIZE):
        ligne = bytearray()
        for px in range(SIZE):
            r = g = b = 0.0
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    x = px + (sx + 0.5) / SAMPLES
                    y = py + (sy + 0.5) / SAMPLES
                    c = echantillon(x, y)
                    r += c[0]; g += c[1]; b += c[2]
            ligne += bytes((int(r * inv + 0.5), int(g * inv + 0.5), int(b * inv + 0.5)))
        lignes.append(ligne)
    return lignes


def ecrire_png(chemin, lignes):
    brut = b''.join(b'\x00' + bytes(l) for l in lignes)

    def bloc(nom, donnees):
        c = nom + donnees
        return struct.pack('>I', len(donnees)) + c + struct.pack('>I', zlib.crc32(c))

    entete = struct.pack('>IIBBBBB', SIZE, SIZE, 8, 2, 0, 0, 0)
    png = (b'\x89PNG\r\n\x1a\n'
           + bloc(b'IHDR', entete)
           + bloc(b'IDAT', zlib.compress(brut, 9))
           + bloc(b'IEND', b''))
    with open(chemin, 'wb') as f:
        f.write(png)


if __name__ == '__main__':
    import sys
    sortie = sys.argv[1] if len(sys.argv) > 1 else 'icon-1024.png'
    ecrire_png(sortie, fabriquer())
    print('ecrit :', sortie)
