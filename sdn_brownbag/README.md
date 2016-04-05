# Brownbag SDN-Controller Ryu + Mininet
## Mininet + Ryu VM
Am Einfachsten die VM von [github](https://github.com/osrg/ryu/wiki/OpenFlow_Tutorial) herunterladen. ALternativ könnt ihr auch einfach mininet und den Ryu Controller bei euch in einer VM installieren, für Ubuntu/Debian gibt es hier zahlreiche Anleitungen: [Mininet](http://mininet.org/download) und [Ryu](http://osrg.github.io/ryu/)
## Usage
### Starte Mininet
```
sudo python my_mininet.py
```
### Starte Controller
Um den entsprechenden Controller zu starten einfach das entsprechende Skript starten:
```
./start_dump_switch.sh 
```
Hierbei wird die OpenFlow Version auf 1.3 gesetzt und danach wird der Controller gestart (auf Port 6633)
### Troubleshooting
Ein Problem das ab und zu auftritt ist: "Address allready in use", dies kann daran liegen, dass der standard Controller noch läuft.
```
sudo lsof -i :6633
```
Gibt die Prozess ID aus, diesen Prozess einfach beenden und dan Controller erneut starten.
