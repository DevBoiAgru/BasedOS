#!/bin/env python3

import subprocess
import os
from pathlib import Path
import argparse

# Global constants
CXX16 = "/home/devboi/.local/bin/openwatcom/binl/wpp"
LD16="//home/devboi/.local/bin/openwatcom/binl/wlink"
ASM = "nasm"
QEMU = "qemu-system-i386"

SRC_DIR = Path("src")
BUILD_DIR = Path("build")

STAGE1_OUTPUT_DIR = BUILD_DIR / "stage1"
STAGE2_OUTPUT_DIR = BUILD_DIR / "stage2"


def buildBLStage2(args):
    if args.verbose:
        print("Building Bootloader (Stage 2)")

    stage2_dir = SRC_DIR / "bootloader" / "stage2"
    asm_dir = stage2_dir / "asm"
    cpp_dir = stage2_dir / "cpp"
    include_dir = stage2_dir / "include"

    obj_asm_dir = STAGE2_OUTPUT_DIR / "asm"
    obj_cpp_dir = STAGE2_OUTPUT_DIR / "cpp"

    obj_asm_dir.mkdir(parents=True, exist_ok=True)
    obj_cpp_dir.mkdir(parents=True, exist_ok=True)

    objects = []

    # Assemble all assembly files into obj
    for source in sorted(asm_dir.rglob("*.asm")):
        relative = source.relative_to(asm_dir)
        output = (obj_asm_dir / relative).with_suffix(".obj")
        output.parent.mkdir(parents=True, exist_ok=True)

        if args.verbose:
            print(f"  ASM: {source}")

        subprocess.run(
            [ASM, "-f", "obj", str(source), "-o", str(output)],
            check=True
        )
        objects.append(output)

    # Compile all C++ files
    for source in sorted(cpp_dir.rglob("*.cpp")):
        relative = source.relative_to(cpp_dir)
        output = (obj_cpp_dir / relative).with_suffix(".obj")
        output.parent.mkdir(parents=True, exist_ok=True)

        if args.verbose:
            print(f"  C++: {source}")

        subprocess.run(
            [
                CXX16,
                "-q",
                "-bt=dos",
                "-ms",
                "-0",
                "-s",
                "-zl",
                f"-i={include_dir}",
                f"-fo={output}",
                str(source),
            ],
            check=True
        )
        objects.append(output)

    # Generate temporary linker configuration from the existing template
    linker_template = stage2_dir / "linker.lnk"
    generated_linker = STAGE2_OUTPUT_DIR / "stage2_linker.lnk"
    output_bin = STAGE2_OUTPUT_DIR / "boot2.bin"

    # Keep linker options, but replace file and output directives
    lines = linker_template.read_text().splitlines()
    lines = [
        line for line in lines
        if not line.strip().upper().startswith(("FILE ", "NAME "))
    ]

    lines.append(f'NAME {output_bin.resolve()}')

    for obj in objects:
        lines.append(f"FILE {obj.resolve()}")

    generated_linker.write_text("\n".join(lines) + "\n")

    # Link all object files
    if args.verbose:
        print("  Linking Stage 2")

    subprocess.run(
        [LD16, f"@{generated_linker.resolve()}"],
        check=True
    )

    if args.verbose:
        print(f"Stage 2 built: {output_bin}")

def buildBootloader(args):
    if args.verbose:
        print("Building Bootloader (Stage 1)")

    subprocess.run([ASM, SRC_DIR / "bootloader/stage1/main.asm", "-o", STAGE1_OUTPUT_DIR / "boot1.bin"])

    buildBLStage2(args)


def runOS(args):
    subprocess.run([QEMU, "-hda", BUILD_DIR / "disk.img"])


def copyBLToDisk(args):
    # Overwrite entire Sector 0 of the disk with the Stage 1 bootloader
    subprocess.run(["dd", f"if={BUILD_DIR / 'stage1/boot1.bin'}", f"of={BUILD_DIR / 'disk.img'}", "bs=512", "count=1", "conv=notrunc", "status=none"])

    # Overwrite entire Sector 1 of the disk with the Stage 2 bootloader
    subprocess.run(["dd", f"if={BUILD_DIR / 'stage2/boot2.bin'}", f"of={BUILD_DIR / 'disk.img'}", "bs=512", "count=1", "conv=notrunc", "status=none", "seek=1"])


def createDisk(args):
    # Create a raw 64 MB File filled with zeroes
    subprocess.run(["dd", "if=/dev/zero", f"of={BUILD_DIR / 'disk.img'}", "bs=1M", "count=64"])

    # Format FAT32 starting at LBA 2048
    subprocess.run(["mkfs.vfat", "--offset=2048", "-F", "32", "-n", "BASEDOS", BUILD_DIR / "disk.img"])

    copyBLToDisk(args)

def main(args):

    # Create output directories if doesnt exist
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    STAGE1_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    STAGE2_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


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