"""bote - back-of-the-envelope toolkit (constants in SI, optional units via pint).

Interactive: set PYTHONSTARTUP to this file, then just `python`.
Scripts / Jupyter:   from bote import *
One-shot CLI:        python bote.py "sqrt(2*G*Mearth/Rearth)"

Names
  c h hbar qe kB NA R F G eps0 mu0 me mp mn amu alpha ...   plain floats, SI
  Q.<name>          same constant as a pint Quantity (with units)
  u                 pint unit registry:  (3*u.kWh).to('MJ')
  const('mass')     list / search constants
  eng(x, 'W')       engineering format with SI prefix -> '1.23 kW'
  oom(x)            order of magnitude (integer power of ten)
  e, pi, sqrt, log, exp, ...   everything from math (e = Euler; charge is qe)
"""
import json as _json
import os as _os
import sys as _sys
from math import *  # noqa: F401,F403
from types import SimpleNamespace as _NS


def _home():
    try:
        return _os.path.dirname(_os.path.abspath(__file__))
    except NameError:  # executed as PYTHONSTARTUP without __file__
        return _os.environ.get("BOTE_HOME", _os.path.join(_os.path.expanduser("~"), ".bote"))


with open(_os.path.join(_home(), "constants.json"), encoding="utf-8") as _f:
    _TABLE = _json.load(_f)

for _k in _TABLE:
    globals()[_k["name"]] = float(_k["value"])

# ---- units (optional) -------------------------------------------------------
try:
    import pint as _pint

    u = _pint.UnitRegistry()
    try:
        u.formatter.default_format = "~P"   # pint >= 0.24
    except AttributeError:
        u.default_format = "~P"             # older pint
    Q = _NS(**{k["name"]: u.Quantity(float(k["value"]), k["unit"]) for k in _TABLE})
except ImportError:
    u = Q = None

# ---- helpers ----------------------------------------------------------------
_PREFIX = {-24: "y", -21: "z", -18: "a", -15: "f", -12: "p", -9: "n", -6: "µ", -3: "m",
           0: "", 3: "k", 6: "M", 9: "G", 12: "T", 15: "P", 18: "E", 21: "Z", 24: "Y"}


def eng(x, unit="", sig=3):
    """Engineering notation. eng(0.00123,'A') -> '1.23 mA'; eng(4.2e7) -> '42e+06'."""
    if hasattr(x, "to_compact"):                      # pint Quantity
        return f"{x.to_compact():.{sig}g~P}"
    x = float(x)
    if x == 0 or not isfinite(x):
        return f"{x:g} {unit}".strip()
    m = float(f"{x:.{sig}g}")                         # round first, then pick exponent
    p = max(-24, min(24, int(floor(log10(abs(m)) / 3)) * 3))
    mant = f"{m / 10**p:.{sig}g}"
    if unit:
        return f"{mant} {_PREFIX[p]}{unit}"
    return mant if p == 0 else f"{mant}e{p:+03d}"


def oom(x):
    """Order of magnitude: oom(3.2e8) -> 8."""
    return int(floor(log10(abs(float(getattr(x, "magnitude", x))))))


def const(pattern=""):
    """Print constants whose name or description contains `pattern`."""
    p = pattern.lower()
    for k in _TABLE:
        if p in k["name"].lower() or p in k["desc"].lower():
            print(f"{k['name']:<7} {float(k['value']):<22.10g} {k['unit']:<15} {k['desc']}")


def _show(r):
    if hasattr(r, "magnitude"):
        return f"{r:.6g~P}   (~ {eng(r)})"
    if isinstance(r, (int, float)):
        return f"{r:.6g}   (~ {eng(r)})"
    return repr(r)


if __name__ == "__main__" and not _sys.argv[0]:  # loaded as PYTHONSTARTUP
    print(f"bote: {len(_TABLE)} constants loaded{', units: u / Q.<name>' if u else ''}. const() to list.")

if __name__ == "__main__" and len(_sys.argv) > 1 and _sys.argv[0].endswith("bote.py"):
    print(_show(eval(" ".join(_sys.argv[1:]), globals())))