To update OEVs run :
./create_oev.pl
or with debuggin
env OEVDEBUG=1 ./create_oev.pl 2>&1 | less
and optionally (recommended)
./oevparse.pl > oevparse.txt
and then check changes 
git status -uno
git commit -am "Message"
