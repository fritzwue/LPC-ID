function [] = writeDataToFile(X,filename)

  % X ... data matrix
  %       more rows (=observations) than columns (=variables)

  if ~exist('filename')
    filename = './Tetrad/data.txt';
  end

  nvar = size(X,2); % number of observed variables
  
  % f.ex. if 3 variables: var_names = {'x1','x2','x3'}
  var_names = cell(1,nvar);
  for i=1:nvar
    if (i<10)
      temp = ['X00',num2str(i)];
    elseif (i<100)
      temp = ['X0',num2str(i)];
    else
      temp = ['X',num2str(i)];
    end
    var_names{i} = temp;
  end

  fid=fopen(filename, 'w');
  for i=1:nvar-1
    mycell=cell2mat(var_names(i));
    fprintf(fid,[mycell '\t']);
  end
  mycell=cell2mat(var_names(end));
  fprintf(fid,[mycell '\n']);

  myformat = '%5d\t ';
  for i=2:nvar
    myformat = [myformat '%5d\t '];
  end
  myformat = [myformat '\n']; % f.ex. if 3 variables: '%5d\t %5d\t %5d \n'
  Xt = X';
  fprintf(fid, myformat, Xt);

  fclose(fid);
