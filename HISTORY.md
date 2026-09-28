# History of Autoconf

Autoconf was a DOS device driver for selecting one of several configurations from a single `CONFIG.SYS`. This document reconstructs its history from the original 1991 magazine article, the recovered source, the English and French `WHATSNEW` files, dated comments and strings embedded in the later source and binaries, and historical build scripts.

Its defining innovation was that the user did not have to wait for a boot menu. A configuration key could be pressed at any time during the earlier stages of boot, before DOS loaded `AUTOCONF.SYS`. The PC BIOS placed the keystroke in its keyboard queue, where it remained until a program consumed it. When Autoconf initialized, it called BIOS keyboard interrupt `INT 16h` with `AH=01h` to check the queue without blocking. If a key was already waiting, it called `INT 16h` with `AH=00h` to read it immediately. Space opened the configuration list; a letter was converted for the selected keyboard layout, changed to uppercase, checked against the declarations in `CONFIG.SYS`, and selected directly. The menu was therefore optional rather than the normal fast path.

The surviving material provides only a handful of exact dates. Releases without a contemporary date are therefore presented in their documented order rather than assigned speculative dates.

## November 1991: The Original Program

The original Autoconf was written by Julien Pommier and published as “La configuration idéale” in *Science & Vie Micro* no. 88, November 1991, pp. 227–233. The article won the magazine's monthly programming contest and received a 2,000-franc prize. It printed the complete source for `AUTOCONF.ASM` and the small companion program `READCONF.ASM`, together with installation instructions and sample `CONFIG.SYS` and `AUTOEXEC.BAT` files.

The original source is preserved in [`original/`](original/). The scanned article is the canonical source; the assembly files are OCR-assisted transcriptions that were manually corrected against the printed listing.

The 472-line original `AUTOCONF.ASM` is a compact DOS character-device driver. During `CONFIG.SYS` processing it:

- recognizes configuration blocks beginning with `DEVICE=*<letter>` and ending with `DEVICE=$`;
- consumes a configuration key that may already have been pressed earlier in the boot process, or waits for one with an optional timeout;
- lists available configurations when Space is pressed;
- supports AZERTY and QWERTY keyboard selection;
- remembers or restores the selected configuration through `AUTOCONF.DAT`;
- removes the unselected configuration lines from the in-memory `CONFIG.SYS`; and
- records the selected configuration through interrupt vector `0xFA`.

The waiting loop in `lit_configuration` combines two BIOS services. `INT 16h/AH=01h` tests whether a key is queued, while `INT 1Ah/AH=00h` reads the approximately 18.2-Hz BIOS clock tick counter. If no key arrives before the configured delay, Autoconf uses the default or previously saved configuration. If a key was pressed long before the driver loaded, the very first keyboard test finds it and avoids the delay entirely.

The 14-line `READCONF.ASM` is an 11-byte `.COM` program that reads the selected value from interrupt vector `0xFA` and returns it as its DOS exit code. On DOS versions later than 3.21 the driver releases all of its memory after initialization; on older versions it remains as a replacement for the `NUL` device.

The recovered listings have been assembled successfully under DOS with JWasm in MASM 5 compatibility mode. They produce a 1,180-byte `AUTOCONF.SYS` and an 11-byte `READCONF.COM`.

## After 1991: A Hand-Typed Fork

