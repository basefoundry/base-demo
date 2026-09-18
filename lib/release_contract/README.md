# Governed release validation

`release_bom.py` and `release-bom.schema.json` are unmodified snapshots from
Base commit `5f316aeddc3680b92bd209fcfe652eac020d02d0`, under the included
Apache-2.0 license. `dependency_inputs.py` is the shared v1 input validator
coordinated with Base #2289 and demo #293, from Base commit
`3b1d72ee0e8a49748fc49f8c78484e8639083fc4`. Keep snapshots byte-identical to upstream;
do not fork a weaker local schema interpretation.

`demo_bom.py` adds consumer policy: all four participants, matching supported
pins, both required platforms, and independently retrieved GitHub evidence.
Base's schema accepts JSON numeric schema versions 1 and 1.0 but rejects true.
The separate dependency-input schema uses integer 1 only.
