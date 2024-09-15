# nativeWeb Server

Welcome to the nativeWeb Server project! This repository contains a high-performance(potentially) web server implemented in flat assembly language. The goal of this project is to demonstrate the power and efficiency of low-level programming while providing a functional and lightweight web server. 

## Table of Contents

- [Overview](#overview)
- [Plans](#plans)
- [Getting Started](#getting-started)
- [Building](#building)

## Overview

The nativeWeb Server is designed to showcase assembly language programming by implementing a simple yet efficient HTTP server. It handles basic HTTP requests and serves static pages for now . 
i welcome interested folks to contribute to this project and make this a low powerhungry beast.  

## Plans

- Lightweight and minimalistic 
- Basic HTTP request handling
- file serving
- Low-level performance optimizations

## getting-started

To get started with the nativeWeb Server, you'll need a few prerequisites:

- An x86-compatible processor
- Flat assembler for assembling the code
- A compatible C library for linking (if needed)

### Prerequisites

1. **Install FASM:**
   - I have already included a excutable fasm build in the project itself
2. **Install a compatible C library:**
   - You may need a C library for linking, such as `glibc` on Linux or `libc` on macOS.

## Building

To build the web server, follow these steps:

1. Clone the repository:
   ```bash
   git clone git@github.com:wbccpals/nativeWeb.git
   cd nativeWeb
   ./fasm nativeWeb.asm && ./nativeWeb
## technical resources
  ```bash
  https://flatassembler.net/
  https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md
  extra -
  https://www.menuetos.net/ 
