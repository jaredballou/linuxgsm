<h1>NEW FORK, NEW RULES</h1>
Use the new lgsm-core script as a starting point (<a href="https://github.com/jaredballou/linuxgsm/blob/master/_MasterScript/lgsm-core">GitHub HTML</a> - <a href="https://raw.githubusercontent.com/jaredballou/linuxgsm/master/_MasterScript/lgsm-core">Direct Download</a>).
Running that script launches the installer, which pulls the list of games from the gamedata directory.
Select the game server you wish to install, and it will ask a few questions as to where to install it.
At this point, the script itself is deployed. Now continue on with the normal instructions.
<h2>How to deploy the new lgsm-core script</h2>
Create a user for your game server if you don't have one already, it's best not to "upgrade" classic LGSM with this new script since it is so different. Go to the location you want to install LGSM (use the home directory if you're not sure). Then, run these commands:
```bash
curl https://raw.githubusercontent.com/jaredballou/linuxgsm/master/lgsm-core -O lgsm-core
chmod +x lgsm-core
./lgsm-core
```
You will now be presented with a menu
<div><img src="https://github.com/jaredballou/linuxgsm/blob/master/images/lgsm_install_menu.png" alt="LGSM Installer Menu"></div>
Select the game you want to install, and press Enter. The installer will ask you a few more questions, namely where to install the LGSM instance for the game you chose. Just press Enter to select the current directory.
<div><img src="https://github.com/jaredballou/linuxgsm/blob/master/images/lgsm_install_exec.png" alt="LGSM Installer Exec"></div>
At this point, the new instance works (mostly) just like the classic LGSM scripts. As of right now, there is no "self-update" functionality for lgsm-core and deployed instances, but it's in the works.
<h2>Benefits of the new fork</h2>

<ul>
<li>One script to rule them all.
</li><li>Game server support provided via extensible gamedata system to reduce duplication and increase ability to support more games
</li><li>Decent enough config backend that exposes most of what game server admins want in flat files
</li><li>Creates separate directory for all LGSM files. Defaults to 'lgsm' in the same directory as the script. The structure of this directory is:
<ul>
<li><b>functions</b> Functions for LGSM. These are like modules, whatever functionality you need from LGSM is mostly handled by these scripts.
</li><li><b>gamedata</b> Data files that describe the games that can be installed. There is a README.md in this folder with more detail on how this system works. This is still very much a work in progress, and may have some serious changes made. In addition, a majority of the games have NOT been tested with the new lgsm-core and gamedata system, so I'd appreciate anyone that wants to help me sort out the remainder of the games.
</li><li><b>servers</b> Each game gets its own directory, for instance 'insserver' for the Insurgency LGSM
<ul>
</li><li><b>cfg</b> Server configuration files. These files are split out from the script so that upgrading the script doesn't require manual editing, the data and code are being separated.
<ul>
<li><b>_default.cfg</b> Generated regularly by the main script, this will always be overwritten so do not edit it if you want to keep your changes!
</li><li><b>_common.cfg</b> The config executed by all your instances. Put defaults for your deployment here, for example ip is a common setting.
</li><li><b>$instance.cfg</b> These configs are created for each instance of LGSM. For example, if I install insserver and create another instance by symlinking to it with "inspvpserver", I will have insserver.cfg and inspvpserver.cfg files here. These files will never be overwritten by the LGSM.
</li>
</ul>
</li><li><b>log</b> Log files. Includes script, console, server by default. I am in the process of defining logging settings in gamedata and cfg files to add flexibility and intelligence here.
</li><li><b>tmp</b> These are "temp files" generated by the gamedata parser. Feel free to take a look at them, but they get regenerated every time the script is ran, so don't make any changes here that you want to keep. Make the changes in the cfg files.
</li>
</ul>
</li><li><b>tmp</b> General purpose temporary file storage.
</li>
</ul>
</li><li><b>Better GitHub integration</b> Supports using Git hashes to check for updated files. Self-bootstrapping sort of works....
</li><li><b>Config files</b> for defaults are in a central location, but will be templated and moved to gamedata at some point.
</li><li><b>Dependencies</b> handled in standard way via gamedata files. Different versions of the files are referenced by MD5 hashes for a widely supported method of identifying binary content.
</li><li><b>SteamCMD and server support</b> for beta and workshop files
</li><li><b>sourcemod</b> command to install latest MetaMod and SourceMod to your game server instance
</li>
</ul>
Probably a lot more, this started off as a POC of hacks and has sort of morphed into a major undertaking all its own. Below is the original upstream README, since the function of the script has been kept as close as possible to legacy.

<h1>Linux Game Server Managers</h1>
<a href="http://gameservermanagers.com"><img src="https://github.com/dgibbs64/linuxgsm/blob/master/images/logo/lgsm-full-light.png" alt="linux Game Server Managers" width="600" /></a>

[![Build Status](https://travis-ci.org/dgibbs64/linuxgsm.svg?branch=master)](https://travis-ci.org/dgibbs64/linuxgsm)
[![Under Development](https://badge.waffle.io/dgibbs64/linuxgsm.svg?label=Under%20Development&title=Under%20Development)](http://waffle.io/dgibbs64/linuxgsm)

The Linux Game Server Managers are command line tools for quick, simple deployment and management of various dedicated game servers and voice comms servers.

<h2>Hassle-Free Dedicated Servers</h2>
Game servers traditionally are not easy to manage yourself. Admins often have to spend hours just messing around trying to get their server working. LGSM is designed to be a simple as possible allowing Admins to spend less time on management and more time on the fun stuff.

<h2>Main features</h2>
<ul>
	<li>Backup</li>
	<li>Console</li>
	<li>Details</li>
	<li>Installer (SteamCMD)</li>
	<li>Monitor (including email notification)</li>
	<li>Update (SteamCMD)</li>
	<li>Start/Stop/Restart server</li>
</ul>
<h2>Compatibility</h2>
The Linux Game Server Managers are tested to work on the following Linux distros.
<ul>
	<li>Debian based (Ubuntu, Mint etc.).</li>
	<li>Redhat based (CentOS, Fedora etc.).</li>
</ul>
Other distros are likely to work but are not fully tested.
<h3>Specific Requirements</h3>
<ul>
	<li><a href="https://github.com/dgibbs64/linuxgsm/wiki/Glibc">GLIBC</a> >= 2.15 recommended [<a href="https://github.com/dgibbs64/linuxgsm/wiki/Glibc#server-requirements">specific requirements</a>].</li>
	<li><a href="https://github.com/dgibbs64/linuxgsm/wiki/Tmux">Tmux</a> >= 1.6 recommended (Avoid Tmux 1.8).</li>
</ul>
<h2>FAQ</h2>
All FAQ can be found here.

<a href="https://github.com/dgibbs64/linuxgsm/wiki/FAQ">https://github.com/dgibbs64/linuxgsm/wiki/FAQ</a>
<h2>Donate</h2>
If you want to donate to the project you can via PayPal, Flattr or Gratipay. I have had a may kind people show their support by sending me a donation. Any donations you send help cover my server costs and buy me a drink. Cheers!
<ul>
<li><a href="http://gameservermanagers.com/#donate">Donate</a></li>
</ul>
<h2>Useful Links</h2>
<ul>
	<li><a href="http://gameservermanagers.com">Homepage</li>
	<li><a href="https://github.com/dgibbs64/linuxgsm/wiki">Wiki</li>
	<li><a href="https://github.com/dgibbs64/linuxgsm">GitHub Code</li>
	<li><a href="https://github.com/dgibbs64/linuxgsm/issues">GitHub Issues</li>
	<li><a href="http://steamcommunity.com/groups/linuxgsm">Steam Group</li>
	<li><a href="https://twitter.com/dangibbsuk">Twitter</li>
	<li><a href="https://www.facebook.com/linuxgsm">Facebook</li>
	<li><a href="https://plus.google.com/+Gameservermanagers1">Google+</li>
</ul>

