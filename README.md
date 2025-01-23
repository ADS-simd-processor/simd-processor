# SIMD Processor integrated with a System-on-Chip

This project implements an SIMD processor that can be used to offload matrix and vector operations from the Zynq SoC. Matrix operations are subdivided into the vector operations **add, subtract, dot product, and transpose**.

## Hardware Architecture

![image](https://github.com/user-attachments/assets/04ba4e4b-8b12-4a7e-bc59-1450201f6fa9)

The processor uses 4 pipeline stages with each taking 2 clock cycles.

1. Instruction fetch and decode
2. Load data
3. Execute
4. Store result

## Instruction Set and Control Signals

![image](https://github.com/user-attachments/assets/fe82976a-bbd8-4e24-9f04-0602431c6636)

## Compiler

The compiler is used to convert a matrix operation into a series of vector operations.

![image](https://github.com/user-attachments/assets/2b75089b-180a-407a-8875-048c35ea5f13)

## Block Design

AXI CDMA was used to transfer data between the PS and the block RAMs.

![image](https://github.com/user-attachments/assets/cddea53e-72db-4226-a73e-8f5b48ccc846)

## Vitis Application

![image](https://github.com/user-attachments/assets/221d7b94-b62e-4708-b8c2-50623dc4ef4a)

## Performance

![image](https://github.com/user-attachments/assets/4d880b70-2d6e-4750-a95b-6f8c2e5e6fb9)






