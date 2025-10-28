# smartreader

I am using a wifi smartreader from [Marcel Zuidwijk](https://www.zuidwijk.com/slimmelezer-smartreader/) to read data from my DSMR smartmeter en send it to DSMR-Reader docker container using the network socket input method.

## installation

### 1. download .bin file from zuidwijk.com

https://www.zuidwijk.com/download/esp-link-precompiled-3-2-47/

### 2. install esptool.py

You will need [either Python 2.7 or Python 3.4 or newer](https://www.python.org/downloads/) installed on your system.

The latest stable esptool.py release can be installed from [pypi](http://pypi.python.org/pypi/esptool) via pip:

```bash
#!/bin/bash
pip install esptool
```

With some Python installations this may not work and you'll receive an error, try `python -m pip install esptool` or `pip2 install esptool`, or consult your [Python installation manual](https://pip.pypa.io/en/stable/installing/) for information about how to access pip.

[Setuptools](https://setuptools.readthedocs.io/en/latest/userguide/quickstart.html) is also a requirement which is not available on all systems by default. You can install it by a package manager of your operating system, or by `pip install setuptools`.

After installing, you will have `esptool.py` installed into the default Python executables directory and you should be able to run it with the command `esptool.py` or `python -m esptool`. Please note that probably only `python -m esptool` will work for Pythons installed from Windows Store.

### 3. Flash the ESP device

Check which path the device is using

```bash
#!/bin/bash
dmesg | grep tty
```

Go to download directory and run following command to flash the ESP device

```bash
#!/bin/bash
esptool.py -p <path> --baud 230400 write_flash --flash_mode dio -fs 32m -ff 40m 0x00000 boot_v1.7.bin 0x3FE000 blank.bin 0x3FC000 esp_init_data_default.bin 0x01000 user1.bin
```