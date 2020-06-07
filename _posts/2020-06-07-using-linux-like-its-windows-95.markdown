---
layout: post
title: getting my computer to play the windows 95 startup sound
description:
  a recount of the process it took to get my Arch Linux computer to play a sound when GDM loaded
  (i.e. at boot)
categories: code
---

Yesterday i had what i called a "profoundly terrible idea". What is that terrible idea, you may ask?
I'll start with the payoff:

> last night i had a profoundly stupid idea, and today i got it working
>
> (embedded video)
>
> ~[@QuietMisdreavus, 2020-06-07 11:19 AM -06:00][video-tweet]
>
> [video-tweet]: https://twitter.com/QuietMisdreavus/status/1269680291796271104

I wanted my computer to play the Windows 95 startup sound when it booted up, like i was back in the
90's and playing sound when the computer was ready was cool and expected. Mostly because i thought
it was funny and it seemed like something i could configure relatively simply.

Some background: My desktop currently runs Arch Linux, which i've been customizing over the last
week or so for fun. I've used Arch a lot in the past, but i hadn't used it as a "daily driver"
desktop OS for a while, and i wanted to try out GNOME 3 as a desktop environment. I'd recently set
up a common-use computer with Ubuntu for my roommates and i thought that it would be nice to use
that kind of environment for my personal computer. I have it in a spot where i like it, and over
the last few days i've just been getting more and more personal with the tweaks i've been putting
in.

Which brings us to today's post. I could find [a sample of the Windows 95 startup chime][win95]
fairly easily. But after that, the trick became how to wedge that into the startup process of my
computer. I knew that the first thing that my computer ran when it could get a graphical environment
running was [GDM], so i started looking at that Arch Wiki article to see what could be done to
customize it. But the methods it had for customizing it didn't mention anything about playing things
at startup, and digging around the method it mentioned (logging in as the GDM user and setting
configuration options directly) also turned up nothing.

[win95]: https://www.youtube.com/watch?v=miZHa7ZC6Z0
[GDM]: https://wiki.archlinux.org/index.php/GDM

On a lark, i looked at the file listing for the GDM package on Arch, and found a folder named
`/usr/share/gdm/greeter/autostart/`, with a file inside called `orca-autostart.desktop`. Since
[Orca] is the screen-reader program that GNOME uses, i figured this file was there so that the
display manager could be read out to people who couldn't read the screen. However, i wanted to know
if i could throw other `.desktop` files in there to make them start automatically as well. This
lined up with [another article i saw][ubuntu-sound-article] about playing a sound when you logged
in on Ubuntu.

[Orca]: https://wiki.gnome.org/Projects/Orca
[ubuntu-sound-article]: https://vitux.com/configure-custom-start-up-sound-in-ubuntu-18-04/

Since i didn't have this "Startup Applications" program sitting around to configure it visually, i
would have to create this entry myself and throw it in the right place. [`.desktop` files] are the
Linux world's answer to desktop shortcuts or application menu entries. It's easy enough to make one
of your own if you know the basic format and what you want it to run. Since the goal of this
shortcut was "play a sound file", i figured the thing to run would be something like `paplay
/path/to/sound-file.ogg`. (`paplay` is a command to play an audio file with PulseAudio, a common
audio system on Linux. It's also the command used in the earlier post about Ubuntu.)

[`.desktop` files]: https://wiki.archlinux.org/index.php/Desktop_entries

The file i came up with wound up looking like this:

```desktop
[Desktop Entry]
Type=Application
TryExec=paplay
Exec=paplay /usr/share/gdm/startup.ogg
Terminal=false

Name=Play sound at startup
```

After writing this file to `/usr/share/gdm/greeter/autostart/startup sound.desktop` and copying the
audio file to `/usr/share/gdm/startup.ogg`, i rebooted my computer to see if it would work. And...
it did! Kinda!

The first version of the video in the tweet had audio that was a little thin-sounding compared to
the final version. I didn't realize it at first, and just thought that it was because the volume was
low. After a while, i realized what was going on. It was playing through the speaker in my monitor!
I didn't want this, primarily because it sounded worse than going through my regular speakers, but
also because it meant i couldn't mute it by turning off my speakers, like i would regularly. So i
had to figure out what was going on.

I'd seen a similar situation on the common-use Ubuntu computer i mentioned, where it would default
to an unused audio device instead of the built-in speakers, so i tried looking at those avenues
first. PulseAudio has a "default preferences" file it loads, so i tried to set the default
audio-output device there, by adding a `set-default-sink <analog stereo line-out device>` line to
`/etc/pulse/default.pa`. Unfortunately, this didn't work, much like it didn't on the Ubuntu
computer.[^pa-per-user] I also tried disabling the HDMI output device by settings its profile to
`off`, but that only caused it to mute the sound when it was trying to play.

[^pa-per-user]: So what happened here was interesting, and leads into the eventual solution.
    Apparently, PulseAudio saves which audio device a given user used last in their user folder as the
    "default device". So if you look in `~/.config/pulse/`, you can see a couple files called
    `<hash>-default-sink` and `<hash>-default-source`. These files have the full names of the device
    that PulseAudio will try to load when that user starts up the PulseAudio daemon. The problem i had
    run into was, once these were set, just saying "the default device is this, actually" in the
    global config file wasn't going to override that! That was part of why i needed to fully disable
    the HDMI output from the GDM user - it was still just going to use that device no matter what.

Eventually, what i had to do was to *sign in as the GDM user* using the command listed in the Arch
Wiki page (`machinectl shell gdm@ /bin/bash`) and try to configure PulseAudio from there.
Unfortunately, this hit another hurdle because PulseAudio is only allowed to be running from one
user at a time, and once i've logged in via GDM i've fully taken it over.

Instead i had to do this *while GDM was still running*, by pressing `Ctrl+Alt+F2` to open a
different TTY, and sign in there in a console session, so i wouldn't try to start PulseAudio. From
there i could open the shell with the GDM user as before and try to set things up. After confirming
the setup with `pacmd list-sinks` and `pacmd list-cards` to look at what GDM was seeing from
PulseAudio, i was able to disable the HDMI output with `pacmd set-card-profile 0 off` to turn off
the HDMI output entirely, for the GDM user. After doing this, i rebooted again to see what that did.

And after that, it was still silent! But the problem then was that the volume slider in GDM itself
had been dialed all the way down. After setting the volume from the system menu in the corner before
logging in and rebooting *once more*, i was able to hear the beautiful sounds of the Windows 95
startup sound coming from my Linux computer in 2020.

-----

I don't have a moral here about things being complicated or open or whatever. I knew going in that
this was a stupid idea, and i'm thankful that i was even able to pull it off. If i had tried this a
few years ago, i would probably have given up midway through, because i wouldn't have known to
bother with the per-user PulseAudio settings or have wanted to bother with it. This wasn't something
that had a guide on the internet that had all the steps for my specific situation - for one, i'm
running Arch Linux, whose entire ethos is some variation of "do it yourself". That's partly why i
wanted to write all this down, in case someone else wanted to try the same thing.

-----
