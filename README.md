# Prusa 3D Printing and more

A personal collection of scripts, profiles, models, and G-code built up while running Prusa 3D printers. Everything here is developed for my own machines and workflow, and shared publicly in case it's useful to someone else.

## ⚠️ Disclaimer — Use At Your Own Risk

**Everything in this repository is provided "AS IS", without warranty of any kind, express or implied.**

3D printers involve high temperatures, moving parts, mains electricity, and long unattended runtimes. Scripts, profiles, and G-code from this repo may not be correct or safe for *your* printer, firmware version, nozzle, filament, or environment.

- **You are solely responsible** for reviewing and testing anything here before using it.
- Files are tuned for my specific hardware and slicer versions. Assume nothing transfers directly.
- Custom G-code and post-processing scripts can command your printer to do damaging things. **Read the G-code before you run it.**
- Never leave a print unattended without appropriate fire safety precautions.
- The author accepts **no liability** for damaged printers, failed prints, wasted filament, property damage, injury, or any other loss arising from use of this repository.

If you're not comfortable reading and validating the contents yourself, don't use them.

## Contents

| Path | Description |
|------|-------------|
| `scripts/` | Automation and utility scripts — G-code post-processors, PrusaSlicer helpers, batch tooling |
| `profiles/` | PrusaSlicer print, filament, and printer configuration files (`.ini`) |
| `models/` | Printable models — `.stl` and `.3mf` project files |
| `gcode/` | Sliced, ready-to-print G-code |

## Usage

### Profiles

Import into PrusaSlicer via **File → Import → Import Config**. Verify nozzle diameter, bed size, filament temperatures, and Z-offset against your own printer before printing.

### Scripts

Check the header comments in each script for required runtime and dependencies. To use a post-processing script in PrusaSlicer: **Print Settings → Output options → Post-processing scripts**.

### G-code

Sliced for the specific printer, nozzle, and filament noted in the file header. **Do not print sliced G-code from this repo on a different configuration without re-slicing.**

## Compatibility

Files are developed and tested only on my own hardware and slicer versions. Other Prusa models, aftermarket parts, and different firmware or slicer releases are untested.

## Contributing

Issues and pull requests are welcome, but this is a personal project maintained on a best-effort basis. There is no support commitment.

## License

Licensed under the MIT License — see [LICENSE](LICENSE). The MIT License includes its own explicit no-warranty and no-liability terms, which apply in full to everything in this repository.
