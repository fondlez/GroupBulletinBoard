# GroupBulletinBoard for 3.3.5a

### [Download Latest](https://github.com/ExoJdi/GroupBulletinBoard_3.3.5a/releases/latest)

## Main changes:
- Fixed class color and class icon display;
- Fixed the "Don't Truncate" feature - now works correctly in both modes;
- Fixed tooltip display on items and achievements (the profession window opens on click);
- Added collection of /shout and /emote requests;
- Added new "By Priority" request filter logic:
-- WotLK>TBC>Classic
-- Raid>Dungeons
-- Raid/Dungeons>Trade>Misc;
- Added the ability to choose the font and font size;
- And a bunch of minor fixes.

  
## This is a port to WotLK (3.3.5a)!

* Fork - WotLK (3.3.5a) port: [fondlez](https://github.com/fondlez)

## Description
GroupBulletinBoard (GBB) provides an overview of the endless requests in the 
chat channels. It detects all requests to the instances, sorts them and presents 
them clearly way. Numerous filtering options reduce the gigantic number to 
exactly the dungeons that interest you. And if that's not enough, GBB will let 
you know about any new request via a sound or chat notification.

Currently, English, German, Russian and Chinese dungeons are recognized 
natively. But it is easily possible to adapt GBB to any language.

To open the settings, use slash command: **`/gbb`** or click the minimap icon.

## Graphical Interface

### Main Window
<img width="773" height="728" alt="MainWindow" src="https://github.com/user-attachments/assets/16e58b45-02f1-422d-a3b9-c0f6a04932fa" />


### Interface Settings
<img width="661" height="589" alt="Settings" src="https://github.com/user-attachments/assets/f95f7811-b00f-4bed-bf18-57adbb5dfc65" />


## Slash Commands

`<value>` can be true, 1, enable, false, 0, disable. If <value> is omitted, the 
current status switches.

* `/gbb notify chat <value>` - On new request make a chat notification
* `/gbb notify sound <value>` - On new request make a sound notification
* `/gbb debug <value>` - Show debug information
* `/gbb reset` -  Reset main window position
* `/gbb config/setup/options` - Open configuration
* `/gbb about` - open about
* `/gbb help` - Print help
* `/gbb chat clean/organize` - Creates a new chat tab if one doesn't already 
exist, named \"LFG\" with all channels subscribed. Removes LFG heavy spam 
channels from default chat tab
* `/gbb` - open main window

## Frequently Asked Questions (FAQ)

### Q. How to blacklist a word?

From GroupBulletinBoard Settings, click on "Search patterns", make sure "Custom"
is checked, add words to "Blacklist words", then reload the user interface, e.g. 
using the `/reload` or `/reloadui` command.

## Credits

### Original Addon
* Arrogant_Dreamer, Hubbotu and kavarus for the Russian translation
* Baudzilla for the graphics/idea of the resize-code
