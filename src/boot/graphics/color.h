#pragma once
#include <stdint.h>

namespace Color {

    // =========================================================================
    // COMPILE-TIME BIT MATH & COLOR UTILITIES
    // =========================================================================

    // Construct 32-bit ARGB/XRGB (0x00RRGGBB)
    constexpr inline uint32_t rgb(uint8_t r, uint8_t g, uint8_t b) {
        return ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)b;
    }

    constexpr inline uint32_t argb(uint8_t a, uint8_t r, uint8_t g, uint8_t b) {
        return ((uint32_t)a << 24) | ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)b;
    }

    // Component extractors
    constexpr inline uint8_t get_a(uint32_t c) { return (c >> 24) & 0xFF; }
    constexpr inline uint8_t get_r(uint32_t c) { return (c >> 16) & 0xFF; }
    constexpr inline uint8_t get_g(uint32_t c) { return (c >> 8)  & 0xFF; }
    constexpr inline uint8_t get_b(uint32_t c) { return c & 0xFF; }

    // Fast integer linear interpolation: t is 0..255 (0 = c1, 255 = c2)
    constexpr inline uint32_t lerp(uint32_t c1, uint32_t c2, uint8_t t) {
        uint32_t r = get_r(c1) + (((get_r(c2) - get_r(c1)) * t) >> 8);
        uint32_t g = get_g(c1) + (((get_g(c2) - get_g(c1)) * t) >> 8);
        uint32_t b = get_b(c1) + (((get_b(c2) - get_b(c1)) * t) >> 8);
        return rgb((uint8_t)r, (uint8_t)g, (uint8_t)b);
    }

    // Alpha blend foreground over background (alpha: 0 = transparent, 255 = opaque)
    constexpr inline uint32_t blend(uint32_t fg, uint32_t bg, uint8_t alpha) {
        return lerp(bg, fg, alpha);
    }

    // Convert any color to perceived luminance grayscale
    constexpr inline uint32_t to_grayscale(uint32_t c) {
        // Human eye weighting: 0.299 R + 0.587 G + 0.114 B ~= (77*R + 150*G + 29*B) / 256
        uint8_t gray = (uint8_t)((77 * get_r(c) + 150 * get_g(c) + 29 * get_b(c)) >> 8);
        return rgb(gray, gray, gray);
    }

    // =========================================================================
    // HARDWARE VGA / BIOS 16-COLOR TEXT MODE PALETTE
    // =========================================================================
    constexpr uint32_t VgaBlack            = 0x00000000;
    constexpr uint32_t VgaBlue             = 0x000000AA;
    constexpr uint32_t VgaGreen            = 0x0000AA00;
    constexpr uint32_t VgaCyan             = 0x0000AAAA;
    constexpr uint32_t VgaRed              = 0x00AA0000;
    constexpr uint32_t VgaMagenta          = 0x00AA00AA;
    constexpr uint32_t VgaBrown            = 0x00AA5500;
    constexpr uint32_t VgaLightGray        = 0x00AAAAAA;
    constexpr uint32_t VgaDarkGray         = 0x00555555;
    constexpr uint32_t VgaBrightBlue       = 0x005555FF;
    constexpr uint32_t VgaBrightGreen      = 0x0055FF55;
    constexpr uint32_t VgaBrightCyan       = 0x0055FFFF;
    constexpr uint32_t VgaBrightRed        = 0x00FF5555;
    constexpr uint32_t VgaBrightMagenta    = 0x00FF55FF;
    constexpr uint32_t VgaYellow           = 0x00FFFF55;
    constexpr uint32_t VgaWhite            = 0x00FFFFFF;

    // =========================================================================
    // CLASSIC OS UI PALETTES
    // =========================================================================

    // Windows 95 / 98 Classic Desktop & Controls
    constexpr uint32_t Win95Desktop        = 0x00008080; // Classic teal desktop background
    constexpr uint32_t Win95ButtonFace     = 0x00C0C0C0; // Standard 3D gray surface
    constexpr uint32_t Win95ButtonHilight  = 0x00FFFFFF; // Top/left 3D border
    constexpr uint32_t Win95ButtonShadow   = 0x00808080; // Bottom/right 3D inner border
    constexpr uint32_t Win95ButtonDark     = 0x00000000; // Bottom/right 3D drop shadow
    constexpr uint32_t Win95ActiveTitle    = 0x00000080; // Active window titlebar navy
    constexpr uint32_t Win95InactiveTitle  = 0x00808080; // Inactive window titlebar gray
    constexpr uint32_t Win95TitleText      = 0x00FFFFFF; // Titlebar text white
    constexpr uint32_t Win95Menu           = 0x00C0C0C0; // Menu bar fill
    constexpr uint32_t Win95Window         = 0x00FFFFFF; // Window canvas background
    constexpr uint32_t Win95WindowText     = 0x00000000; // Standard body text

    // System Crash & Kernel Panic Screens
    constexpr uint32_t BsodClassicBlue     = 0x000000AA; // Windows NT/9x Blue Screen
    constexpr uint32_t BsodModernBlue      = 0x000078D7; // Windows 8/10/11 Blue Screen
    constexpr uint32_t GsodInsiderGreen    = 0x00107C41; // Windows Insider Green Screen
    constexpr uint32_t RsodFatalRed        = 0x00780000; // BIOS/Console Red Screen of Death
    constexpr uint32_t PanicCrimson        = 0x00880000; // Linux / Unix Kernel Panic

    // Classic Apple Macintosh / System 7 / Platinum
    constexpr uint32_t MacPlatinum         = 0x00D8D8D8; // Classic Mac Platinum UI gray
    constexpr uint32_t MacDarkPlatinum     = 0x00B4B4B4; // Darker control boundary
    constexpr uint32_t MacCharcoal         = 0x00404040; // Charcoal titlebar text
    constexpr uint32_t MacAquaBlue         = 0x003399FF; // OS X Aqua accent
    constexpr uint32_t MacAquaPillClose    = 0x00FF5F56; // Window stoplight red
    constexpr uint32_t MacAquaPillMin      = 0x00FFBD2E; // Window stoplight yellow
    constexpr uint32_t MacAquaPillMax      = 0x0027C93F; // Window stoplight green

    // =========================================================================
    // MODERN DEVELOPER & TERMINAL PALETTES
    // =========================================================================

    // Nord Theme (Arctic Ice)
    constexpr uint32_t NordPolarNight0     = 0x002E3440; // Base background
    constexpr uint32_t NordPolarNight1     = 0x003B4252; // Lighter background
    constexpr uint32_t NordPolarNight2     = 0x00434C5E; // Selection background
    constexpr uint32_t NordPolarNight3     = 0x004C566A; // Comments / muted text
    constexpr uint32_t NordSnow0           = 0x00D8DEE9; // Darkest text
    constexpr uint32_t NordSnow1           = 0x00E5E9F0; // Default text
    constexpr uint32_t NordSnow2           = 0x00ECEFF4; // Brightest white text
    constexpr uint32_t NordFrost0          = 0x008FBCBB; // Green-tinted teal
    constexpr uint32_t NordFrost1          = 0x0088C0D0; // Light ice blue
    constexpr uint32_t NordFrost2          = 0x0081A1C1; // Frost blue
    constexpr uint32_t NordFrost3          = 0x005E81AC; // Deep blue
    constexpr uint32_t NordRed             = 0x00BF616A;
    constexpr uint32_t NordOrange          = 0x00D08770;
    constexpr uint32_t NordYellow          = 0x00EBCB8B;
    constexpr uint32_t NordGreen           = 0x00A3BE8C;
    constexpr uint32_t NordPurple          = 0x00B48EAD;

    // Dracula Theme
    constexpr uint32_t DraculaBg           = 0x00282A36;
    constexpr uint32_t DraculaCurrentLine  = 0x0044475A;
    constexpr uint32_t DraculaFg           = 0x00F8F8F2;
    constexpr uint32_t DraculaComment      = 0x006272A4;
    constexpr uint32_t DraculaCyan         = 0x008BE9FD;
    constexpr uint32_t DraculaGreen        = 0x0050FA7B;
    constexpr uint32_t DraculaOrange       = 0x00FFB86C;
    constexpr uint32_t DraculaPink         = 0x00FF79C6;
    constexpr uint32_t DraculaPurple       = 0x00BD93F9;
    constexpr uint32_t DraculaRed          = 0x00FF5555;
    constexpr uint32_t DraculaYellow       = 0x00F1FA8C;

    // Monokai Pro
    constexpr uint32_t MonokaiBg           = 0x00272822;
    constexpr uint32_t MonokaiFg           = 0x00F8F8F2;
    constexpr uint32_t MonokaiYellow       = 0x00E6DB74;
    constexpr uint32_t MonokaiGreen        = 0x00A6E22E;
    constexpr uint32_t MonokaiOrange       = 0x00FD971F;
    constexpr uint32_t MonokaiRed          = 0x00F92672;
    constexpr uint32_t MonokaiPurple       = 0x00AE81FF;
    constexpr uint32_t MonokaiCyan         = 0x0066D9EF;

    // Solarized
    constexpr uint32_t SolBase03           = 0x00002B36; // Darkest background
    constexpr uint32_t SolBase02           = 0x00073642;
    constexpr uint32_t SolBase01           = 0x00586E75;
    constexpr uint32_t SolBase00           = 0x00657B83;
    constexpr uint32_t SolBase0            = 0x00839496;
    constexpr uint32_t SolBase1            = 0x0093A1A1;
    constexpr uint32_t SolBase2            = 0x00EEE8D5; // Light background
    constexpr uint32_t SolBase3            = 0x00FDF6E3;
    constexpr uint32_t SolYellow           = 0x00B58900;
    constexpr uint32_t SolOrange           = 0x00CB4B16;
    constexpr uint32_t SolRed              = 0x00DC322F;
    constexpr uint32_t SolMagenta          = 0x00D33682;
    constexpr uint32_t SolViolet           = 0x006C71C4;
    constexpr uint32_t SolBlue             = 0x00268BD2;
    constexpr uint32_t SolCyan             = 0x002AA198;
    constexpr uint32_t SolGreen            = 0x00859900;

    // =========================================================================
    // DOOM / RETRO GAME ENGINE PALETTE ACCENTS
    // =========================================================================
    constexpr uint32_t DoomMarineArmor     = 0x005B7347; // Olive green praetor suit
    constexpr uint32_t DoomBloodRed        = 0x008C0000; // Menu skull cursor red
    constexpr uint32_t DoomAcidSlime       = 0x0064B82A; // Nuclear slime floor
    constexpr uint32_t DoomNukageGreen     = 0x00478018; // Radioactive nukage vat
    constexpr uint32_t DoomFireOrange      = 0x00E86800; // Title flame orange
    constexpr uint32_t DoomHudGray         = 0x004F4F4F; // Status bar border gray
    constexpr uint32_t DoomKeycardBlue     = 0x000047AB; // Blue skull / keycard
    constexpr uint32_t DoomKeycardYellow   = 0x00D4AF37; // Yellow skull / keycard
    constexpr uint32_t DoomKeycardRed      = 0x00C41E3A; // Red skull / keycard

    // =========================================================================
    // EXHAUSTIVE W3C / X11 / CSS STANDARD SPECTRUM (140+ COLORS)
    // =========================================================================

    // --- Whites, Grays & Neutrals ---
    constexpr uint32_t Black               = 0x00000000;
    constexpr uint32_t Night               = 0x000C0C0C;
    constexpr uint32_t Charcoal            = 0x00212121;
    constexpr uint32_t DarkSlateGray       = 0x002F4F4F;
    constexpr uint32_t DimGray             = 0x00696969;
    constexpr uint32_t Gray                = 0x00808080;
    constexpr uint32_t SlateGray           = 0x00708090;
    constexpr uint32_t LightSlateGray      = 0x00778899;
    constexpr uint32_t DarkGray            = 0x00A9A9A9;
    constexpr uint32_t Silver              = 0x00C0C0C0;
    constexpr uint32_t LightGray           = 0x00D3D3D3;
    constexpr uint32_t Gainsboro           = 0x00DCDCDC;
    constexpr uint32_t WhiteSmoke          = 0x00F5F5F5;
    constexpr uint32_t GhostWhite          = 0x00F8F8FF;
    constexpr uint32_t AliceBlue           = 0x00F0F8FF;
    constexpr uint32_t Azure               = 0x00F0FFFF;
    constexpr uint32_t MintCream           = 0x00F5FFFA;
    constexpr uint32_t Honeydew            = 0x00F0FFF0;
    constexpr uint32_t FloralWhite         = 0x00FFFAF0;
    constexpr uint32_t Ivory               = 0x00FFFFF0;
    constexpr uint32_t Snow                = 0x00FFFAFA;
    constexpr uint32_t SeaShell            = 0x00FFF5EE;
    constexpr uint32_t OldLace             = 0x00FDF5E6;
    constexpr uint32_t Linen               = 0x00FAF0E6;
    constexpr uint32_t AntiqueWhite        = 0x00FAEBD7;
    constexpr uint32_t LavenderBlush       = 0x00FFF0F5;
    constexpr uint32_t MistyRose           = 0x00FFE4E1;
    constexpr uint32_t White               = 0x00FFFFFF;

    // --- Reds ---
    constexpr uint32_t DarkRed             = 0x008B0000;
    constexpr uint32_t Maroon              = 0x00800000;
    constexpr uint32_t Brown               = 0x00A52A2A;
    constexpr uint32_t Firebrick           = 0x00B22222;
    constexpr uint32_t Crimson             = 0x00DC143C;
    constexpr uint32_t Red                 = 0x00FF0000;
    constexpr uint32_t Scarlet             = 0x00FF2400;
    constexpr uint32_t IndianRed           = 0x00CD5C5C;
    constexpr uint32_t LightCoral          = 0x00F08080;
    constexpr uint32_t Salmon              = 0x00FA8072;
    constexpr uint32_t DarkSalmon          = 0x00E9967A;
    constexpr uint32_t LightSalmon         = 0x00FFA07A;

    // --- Pinks & Roses ---
    constexpr uint32_t Pink                = 0x00FFC0CB;
    constexpr uint32_t LightPink           = 0x00FFB6C1;
    constexpr uint32_t HotPink             = 0x00FF69B4;
    constexpr uint32_t DeepPink            = 0x00FF1493;
    constexpr uint32_t PaleVioletRed       = 0x00DB7093;
    constexpr uint32_t MediumVioletRed     = 0x00C71585;
    constexpr uint32_t Rose                = 0x00FF007F;

    // --- Oranges & Ambers ---
    constexpr uint32_t Coral               = 0x00FF7F50;
    constexpr uint32_t Tomato              = 0x00FF6347;
    constexpr uint32_t OrangeRed           = 0x00FF4500;
    constexpr uint32_t DarkOrange          = 0x00FF8C00;
    constexpr uint32_t Orange              = 0x00FFA500;
    constexpr uint32_t Amber               = 0x00FFBF00;

    // --- Yellows & Golds ---
    constexpr uint32_t Gold                = 0x00FFD700;
    constexpr uint32_t Yellow              = 0x00FFFF00;
    constexpr uint32_t LightYellow         = 0x00FFFFE0;
    constexpr uint32_t LemonChiffon        = 0x00FFFACD;
    constexpr uint32_t LightGoldenrod      = 0x00FAFAD2;
    constexpr uint32_t PapayaWhip          = 0x00FFEFD5;
    constexpr uint32_t Moccasin            = 0x00FFE4B5;
    constexpr uint32_t PeachPuff           = 0x00FFDAB9;
    constexpr uint32_t PaleGoldenrod       = 0x00EEE8AA;
    constexpr uint32_t Khaki               = 0x00F0E68C;
    constexpr uint32_t DarkKhaki           = 0x00BDB76B;

    // --- Browns, Tans & Earthy ---
    constexpr uint32_t Cornsilk            = 0x00FFF8DC;
    constexpr uint32_t BlanchedAlmond      = 0x00FFEBCD;
    constexpr uint32_t Bisque              = 0x00FFE4C4;
    constexpr uint32_t NavajoWhite         = 0x00FFDEAD;
    constexpr uint32_t Wheat               = 0x00F5DEB3;
    constexpr uint32_t Burlywood           = 0x00DEB887;
    constexpr uint32_t Tan                 = 0x00D2B48C;
    constexpr uint32_t RosyBrown           = 0x00BC8F8F;
    constexpr uint32_t SandyBrown          = 0x00F4A460;
    constexpr uint32_t Goldenrod           = 0x00DAA520;
    constexpr uint32_t DarkGoldenrod       = 0x00B8860B;
    constexpr uint32_t Peru                = 0x00CD853F;
    constexpr uint32_t Chocolate           = 0x00D2691E;
    constexpr uint32_t SaddleBrown         = 0x008B4513;
    constexpr uint32_t Sienna              = 0x00A0522D;

    // --- Greens ---
    constexpr uint32_t DarkOliveGreen      = 0x00556B2F;
    constexpr uint32_t Olive               = 0x00808000;
    constexpr uint32_t OliveDrab           = 0x006B8E23;
    constexpr uint32_t YellowGreen         = 0x009ACD32;
    constexpr uint32_t LimeGreen           = 0x0032CD32;
    constexpr uint32_t Lime                = 0x0000FF00;
    constexpr uint32_t LawnGreen           = 0x007CFC00;
    constexpr uint32_t Chartreuse          = 0x007FFF00;
    constexpr uint32_t GreenYellow         = 0x00ADFF2F;
    constexpr uint32_t SpringGreen         = 0x0000FF7F;
    constexpr uint32_t MediumSpringGreen   = 0x0000FA9A;
    constexpr uint32_t LightGreen          = 0x0090EE90;
    constexpr uint32_t PaleGreen           = 0x0098FB98;
    constexpr uint32_t DarkSeaGreen        = 0x008FBC8F;
    constexpr uint32_t MediumSeaGreen      = 0x003CB371;
    constexpr uint32_t SeaGreen            = 0x002E8B57;
    constexpr uint32_t ForestGreen         = 0x00228B22;
    constexpr uint32_t Green               = 0x00008000;
    constexpr uint32_t DarkGreen           = 0x00006400;
    constexpr uint32_t Emerald             = 0x0050C878;

    // --- Cyans & Teals ---
    constexpr uint32_t MediumAquamarine    = 0x0066CDAA;
    constexpr uint32_t Aqua                = 0x0000FFFF;
    constexpr uint32_t Cyan                = 0x0000FFFF;
    constexpr uint32_t LightCyan           = 0x00E0FFFF;
    constexpr uint32_t PaleTurquoise       = 0x00AFEEEE;
    constexpr uint32_t Aquamarine          = 0x007FFFD4;
    constexpr uint32_t Turquoise           = 0x0040E0D0;
    constexpr uint32_t MediumTurquoise     = 0x0048D1CC;
    constexpr uint32_t DarkTurquoise       = 0x0000CED1;
    constexpr uint32_t LightSeaGreen       = 0x0020B2AA;
    constexpr uint32_t CadetBlue           = 0x005F9EA0;
    constexpr uint32_t DarkCyan            = 0x00008B8B;
    constexpr uint32_t Teal                = 0x00008080;

    // --- Blues ---
    constexpr uint32_t LightSteelBlue      = 0x00B0C4DE;
    constexpr uint32_t PowderBlue          = 0x00B0E0E6;
    constexpr uint32_t LightBlue           = 0x00ADD8E6;
    constexpr uint32_t SkyBlue             = 0x0087CEEB;
    constexpr uint32_t LightSkyBlue        = 0x0087CEFA;
    constexpr uint32_t DeepSkyBlue         = 0x0000BFFF;
    constexpr uint32_t DodgerBlue          = 0x001E90FF;
    constexpr uint32_t CornflowerBlue      = 0x006495ED;
    constexpr uint32_t SteelBlue           = 0x004682B4;
    constexpr uint32_t RoyalBlue           = 0x004169E1;
    constexpr uint32_t Blue                = 0x000000FF;
    constexpr uint32_t MediumBlue          = 0x000000CD;
    constexpr uint32_t DarkBlue            = 0x0000008B;
    constexpr uint32_t Navy                = 0x00000080;
    constexpr uint32_t MidnightBlue        = 0x00191970;

    // --- Purples, Violets & Magentas ---
    constexpr uint32_t Lavender            = 0x00E6E6FA;
    constexpr uint32_t Thistle             = 0x00D8BFD8;
    constexpr uint32_t Plum                = 0x00DDA0DD;
    constexpr uint32_t Violet              = 0x00EE82EE;
    constexpr uint32_t Orchid              = 0x00DA70D6;
    constexpr uint32_t Fuchsia             = 0x00FF00FF;
    constexpr uint32_t Magenta             = 0x00FF00FF;
    constexpr uint32_t MediumOrchid        = 0x00BA55D3;
    constexpr uint32_t MediumPurple        = 0x009370DB;
    constexpr uint32_t BlueViolet          = 0x008A2BE2;
    constexpr uint32_t DarkViolet          = 0x009400D3;
    constexpr uint32_t DarkOrchid          = 0x009932CC;
    constexpr uint32_t DarkMagenta         = 0x008B008B;
    constexpr uint32_t Purple              = 0x00800080;
    constexpr uint32_t Indigo              = 0x004B0082;
    constexpr uint32_t DarkSlateBlue       = 0x00483D8B;
    constexpr uint32_t SlateBlue           = 0x006A5ACD;
    constexpr uint32_t MediumSlateBlue     = 0x007B68EE;

} // namespace Color