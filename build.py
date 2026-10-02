#!/bin/env python3

import subprocess
import os
from pathlib import Path
import argparse

# Global constants
CXX = "g++"
ASM = "nasm"
QEMU = "qemu-system-i386"

SRC_DIR = Path("src")
BUILD_DIR = Path("build")

def buildBootloader(args):
    if args.verbose:
        print("Building Bootloader (Stage 1)")
    subprocess.run([ASM, SRC_DIR / "bootloader/stage1/boot1.asm", "-o", BUILD_DIR / "boot1.bin"])

def runOS(args):
    subprocess.run([QEMU, "-hda", BUILD_DIR / "disk.img"])


def copyBLToDisk(args):
    # Overwrite entire Sector 0 of the disk with the Stage 1 bootloader
    subprocess.run(["dd", f"if={BUILD_DIR / 'boot1.bin'}", f"of={BUILD_DIR / 'disk.img'}", "bs=512", "count=1", "conv=notrunc", "status=none"])

def createDisk(args):
    # Create a raw 64 MB File filled with zeroes
    subprocess.run(["dd", "if=/dev/zero", f"of={BUILD_DIR / 'disk.img'}", "bs=1M", "count=64"])

    # Format FAT32 starting at LBA 2048
    subprocess.run(["mkfs.vfat", "--offset=2048", "-F", "32", "-n", "BASEDOS", BUILD_DIR / "disk.img"])

    copyBLToDisk(args)

def main(args):

    # Create output directory if doesnt exist
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    if args.bootloader or args.all:
        buildBootloader(args)
    if args.image or args.all:
        createDisk(args)
    if args.copybl:
        copyBLToDisk(args)

    if args.run:
        runOS(args)
    

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Build script for Based OS."
    )

    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output.")
    parser.add_argument("-b", "--bootloader", action="store_true", help="Build only the bootloader.")
    parser.add_argument("-i", "--image", action="store_true", help="Create the disk image.")
    parser.add_argument("-c", "--copybl", action="store_true", help="Copy the bootloader onto the disk image.")
    parser.add_argument("-r", "--run", action="store_true", help="Run the OS.")
    parser.add_argument("-a", "--all", action="store_true", help="Build everything.")
    
    
    args = parser.parse_args()


    
    main(args)