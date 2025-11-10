Source one of the following scripts:

 - `okosh.sh` is the basic set of functions which are pretty closely POSIX-compliant.
 - `okosh.bash` internally sources the `okosh.sh` set and also extends it with some functions that require extra bashisms.

Place both files in same directory if you use the bash-variant so that it finds the basic set too.

Obviously, you can also source this file in your `.bashrc` or similar to gain access to these functions while working in shell.
