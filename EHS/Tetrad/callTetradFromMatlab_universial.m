function [] = callTetradFromMatlab_universial(mytype, pathName, algName, ...
               fileName, outFileName, knowledgeFileName, dataType, sig, ...
               completeRuleSet, PossDsepSearch)

  % REQUIRED
  % mytype = 'graphbg' (DAG model with tiers as background knowledge)
  %          'databg' (date from DAG model with tiers as background knowledge)
  % pathName = where Tetrad jar is (also where to save the files: mypath/
  %            be sure to have the last backslash in the path-name)
  % algName = 'fci' (calls standard FCI)
  %           'cfci' (calls standard CFCI)
  % fileName = f.ex. 'graph.txt', 'cov.txt', or 'data.txt'
  %            where input graph/covariance matrix/data are saved
  % outFilename = f.ex. 'resultFCI.txt'
  %               where output is to be saved
  % knowledgeFileName = f.ex. 'knowledge.txt'
  %                     where background knowledge is saved (tiers)
  %                     NULL - if there is no background knowledge
  % If input is data matrix, additionally need
  % datatype = 'continuous'
  %            'discrete'
  % sig = f.ex. 0.05, significance level for independence test
  % completeRuleSet ... 'true' or 'false' (use only R0-R4)
  % PossDsepSearch ... 'true' or 'false'

  tetradJarName =  'tetradcmd-4.3.9-24.jar'; % updated TetradCmd.java for our purposes

  if (strcmp(mytype,'graphbg'))
    % calls standard FCI/CFCI for graphs including tiers in backgroundknowledge
    progcall = strcat('java -jar', {' '}, pathName, tetradJarName, {' '}, ...
      '-graph', {' '}, pathName, fileName, {' '}, '-algorithm', {' '}, ...
      algName, {' '}, '-knowledge', {' '},  pathName, knowledgeFileName, ...
      {' '}, '-outfile', {' '}, pathName, outFileName);
  end

  if (strcmp(mytype,'databg'))
    % calls standard FCI/CFCI for data including tiers in backgroundknowledge
    progcall = strcat('java -jar', {' '}, pathName, tetradJarName, {' '}, ...
      '-data', {' '}, pathName, fileName, {' '}, '-datatype', {' '}, ...
      dataType, {' '}, '-significance', {' '}, num2str(sig), {' '}, ...
      '-algorithm', {' '}, algName, {' '}, '-knowledge', {' '}, pathName, ...
      knowledgeFileName, {' '}, '-completeRuleSet', {' '}, ...
      completeRuleSet, {' '}, '-PossDsepSearch', {' '}, ...
      PossDsepSearch, {' '}, '-outfile', {' '}, pathName, outFileName);
  end

  if (length(progcall)==1)
    system(progcall{1}); % if progcall is very long, matlab puts it into an array
                         % i.e. progcall = [1x370 char]; need to call progcall{1}
                         % to get to actual string
  else
    system(progcall);
  end 
