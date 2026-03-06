/* color — imprime el color hex del pixel al hacer click (cursor en cruz)
 * Sin dependencias externas; protocolo X11 raw sobre socket Unix.
 * Compilar: gcc color.c -o color
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include <pwd.h>
#include <sys/socket.h>
#include <sys/un.h>

#define X_OpenFont          45
#define X_CreateGlyphCursor 94
#define X_GrabPointer       26
#define X_UngrabPointer     27
#define X_GetImage          73

#define ZPIXMAP              2
#define ButtonPressMask      4
#define ButtonPress          4
#define XC_crosshair        34

static int xread(int fd, void *buf, size_t n) {
    uint8_t *p = buf;
    while (n) { ssize_t r = read(fd, p, n); if (r <= 0) return -1; p += r; n -= r; }
    return 0;
}

static int xwrite(int fd, const void *buf, size_t n) {
    const uint8_t *p = buf;
    while (n) { ssize_t r = write(fd, p, n); if (r <= 0) return -1; p += r; n -= r; }
    return 0;
}

static int ctz32(uint32_t v) {
    int n = 0; if (!v) return 0;
    while (!(v & 1)) { v >>= 1; n++; }
    return n;
}

/* Lee MIT-MAGIC-COOKIE-1 del archivo Xauthority para el display dado */
static int get_cookie(int dispnum, uint8_t *out, int maxlen) {
    char path[512];
    const char *xa = getenv("XAUTHORITY");
    if (xa) {
        snprintf(path, sizeof(path), "%s", xa);
    } else {
        const char *home = getenv("HOME");
        if (!home) { struct passwd *pw = getpwuid(getuid()); if (pw) home = pw->pw_dir; }
        if (!home) return 0;
        snprintf(path, sizeof(path), "%s/.Xauthority", home);
    }
    FILE *f = fopen(path, "rb");
    if (!f) return 0;
    char dispstr[16];
    int dslen = snprintf(dispstr, sizeof(dispstr), "%d", dispnum);
    for (;;) {
        uint8_t b[2];
#define RD2(x) if (fread(b,1,2,f)!=2) goto done; x=(uint16_t)((b[0]<<8)|b[1])
        uint16_t fam; RD2(fam); (void)fam;
        uint16_t alen; RD2(alen); fseek(f, alen, SEEK_CUR);
        uint16_t dlen; RD2(dlen);
        char dnum[32]={0};
        if (dlen < sizeof(dnum)) { if ((int)fread(dnum,1,dlen,f) != dlen) goto done; }
        else fseek(f, dlen, SEEK_CUR);
        uint16_t nlen; RD2(nlen);
        char name[32]={0};
        if (nlen < sizeof(name)) { if ((int)fread(name,1,nlen,f) != nlen) goto done; }
        else fseek(f, nlen, SEEK_CUR);
        uint16_t datlen; RD2(datlen);
#undef RD2
        if (dlen==(uint16_t)dslen && !memcmp(dnum,dispstr,dslen) &&
            nlen==18 && !memcmp(name,"MIT-MAGIC-COOKIE-1",18) &&
            datlen<=(uint16_t)maxlen) {
            if ((int)fread(out,1,datlen,f)!=datlen) goto done;
            fclose(f); return datlen;
        }
        fseek(f, datlen, SEEK_CUR);
    }
done:
    fclose(f); return 0;
}

