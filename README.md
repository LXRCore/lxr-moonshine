<img src="https://raw.githubusercontent.com/LXRCore/.github/main/profile/lxrcore-logo.png" alt="LXRCore" width="72" align="left" style="margin-right:12px">

# lxr-moonshine — A still in the woods, for LXRCore

Use the `still_kit` somewhere the law does not ride and a copper still
stands there until you pack it up — or the law smashes it. Load a recipe
from your satchel, come back when the timer is done. Stills live on the
server and survive restarts. Everything in and out is the core catalog's:
corn from lxr-farming, sugar and jars from the store, mash and liquor that
the fence and lxr-contraband already trade.

![The still card](docs/img/still.png)

## What it does

* **Place** — the `still_kit` item, outside `Config.Still.towns`, at least
  `spacing` from another still, `perPlayer` at a time. **Pack up** an idle
  still and the kit comes back.
* **Recipes** — `Config.Recipes`: mash (corn, sugar, yeast → corn mash),
  first run (mash, jars → moonshine), aging, berry infusion. `minutes`
  each; inputs are taken on load, outputs handed over on **Collect**.
* **The risk** — a working still may put a call on the wire through
  lxr-dispatch (`callChancePerMinute`, only with law on duty). The law's
  **Smash** option destroys the still; nothing comes back.
* **The card** — nearest still on the LXR UI Kit: recipe, progress, time left.
* **Prop** — `Config.Still.prop`; a model that fails `IsModelValid` is
  skipped and the still is marked by its prompt.
* **Events** — `lxr:moonshine:placed / loaded / collected / smashed`.

## Install

```cfg
ensure lxr-core
ensure lxr-interact
ensure lxr-dispatch   # optional: the call
ensure lxr-moonshine
```

The table `lxr_moonshine` is created by the core migration runner.

## API

| Name | Side | Purpose |
|---|---|---|
| `Stills(citizenid?)` | server | every still, or one player's |
| `Remove(id)` | server | take a still down |
| `Stills()` | client | the stills this client knows |

## Licence

© 2026 iBoss21 / LXRCore — All Rights Reserved. See `LICENSE`.
