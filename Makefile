POWERSHELL ?= powershell.exe

.PHONY: all install uninstall clean test

all:
	$(POWERSHELL) -NoProfile -ExecutionPolicy Bypass -File Tools/build.ps1

install:
	$(POWERSHELL) -NoProfile -ExecutionPolicy Bypass -File Tools/install.ps1

uninstall:
	$(POWERSHELL) -NoProfile -ExecutionPolicy Bypass -File Tools/uninstall.ps1

clean:
	$(POWERSHELL) -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue"

test:
	$(POWERSHELL) -NoProfile -ExecutionPolicy Bypass -File Tools/test.ps1
