/******************************************************************************
 *
 * Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Use of the Software is limited solely to applications:
 * (a) running on a Xilinx device, or
 * (b) that interact with a Xilinx device through a bus or interconnect.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
 * OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Except as contained in this notice, the name of the Xilinx shall not be used
 * in advertising or otherwise to promote the sale, use or other dealings in
 * this Software without prior written authorization from Xilinx.
 *
 ******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_types.h"
#include "xaxicdma.h"
#include "xscugic.h"
#include "xstatus.h"
#include "xparameters.h"
#include "xtime_l.h"
#include "xil_printf.h"
#include "xdebug.h"
#include "xil_exception.h"
#include "xil_cache.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>

#define DMA_TRANSFER_SIZE 32
// #define DMA_TRANSFER_SIZE 32
// #define SRC_DDR_MEMORY XPAR_PS7_DDR_0_S_AXI_BASEADDR+0x00200000 // pass all code and data sections	(2 MB)
// #define DST_DDR_MEMORY SRC_DDR_MEMORY+0x00200000 // (2 MB)
// #define DST_OCM_MEMORY XPAR_PS7_RAM_1_S_AXI_BASEADDR

// INTC
#define INTC_DEVICE_ID XPAR_SCUGIC_0_DEVICE_ID
// #define INTC_BASEADDR XPAR_PS7_SCUGIC_0_BASEADDR

// DMA
#define DMA_ID XPAR_AXI_CDMA_0_DEVICE_ID
#define DMA_CTRL_IRPT_INTR XPAR_FABRIC_AXICDMA_0_VEC_ID

// driver instances
static XScuGic Intc; // The instance of the generic interrupt controller (GIC)
static XAxiCdma Dma; /* Instance of the XAxiCdma */
#define CDMA_BRAM_MEMORY_0 0xC0000000
#define CDMA_BRAM_MEMORY_1 0xC2000000 // portA of BRAM (connection from CDMA)
#define CDMA_BRAM_MEMORY_2 0xC4000000
#define CDMA_BRAM_MEMORY_3 0xC6000000
#define CDMA_BRAM_MEMORY_4 0xC8000000

#define UNIT 4
#define OP_WIDTH 3
#define ADDR_WIDTH 10
#define INST_WIDTH 64
#define MAX_INST_COUNT 65536
#define INST_BRAM_DEPTH 2048

#define SHIFT_A (ADDR_WIDTH * 2 + OP_WIDTH)
#define SHIFT_B (ADDR_WIDTH + OP_WIDTH)
#define SHIFT_R OP_WIDTH

#define MAX(a, b) ((a) > (b) ? (a) : (b))

// #define CDMA_BRAM_MEMORY_1 0x42000000	// portB of BRAM (connection from PS)
// #define CDMA_OCM_MEMORY_0 0x00000000

typedef enum
{
	NOP,
	ADD,
	SUB,
	MUL,
	DOT_SFT,
	DOT_ACC,
	DOT_CLR,
	PASS_B
} Opcode;

typedef enum
{
	MADD,
	MSUB,
	MTRANS,
	MDOT
} MatrixOp;

u64 instructions[MAX_INST_COUNT] = {0};
u16 pc = 0;
u16 last_sent_pc = 0;

// Source and Destination memory segments
u32 Src[DMA_TRANSFER_SIZE];		// source is always DRAM
u32 Dst_DDR[DMA_TRANSFER_SIZE]; // for CDMA to access the DRAM
u32 Dst_OCM[DMA_TRANSFER_SIZE] __attribute__((section(".mba_ocm_section")));
u32 Dst_BRAM[DMA_TRANSFER_SIZE] __attribute__((section(".mba_bram_section")));

