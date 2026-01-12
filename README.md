# Tarea 4 IPD432 2025

## **Coprocesador de Distancia Euclidiana y Producto Punto en Nexys 4 DDR**

### Bastián Rivas


## 1. Descripción general

En esta tarea se exploran las capacidades del desarrollo de módulos de hardware utilizando HLS dentro de la herramienta Vitis. En particular, se diseña un coprocesador que soporta el cálculo de la distancia euclideana y el producto punto entre vectores de 1024 palabras de 10 bits cada una.
El equipo utilizado cuenta con el sistema operativo Windows 10 versión 22H2.

Los tiempos estimados de síntesis e implementación fueron tomados operando en un computador con las siguientes caracterisiticas:

* Procesador: Intel Core i5-6300HQ CPU @ 2.30GHz
* Memoria (RAM): 16 GB @ 2133 MHz

El objetivo de este proyecto es el diseño e implementación de un **coprocesador hardware** capaz de calcular:

* **Distancia euclidiana**
* **Producto punto**

entre **dos vectores de 1024 elementos**, donde cada elemento se representa con **10 bits** en formato entero sin signo.

El coprocesador se integra a un sistema completo que incluye:

* Comunicación con un computador mediante **UART**
* Transferencia de vectores desde **MATLAB**
* Almacenamiento de datos en **BRAM**
* Visualización del resultado en **displays de 7 segmentos**
* Ejecución del núcleo de cálculo en un **dominio de reloj dedicado**

Los resultados se muestran en **formato hexadecimal** para ajustarse al ancho de palabra del resultado y a los **8 displays disponibles** de la Nexys 4 DDR.

---

## 2. Herramientas utilizadas

| Herramienta       | Versión                        |
| ----------------- | ------------------------------ |
| Vitis HLS         | 2025.1                         |
| Vivado            | 2025.1                         |
| MATLAB            | R2024b                         |
| Placa FPGA        | Nexys 4 DDR (XC7A100TCSG324-1) |
| Sistema Operativo | Windows 10                     |

### Plataforma de evaluación

Los tiempos de síntesis y de implementación se midieron en el siguiente equipo:

* **CPU:** Intel Core i7-10750H @ 2.60 GHz
* **RAM:** 12 GB @ 2933 MHz

---

## 3. Arquitectura del sistema

El sistema completo está compuesto por los siguientes bloques:

1. **Interfaz UART**

   * Recibe los vectores desde MATLAB
   * Controla la ejecución de las operaciones

2. **Módulo de memoria**

   * Almacena los vectores en BRAM
   * Reorganiza los datos según el formato requerido por HLS

3. **Processing Core (HLS)**

   * `euc_dist`: distancia euclidiana
   * `dot_prod`: producto punto
   * Ambos usan paralelismo espacial y acceso a memoria en paralelo

4. **Controlador**

   * Coordina lectura, ejecución y escritura de resultados

5. **Interfaz de salida**

   * Envía el resultado por UART
   * Muestra el resultado en displays de 7 segmentos

---

## 4. Núcleo de procesamiento (HLS)

El núcleo se implementa con **Vitis HLS** y consta de dos IPs:

* `euc_dist`
* `dot_prod`

Ambos trabajan sobre vectores de **1024 elementos de 10 bits**.

### 4.1 Paralelismo y organización de memoria

Para lograr paralelismo sin exceder los recursos de la Nexys 4 DDR se utilizan:

| Pragma          | Configuración                   |
| --------------- | ------------------------------- |
| `ARRAY_RESHAPE` | `factor = 128`, `type = cyclic` |
| `UNROLL`        | `factor = 128`                  |

Esto reorganiza cada vector de entrada en:

* **8 arreglos**
* Cada uno de **1280 bits** (128 × 10 bits)

permitiendo leer **128 valores por ciclo** sin replicar completamente la memoria.

Se utiliza el reloj por defecto de 10 ns para evitar posibles descoordinaciones entre los medios.

---

## 5. Manejo de memoria

Debido al uso de `ARRAY_RESHAPE`, los vectores almacenados en BRAM deben ser **empaquetados** antes de ingresar al núcleo HLS.

El módulo de memoria:

* Recibe datos secuenciales desde UART
* Los almacena en BRAM
* Los reorganiza según:

[
A_{res}[k][B\cdot X-1:0] = A_{original}[(k+1)X-1 : kX]
]

donde:

* (B = 10) bits
* (X = 128)
* 
_Ojo: El módulo de cálculo de producto punto no lee bien la memoria porque omite el primer bloque! (Pierde 128 datos y los restantes los desplaza)_


## 6. Validación funcional

Se realizaron tres niveles de validación:

1. **Simulación en C (Vitis HLS)**
2. **Cosimulación C/RTL**
3. **Simulación RTL en Vivado**

Se detectaron discrepancias entre HLS y RTL asociadas a **dependencias de lectura/escritura**, lo que obligó a:

* Introducir acumuladores parciales
* Separar ciclos de lectura y operación
* Ajustar el adaptador de memoria

---

## 7. Guía de replicación

### 7.1 Descargar archivos
Para obtener los archivos de este repositorio se puede clickear el botón verde > Download ZIP o con el comando
<img width="767" height="459" alt="imagen" src="https://github.com/user-attachments/assets/458e5ade-31c6-41d6-aabb-70d410d01836" />

