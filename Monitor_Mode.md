## Monitor Mode using ```iw``` and ```ip```

2021-02-19

-----
### Enter Monitor Mode

Start by making sure the system recognizes the WiFi interface
```
$ iw dev
```
Note: The output shows the WiFi interface name and the current
mode among other things. The interface name may be something like
`wlx00c0cafre8ba` and is required for many of the below commands.


Take the interface down
```
$ sudo ip link set <your interface name here> down
```

Set monitor mode
```
$ sudo iw <your interface name here> set monitor control
```

Bring the interface up
```
$ sudo ip link set <your interface name here> up
```

Verify the mode has changed
```
$ iw dev
```
-----

### Revert to Managed Mode

Take the interface down
```
$ sudo ip link set <your interface name here> down
```

Set managed mode
```
$ sudo iw <your interface name here> set type managed
```

Bring the interface up
```
$ sudo ip link set <your interface name here> up
```

Verify the mode has changed
```
$ iw dev
```
-----

### Change the MAC Address before entering Monitor Mode

Take down things that might interfere
```
$ sudo airmon-ng check kill
```
Check the WiFi interface name
```
$ iw dev
```
Take the interface down
```
$ sudo ip link set dev <your interface name here> down
```
Change the MAC address
```
$ sudo ip link set dev <your interface name here> address <your new mac address>
```
Set monitor mode
```
$ sudo iw <your interface name here> set monitor control
```
Bring the interface up
```
$ sudo ip link set dev <your interface name here> up
```
Verify the MAC address and mode has changed
```
$ iw dev
```
