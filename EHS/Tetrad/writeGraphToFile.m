function [] = writeGraphToFile(B,nobs,nhid,filename)

  if ~exist('filename')
    filename = './Tetrad/graph.txt';
  end
  
  % B: connection matrix, 
  %    first nobs-2 covariates, then x (treatment) and y (outcome) and then
  %    nhid hidden variables
  % B = 0 1 0 0   x1 := x2 + e1
  %     0 0 0 0   x2 := e2
  %     1 1 0 0   x3 := x1 + x2 + e3
  %     0 0 0 0   x4 (a hidden)
  % nobs: number of observed variables
  % nhid: number of hidden variables

  %% get nodes string
  str_var = 'X001';
  var_names{1} = 'X001'; % for writing the edges

  for i=2:nobs
    if (i < 10)
      str = strcat('X00',num2str(i));
    elseif (i < 100)
      str = strcat('X0',num2str(i));
    else
      str = strcat('X',num2str(i));
    end
    str_var = strcat(str_var,',',str);
    var_names{i} = str;
  end

  for i=1:nhid
    str = strcat('Latent(L',num2str(i),')');
    str_var = strcat(str_var,',',str);
    var_names{nobs+i} = strcat('L',num2str(i));
  end

  %% get edges string
  str_edge = '';

  % edges j -> i
  for i=1:(nobs+nhid)
    for j=1:(nobs+nhid)
      if (B(i,j)~=0)
        str = strcat(var_names{j}, '-->', var_names{i});
        if strcmp(str_edge,'')
          str_edge = str; % no comma when writing first edge
        else
          str_edge = strcat(str_edge,',',str);
        end
      end
    end
  end

  %% and finally write the whole string to the file
  str_final = strcat(str_var,',',str_edge);

  fileID = fopen(filename,'w');
  fprintf(fileID,'%s',str_final);
  fclose(fileID);
