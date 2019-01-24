
nwn-hak will merge files in each folder it's contained with into a .hak

Requires Ruby

For Windows:

https://rubyinstaller.org/

After it's installed run a ruby command prompt and run:

gem install nwn-lib

Navigate to the folder that contains this git repo and run ruby nwn-test


CreateHakNim.bat

Performs the same operation as the above ruby file, but uses the nim files found here:

https://github.com/niv/neverwinter.nim

After compiling them make sure they're in your PATH. Place the .bat file inside the same folder where the haks-to-be are located, then run it.


nwn_desc.nim:

With the aid of the above scripts, takes defined values from description.ini. Merges a present tlk file with the additional descriptions outputting them into a new .json which can be converted into a tlk with nwn_tlk.
Finally, it updates the tlk references in the 2da.

Supported 2das: classes, spells, racialtypes, feat

Requirements: By default, the original 2das should be within Input 2das and the jsons which hold descriptions should be within Input json. The file name of the jsons should match the 2da. The default values can be changed within description.ini

Input json fields:

id - the row number of the 2da (required), you can also specify multile row numbers like so: "3,8,10" will update 2da rows 3, 8 and 10.
text - the description 
name - the name

Feat.json supports these additional fields:
iprp_spells - value should be the id of a row in iprp_spells
iprp_feats - as above, but with iprp_feats
spells - as above

Spells.json share iprp_spells.

This will share feat/spells name field with the other twodas.

Other columns with a tlk reference can be used. They follow name format of 2da column name in lower case. (So NamePlural becomes nameplural)