u32 *cdma_memory_destination_bram0 = (u32 *)CDMA_BRAM_MEMORY_0;	  // BRAM A
u32 *cdma_memory_destination_bram1 = (u32 *)CDMA_BRAM_MEMORY_1;	  // BRAM B
u32 *cdma_memory_destination_bram2 = (u32 *)CDMA_BRAM_MEMORY_2;	  // BRAM INS
u32 *cdma_memory_destination_bram3 = (u32 *)CDMA_BRAM_MEMORY_3;	  // BRAM R
u32 *(cdma_memory_destination_bram4) = (u32 *)CDMA_BRAM_MEMORY_4; // BRAM CHECK
// u32 *cdma_memory_destination_ocm = (u32 *)CDMA_OCM_MEMORY_0;		// for CDMA to access the OCM

// AXI CDMA related definitions
XAxiCdma_Config *DmaCfg;

int Status = 0;
int i = 0;

XTime tStart, tEnd;
u32 totalCycle = 0;

int Done = 0;
int Error = 0;

// lfsr seed
uint32_t start_state = 0xAC000000u; /* Any nonzero start state will work. */
uint32_t lfsr = 0xAC000000u;

// GIC Setup
int SetupInterruptSystem(XScuGic *GicInstancePtr, XAxiCdma *DmaPtr);
// DMA done interrupt handler
static void Example_CallBack(void *CallBackRef, u32 IrqMask, int *IgnorePtr);
// function decleration for simple 8-bit lfsr for pseudo-random number generator

void single_inst_gen(Opcode opcode, u16 a_addr, u16 b_addr, u16 r_addr);
void inst_gen(MatrixOp op, u16 a_start, u16 b_start, u16 r_start, u16 m, u16 n, u16 p);
void reset_pc();
void SendInstructions();

u32 lfsr_rand();
u32 check = 0x00000001;

