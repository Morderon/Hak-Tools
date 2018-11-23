
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
