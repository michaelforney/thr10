This repository contains some tools and scripts for working with
and patching Yamaha THR10/THR10c/THR10x firmware.

### Requirements

- armeb-none-eabi toolchain
- Original THR10c firmware (`thr10_ver104c_20120803.bin`)

### Supported firmwares

| Name | SHA256 |
| ---- | ------ |
| thr10_ver104c_20120803.bin | b08a90c2a6ea4b0c2ab17bde10754b29641f1503eafd62015519af36feef239c |

If you have a different firmware, please contact me and I can help
with adding support for it.

### Extracting firmware

No hardware modification is required to extract the firmware from
your device.

1. Boot into update mode by turning on the amp while holding the
   TAP/TIME button, then once the LED display turns on, press the
   TAP/TIME button 5 times within the next 4 seconds. After 6 more
   seconds, the device will reboot into update mode and show a `U`
   on the LED display.
2. Connect the amp to a computer with a USB cable. On Linux, identify
   the THR10 MIDI hardware port by finding it in the output `amidi -l`
   (e.g. `hw:1`).
3. Start recording MIDI from the device. On Linux, this can be done
   with `arecordmidi -p THR10 fw.mid`.
4. Send a `DTA1ROMR` sysex command (`F0 43 7D 50 44 54 41 31 52 4F 4D 52 02 F7`)
   to the device to trigger a firmware dump. On Linux, this can be
   done for `hw:1` with `amidi -p hw:1 -S 'F0 43 7D 50 44 54 41 31 52 4F 4D 52 02 F7'`.
5. Wait for 2.5 minutes for the firmware dump to complete. You can
   monitor the progress by watching the MIDI events from the device.
   On Linux, this can be done with `aseqdump -p THR10`. The dump
   is complete when you see a `DTA1CSUM` command, which looks like
   `F0 43 7D 70 44 54 41 31 43 53 55 4D XX F7`, where XX varies per
   firmware version.
6. Stop the MIDI recording.
7. Extract the binary firmware from the MIDI sysex messages using
   `lua tools/midtobin.lua fw.mid fw.bin`. If successful, you should
   see the message `checksum matched`.
8. Calculate the SHA256 sum of your dumped `fw.bin` to find the
   firmware it matches in the [Supported firmwares](#Supported
   firmwares) table, and rename it appropriately.

### Building

Build with `FW` set according to your firmware version.

```
make FW=thr10_ver104c_20120803.bin
```

The raw patched firmware will be built at `thr10.bin`, as well as
a MIDI update file `thr10.mid`.

### Flashing patched firmware

> [!CAUTION]
> Make sure you have backed up your firmware before proceeding.
> Yamaha only provides firmware for the original THR10 model. If
> you flash your THR10c or THR10x and then want to restore the
> original firmware, you will need a backup of the original firmware.

> [!WARNING]
> Proceed at your own risk. This process only overwrites the main
> firmware (DTAm) while leaving the boot firmware containing the
> updater intact (DTAb), so it should be fairly safe, but even so,
> I am not responsible for any damage to your device.

Once you have built your new patched firmware `thr10.mid`, you can
flash it to the device.

1. Boot into update mode by turning on the amp while holding the
   TAP/TIME button, then once the LED display turns on, press the
   TAP/TIME button 5 times within the next 4 seconds. After 6 more
   seconds, the device will reboot into update mode and show a `U`
   on the LED display.
2. Connect the amp to a computer with a USB cable.
3. Start the flashing process by playing the MIDI update to your
   device. On Linux, this can be done with `aplaymidi -p THR10 thr10.mid`.
4. For the first 16 seconds, the LED display will show the two
   triangle icons used during tuning. This indicates that the flash
   is being erased prior to writing. After this, the green dot will
   start flashing while the new firmware is written.
5. If successful, the display will show `E`, `n`, `d` in a loop.
6. Reboot into the new firmware by power cycling the amp.

## Firmware modifications

### Speaker simulation bypass

Each of the amp's firmware models has an associated speaker cabinet
emulation. This can be changed over MIDI using the THR Editor or
THR Librarian software (or sending sysex commands manually). The
FLAT mode uses a flat speaker response, effectively disabling the
speaker emulation.

If the amp is modified with a speaker output jack and hooked up to
real guitar speakers, you may want to disable the speaker emulation.
This can be done using the software mentioned above, and saved to
a preset, but as soon as the amp model is changed, the amp will
revert to the default speaker type for that model.

This modification adds a speaker simulation bypass mode that can
be toggled by pressing and holding the TAP/TIME button and then
pressing the preset 1 button.

When speaker bypass mode is enabled, the LED display will show the
two triangle icons used in tuning mode and the speaker emulation
will be disabled. When the amp model is changed or a preset is
loaded, the speaker emulation will remain disabled.

When speaker bypass mode is disabled, the device functions normally.
