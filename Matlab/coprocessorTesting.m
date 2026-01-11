clear all; % borra el workspace
clear; clc;
%% Configuracion de entorno global
NUM_ELEMENTOS = 1024;  % define el numero de elementos de cada vector
                      % Cambiar vector_size dentro de command2dev si se usa
                      % otro tamaño
BIT_WIDTH = 10;
N_TESTS = 3; % Repeticiones de pruebas

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
    % Acá incluyo una variedad de tests para confirmar distintos aspectos
    % del diseño. Sugiero descomentar un par A B cada vez usando un N_TESTS
    % bajo porque son valores fijos.
    %Genera vectores A y B de 1024 elementos con numeros positivos 
    %(puede adaptarse facilmente si usan negativos y positivos).
    %A=ceil(rand(NUM_ELEMENTOS,1)*2^BIT_WIDTH)-1;
    %B=ceil(rand(NUM_ELEMENTOS,1)*2^BIT_WIDTH)-1;

    % Sanity check: todos 1 o todos 0
    %A=0*(ceil(rand(NUM_ELEMENTOS,1)*2^BIT_WIDTH)-1)+1;
    %B=0*(ceil(rand(NUM_ELEMENTOS,1)*2^BIT_WIDTH)-1)+1;
    
    %% Check: se están relacionando los elementos correctamente?
    %A = (0:1023).';
    %B = ones(1024,1);

    %% Check: se están leyendo todos los bloques?
    %A = zeros(1024,1);
    %B = ones(1024,1);
    %
    %for k = 0:7
        %A(k*128+1:(k+1)*128) = k+1;   % Bloques: 1,2,3,...8
    %end

    % = 128*(1+2+3+4+5+6+7+8) = 128*36 = 4608 si se leen todos 
    % (1024 elem y 10 bits)

    %% Check: Hay bloques que se estén intercambiando?
    % Cada bloque de 1280 elementos tiene su propio valor
    A = (0:1023).';
    B = A;







    %% Guarda vectores A y B (cada uno de una columna de 1024 filas) en un
    %archivo de texto. Cada linea del archivo contiene un elemento.
    h= fopen('vectorA.txt', 'w');
    fprintf(h, '%i\n', A);
    fclose(h);
    
    h= fopen('vectorB.txt', 'w');
    fprintf(h, '%i\n', B);
    fclose(h);
    
    %% Calcula valores de referencia para las operaciones, realizadas en forma local en el host
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

    write2dev('vectorB.txt','BRAMB',port); 
    %%
    %readVec lee el contenido de la BRAM indicada por medio de la UART
    
    VecA_device = command2dev('readVec','BRAMA', port);
   
    VecB_device = command2dev('readVec','BRAMB', port);

    euc_device = command2dev('eucDist', port); %realiza el calculo de la distancia Euclideana entre dos vectores y envia el resultado por la UART
    
    dot_device = command2dev('dotProd', port);
    %% Validacion.
    % Los resultados _diff deberian ser 0 (o cercanos, dependiendo de su
    % decision de diseno en el diseno del coprocesador). Si no es 0, indique
    % claramente por que en su informe.
    
    euc_diff = euc_host - euc_device;
    dot_diff = dot_host - dot_device;

    fprintf("Test %d:\t",test);
    fprintf("Euc HW: %.2f\t Euc Gold: %.2f\t Dot HW: %d\t DotGold: %d\t\n", euc_device, euc_host, dot_device, dot_host);
    fprintf("\teuc_diff:%.2f\t dot_diff:%d\t\n", euc_diff, dot_diff);
    
    

end

% Cerrar puerto
clear port;
