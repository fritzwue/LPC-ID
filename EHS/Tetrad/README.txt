NOTE: The only file modified in the Tetrad code is the file TetradCmd.java,
to allow loading background knowledge from the command line. As tetrad is under
GNU General Public License this naturally applies to that file as well.

The java jar is provided in the code package, and was obtained as follows
(this was only tested under Linux):

1. download the Tetrad java code from the Tetrad homepage 
http://www.phil.cmu.edu/projects/tetrad_download/download/
The used file was 'tetraddist-4.3.9-24.zip'.

2. Extract the zip file tetraddist-4.3.9-24.zip

3. copy the file 'TetradCmd.java' (provided in the code package) to the folder
tetrad-4.3.9-24/scr/edu/cmu/tetradapp (replace the existing 'TetradCmd.java')

4. open a konsole/terminal, and go to the folder tetrad-4.3.9-24

5. run the command 'ant cmdjar' 
This builds the java-jar. This requires that 'ant' is installed.

6. copy the java-jar from the folder tetrad-4.3.9-24/build/tetrad/upload to
the folder codepackage/Tetrad





