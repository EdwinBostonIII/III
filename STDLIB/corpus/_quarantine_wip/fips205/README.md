FIPS-205 OFFLINE REFERENCE-VECTOR GENERATORS (quarantined; III-REUNIFICATION-PLAN W2.4.1)

These two Python scripts generate the SLH-DSA reference vectors committed as
STDLIB/corpus/_fips205_*.json.  They are NOT part of any build, gate, or judgment
path (no-Python law); they exist only to regenerate the vectors from the FIPS-205
spec if the committed .json ever needs re-derivation.  The slhdsa module itself is
E-SLH-2 NON-STANDARD (see its header); the vectors serve its KATs.
