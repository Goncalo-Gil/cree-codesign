# CREE — parametric model for immersive codesign

Parametric model of the CREE modular building system, written in Julia with
[Khepri](https://github.com/aptmcl/Khepri.jl). It is the prototype artefact of the MSc
dissertation *Codesigning Modular Buildings: a parametric and immersive approach to
early-stage modular design*.

The model encodes the CREE structural grid and generates a constructively valid
configuration from a set of parameters: grid lines and columns and their spacing, number
of storeys and storey height, voids, cores, window sizes and positions per grid index, and
plan rotation. It is written against Khepri's **BIM layer** (`wall` + `add_window`,
`free_column` with `rectangular_profile`, `slab` on `level`), not raw solids, so the same
model can be realised through different backends.

## Layout

```
notebooks/cree_model.jl    the model — a Pluto notebook: parameter widgets,
                           EdificioParams, and the generating functions
```

## Running it

```julia
julia> using Pluto; Pluto.run()
```

Open `notebooks/cree_model.jl`. AutoCAD must be running with the Khepri plugin loaded
before the final cell executes; the backend is selected at the bottom of the notebook with
`backend(autocad)`.

## History

Development before this repository existed was versioned by hand, as numbered copies in a
`Code/old/` folder. Those nineteen files have been replayed here as commits in their
original chronological order, each tagged with the version number it carried, so the
history is navigable instead of being a folder of dead files:

```
v1.0.0 … v4.1.2    the model as a plain Julia script  (src/cree.jl)
v5.0.0             converted to a Pluto notebook      (notebooks/cree_model.jl)
```

Every tagged file is byte-for-byte identical to the original it was reconstructed from, and
each commit message lists the functions that appeared or disappeared at that step.

Note that `v4.1.2` is the last *plain script* form of the model — the same 42 functions as
the current notebook, outside Pluto. It is the natural starting point for extracting the
model into a reusable module. To get it back without disturbing anything:

```bash
git show v4.1.2:src/cree.jl > src/cree.jl
```

Four of the five leaf geometry functions are byte-identical between `v4.1.2` and the
current notebook; only `painel_fachada_singular` differs, having been simplified during the
Pluto conversion.

## Where this folder should live

Not inside OneDrive, Dropbox or Google Drive. Those sync `.git/` file by file and can
corrupt the repository. Keep it on a plain local path and use the GitHub remote as the
backup.

## Planned next steps

- Verify that the Khepri **Unity** backend realises the BIM layer (a wall with a window, a
  column with a profile, a slab on a level) as completely as the AutoCAD backend does.
- Separate rule evaluation from geometry emission: have the seven `*_singular` functions
  return typed placement records rather than calling Khepri directly, and put the Khepri
  calls behind one thin emitter. This is what makes the backend swappable, makes partial
  regeneration possible, and makes quantities derivable from the model.
