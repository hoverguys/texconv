# Die Texconv-Maschine

Your faithful reddit meme gif to Gamecube renderable pipeline tool.

Encodes many image formats to GC-friendly image formats.

## Usage

```
USAGE:
  texconv [OPTIONS]

OPTIONS:
      --wrap <VALUE>             Wrapping strategy (valid values: clamp, repeat, mirror)
      --filter <VALUE>           Filter (valid values: near, bilinear, trilinear)
      --color-format <VALUE>     Output color format (see README for list)
      --palette-format <VALUE>   Palette color format (see README for list)
      --mipmap-min <VALUE>       Minimum mipmap level (0-10)
      --mipmap-max <VALUE>       Maximum mipmap level (0-10)
      --in <VALUE>               Image file to convert
      --out <VALUE>              Output file
  -h, --help                     Show this help output.
      --color <VALUE>            When to use colors (*auto*, never, always).
```

Example: `texconv --in ./testdata/alpha.png --color-format IA8 --out test.bin`

See below for color and palette formats (at time of writing not all of them are implemented)

### Color formats

| Value    | Description                                |
| -------- | ------------------------------------------ |
| `I4`     | Grayscale 4bit (I4)                        |
| `IA4`    | Grayscale + Alpha 4bit (I4A4)              |
| `IA8`    | Grayscale + Alpha 8bit (I8A8)              |
| `RGB565` | Limited color (R5G6B5)                     |
| `RGBA8`  | Full 8bpc color (A8R8G8B8)                 |
| `I8`     | Grayscale 8bit (I8)                        |
| `RGB5A3` | Limited color and alpha (R4B4G4A3\|R5B5G5) |
| `A8`     | Alpha-only 8bit (A8)                       |
| `CI4`    | Palette-indexed 4bit (CI4)                 |
| `CI8`    | Palette-indexed 8bit (CI8)                 |

### Palette color formats

| Value    | Description                                |
| -------- | ------------------------------------------ |
| `IA8`    | Grayscale + Alpha 8bit (I8A8)              |
| `RGB565` | Limited color (R5G6B5)                     |
| `RGB5A3` | Limited color and alpha (R4B4G4A3\|R5B5G5) |

## License

`AGPL-3.0-only`, check `LICENSE` for full text