```
gh repo clone BRivsC/T4-IPD432-Bastian-Rivas
```
Luego, se descomprimen en una carpeta a elección.

### 7.2 Vitis HLS

Los archivos fuente se encuentran en:

```
/SRC_VITIS_HLS
```
Primeros pasos:
1. Escoger una carpeta
2. Definir workspace en dicha carpeta
3. Crear un componente (ver más abajo)
4. Copiar carpetas 'tb' y 'src'

Pasos para crear un componente:
1. Crear componente en Vitis HLS en File > New Component > HLS
<img width="526" height="191" alt="imagen" src="https://github.com/user-attachments/assets/7d58a55b-a635-4b9d-b6c6-309541cb86dd" />
2. Definir un nombre y lugar donde guardarlo
<img width="662" height="305" alt="imagen" src="https://github.com/user-attachments/assets/97f4f9f1-3003-40bd-8db8-c4a9112b23b0" />
3. Pulsar Next hasta llegar a Part
<img width="638" height="466" alt="imagen" src="https://github.com/user-attachments/assets/1a85f39b-21c2-4608-b51f-d024a6b29850" />
4. En Part buscar la placa `xc7a100tcsg324-1`
<img width="882" height="445" alt="imagen" src="https://github.com/user-attachments/assets/682ff178-3e5e-4e4b-b7bc-bc2145546f5c" />
5. Sobre 'Sources' hacer click derecho y seleccionar 'Add Source File'
 <img width="330" height="176" alt="imagen" src="https://github.com/user-attachments/assets/3503517f-a96b-476f-b54e-b263d1596262" />
6. Seleccionar los archivos dentro de la carpeta src
<img width="804" height="289" alt="imagen" src="https://github.com/user-attachments/assets/ce811292-a717-489e-a04b-290e27dda426" />
7. Repetir el proceso haciendo click derecho sobre 'Test Bench' y escogiendo el archivo dentro de la carpeta 'tb'

Pasos para definir una función top y empezar a sintetizar
1. Abrir la configuración desde el engranaje en el apartado Flow en el costado izquierdo de la ventana
<img width="441" height="211" alt="imagen" src="https://github.com/user-attachments/assets/db9d9785-b23e-40d5-bfa9-a4f0b08aa3d7" />
2. Seleccionar `hls_config.cfg`
<img width="329" height="221" alt="imagen" src="https://github.com/user-attachments/assets/f86ae328-90d3-4d06-91b8-3a3214f5aff7" />
3. Buscar 'top', poner Browse y esperar a que cargue el listado de funciones
[Uploading imagen.png…]()
4. Seleccionar `euc_dist...` del listado
4. De no aparecer: entrar a Source Editor y pegar la siguiente línea: 
<img width="378" height="135" alt="imagen" src="https://github.com/user-attachments/assets/2830e1bd-590c-4ebb-9f12-821009b3b026" />
```
syn.top=euc_dist
```

12. Ejecutar **C Synthesis**
13. Ejecutar **Cosimulation**
14. Exportar **Package**
15. Repetir el mismo proeso para `dot_prod`

---

### 7.2 Vivado

Los archivos se encuentran en:

```
/SRC_VIVADO_DESIGN
```

Pasos:

1. Crear proyecto RTL
2. Agregar fuentes
3. Importar IPs de HLS
4. Agregar constraints de Nexys 4 DDR
5. Sintetizar
6. Implementar
7. Generar bitstream
8. Programar la FPGA

---

## 8. Pruebas con MATLAB

Los scripts se encuentran en:

```
/MATLAB
```

* `coprocessorTesting.m`
* `coprocessorTesting_all.m`

Estos permiten:

* Enviar vectores a la FPGA
* Ejecutar ambas operaciones
* Comparar con resultados software


---

## 9. Rendimiento

### Frecuencia

El diseño cumple timing a:

* **100 MHz**

con margen positivo de WNS.

---

### Latencia (ignorando comunicación)

| Operación            | Latencia aproximada |
| -------------------- | ------------------- |
| Distancia euclidiana | ~25 ciclos          |
| Producto punto       | ~14 ciclos          |



---

### Throughput

A 100 MHz y 16 ciclos:

[
\text{Throughput} \approx 6.25 \times 10^7 \text{ operaciones/s}
]

---

## 10. Uso de recursos

El diseño final cumple:

* 38922 LUT
* 45966 FF
* 128 DSP

permitiendo integrar UART, memoria y control sin saturar la FPGA.

---

## 11. Tiempos de síntesis

| Etapa                 | Tiempo  |
| --------------------- | ------- |
| Vitis HLS             | ~2 min  |
| Vivado Synthesis      | ~26 min |
| Vivado Implementation | ~16 min |

---

## 12. Conclusión

Este proyecto demuestra cómo **Vitis HLS** permite explorar arquitecturas altamente paralelas sin escribir RTL manualmente, aunque también evidencia que:

* La cosimulación no es suficiente
* La organización de memoria es crítica
* El paralelismo debe balancearse con dependencias de datos

El coprocesador final logra integrar **operaciones matemáticas complejas, paralelismo, memoria y comunicación UART** en un sistema funcional y validado sobre hardware real.
