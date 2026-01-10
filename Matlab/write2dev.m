function [] = write2dev(file,BRAMX,port)
%write2dev Enviar comando de escritura por UART y datos almacenados en un
%archivo .txt
% arguments (Input)
%     file    string {mustBeFile}
%     BRAMX   string {mustBeMember(BRAMX,["BRAMA","BRAMB"])}
%     port    Serialport
% end

if BRAMX == "BRAMA"
    buffer = 0b00000001;
else
    buffer = 0b10000001;
end

vector = readmatrix(file);
write(port,buffer,"uint8");

% Enviar datos
write(port,vector,"uint16");

end