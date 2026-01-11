clear all; % borra el workspace
clear; clc;
%% Configuracion de entorno global
NUM_ELEMENTOS = 8;  % define el numero de elementos de cada vector
                      % Cambiar vector_size dentro de command2dev si se usa
                      % otro tamaño
BIT_WIDTH = 10;
N_TESTS = 3; % Repeticion de pruebas

% Configurar puerto serial
%COM_port = "/dev/ttyUSB1";
COM_port = "COM13";
vector_size = NUM_ELEMENTOS;
baud_rate = 115200;
port = serialport(COM_port,baud_rate);
port.DataBits = 8;
port.Timeout = 0.5;
port.Parity = "none";
port.StopBits = 1;
port.FlowControl = "none";

flush(port,"input");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Para las pruebas dinamicas, se recomienda incluir el codigo en un loop que le permita probar varias iteraciones de operaciones
for test = 1:N_TESTS
    
    %Genera vectores A y B de 1024 elementos con numeros positivos 
    %(puede adaptarse facilmente si usan negativos y positivos).
    %A=ceil(rand(NUM_ELEMENTOS,1)*2^BIT_WIDTH)-1;
    %B=ceil(rand(NUM_ELEMENTOS,1)*2^BIT_WIDTH)-1;

    % Sanity checks: todos 1 o todos 0
    A=1;
    B=1;

    %% Guarda vectores A y B (cada uno de una columna de 1024 filas) en un
    %archivo de texto. Cada linea del archivo contiene un elemento.
    h= fopen('vectorA.txt', 'w');
    fprintf(h, '%i\n', A);
    fclose(h);
    
    h= fopen('vectorB.txt', 'w');
    fprintf(h, '%i\n', B);
    fclose(h);
    
    %% Calcula valores de referencia para las operaciones, realizadas en forma local en el host
    %sumVec_host = A+B;
    %avgVec_host = (A+B)/2;
    %man_host = sum(abs(A-B));
    euc_host = sqrt(sum((A-B).^2));
    dot_host = dot(A,B);
    

    %% A partir de aca se realizan las operaciones por medio de comandos al coprocesador
    
    % Los siguientes comandos son con formato tentativo. 
    % Puede aplicar cambios menores para adaptarlos a su implementacion, lo cual debe quedar claramente documentado.
    % En cualquier caso, debe incluir solo argumentos necesarios para cada operacion. 
    % No aplique aca "parches de software" para cubrir deficiencias en el diseño de hardware.
    % No se aceptarán comentarios del tipo: "hay que poner ese argumento porque sino no funciona", sin una justificacion adecuada.
    
    %writeVec escribe un vector almacenado en un archivo de texto en la BRAM indicada por medio de la UART
    write2dev('vectorA.txt','BRAMA',port); 
    disp('Escrito Vector A');
    write2dev('vectorB.txt','BRAMB',port); 
    disp('Escrito Vector B');
    %readVec lee el contenido de la BRAM indicada por medio de la UART
    %%
    VecA_device = command2dev('readVec','BRAMA', port);
   
    VecB_device = command2dev('readVec', 'BRAMB', port);
   
    %sumVec_device = command2dev('sumVec', port); %realiza la suma elemento a elemento de los vectores almacenados y envia el resultado por la UART
   
    %avgVec_device = command2dev('avgVec', port);
   
    %man_device = command2dev('manDist', port); %realiza el calculo de la distancia de Manhattan entre dos vectores y envia el resultado por la UART

    euc_device = command2dev('eucDist', port); %realiza el calculo de la distancia Euclideana entre dos vectores y envia el resultado por la UART
    
    dot_device = command2dev('dotProd', port);
    %% Validacion.
    % Los resultados _diff deberian ser 0 (o cercanos, dependiendo de su
    % decision de diseno en el diseno del coprocesador). Si no es 0, indique
    % claramente por que en su informe.
    
    %sumVec_diff = sum(sumVec_host - sumVec_device);
    %avgVec_diff = sum(avgVec_host - avgVec_device); % Este suele tener error porque el coprocesador no trabaja con flotantes
    %man_diff = man_host - man_device;
    euc_diff = euc_host - euc_device;
    dot_diff = dot_host - dot_device;

    fprintf("Test %d:\t",test);
    %fprintf("euc_diff:%d\t dot_diff:%.2f\t\n", euc_diff, dot_diff);
    fprintf("Euc HW: %.2f\t Euc Gold: %.2f\t Dot HW: %.2f\t DotGold: %.2f\t\n", euc_device, euc_host, dot_device, dot_host);
    

end

% Cerrar puerto
clear port;