I ([Daniel Doubrovkine](https://code.dblock.org/about/)) copied the printed assembly source by hand as my first x86 assembly program and used it as the engine for my own versions. The precise date this work began is not recorded. The later built-in English and French help still described the origin accurately, although I had forgotten Julien Pommier's name: a French programmer had written the original engine, a version had appeared in SVM, and roughly 90 percent of the program had since been modified.

The name Autoconf was retained while the small original program grew into a much larger bilingual boot-configuration system. The surviving release history records 145 changes from versions 1.0 through 3.00 beta 2.

## Versions 1.0–1.54: Expanding the Original Interface

The early releases have no surviving dates, but `WHATSNEW.ENG` and `WHATSNEW.FR` establish their order.

- **1.0–1.24:** removed display garbage, added names and a list of configurations, rewrote the online guide, allowed navigation through the guide, and added recovery after invalid choices.
- **1.3:** added color output and the `/P`, `/J`, `/F`, `/E`, and `/N` options.
- **1.4–1.42:** added DOS 6-aware recovery, removed the original 33-configuration limit, repaired French and Swiss keyboard support, added a selectable default configuration, and introduced time-dependent welcome messages.
- **1.5–1.54 beta:** concentrated on error recovery and silent mode, restored or saved the previous configuration through `AUTOCONF.DAT`, varied messages by time of day, and introduced `READCONF.COM` 2.0. The French history says the final 1.54 was not distributed.

## March 1993: MS-DOS Adds Native Multiple Configurations

MS-DOS 6.0 introduced built-in multiple configurations in March 1993. Its `CONFIG.SYS` syntax used a `[MENU]` section with `MENUITEM` entries and named configuration blocks. DOS passed the selected block name to `AUTOEXEC.BAT` through the `%CONFIG%` environment variable.

The [`msdos6.2/`](msdos6.2/) demo recreates the same Minimal DOS, DOOM, and Windows 95 choices used by the Autoconf demonstration with native MS-DOS 6.22 syntax. It includes reproducible instructions for extracting the bootable floppy image from a separately downloaded MS-DOS 6.22 ISO; the proprietary image itself is ignored by Git.

![Selecting the DOOM configuration with native MS-DOS 6.22](media/msdos622-multiconfig.gif)

## By November 23, 1993: Version 2-era Development

Two comments in the surviving `AUTOCONF.ASM` are dated Tuesday, November 23, 1993. They annotate the parsing that preserves upper- and lowercase characters in configuration names, a feature listed under version 2.0. This is the earliest exact development date embedded in the evolved assembly source.

The custom text encoder in `CODE2.CPP` identifies itself as a 1993 internal development tool. It was created because `AUTOCONF.SYS` had run into the 64 KB limit, making the growing help and message data too large to keep uncompressed. It transformed the readable English or French message source into generated include files before assembly. Printable characters inside assembly strings were XORed with `0xE8`; runs longer than four identical encoded bytes were stored as `0xFE`, the encoded character, and the repeat count plus 100. The runtime display code reversed the XOR and expanded the runs. This is why `AUTOCONF.INC` and `AUTOCON2.INC` look like damaged text when viewed directly even though they are valid generated data.

Version 2.0 added mixed-case configuration titles, processor, coprocessor, and DOS detection, much faster screen output, broader error handling, and `READCONF.EXE` 3.0. Unlike the original tiny `.COM`, the new `READCONF` placed the selected configuration in the permanent DOS environment as `CONF=<name>`.

Version 2.1 replaced the simple list with a sorted, scrollable, highlighted menu supporting an effectively unlimited number of configurations. It added customizable time-of-day messages and more complete keyboard navigation. Versions 2.2 and 2.3 addressed QEMM and DOSDATA behavior, added function-key configurations from F1 through F10, and advanced `READCONF` to version 3.12. Version 2.32 introduced faster direct-video routines contributed by Hitcher.

## June–July 1994: Viewer, BOOTIT, Video, and Keyboard Work

The release history gives the first explicit release date: version 2.41 was last modified on **Thursday, June 16, 1994**. Version 2.4 introduced a configuration viewer opened with Tab, allowing users to inspect and navigate configurations before loading them.

The source contains a cluster of dated video and keyboard routines from **July 3–8, 1994**, including EGA detection, cursor positioning, attribute filling, keyboard conversion, and scrolling helpers. A top-level display macro is marked **July 7, 1994**. These changes align with versions 2.42 through 2.5:

- **2.42:** added `BOOTIT` 1.0 for rebooting directly into a selected configuration, smoother help and manual display, and safer handling of navigation keys.
- **2.5:** added 25- and 50-line screen modes, CGA support, duplicate-designation viewing, and support for the keyboard layouts recognized by DOS `KEYB.COM`.
- **2.51:** fixed option parsing and added a visible or suppressible countdown pulse.

The C source for `READCONF.EXE` displays a 1994 copyright date. The historical release scripts compile the C utilities with Borland C++, assemble the driver and manual with Borland TASM, link them with TLINK, convert the driver with EXE2BIN, and package separate English and French ZIP archives with PKZIP.

## 1995: Windows 95, Nested Configurations, and Interactive Editing

Version 2.60 added support for Windows 4.0 “Chicago” and DOS 7. The English and French message sources call this support “final august 1995,” providing an **August 1995** milestone. Versions 2.6x and 2.70 refined coexistence with Chicago, DOS, QEMM, and DOSDATA; updated `BOOTIT`; added common-only booting; and expanded configuration viewing.

Version 2.80, together with `BOOTIT` 1.2 and `READCONF` 4.0, added nested configuration groups of arbitrary depth. The selected path could be exported as a value such as `F2_F3_J_O`. Revisions 2.80.01 through 2.80.03 corrected navigation, display, message, cache, STACKER, and reboot problems.

Versions 2.81 and 2.82 added separate DOS and Windows 95 countdown behavior, visible countdown timers, colored configuration names, and a workaround for Award BIOS keyboard-buffer behavior.

Version 2.90 integrated the `AUTOEXEC.BAT` handoff into the driver as `iREAD`, eliminating the normal need for the separate `READCONF` utility. It also introduced `iLINE`, an editor that could temporarily enable, disable, or prompt for individual lines while viewing a configuration. The relevant assembly routines are explicitly dated **September 13, 1995**.

Versions 2.91 through 2.93 refined `iLINE`, the configuration viewer, converters, `BOOTIT`, Windows 95 defaults, and search:

- `iLINE` 1.1 added question-mark prompts and immediate display of edits.
- `BOOTIT` 1.5 learned to reboot nested configurations and display the configuration list.
- The help system and `MANUAL.EXE` gained text search.
- DOS 5 compatibility could disable `iREAD` and fall back to `READCONF.EXE`.
- Configuration declarations became more tolerant of spaces.

The English and French histories are signed **September 1995**. The French file's banner says **version 3.00, November 1995**, suggesting that the beta documentation continued to be revised after the signed history text. The preserved release is consistently labeled **3.00 beta 2**.

Version 3.00 beta 2 fixed edge cases in `iLINE`, empty-line handling, duplicate designations, viewer selection, and split-line conversion in `ACF2DOS` and `DOS2ACF`. The planned final 3.00 release was also intended to include `iLOOM`, a customizable menu system by Serge Huber with arbitrary layouts, ANSI backgrounds, animations, and a separate menu editor. The source and release notes say that `iLOOM` was still under construction in 1995, and the preserved beta keeps it disabled.

The release history counted 7,065 lines in `AUTOCONF.ASM`, excluding text and manuals, plus 358 lines for the manual, 573 lines for `iLOOM`, and approximately 800 condensed C lines each for `DOS2ACF` and `ACF2DOS`. The preserved `AUTOCONF.ASM` is 7,109 lines, compared with 472 lines in the original article transcription.

## January 11, 1996: Preserved Beta Build

`CMPDATE.EXE` updated the `compiled_date` string before each build using day/month/year order. The preserved source and both English and French `AUTOCONF.SYS` binaries contain:

```text
assembl.: 11/01/96 (14:26)
```

This dates the preserved 3.00 beta 2 driver build to **January 11, 1996 at 14:26**. The matching timestamp in both localized binaries indicates that they were produced from the same build cycle, with different generated message includes.

The final DOS packaging script built both language editions, regenerated the compressed message includes with `CODE2.EXE`, compiled the C utilities, assembled the driver and manuals, created `ACNF3B1E.ZIP` and `ACNF3B1F.ZIP`, and tested both archives.

## 1996: MegaBoot, a Spiritual Successor

David Jilli of DSF Productions wrote [MegaBoot](https://github.com/dblock/megaboot) in 1996 as a spiritual successor to Autoconf. MegaBoot retained the idea of selecting among multiple configurations while DOS processed `CONFIG.SYS`, but presented the choices in a full-screen menu and rewrote the in-memory configuration so DOS continued with only the selected block.

MegaBoot was written while David and I spent time in the basement of Infomaniak in Carouge, Switzerland.

## September 5, 2011: The Later Source Resurfaces

I found the later Autoconf source and release files and put them on GitHub. They included the evolved assembly source, English and French 3.00 beta 2 binaries, manuals, release histories, build tools, and companion utilities. The date records when the files resurfaced, not when they were developed; their contemporary strings and comments place them primarily in 1993–1996.

## 2015: The Original Download Is Retired

In my 2009 retrospective, [“Autoconf, World's Best Multiple Configurations Software”](https://code.dblock.org/2009/09/22/autoconf-worlds-best-multiple-configurations-software.html), I described Autoconf as my first commercial product and linked to its full x86 assembly source. In a 2015 update, I retired the old software download, replaced the historical product-page link with an Internet Archive copy, and directed readers to the source on GitHub.

## September 27, 2026: The Original Source Is Identified

The original program was traced to Julien Pommier's article in SVM issue 88. Its seven pages were extracted, both printed listings were transcribed and corrected, and the recovered programs were successfully assembled under DOS. The scan, source, and reproducible build instructions were then added to GitHub alongside the later version.

## Chronology at a Glance

| Date | Version or event | Evidence |
| --- | --- | --- |
| November 1991 | Julien Pommier's original Autoconf published in SVM no. 88 | Article scan and recovered listing |
| After November 1991 | Daniel manually copies the listing and begins extending it | Project provenance and later built-in help |
| Undated | Versions 1.0–1.54 | Ordered English and French release histories |
| March 1993 | MS-DOS 6.0 introduces native multiple configurations | DOS 6 documentation and the reproduced MS-DOS 6.22 demo |
| November 23, 1993 | Version 2-era name-parsing work | Dated comments in `src/AUTOCONF.ASM` |
| 1993 | `CODE2` text encoder | Copyright string in `src/CODE2.CPP` and `CODE2.EXE` |
| June 16, 1994 | Version 2.41 last modified | English and French release histories |
| July 3–8, 1994 | Video and keyboard routines revised | Dated comments in `src/AUTOCONF.ASM` |
| 1994 | `READCONF.EXE` generation | Copyright text in English and French C sources |
| August 1995 | Windows 95 support described as final | English and French message sources |
| September 13, 1995 | `iLINE` line editing implemented | Dated comments in `src/AUTOCONF.ASM` |
| September 1995 | Version history signed; 3.00 beta 2 and planned `iLOOM` documented | `WHATSNEW.ENG` and `WHATSNEW.FR` |
| November 1995 | French 3.00 release-history banner revised | `WHATSNEW.FR` |
| January 11, 1996, 14:26 | Preserved English and French 3.00 beta 2 drivers assembled | Embedded source and binary build timestamp |
| 1996 | [MegaBoot](https://github.com/dblock/megaboot), a spiritual successor to Autoconf, written by David Jilli | Recovered MegaBoot source and embedded copyright |
| September 22, 2009 | [A retrospective on Autoconf](https://code.dblock.org/2009/09/22/autoconf-worlds-best-multiple-configurations-software.html) is published | Contemporary blog post |
| September 5, 2011 | Later source and binaries found and published on GitHub | GitHub publication date |
| 2015 | The retrospective is updated to retire the old download and direct readers to GitHub | Update to the 2009 blog post |
| September 27, 2026 | Original article identified and its source listings recovered | Article scan, transcriptions, and DOS build |

## Sources and Limitations

The principal sources are:

- [`original/SVM-88-Autoconf-pages-227-233.pdf`](original/SVM-88-Autoconf-pages-227-233.pdf), the original November 1991 article and printed source;
- [`original/AUTOCONF.ASM`](original/AUTOCONF.ASM) and [`original/READCONF.ASM`](original/READCONF.ASM), searchable transcriptions of the listings;
- [`src/WHATSNEW.ENG`](src/WHATSNEW.ENG) and [`src/WHATSNEW.FR`](src/WHATSNEW.FR), parallel release histories;
- [`src/AUTOCONF.ASM`](src/AUTOCONF.ASM), including dated implementation comments and the final embedded build timestamp;
- [`src/AUTOCONF.ENG`](src/AUTOCONF.ENG) and [`src/AUTOCONF.FR`](src/AUTOCONF.FR), readable message and help sources;
- [`src/CODE2.CPP`](src/CODE2.CPP), [`src/HELP.INC`](src/HELP.INC), and the runtime decoder in `src/AUTOCONF.ASM`, which document the custom message codec;
- [`src/DT.BAT`](src/DT.BAT) and [`src/DOIT.BAT`](src/DOIT.BAT), which preserve the DOS build and packaging process.
- [“Autoconf, World's Best Multiple Configurations Software”](https://code.dblock.org/2009/09/22/autoconf-worlds-best-multiple-configurations-software.html), my 2009 retrospective and its 2015 update.

The original article is authoritative for the 1991 program. The later `WHATSNEW` files are contemporary but informal: they contain spelling errors, repeated item numbers, slight differences between languages, and many releases without dates. File modification times from the recovered archive are not treated as historical evidence. Dates inferred from source comments are tied to the specific code they annotate and do not necessarily represent public release dates.
