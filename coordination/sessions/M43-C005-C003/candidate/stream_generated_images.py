import base64
import ctypes
import msvcrt
import sys

handle = msvcrt.get_osfhandle(0)
mode = ctypes.c_ulong()
kernel = ctypes.windll.kernel32
kernel.GetConsoleMode(handle, ctypes.byref(mode))
kernel.SetConsoleMode(handle, mode.value & ~0x0004)
output = None
while True:
    line = sys.stdin.readline()
    if not line:
        break
    line = line.strip()
    if line.startswith("!FILE!"):
        if output is not None:
            output.close()
        output = open(line[6:], "wb")
    elif line == "!ENDIMG!":
        if output is not None:
            output.close()
            output = None
        print("SAVED", flush=True)
    elif line == "!ENDALL!":
        break
    elif output is not None:
        output.write(base64.b64decode(line))
if output is not None:
    output.close()