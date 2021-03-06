
# g810-profile A profile manager for Logitech RGB-keyboards compatible with g810-led
See [https://github.com/MatMoul/g810-led](https://github.com/MatMoul/g810-led) for the g810-led application.


## Features
- Dynamic load/unload of application profiles
- Dynamic media controls
- 'On press' mute toggler
- 'Google Keyboard'-Toggler for a keyboard full of colors based on running applications.

## How it works
The script is based on a application listener ('while loop' based on 'ps o comm -C'), a dbus-listener (dbus-monitor) for the multimedia controls and a 'on press' mute toggler (amixer).
The script is configured with the files PROFILE_BASE, PROFILES, GOOGLE_KEYBOARD, PROFILES_PERMANAENT.
These files must have the following format:
```
application1,application2,application3,application4,application5
```
Start any application in the terminal and/or use the top/htop command to get the application name used in the PROFILES* files.


## Installation and basic configuration

- Clone repository
```
git clone https://github.com/minimec/g810-profile
```

- Hide the folder
```
mv g810-profile .g810-profile
```

- Make script(s) executable / create 'bin' folder and link the script file
```
chmod +x $HOME/.g810-profile/src/g810-profile.sh $HOME/.g810-profile/src/g810-media-control.sh
```
```
mkdir $HOME/.g810-profile/bin  
```
```
ln -s $HOME/.g810-profile/src/g810-profile.sh $HOME/.g810-profile/bin/g810-profile  
```

- Backup current .profile / add '~/.g810-profile/bin' to PATH
```
cp .profile{,.backup."$(date +%Y-%m-%d)"}
```
```
printf "\n# g810-profile (keyboard profile manager)\nPATH=\$PATH:~/.g810-profile/bin" >> .profile
```



- Configure default music player in script. --> See #Variables (examples) All Mpris2 compatible players should work. (ctrl+x to save)
```
nano .g810-profile/src/g810-profile.sh
```

- Add default player to the 'PROFILES' file in the '~/.g810-profile' folder. (ctrl+x to save)
```
nano .g810-profile/PROFILES
```

- logout/login user session  
*Logout/login user session to load new PATH in .profiles*

- start g810-profile
```
g810-profile start
```

- First test:
```
g810-profile --join
```
- 'Google Keyboard' Name of all applications in GOOGLE_KEYBOARD written on the keyboard in various colors.    
The function is a 'toggler'. Maybe add a custom shortcut...
```
g810-profile --google
```
- Mute toggle
Disable 'mute' shortcut in the settings of your window manager (normally 'Backspace'-key to disable shortcut.
Add a new custom shortcut for the 'mute' button with the fallowing value...
```
g810-profile --mute
```
## Usage
- Start g810-profile
```
g810-profile start
```
- Stop g810-profile
```
g810-profile stop
```
## Notes
The 'ding' sound file has been published under the Creatice Commons 'Sampling Plus 1.0' license and was found here [http://soundbible.com/1441-Elevator-Ding.html](http://soundbible.com/1441-Elevator-Ding.html)
