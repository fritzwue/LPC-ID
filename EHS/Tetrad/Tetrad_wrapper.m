function pag = Tetrad_wrapper(mytype, algName, BX, nobs, nhid, dataType, sig, completeRuleSet, PossDsepSearch)

  % INPUT
  % mytype = 'graphbg' (DAG model with tiers as background knowledge)
  %          'databg' (date from DAG model with tiers as background knowledge)
  % algName = 'fci' (calls standard FCI)
  %           'cfci' (calls standard CFCI)
  % BX = graph skeleton or data matrix (observations in cols, vars in rows)
  % nobs = number of observed variables
  % nhid = number of hidden variables, NaN if not known (If input is data matrix)
  % If input is data matrix, additionally need
  % datatype = 'continuous'
  %            'discrete'
  % sig = f.ex. 0.05, significance level for independence test
  % completeRuleSet ... 'true' or 'false' (use only R0-R4)
  % PossDsepSearch ... 'true' or 'false'

  % OUTPUT
  % pag = partial ancestra graph, inferred from Tetrad
  %       nobs x nobs matrix with
  %         pag(i,j) = 0 no edge between i and j
  %                  = 1 if i *-- j (tail at j)
  %                  = 2 if i *-> j (head at j)
  %                  = 3 if i *-o j (circle at j)
  %       Note: pag matrix is not symmetric, f.ex. if i--> j, then
  %             pag(i,j) = 2 and pag(j,i) = 1
  
  pathName = './Tetrad/';
  outFileName = 'resultFCI.txt';
  

  if (strcmp(mytype,'graphbg'))

    writeGraphToFile(BX,nobs,nhid);
    writeKnowledgeToFile_xy(nobs);

    fileName = 'graph.txt';
    knowledgeFileName = 'knowledge.txt';

    callTetradFromMatlab_universial(mytype, pathName, algName, ...
               fileName, outFileName, knowledgeFileName);
               
    pag = readFCIoutput();
  end
  

  if (strcmp(mytype,'databg'))

    writeDataToFile(BX');
    writeKnowledgeToFile_xy(nobs);

    fileName = 'data.txt';
    knowledgeFileName = 'knowledge.txt';

    callTetradFromMatlab_universial(mytype, pathName, algName, ...
               fileName, outFileName, knowledgeFileName, dataType, sig, ...
               completeRuleSet, PossDsepSearch);

    pag = readFCIoutput();
  end

  