1. **(OPTIONAL) To set up a separate Opam "universe" -- useful if you want
   multiple versions of Coq -- do:**

  1. `opam switch install coq8.5 --alias-of system`
  2. `` eval `opam config env` ``

2. **To install Coq 8.6 and MathComp (which now includes SSReflect):**

  1. `opam repo add coq-released https://coq.inria.fr/opam/released` (for
     SSReflect and MathComp)
  2. `opam update`
  3. `opam install coq.8.6 coq-mathcomp-ssreflect.1.6.1`

3. **To install `metalib`:**

  1. `git clone https://github.com/plclub/metalib.git` in the same directory as
     `corespec` (so `corespec` and `metalib` are siblings).
  2. `make`

4. **To install `lngen`:**

  1. `git clone https://github.com/plclub/lngen.git` in the same directory as
     `corespec` (so `corespec` and `lngen` are siblings).
  2. In the `lngen` directory, compile lngen
       `cabal sandbox init`
	   `cabal install`
  3. Makefile will look here