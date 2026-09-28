# Autoconf MS-DOS 5 Boot Demo

The demo uses a bootable 1.44 MB MS-DOS 5 floppy image to run the preserved English Autoconf 3.00 beta 2 driver.

Boot it with DOSBox-X:

```sh
dosbox-x -fastlaunch -c "boot demo/autoconf-msdos5.img"
```

The `/J` option forces Autoconf to display a menu with three sample configurations:

- `A` - Minimal DOS
- `B` - DOOM
- `C` - Windows 95

Press `B` to select DOOM. Autoconf can also consume a configuration letter pressed earlier in the boot process because it reads the BIOS keyboard queue when the driver loads.

![Selecting the DOOM configuration](../media/autoconf-doom-boot.gif)

The configuration area uses `DEVICE=*A`, `DEVICE=*B`, and `DEVICE=*C` to begin configurations, while `DEVICE=$` ends it. DOS tokenizes the `DEVICE` keyword before the driver examines the in-memory configuration, which is why the assembly parser looks for the compact internal forms `D*` and `D$`.

## MS-DOS Image

The tested image was made from the `Dos5.0.img` boot disk in <https://archive.org/download/dos-5.0-bootdisk/DOS5.0_bootdisk.zip>, downloaded separately by the user. MS-DOS 5 remains proprietary Microsoft software and has not been released under the MIT license used by Microsoft's public MS-DOS 1.25, 2.0, and 4.0 source repository.

From the repository root on macOS, install `mtools`, download and extract the archive, then create the private demo image:

```sh
brew install mtools
curl -fLO https://archive.org/download/dos-5.0-bootdisk/DOS5.0_bootdisk.zip
unzip DOS5.0_bootdisk.zip
cp DOS5.0_bootdisk/Dos5.0.img demo/autoconf-msdos5.img

mcopy -o -i demo/autoconf-msdos5.img \
  bin/3b1e/AUTOCONF.SYS ::AUTOCONF.SYS
mcopy -o -i demo/autoconf-msdos5.img demo/CONFIG.SYS ::CONFIG.SYS
mcopy -o -i demo/autoconf-msdos5.img demo/AUTOEXEC.BAT ::AUTOEXEC.BAT
```

The directory created by `unzip` may differ between archive versions. Locate `Dos5.0.img` and adjust the `cp` source path if necessary.

The image is kept in the working tree only for private historical testing. Do not commit, publish, or redistribute `autoconf-msdos5.img` without permission from the applicable rights holder.