int main()
{
	init_platform();
	xil_printf("Starting\n");
	reset_pc();
	/* Initialize the XAxiCdma device.
	 */
	DmaCfg = XAxiCdma_LookupConfig(DMA_ID);
	if (!DmaCfg)
	{
		return XST_FAILURE;
	}

	Status = XAxiCdma_CfgInitialize(&Dma, DmaCfg, DmaCfg->BaseAddress);
	if (Status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}

	Status = SetupInterruptSystem(&Intc, &Dma);
	if (Status != XST_SUCCESS)
		return XST_FAILURE;

	XAxiCdma_IntrEnable(&Dma, XAXICDMA_XR_IRQ_ALL_MASK);

	// Disable DCache
	Xil_DCacheDisable();

	xil_printf("initialization finish\n");
	xil_printf("\n");

	/**** Generate Instructions ***/

	// From here the matrix generations part starts
	/////***************************************************************////////
	// srand(time(NULL));

	for (size_t num = 4; num < 21; num += 4)
	{	//////Change max num if needed
		// xil_printf("num: %d\n", num);
		//				size_t num =16;
		reset_pc();
		inst_gen(MDOT, 0, 0, 0, num, num, num);

		//	    		xil_printf("Generated instructions. First instruction: 0x%09X\n", instructions[0]);
		//	    		xil_printf("Last instruction: 0x%09X\n", instructions[pc-1]);

		SendInstructions();

		int A_row = num;
		int A_col = num;
		int B_col = num;
		int B_row = num;
		xil_printf("Row and Coloum Size of the Matrix : %d \n", num);
		xil_printf("\n");
		u32 mat_res[A_row][B_col];
		u32 mat_a[A_row][A_col];
		u32 mat_b[B_row][B_col];
		u32 mat_b_T[B_col][B_row];
		u32 mat_got[A_row][B_col];

		u32 *Src_a = (u32 *)mat_a;
		u32 *Src_b = (u32 *)mat_b;
		u32 *Src_b_T = (u32 *)mat_b_T;
		u32 *Src_res = (u32 *)mat_got;

		u32 DMA_TRANSFER_SIZE_A = A_row * A_col;
		u32 DMA_TRANSFER_SIZE_B = B_col * B_col;

		for (size_t count = 0; count < 5; count++)
		{ /////Change max count if needed
			// initialize mat_a and mat_b with random values
			for (int i = 0; i < A_row; i++)
			{
				for (int j = 0; j < A_col; j++)
				{
					mat_a[i][j] = (int)rand() % 100;
				}
			}

			for (int i = 0; i < A_col; i++)
			{
				for (int j = 0; j < B_col; j++)
				{
					mat_b[i][j] = (int)rand() % 100;
				}
			}

			for (int i = 0; i < A_col; i++)
			{
				for (int j = 0; j < B_col; j++)
				{
					mat_b_T[j][i] = mat_b[i][j];
				}
			}
			XTime_GetTime(&tStart);
			// multiply mat_a and mat_b and store the result in mat_res
			for (int i = 0; i < A_row; i++)
			{
				for (int j = 0; j < B_col; j++)
				{
					mat_res[i][j] = 0;
					for (int k = 0; k < A_col; k++)
					{
						mat_res[i][j] += mat_a[i][k] * mat_b[k][j];
					}
				}
			}

			XTime_GetTime(&tEnd);
			u64 et_dma_bram = (tEnd - tStart);
			xil_printf("Dimension : %d  |  Time taken for the PS matrix multiplication : %d  \n", num, et_dma_bram);

			Status = XAxiCdma_SimpleTransfer(&Dma, (u32)Src_a,
											 (u32)cdma_memory_destination_bram0, DMA_TRANSFER_SIZE_A * (sizeof(u32)), Example_CallBack,
											 (void *)&Dma);

			XTime_GetTime(&tStart);
			if (Status == XST_SUCCESS)
			{
				while (!Done && !Error)
					;
			}

			xil_printf("BRAM Transaction to BRAM A  Done   \n");

			XTime_GetTime(&tEnd);
			et_dma_bram = tEnd - tStart;
			//xil_printf("Dimension : %d  |  Time taken to tranfer the matrix from PS to PL  : %d  \n", num, et_dma_bram);

			XTime_GetTime(&tStart);
			Status = XAxiCdma_SimpleTransfer(&Dma, (u32)Src_b_T,
											 (u32)cdma_memory_destination_bram1, DMA_TRANSFER_SIZE_B * (sizeof(u32)), Example_CallBack,
											 (void *)&Dma);


			if (Status == XST_SUCCESS)
			{
				while (!Done && !Error)
					;
			}
			//	            XTime_GetTime(&tEnd);
			XTime_GetTime(&tEnd);
			et_dma_bram = tEnd - tStart;
			xil_printf("Dimension : %d  |  Time taken to tranfer the matrix from PS to PL  : %d  \n", num, et_dma_bram);
			xil_printf("BRAM Transaction to BRAM B done  \n");

			XTime_GetTime(&tStart);
			check = 1;
			Status = XAxiCdma_SimpleTransfer(&Dma, (u32)(&check),
											 (u32)cdma_memory_destination_bram4, 1 * (sizeof(u32)), Example_CallBack,
											 (void *)&Dma);
			if (Status == XST_SUCCESS)
			{
				while (!Done && !Error)
					;
			}

			//	            Status = XAxiCdma_SimpleTransfer(&Dma, (u32)cdma_memory_destination_bram4 ,
			//	            							(u32)Src_res, 1 * (sizeof(u32)), Example_CallBack,
			//	            	            									 (void *)&Dma);
			//	            if (Status == XST_SUCCESS)
			//	            	            	            	            {
			//	            	            	            	                while (!Done && !Error);
			//	            	            	            	            }

			XTime_GetTime(&tEnd);
			et_dma_bram = tEnd - tStart;
			//xil_printf("Dimension : %d  |  Time taken to tranfer the matrix from PS to PL  : %d  \n", num, et_dma_bram);

			// xil_printf("Time taken for one transaction: %llu\n", et_dma_bram);

			check = 0;

			Status = XAxiCdma_SimpleTransfer(&Dma, (u32)(&check),
											 (u32)cdma_memory_destination_bram4, 1 * (sizeof(u32)), Example_CallBack,
											 (void *)&Dma);
			if (Status == XST_SUCCESS)
			{
				while (!Done && !Error)
					;
			}

			//	            	            Status = XAxiCdma_SimpleTransfer(&Dma, (u32)cdma_memory_destination_bram4 ,
			//	            	            	            	            							(u32)Src_res, 1 * (sizeof(u32)), Example_CallBack,
			//	            	            	            	            	            									 (void *)&Dma);
			//	            	            if (Status == XST_SUCCESS)
			//	            	            	            	            	            {
			//	            	            	            	            	                while (!Done && !Error);
			//	            	            	            	            	            }
			//
			//	            	            	            	            xil_printf("value check %d \n",Src_res[0]);

			xil_printf("BRAM data and Instructions Finish writing  \n");

			sleep(1);

			Status = XAxiCdma_SimpleTransfer(&Dma, (u32)cdma_memory_destination_bram3, (u32)Src_res,
											 DMA_TRANSFER_SIZE_A * (sizeof(u32)), Example_CallBack,
											 (void *)&Dma);

			if (Status == XST_SUCCESS)
			{
				while (!Done && !Error)
					;
			}

			xil_printf("Comparing the mul of mat_a and mat_b with Src_res:\n");

			int match = 1; // Flag to check if all values match
			for (int i = 0; i < A_row; i++)
			{
				for (int j = 0; j < B_col; j++)
				{
					u32 expected_value = mat_res[i][j];
					u32 result_value = Src_res[i * B_col + j]; // Access the corresponding value from Src_res

					// xil_printf("mat_res[%d][%d] = %d, Src_res[%d] = %d --> ", i, j, expected_value, i * B_col + j, result_value);

					if (expected_value == result_value)
					{
						// xil_printf("MATCH\n");
					}
					else
					{
						// xil_printf("MISMATCH\n");
						match = 0;
					}
				}
			}

			if (match)
			{
				xil_printf("Matrix multiplication is correct\n");
			}
			else
			{
				xil_printf("Matrix multiplication has mismatches\n");
			}
			xil_printf("\n");
		}

		//	            for (int i = 0; i < A_row; i++) {
		//	                for (int j = 0; j < B_col; j++) {
		//	                    int expected_value = mat_a[i][j] + mat_b[i][j];
		//	                    int result_value = Src_res[i * B_col + j];  // Access the corresponding value from Src_res
		//
		//	                    xil_printf("mat_a[%d][%d] + mat_b[%d][%d] = %d, Src_res[%d] = %d --> ", i, j, i, j, expected_value, i * B_col + j, result_value);
		//
		//	                    if (expected_value == result_value) {
		//	                        xil_printf("MATCH\n");
		//	                    } else {
		//	                        xil_printf("MISMATCH\n");
		//	                    }
		//	                }
		//	            }

		xil_printf("\n");

		reset_pc();
		inst_gen(MTRANS, 0, 0, 0, num, num, num);
		// xil_printf("generated PC %d , %d ", pc , last_sent_pc);

		// xil_printf("Generated instructions. First instruction: %ld \n", instructions[0]);
		// xil_printf("Last instruction: %ld \n", instructions[pc-1]);

		SendInstructions();

		for (int i = 0; i < A_col; i++)
		{
			for (int j = 0; j < B_col; j++)
			{
				mat_b[i][j] = (int)rand() % 100;
			}
		}
		for (int j = 0; j < B_col; j++)
		{
			for (int i = 0; i < B_col; i++)
			{
				Status = XAxiCdma_SimpleTransfer(&Dma, (u32)(&mat_b[i][j]),
												 (u32)(cdma_memory_destination_bram1 + j * B_col + i), 1 * (sizeof(u32)), Example_CallBack,
												 (void *)&Dma);

				if (Status == XST_SUCCESS)
				{
					while (!Done && !Error)
						;
				}
			}
		}

		XTime_GetTime(&tStart);
		check = 1;
		Status = XAxiCdma_SimpleTransfer(&Dma, (u32)(&check),
										 (u32)cdma_memory_destination_bram4, 1 * (sizeof(u32)), Example_CallBack,
										 (void *)&Dma);
		if (Status == XST_SUCCESS)
		{
			while (!Done && !Error)
				;
		}

		//	            Status = XAxiCdma_SimpleTransfer(&Dma, (u32)cdma_memory_destination_bram4 ,
		//	            							(u32)Src_res, 1 * (sizeof(u32)), Example_CallBack,
		//	            	            									 (void *)&Dma);
		//	            if (Status == XST_SUCCESS)
		//	            	            	            	            {
		//	            	            	            	                while (!Done && !Error);
		//	            	            	            	            }

		XTime_GetTime(&tEnd);
		u64 et_dma_bram = tEnd - tStart;
		// xil_printf("Time taken for one transaction: %llu\n", et_dma_bram);

		check = 0;

		Status = XAxiCdma_SimpleTransfer(&Dma, (u32)(&check),
										 (u32)cdma_memory_destination_bram4, 1 * (sizeof(u32)), Example_CallBack,
										 (void *)&Dma);
		if (Status == XST_SUCCESS)
		{
			while (!Done && !Error)
				;
		}

		sleep(1);

		Status = XAxiCdma_SimpleTransfer(&Dma, (u32)cdma_memory_destination_bram1, (u32)Src_res,
										 DMA_TRANSFER_SIZE_A * (sizeof(u32)), Example_CallBack,
										 (void *)&Dma);
		if (Status == XST_SUCCESS)
		{
			while (!Done && !Error)
				;
		}

		for (int i = 0; i < A_col; i++)
		{
			for (int j = 0; j < B_col; j++)
			{
				mat_b_T[j][i] = mat_b[i][j];
			}
		}

		int match = 1; // Flag to check if all values match
		for (int i = 0; i < A_row; i++)
		{
			for (int j = 0; j < B_col; j++)
			{
				u32 expected_value = mat_b_T[i][j];
				u32 result_value = Src_res[i * B_col + j]; // Access the corresponding value from Src_res

				// xil_printf("mat_res[%d][%d] = %d, Src_res[%d] = %d --> ", i, j, expected_value, i * B_col + j, result_value);

				if (expected_value == result_value)
				{
					// xil_printf("MATCH\n");
				}
				else
				{
					// xil_printf("MISMATCH\n");
					match = 0;
				}
			}
		}
		if (match)
		{
			xil_printf("Transposed matrix read from  PL is correct\n");
		}
		else
		{
			xil_printf("Transposed matrix read from  PL has  mismatches\n");
		}

		xil_printf("\n");
	}

	cleanup_platform();
	return 0;
}



