function [] = writeKnowledgeToFile_xy(nobs,filename)

  
  % nobs: number of observed variables
  % assume partial knowledge s.t. x_1, ... x_nobs-2 before x_nobs-1 (treatment)
  %   before x_nobs (outcome)

  % write 3 tiers:
  %   tier 1: x_1, ... x_nobs-2 (covariates)
  %   tier 2: x_nobs-1 (treatment)
  %   tier 3: x_nobs (outcome)
  %   
  
  
  if ~exist('filename')
    filename = './Tetrad/knowledge.txt';
  end

  %% write tiers to file

  fileID = fopen(filename,'w'); % open file to write results
  % last variable is in last/third tier (indicated by 2)
  if (nobs>=100)
    str = strcat(int2str(2),' X', int2str(nobs));
  elseif (nobs>=10)
    str = strcat(int2str(2),' X0', int2str(nobs));
  else
    str = strcat(int2str(2),' X00', int2str(nobs));
  end
  fprintf(fileID,'%s\n',str);

  % second last variable is in second last/second tier (indicated by 1)
  if (nobs-1>=100)
    str = strcat(int2str(1),' X', int2str(nobs-1));
  elseif (nobs-1>=10)
    str = strcat(int2str(1),' X0', int2str(nobs-1));
  else
    str = strcat(int2str(1),' X00', int2str(nobs-1));
  end
  fprintf(fileID,'%s\n',str);

  % all other variables are in first tier (indicated by 0)
  for j=1:(nobs-2)
    if (j>=100)
      str = strcat(int2str(0),' X', int2str(j));
    elseif (j>=10)
      str = strcat(int2str(0),' X0', int2str(j));
    else
      str = strcat(int2str(0),' X00', int2str(j));
    end
    fprintf(fileID,'%s\n',str);
  end

  fclose(fileID); % close file
