# CREE — parametric model for immersive codesign

Parametric model of the CREE modular building system, written in Julia with
[Khepri](https://github.com/aptmcl/Khepri.jl). It is the prototype artefact of the MSc
dissertation *Codesigning Modular Buildings: a parametric and immersive approach to
early-stage modular design*.

The model encodes the CREE structural grid and generates a constructively valid
configuration from a set of parameters: grid lines and columns and their spacing, number
of storeys and storey height, voids, cores, window sizes and positions per grid index, and
plan rotation. It is written against Khepri's **BIM layer** (`wall` + `add_window`,
`free_column` with `rectangular_profile`, `slab` on `level`)

## Layout

```
src/CREE.jl                the model: EdificioParams, DimensoesSistema, the 42
                           rule and geometry functions, edificio_CREE and
                           generate_model
notebooks/cree_model.jl    the interface: parameter widgets, and the call
```

The split is the point. `src/CREE.jl` holds the rules of the system and nothing else — no
interface, no backend selection, no parameter values — so it can be driven from a notebook,
from a plain script, or from whatever ends up feeding the immersive environment. The
notebook is one caller among several, not the home of the model.

## The two kinds of input

`generate_model(params, dims)` takes them separately:

- **`EdificioParams`** — the design parameters. Grid lines and columns and their spacing,
  storeys and storey height, voids, cores, windows, rotation. These are what varies between
  configurations and what the architect manipulates during a session.
- **`DimensoesSistema`** — the dimensions of the components themselves: slab thickness,
  column and beam cross-sections, core and facade thickness. Fixed context. No configuration
  reachable by moving a slider changes them.

`DimensoesSistema` has keyword defaults, so `generate_model(params)` behaves exactly as
before, and a variant is one call away:

```julia
Modelo.generate_model(parametros, Modelo.DimensoesSistema(hvb = 0.45, e_fachada = 0.12))
```

What each symbol means is recorded once, in `DESCRICOES_DIMENSOES`.
`markdown_dimensoes(dims)` renders the table by full name, which is what the notebook
displays.

The default values are the ones the model has generated with since `v1.0.0`. They have
**not** been checked against CREE's own component documentation — the struct carries a
`fonte` field to record, per value, where each one came from once that check is done. The
admissible range of each is likewise still open.

## Running it

```julia
julia> using Pluto; Pluto.run()
```

Open `notebooks/cree_model.jl`. AutoCAD must be running with the Khepri plugin loaded
before the final cell executes; the backend is selected near the bottom of the notebook
with `backend(autocad)`.

To use the model without Pluto:

```julia
using Khepri
backend(autocad)
Modelo = include("src/CREE.jl")
Modelo.generate_model(Modelo.EdificioParams(0,0,0, 2,6.0, 7,3.0, 0,0,0, [], [], 3,3.0, [], []))
```

`include` returns the module because the `module CREE ... end` definition is the last
top-level expression in the file. Keep it last: binding the result to a name is what lets
Pluto treat the model as an ordinary dependency and run the loader cell before the cells
that use it.

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

`v4.1.2` is the last *plain script* form of the model, before the Pluto conversion. To look
at it without disturbing the working tree:

```bash
git show v4.1.2:src/cree.jl | less
```

## The extraction

`src/CREE.jl` was produced from the notebook at `v5.0.0`, not from the older script, so it
carries the current version of every function — including `painel_fachada_singular`, the
one function that was simplified during the Pluto conversion and therefore differs between
the two lineages.

The extraction was deliberately mechanical, so that it provably changes no behaviour. Every
function body in `src/CREE.jl` is byte-identical to the notebook cell it came from, which is
why they sit unindented inside `module CREE` — indenting them would have made the move
unverifiable. Three things were not pure moves, and they are the only places behaviour could
have changed:

1. `EdificioParams` was lifted out of the `begin` block it shared with `parametros`, and its
   fields re-indented. Field names, types and order are untouched.
2. `parametros` and the generate call in the notebook now say `Modelo.EdificioParams` and
   `Modelo.generate_model`.
3. Empty disabled cells left over from earlier work were dropped, and the nine `## Funções
   de …` markdown cells became the comment headers of the corresponding module sections.

## Planned next steps

- Verify that the Khepri **Unity** backend realises the BIM layer (a wall with a window, a
  column with a profile, a slab on a level) as completely as the AutoCAD backend does.
- Confirm the thirteen values in `DimensoesSistema` against CREE's component documentation,
  and fill in the `fonte` field and the admissible range of each.
- Separate rule evaluation from geometry emission: have the seven `*_singular` functions
  return typed placement records rather than calling Khepri directly, and put the Khepri
  calls behind one thin emitter. This is what makes the backend swappable, makes partial
  regeneration possible, and makes quantities derivable from the model.

## Where this folder should live

Not inside OneDrive, Dropbox or Google Drive. Those sync `.git/` file by file and can
corrupt the repository. Keep it on a plain local path and use the GitHub remote as the
backup.
