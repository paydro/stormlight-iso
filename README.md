# stormlight-iso

This project builds an Ubuntu 18.04 ISO to [install Ubuntu
unattended](https://help.ubuntu.com/lts/installation-guide/i386/apb.html) (no
keyboard interaction) on Intel NUC 8 Core i3 machines.

This project assumes:

* Installation of Ubuntu via USB stick
* ISO built on a Mac OSX machine
* Intel NUC has a static IP assigned to it to SSH to the machine
* A USB stick with minimum 100MB of space

The project is designed to minimize the amount of physical effort to set up an
Intel NUC because the author is lazy and forgetful. Also, the author has several
Intel NUCs and manually entering in configuration value is error prone. Here's
what the installation process looks like.

1. Build the `stormlight.iso` with preseed config and an ssh public key
2. Create a bootable USB from the `stormlight.iso`
3. Walk over to the Intel NUC, plug in USB stick, and power on the machine
4. Wait until the machine powers itself down after the installation (roughly
   10-15 mins). "Look ma, no keyboard!"
5. Unplug USB stick and power on the machine.
6. Walk back to your computer and SSH into the machine.

That's it!

## Table of Contents

* [Base Operating System Properties](#base-operating-system-properties)
* [Usage](#usage)
  * [Create a bootable USB thumb drive](#create-a-bootable-usb-thumb-drive)
  * [Installation](#installation)
* [Customizing Preseed Configuration](#customizing-preseed-configuration)
  * [Optimizing the Change-Install-Validate-Repeat](#optimizing-the-change-install-validate-repeat)
* [Testing](#testing)
* [Contributing](#contributing)
* [Author](#author)
* [FAQ](#faq)


## Base Operating System Properties

Once the ISO is built, the ISO installs a minimal Ubuntu 18.04 Server with the
following properties:

* Installs `openssh-server` package and disables password logins.
* Creates the user `hoid` with `sudo` privileges. `hoid` is locked down and
  password is randomly generated before the next boot of the machine. The public
  ssh key for `hoid` is configured in `config/authorized_keys` and is required
  to build ISO.
* The first `nvme` device is used as the root partition. The device is formatted
  using `ext4`.
* Disables swap

## Usage

`stormlight-iso` depends on homebrew to install dependencies.

```bash
git clone https://github.com/paydro/stormlight-iso.git
make install-deps
```

Now add your publich SSH key to the repo

```bash
cat /path/to/ssh_key.pub > config/authorized_keys
```

Finally, create the ISO with `make`

```bash
make
```

`stormlight.iso` is now available in the root directory of the repo.

### Create a bootable USB thumb drive

I like to use [balena etcher](https://www.balena.io/etcher/). It's a GUI app and
extremely fast (almost instant). The downside is the use of a mouse. You could
also use [`hdutil` and
`dd`](https://www.google.com/search?q=make+bootable+usb+mac+commandline) to
create the thumb drive, but in my tests it took 40 seconds. I'm allergic to
slow, so the mouse and GUI are my preferred choice.

Once youre thumb drive is ready, you can install the OS.

### Installation

There's not much to say here.

Stick the thumb drive in, boot the NUC, and wait for the machine to power down.

Once the machine has powered down, remove the thumb drive, and boot the machine
once more.

Once the NUC is online, you can now SSH to the instance:

```bash
ssh -i path/to/ssh_key hoid@<NUC IP>
```

Done!

## Customizing Preseed Configuration

If you don't like the defaults provided by this project (how dare you not like
[Hoid](https://coppermind.net/wiki/Hoid)?!), then this project includes tools to
help you make an ISO for your own needs.

First, know that most of the code in this repo is based around automating the
steps from [Ubuntu's appendix on unattended
installation](https://help.ubuntu.com/lts/installation-guide/i386/apb.html) as
well as the [wiki page on CD
customization](https://help.ubuntu.com/community/InstallCDCustomization). The
project boils down customizing the installation by modifying a few files:

1. Modify `config/preseed.cfg` (see and possibly Ubuntu's
   [example](https://help.ubuntu.com/lts/installation-guide/example-preseed.txt)
   for more information)
2. Modify `config/post-install.sh` if needed to suit your needs.
   `post-install.sh` is where the `hoid` user is locked down and the password is
   regenerated.
3. Run `make`

That's it.

If you're overwhelmed, then definitely read through the Ubuntu appendix linked
above.

### Optimizing the Change-Install-Validate-Repeat

Changing the preseed config and testing that it works is tedious with a real
Intel NUC (you know, thumb drive, walking to the machine, allergic reactions to
slow, etc...). So this project includes `Makefile` targets to build a virtual
machine (VM) using Virtualbox. The VM mimics the configuration of an Intel NUC
with configuration for testing.

* EFI enabled
* Two storage controllers:
	* `nvme` for the base installation
  * `ide` for the bootable dvd drive (`stormlight.iso` is loaded here because
    virtualbox cannot boot from a USB at this point)
* Port forwarding of VM's port `22` to host machine's port `2522`

To build the VM, run:

```bash
make vm
```

This will create a VM named `stormlight-nuc`, create the `stormlight.iso`, boot
the VM with the ISO, wait for the OS to install and power off, and finally boot
the VM again. By default, the VM has networking configuration to allow SSH
connections on your machine's port 2522. So after the build completes, execute
the following to connect to the VM:

```bash
ssh -i /path/to/your_ssh_key -p 2522 127.0.0.1
```

## Testing

This project also includes some smoke tests using
[bats](https://github.com/sstephenson/bats). By default, it assumes you've built
the VM mentioned above. To run tests:

```bash
make test
```

## Contributing

Pull requests are welcome!

## Author

[paydro](https://tightlycoupled.io/about/)

## FAQ

### Can I use this project to build an ISO for another type of machine?

Yes! While this project is tailored for my personal home cluster, the
configuration can be modified to fit any type of machine. Simply change the
files in `config` to match your needs and then run `make`.

### Why is it called `stormlight-iso`?

The name `stormlight` is what I named my home Intel NUC cluster. Hence,
`stormlight-iso`. But, "stormlight" comes from Brandon Sanderson's [Stormlight
Archive](https://coppermind.net/wiki/The_Stormlight_Archive) series -- one of my
favorite authors and on-going series of books.

For my home cluster, I name the Intel NUCs after different
[surgebinders](https://coppermind.net/wiki/Surgebinding). :)

### Why don't you use PXE boot?

Honestly, I haven't educated myself on it yet. Also, I don't have another
machine to do it with. I might look into a raspberry pi in the future. For now,
this works well enough that I can forget about this setup and rely on my
bootable USB stick to tear down and reconfigure a machine.

