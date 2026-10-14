# bote — back-of-the-envelope calculations

One constants table (`constants.json`, SI, CODATA 2022 / IAU) shared by PowerShell and Python.

## Install (Windows, current user)

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Copies everything to `~\.bote`, installs `pint`, sets `PYTHONSTARTUP`/`PYTHONPATH`, adds the module to both PowerShell profiles. Open a new terminal afterwards.

## PowerShell

```powershell
$AU / $c                          # light-travel time Sun→Earth, s
sqrt (2*$G*$Mearth/$Rearth)       # escape velocity (helpers: sqrt cbrt ln log10 exp oom)
$kB*300/$qe | eng -Unit eV        # 25.9 meV
const mass                        # search the table
bote "(1*u.kWh).to('MJ')"         # full Python + units from PowerShell
```

## Python

```python
>>> sqrt(kB*300/me)               # plain floats, SI
>>> (Q.h*Q.c/(500*u.nm)).to('eV') # constants with units (pint)
>>> eng(3.2e-7, 'F')              # '320 nF'
>>> const('sun')
```

In scripts or Jupyter: `from bote import *`.

Naming: `qe` = elementary charge, `e` = Euler's number, `amu` = dalton, `u` = unit registry, `Q.<name>` = constant with units.
Add your own constants by appending to `constants.json` (names must be unique ignoring case, because PowerShell variables are case-insensitive).
