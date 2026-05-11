function [counts, counts_norm] = getCountsFromPvalues(out, p_reject, p_accept, newR3)

  % out is the output of algorithm_applyRules123.m (or from main_simulations,
  %   outsim.algOut(:,k), for some k, so a column of outputs of the function
  %   algorithm_applyRules123.m)
  % each cell contains another cell with 3 matrices, the p-values for R1-R3
  % get counts how often R1, R2 and R3 applied, return number how often
  % D2 (=counts of R1+D2), and D1 (= counts of R3) were made (in that order),
  % and normalized counts, i.e. how often was decision Di made, among all
  % possibilities that it could have been made
  
  if ~exist('newR3')
    newR3 = 1; % take out condition (i) w not indep x given Z of R3
  end
  
  m = length(out);
  pvalues = cell(m,1);
  counts = zeros(2,m);
  counts_norm = zeros(2,m);

  for i=1:m
    temp = cell(1,3);    
    temp{1} = out{i}.R1_p; temp{2} = out{i}.R2_p; temp{3} = out{i}.R3_p;
    pvalues{i} = temp;
  end

  
  for i=1:m

    temp = pvalues{i};
    cntR1 = sum( temp{1} > p_accept );
    cntR2 = sum( temp{2}(:,1) < p_reject & temp{2}(:,2) > p_accept );
    
    if (newR3==1)
      cntR3 = sum( temp{3}(:,2) > p_accept & temp{3}(:,3) < p_reject);
    else
      cntR3 = sum( temp{3}(:,1) < p_reject & temp{3}(:,2) > p_accept & temp{3}(:,3) < p_reject);
    end

%  fprintf('---\n')
%  cntR1/length(temp{1})
%  cntR2/length(temp{2})
%  cntR3/length(temp{3})

    counts(:,i) = [cntR1+cntR2, cntR3];
    counts_norm(:,i) = [ (cntR1+cntR2) / (size(temp{1},1)+size(temp{2},1)), cntR3/size(temp{3},1)];

  end % for i

