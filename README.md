# Four-Lane INT8 Dot-Product Engine

## Overview

This project implements a four-lane signed INT8 dot-product engine in Verilog. It accepts two packed 32-bit vectors, interprets each vector as four signed 8-bit values, multiplies corresponding values in parallel, and adds the four products to produce a dot-product result.

A self-checking testbench is included to verify the design with positive, negative, zero, and boundary-value inputs.

## Operation

For two input vectors:

```text
A = [a0, a1, a2, a3]
B = [b0, b1, b2, b3]
```

the engine calculates:

```text
productALL = (a0 * b0)
           + (a1 * b1)
           + (a2 * b2)
           + (a3 * b3)
```

Each multiplication is handled by an independent lane:

```text
Lane 0: a0 * b0 --\
Lane 1: a1 * b1 ---\
Lane 2: a2 * b2 ----> Addition --> productALL
Lane 3: a3 * b3 ---/
```

Each lane multiplies two signed 8-bit operands and produces a signed 16-bit product.

## Module hierarchy

```text
top_module_tb
└── top_module
    ├── multiplier1
    ├── multiplier2
    ├── multiplier3
    └── multiplier4
```

### `multiplier`

The `multiplier` module represents one lane. It outputs one 8 bit signed multiplication at every rising edge of the clock

### `top_module`

The `top_module` distributes the input matrices to four multiplier instances, adds their registered products, and produces `productALL`. It delays `in_valid` so that `out_valid` is aligned with the result.

### `top_module_tb`

The testbench generates the clock and reset, applies input vectors, calculates expected results, checks the design output, and reports passed and failed tests.

## Interface

| Signal | Direction | Width | Description |
|---|---|---:|---|
| `clk` | Input | 1 bit | Rising-edge system clock |
| `reset` | Input | 1 bit | Synchronous active-high reset |
| `numA` | Input | 32 bits | Four packed signed INT8 operands |
| `numB` | Input | 32 bits | Four packed signed INT8 operands |
| `in_valid` | Input | 1 bit | Indicates that `numA` and `numB` contain valid data |
| `out_valid` | Output | 1 bit | Indicates that `productALL` contains a valid result |
| `productALL` | Output | 64 bits | Signed dot-product result |

## Input packing

Each 32-bit input contains four signed INT8 values:

| Bit range | Element |
|---|---|
| `[31:24]` | Element 3 |
| `[23:16]` | Element 2 |
| `[15:8]` | Element 1 |
| `[7:0]` | Element 0 |

The testbench packs the inputs with:

```verilog
numA = {a3, a2, a1, a0};
numB = {b3, b2, b1, b0};
```

