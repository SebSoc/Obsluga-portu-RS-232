# Obsluga-portu-RS-232
Projekt na FPGA. 

Moduły nadajnika i odbiornika danych w standardzie RS-232 dla następujących parametrów transmisji: 8 bitów danych, bez bitu parzystości, jeden bit stopu, szybkość transmisji 9600bps bez sprzętowej kontroli przepływu.  Moduły połączone tak aby odbiornik RS232 po otrzymaniu danych podawał je do sumatora i po dodaniu do nich wartości 20h, moduł nadajnika wysyłał je. 

Implementacja w języku VHDL oraz Verilog.