void single_inst_gen(Opcode opcode, u16 a_addr, u16 b_addr, u16 r_addr)
{
	instructions[pc++] = ((u64)a_addr << SHIFT_A) | ((u32)b_addr << SHIFT_B) | ((u32)r_addr << SHIFT_R) | opcode;
}

void inst_gen(MatrixOp op, u16 a_start, u16 b_start, u16 r_start, u16 m, u16 n, u16 p)
{

	u16 n_times = MAX(n / UNIT, 1);

	Opcode opcode;
	u16 i, j, k, offset;

	if (op != MDOT)
	{
		if (op == MADD)
			opcode = ADD;
		else if (op == MSUB)
			opcode = SUB;
		else if (op == MTRANS)
			opcode = PASS_B;
		else
			opcode = NOP;

		for (i = 0; i < m; i++)
		{
			for (j = 0; j < n_times; j++)
			{
				offset = n_times * i + j;
				single_inst_gen(opcode, a_start + offset, b_start + offset, r_start + offset);
			}
		}
	}
	else
	{
		// Row of A
		for (i = 0; i < m; i++)
		{
			// Col of B
			for (k = 0; k < p; k++)
			{
				offset = i * MAX(p / UNIT, 1) + (k / UNIT);

				// Single element calculation
				if (k % UNIT == 0)
				{
					single_inst_gen(DOT_CLR, a_start + n_times * i + 0, b_start + n_times * k + 0, r_start + offset);
				}
				else
				{
					single_inst_gen(DOT_SFT, a_start + n_times * i + 0, b_start + n_times * k + 0, r_start + offset);
				}

				for (j = 1; j < n_times; j++)
				{
					single_inst_gen(DOT_ACC, a_start + n_times * i + j, b_start + n_times * k + j, r_start + offset);
				}
			}
		}
	}
}

