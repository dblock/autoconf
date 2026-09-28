# Autoconf

Autoconf is a DOS device driver for selecting one of several configurations from a single `CONFIG.SYS`. Its defining feature is that a configuration key can be pressed before the driver loads: Autoconf later reads the key from the BIOS keyboard queue and continues booting with the selected configuration.

![Selecting the DOOM configuration](media/autoconf-doom-boot.gif)

The original program was written by Julien Pommier and published in *Science & Vie Micro* no. 88 in November 1991. Daniel Doubrovkine later expanded it into the much larger bilingual Autoconf 3.00 beta 2 preserved here.

Daniel's later Autoconf versions and David Jilli's MegaBoot were developed while the two friends spent time in the basement of Infomaniak in Carouge, Switzerland.

- Read the reconstructed [project history](HISTORY.md).
- Explore the [original article and recovered source](original/).
- Run the [MS-DOS 5 boot demonstration](demo/).
- See [MegaBoot](https://github.com/dblock/megaboot), David Jilli's 1996 spiritual successor to Autoconf.
