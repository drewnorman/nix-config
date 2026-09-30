# OBS into Google Meet

After `just switch`, reboot if the update installed a new kernel. The virtual camera kernel module must match the running kernel. If the OBS Controls dock has no **Start Virtual Camera** button, compare `uname -r` with `ls /run/current-system/kernel-modules/lib/modules` and reboot when they differ. Then start OBS and Chromium.

1. In OBS, create scenes for the webcam, birthday reveal, and any clips. Add the webcam as a Video Capture Device and clips as Media Sources. Assign scene and source hotkeys in **Settings → Hotkeys**. Studio Mode lets you preview a scene before taking it live.
2. In **OBS → Settings → Audio → Advanced**, set **Monitoring Device** to **MeetBus**. Add your microphone as an Audio Input Capture source using its **PulseAudio/PipeWire** device, rather than opening the webcam's ALSA device directly. In **Advanced Audio Properties**, set the microphone and any clip audio meant for the call to **Monitor and Output**.
3. Click **Start Virtual Camera** in OBS. In Meet, select **OBS Virtual Camera** as camera and **MeetMic** as microphone. Keep Meet's speaker output on headphones; don't route Meet's incoming audio into OBS.
4. Test in a private Meet with another device before the call. Check your voice, each clip, and scene hotkeys. If effects sound muffled, try Meet's noise cancellation setting during the test.

The virtual camera carries video only. OBS sends audio to the MeetBus sink, and MeetMic exposes its monitor as a microphone that Chromium can list. `pavucontrol` can help inspect the routing if a device is missing.

OBS saves scenes and profiles automatically in `~/.config/obs-studio`. This directory is persisted across reboots. To keep a portable backup, use **Scene Collection → Export** in OBS and save the JSON file in `documents` or another persisted directory.