void reset_pc()
{
	pc = 0;
	last_sent_pc = 0;
}

void SendInstructions()
{

	int length;
	if (pc == 0)
	{
		length = INST_BRAM_DEPTH;
	}
	else if ((pc - last_sent_pc) < INST_BRAM_DEPTH)
	{
		length = INST_BRAM_DEPTH;
	}
	else
	{
		length = INST_BRAM_DEPTH;
	}

	u32 Status = XAxiCdma_SimpleTransfer(&Dma, (u32)(instructions + last_sent_pc), (u32)cdma_memory_destination_bram2,
										 length * (sizeof(u64)), Example_CallBack,
										 (void *)&Dma);
	if (Status == XST_SUCCESS)
	{
		while (!Done && !Error)
			;
	}

	xil_printf("Instructions from %d to %d sent\r\n", last_sent_pc, last_sent_pc + length - 1);

	last_sent_pc += length;
}

/***************************************************************************************************************************************************/
// SetupInterruptSystem
/***************************************************************************************************************************************************/
int SetupInterruptSystem(XScuGic *GicInstancePtr, XAxiCdma *DmaPtr)
{
	XScuGic_Config *IntcConfig;

	Xil_ExceptionInit();

	// initialize the interrupt control driver so that it is ready to use
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	Status = XScuGic_CfgInitialize(GicInstancePtr, IntcConfig, IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS)
		return XST_FAILURE;

	XScuGic_SetPriorityTriggerType(GicInstancePtr, DMA_CTRL_IRPT_INTR, 0xA0, 0x3);

	// Connect the interrupt controller interrupt handler to the hardware interrupt handling logic in the processor
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, GicInstancePtr);

	// Connect the device driver handler that will be called when an interrupt for the device occurs
	// The handler defined above performs the specific interrupt processing for the device

	// Connect the Fault ISR
	Status = XScuGic_Connect(GicInstancePtr, DMA_CTRL_IRPT_INTR, (Xil_InterruptHandler)XAxiCdma_IntrHandler, (void *)DmaPtr);
	if (Status != XST_SUCCESS)
		return XST_FAILURE;

	// Enable the interrupt for the device
	XScuGic_Enable(GicInstancePtr, DMA_CTRL_IRPT_INTR);

	Xil_ExceptionInit();

	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
								 (Xil_ExceptionHandler)XScuGic_InterruptHandler,
								 GicInstancePtr);

	Xil_ExceptionEnable();

	// enable interrupts in the processor
	// Xil_ExceptionEnableMask(XIL_EXCEPTION_IRQ);

	return XST_SUCCESS;
}

static void Example_CallBack(void *CallBackRef, u32 IrqMask, int *IgnorePtr)
{

	if (IrqMask & XAXICDMA_XR_IRQ_ERROR_MASK)
	{
		Error = TRUE;
	}

	if (IrqMask & XAXICDMA_XR_IRQ_IOC_MASK)
	{
		Done = TRUE;
	}
}

// simple 8-bit lfsr for pseudo-random number generator
u32 lfsr_rand()
{
	unsigned lsb = lfsr & 1; /* Get LSB (i.e., the output bit). */
	lfsr >>= 1;				 /* Shift register */
	if (lsb)
	{ /* If the output bit is 1, apply toggle mask. */
		lfsr ^= 0x71000000u;
	}
	return lfsr;
}
