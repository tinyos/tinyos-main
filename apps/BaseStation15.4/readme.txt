Sniffer
-----------------------------------

	by 		Silvia Krug
	date	20120921


-----------------------------------
Hardware
-----------

tmote / telosB Knoten

-----------------------------------
Software - auf Knoten
-----------
	Anwendung: packetsniffer
	Pfad: 	   tinyos-2.x/apps/tests/tkn15.4/packetsniffer

	notwendige Einstellungen:
		Kanal: in app_profile.h INITAL_RADIO_CHANNEL setzen

	übersetzen mit: 
		make tmote install,<id>

		<id> = Knoten-ID 

Der Knoten ist in dieser Anwendung passiv und zeichnet alle Pakete auf 
der Luftschnittstelle auf. Die Anwendung stellt eine Art Basisstation 
bereit, d.h. die Pakete werden über die Serielle Schnittstelle zum 
Rechner übertragen.

-----------------------------------
Software - auf Rechnerseite
-----------
	Anwendung: BaseStation15.4
	Pfad: 	   tinyos-2.x/apps/BaseStation15.4

	übersetzen mit: 
		make tmote

Auf Rechnerseite wird ein C-Programm verwendet, das sich im genannten 
Ordner befindet. Dieses wurde erweitert, um

	1) Pakete im Wireshark-Format pcap zu speichern und
	2) die Zusatzinformationen (LQI,RSSI,CRC ok,MAC Header Länge,PHY 
	   Kanal und Zeitstemple) des TKN15.4-Protokolls anzuzeigen

Das C.Programm wird mit der Anwendung übersetzt und ist anschließend 
einsatzbereit. Die Wireshark-Datei wird im gleichen Verzeichnis angelegt.
	   
	Aufruf:
		./seriallisten15-4 iframe </dev/ttyUSB0> 115200 <mac.pcap>

		</dev/ttyUSB0> = Serielle Schnittstelle an der der Sniffer 
		                 angeschlossen ist
		                 
		<mac.pcap> = Datei, in der die Pakete für Wireshark gespeichert 
		             werden         

Fehlermeldungen werden in die Konsole geschrieben. Ggf. ist nach dem 
Start des C-Programms ein Reset der Knotens notwendig.


-----------------------------------
Auswertung mit Wireshark
-----------

Die erzeugte Datei kann mit Wireshark geöffnet und analysiert werden. 
Der Funkchip der Tmotes schneidet die letzen 2 Byte (CRC des Paketes) ab 
und ersetzt sie durch andere Informationen. Damit die Pakete in 
Wireshark korrekt angezeigt werden sind folgende Einstellungen 
notwendig:

	Unter: Eintstellungen -> Protokolle -> IEEE 802.15.4 
	den Haken bei 'TI CC24xx FCS format' setzen

 
Pakete, die mit Blip 1 versendet wurden können aber nicht korrekt 
entschlüsselt werden. Ohne weitere Einstellungen werden diese Pakete 
ggf. als ZigBee Pakete interpretiert. Um dies zu verhindern sollten die 
ZigBee-Protokolle in Wireshark deaktiviert werden.

	Unter: Analyze -> Enabled Protocols
	die entsprechenden Haken bei ZigBee entfernen.

Blip 2 Pakete sollten von der in Wireshark enthaltenen 6LoWPAN Engine 
dekodiert werden können.