int main(void) {
    const char *disp_env = getenv("DISPLAY");
    if (!disp_env) { fprintf(stderr, "DISPLAY no definido\n"); return 1; }
    const char *colon = strchr(disp_env, ':');
    int dispnum = colon ? atoi(colon + 1) : 0;

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) { perror("socket"); return 1; }
    struct sockaddr_un sa = {0};
    sa.sun_family = AF_UNIX;
    snprintf(sa.sun_path, sizeof(sa.sun_path), "/tmp/.X11-unix/X%d", dispnum);
    if (connect(fd, (struct sockaddr *)&sa, sizeof(sa)) < 0) {
        perror("connect"); close(fd); return 1;
    }

    /* Autenticación MIT-MAGIC-COOKIE-1 */
    uint8_t cookie[32];
    int clen = get_cookie(dispnum, cookie, sizeof(cookie));
    uint16_t anlen = clen > 0 ? 18 : 0;
    int anpad = anlen ? (4 - anlen % 4) % 4 : 0;
    int cpad  = clen  ? (4 - clen  % 4) % 4 : 0;

    uint8_t hdr[12] = {'l', 0, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint16_t cl = (uint16_t)clen;
    memcpy(hdr + 6, &anlen, 2);
    memcpy(hdr + 8, &cl,    2);
    xwrite(fd, hdr, 12);
    if (anlen) {
        static const char aname[] = "MIT-MAGIC-COOKIE-1";
        static const uint8_t pad4[4] = {0};
        xwrite(fd, aname, 18);    xwrite(fd, pad4, anpad);
        xwrite(fd, cookie, clen); xwrite(fd, pad4, cpad);
    }

    /* Leer respuesta de setup */
    uint8_t rhdr[8];
    if (xread(fd, rhdr, 8) < 0 || rhdr[0] != 1) {
        fprintf(stderr, "Conexión X11 rechazada\n"); close(fd); return 1;
    }
    uint16_t elen; memcpy(&elen, rhdr + 6, 2);
    uint8_t *info = malloc((size_t)elen * 4);
    if (!info || xread(fd, info, (size_t)elen * 4) < 0) { close(fd); return 1; }

    /* Parsear info de setup:
     *  info[4..7]  resource-id-base
     *  info[8..11] resource-id-mask
     *  info[16..17] vendor-length, info[21] nformats
     *  screen 0 empieza en: 32 + pad4(vendor_len) + nformats*8
     *  En screen: root@0, root-visual@32, ndepths@39, depths@40
     */
    uint32_t res_base, res_mask;
    memcpy(&res_base, info + 4, 4);
    memcpy(&res_mask, info + 8, 4);
    uint16_t vlen; memcpy(&vlen, info + 16, 2);
    int scroff = 32 + (((int)vlen + 3) & ~3) + (int)info[21] * 8;
    uint8_t *s = info + scroff;

    uint32_t root_win, root_vis;
    memcpy(&root_win, s,      4);
    memcpy(&root_vis, s + 32, 4);

    uint32_t rmask = 0, gmask = 0, bmask = 0;
    uint8_t *dp = s + 40;
    for (int d = 0; d < (int)s[39]; d++) {
        uint16_t nv; memcpy(&nv, dp + 2, 2);
        for (int v = 0; v < (int)nv; v++) {
            uint32_t vid; memcpy(&vid, dp + 8 + v * 24, 4);
            if (vid == root_vis) {
                memcpy(&rmask, dp + 8 + v * 24 +  8, 4);
                memcpy(&gmask, dp + 8 + v * 24 + 12, 4);
                memcpy(&bmask, dp + 8 + v * 24 + 16, 4);
            }
        }
        dp += 8 + (int)nv * 24;
    }
    free(info);

    if (!rmask && !gmask && !bmask) {
        fprintf(stderr, "Color indexado no soportado\n"); close(fd); return 1;
    }

    /* IDs de recursos: font y cursor */
    uint32_t font_id   = res_base | (1 & res_mask);
    uint32_t cursor_id = res_base | (2 & res_mask);

    /* OpenFont "cursor" (opcode 45)
     * Layout: [opcode, unused, len(2), fid(4), namelen(2), unused(2), name(padded)]
     * "cursor" = 6 bytes + 2 pad → total 20 bytes = 5 unidades de 4 bytes
     */
    {
        uint8_t req[20] = {X_OpenFont, 0, 5, 0};
        uint16_t fnlen = 6;
        memcpy(req + 4, &font_id, 4);
        memcpy(req + 8, &fnlen,   2);
        memcpy(req + 12, "cursor", 6);
        xwrite(fd, req, 20);
    }

    /* CreateGlyphCursor (opcode 94)
     * Usa XC_crosshair (glifo 34, máscara 35) del font "cursor"
     * Negro sobre blanco para máxima visibilidad
     */
    {
        uint8_t req[32] = {X_CreateGlyphCursor, 0, 8, 0};
        uint16_t src = XC_crosshair, msk = XC_crosshair + 1;
        uint16_t fore[3] = {0x0000, 0x0000, 0x0000};      /* negro */
        uint16_t back[3] = {0xFFFF, 0xFFFF, 0xFFFF};      /* blanco */
        memcpy(req +  4, &cursor_id, 4);
        memcpy(req +  8, &font_id,   4);
        memcpy(req + 12, &font_id,   4);
        memcpy(req + 16, &src,       2);
        memcpy(req + 18, &msk,       2);
        memcpy(req + 20, fore,       6);
        memcpy(req + 26, back,       6);
        xwrite(fd, req, 32);
    }

    /* GrabPointer (opcode 26) — captura el puntero con el cursor en cruz
     * Layout: [opcode, owner-events, len(2), grab-win(4), event-mask(2),
     *          ptr-mode(1), kbd-mode(1), confine-to(4), cursor(4), time(4)]
     */
    {
        uint8_t req[24] = {X_GrabPointer, 0, 6, 0};
        uint16_t evmask = ButtonPressMask;
        uint32_t none = 0, time0 = 0;
        memcpy(req +  4, &root_win, 4);
        memcpy(req +  8, &evmask,   2);
        req[10] = 1;  /* pointer-mode: Async */
        req[11] = 1;  /* keyboard-mode: Async */
        memcpy(req + 12, &none,      4);  /* confine-to: None */
        memcpy(req + 16, &cursor_id, 4);
        memcpy(req + 20, &time0,     4);  /* CurrentTime */
        xwrite(fd, req, 24);
    }

    uint8_t rep[32];
    xread(fd, rep, 32);
    if (rep[0] != 1 || rep[1] != 0) {
        fprintf(stderr, "GrabPointer falló (status=%d)\n", rep[1]);
        close(fd); return 1;
    }
    /* Esperar evento ButtonPress (tipo 4)
     * Layout: [type(1), button(1), seq(2), time(4), root(4),
     *          event(4), child(4), root-x(2), root-y(2), ...]
     */
    int16_t px = 0, py = 0;
    for (;;) {
        uint8_t ev[32];
        if (xread(fd, ev, 32) < 0) break;
        if ((ev[0] & 0x7F) == ButtonPress) {
            memcpy(&px, ev + 20, 2);
            memcpy(&py, ev + 22, 2);
            break;
        }
    }

    /* UngrabPointer (opcode 27) */
    {
        uint8_t req[8] = {X_UngrabPointer, 0, 2, 0, 0, 0, 0, 0};
        xwrite(fd, req, 8);
    }

    /* GetImage 1×1 en la posición del click */
    {
        uint8_t req[20] = {X_GetImage, ZPIXMAP, 5, 0};
        uint32_t plane = 0xFFFFFFFF;
        uint16_t w = 1, h = 1;
        memcpy(req +  4, &root_win, 4);
        memcpy(req +  8, &px, 2);
        memcpy(req + 10, &py, 2);
        memcpy(req + 12, &w,  2);
        memcpy(req + 14, &h,  2);
        memcpy(req + 16, &plane, 4);
        xwrite(fd, req, 20);
    }
    xread(fd, rep, 32);
    if (rep[0] != 1) {
        fprintf(stderr, "GetImage falló (err %d)\n", rep[1]);
        close(fd); return 1;
    }

    uint32_t dwords; memcpy(&dwords, rep + 4, 4);
    uint8_t pixbuf[4] = {0};
    if (dwords > 0) {
        xread(fd, pixbuf, 4);
        uint8_t drain[4];
        for (uint32_t i = 1; i < dwords; i++) xread(fd, drain, 4);
    }
    close(fd);

    /* Extraer R,G,B usando las máscaras y escalar a 8 bits */
    uint32_t pixel; memcpy(&pixel, pixbuf, 4);
    int rs = ctz32(rmask), gs = ctz32(gmask), bs = ctz32(bmask);
    uint32_t rv = (pixel & rmask) >> rs;
    uint32_t gv = (pixel & gmask) >> gs;
    uint32_t bv = (pixel & bmask) >> bs;
    uint32_t rmax = rmask >> rs, gmax = gmask >> gs, bmax = bmask >> bs;
    uint8_t r8 = rmax ? (uint8_t)(rv * 255 / rmax) : 0;
    uint8_t g8 = gmax ? (uint8_t)(gv * 255 / gmax) : 0;
    uint8_t b8 = bmax ? (uint8_t)(bv * 255 / bmax) : 0;

    printf("#%02x%02x%02x\n", r8, g8, b8);
    return 0;
}
