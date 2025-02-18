# Introduction

In 2025, Bambulab decided to potentially significantly restrict the functionality of their printers - through a firmware update. You can learn all about it starting with [Louis Rossmann's video](https://www.youtube.com/watch?v=aIyaDD8onIE).

I obviously do not want to run into issues such as

- Bambulab bricking my connectivity to Orca Slicer (imminent)
- Bambulab bricking my printers (speculative, but possible)
- Bambulab switching to a subscription model (speculative, but possible)


Bambulab could do this using just a firmware update. Since my firmware is running just fine, and I love using Orca Slicer all the while, I hate if other people tell me what I'm allowed to do, I decided to lock down my system. I'm going to describe the precise steps I took here. Here are the steps:

1. Switch the printer to LAN mode
   - Give it a static IP on my network
   - Restrict it's access to the Internet
2. Restore the ability to use the camera feed locally
3. Restore the ability to control the printer remotely


So before you read on, here's what is possible

1. You can block the printer's access to the internet and run it completely locally
2. You can still use the camera feed through your slicer (like, Orca Slicer)
3. You can also use the camera feed through third party applications
4. You can not only view the camera feed remotely, but even control the printer remotely, without the "Bambulab Handy App".


Sounds good? Let's dive right in.

# Switch to LAN Mode

## Assign a static IP address

We are first going to assign a static IP address to our printer. This will be needed way further down the line. To do so, we go to the printer panel:


![](img/x1c-nw.png)

We copy the MAC address starting with `08:FB:`. We then go to our router, which in my case is an Asus ZenWiFi Pro XT12 with the Merlin firmware. The model of the router is not really that important at this stage, as almost all routers will allow you to go into the DHCP settings and assign a static IP Address to a given MAC Address. In our case, my printer is going to have the `192.168.1.252`:

![](img/asus.png)

## Restrict the Printer's Internet Access

We really do not want the printer to access the internet *unless we say so*. This part is not necessarily required if you would trust Bambulab to not remotely enforce a firmware update (which they allow themselves to do throughout their fine print). This step will depend on your router; as I have the Merlin firmware, I can log into the command line of the router, and add a file `/jffs/scripts/nat-start.sh` which I have copied for you [here](src/router/jffs/scripts/nat-start.sh). Copy that file to the `/jffs/scripts` directory and make it executable using

```bash
chmod 755 /jffs/scripts/nat-start.sh
```

You can start that script from the router's command line without any parameters; this is what the router will do when it starts. Alternatively, you can also do this to show the other options:

```bash
admin@ZenWiFi_Pro_XT12-FD80:/jffs/scripts# ./nat-start -h
Usage: nat-start [OPTION]
Manage NAT and printer firewall rules

Options:
  -h, --help     Show this help message
  -D, --delete   Delete all rules
  -s, --show     Show current rules

Without options, rules will be added (default behavior)
```

Once you have done that, the device with the IP address `192.168.1.252` (which will be our printer soon) won't be able to access the internet, but it will be remotely accessible from anywhere within our network.

The actual rules to restrict the access that we set are these:

```bash
iptables -A INPUT   -s 192.168.1.0/24  -d 192.168.1.252  -j ACCEPT
iptables -A OUTPUT  -d 192.168.1.0/24  -s 192.168.1.252  -j ACCEPT
iptables -A FORWARD -s 192.168.1.252 ! -d 192.168.1.0/24 -j DROP
iptables -A OUTPUT  -s 192.168.1.252 ! -d 192.168.1.0/24 -j DROP
```


## Set the Printer to the new IP Address

We go back to the printer panel and tap on the Wifi network that we currently are attached to, and choose `Forget`, to then join it again. We verify that the printer now has the correct IP address:


![](img/x1c-nw.png)

## Check things out

We should be able to reboot the printer; in my case it had always been asking for whether I want to do a firmware upgrade; this message now does not appear anymore.


# Restore the Camera Feed Locally

## Switch on LAN Only and Lan Mode Liveview

To restore local access to the camera feed, we go to the printer and look at this page:

![](img/x1c-lanmode.png)

We need to take a copy of our "Access Code" as well as of the Serial Number, which is next to "Device info". Then we switch on "LAN Only" and also "LAN Mode Liveview".

## Connect the Slicer


In Bambu Studio, we go to the Device Page and add the printer locally; it was necessary here to enter both the access code as well as the serial number, and the IP address.
Orca Slicer detected the printer right away and just asked for the access code. I have noticed that both Orca Slicer and Bambu Studio sometimes need a while, and perhaps
a failed attempt, to connect to the printer.

## Create an independent Camera Viewer

You actually do not need the Slicer to view the camera image. Using `ffmpeg`, you can connect directly to the camera screen.

First, we install `ffmpeg` using [Homebrew](https://brew.sh/):

```bash
brew install ffmpeg
```

Then we can very simply start the camera view like so:

```bash
ffplay -hide_banner rtsps://bblp:accesscode@192.168.1.252:322/streaming/live/1 2>/dev/null 1>&2
```

On a Windows or Linux machine, it should be similar. I was not able to make VLC work, but this is a good workaround for me.


# Restore the Remote Operation

You can restore the ability to remotely operate the printer and see the camera feed using [Home Assistant](https://homeassistant.io/). I have Home Assistant running on a Raspi 4 and just had to add the printer to it.
I am not going to go through the entire configuration, as there's a [great video](https://www.youtube.com/watch?v=bVcYGfN2AFU) out there that shows all of it. I'm listing here the source files that I created to embed them in my dashboards.
Those have been created mostly automatically for me when I configured the printer in Home Assistant (so in those files you're going to find the name I gave to my printer, like `x1c`):


1. [Camera View](src/ha/ha-camera.yaml): You need to put your serial number in here, replacing `_00mSERIAL_`
2. [Printer Control](src/ha/ha-camera.yaml): This allows me to pause/resume/stop the printer. The printer id in there was generated for me by Home Assistant.
2. [Printer View](src/ha/ha-printer.yaml): That printer id in there was generated for me by Home Assistant
3. [AMS View](src/ha/ha-ams.yaml): Similarly, that AMS id in there was generated for me by Home Assistant

With those changes, I can see the printer even on my mobile phone:

![](img/ha-x1c.png)

as well as all of my four AMS:

![](img/ha-ams.png)

I can even see and operate the printer remotely, as I have just added a port mapping to my home assistant within my browser (and have a static IP or would otherwise be using a dyndns sort of client).

And there you have it: The printer is now mine, and mine only. Hence the name of this repository.

# License

This description is released under the [WTFPL License](https://en.wikipedia.org/wiki/WTFPL).









