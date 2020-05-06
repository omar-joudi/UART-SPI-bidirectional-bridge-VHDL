# UART - SPI bridge consisting of a simple UART and SPI master
Note: ModelSim - Intel FPGA Starter Edition 10.5b was used in the building and simulation of this project.
### Overview:
- Consists of separate and isolated UART and SPI master entities which work with different frequencies and can work  together as a bidirectional bridge.
- Can handle different slave widths (from 1 to 16 bits).
- Can support up to four slave select signals.
- UART supports different baud rates.
- SPI supports clock polarity, clock phase and least or most significant bit first.
- Can send or receive up to 64 words in a row.
- A memory saves data from the SPI master in order to be sent via UART, as the SPI is faster than the UART.

### Protocol description: 
- It starts by receiving two bytes which represent the modes of operation and the control signals. Here is how it is encoded:

**First byte (command 1):**

| Number of words (up to 64 words) | - | - | - | - | - | Slave select | - |
| - | - | - | - | - | - | - | - |
| 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |

**Second byte (command 2):**

| send/ receive | Word size (up to 16 bits) | - | - | - | Clock polarity | Clock phase | LSB first
| - | - | - | - | - | - | - | - |
| 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |


