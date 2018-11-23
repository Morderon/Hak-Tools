@echo off

for /D %%d in (*) do (
  nwn_erf -f %%d.hak -e HAK -c %%d 
) 