function [estimates,CI,P_est] =  calculateEstimatedEffect(D, Zs, dataType, states, getCI)

  % INPUT:
  % D ... Data (variables in rows, observations in columns)
  % Zs ... cell array in which each cell is a set Z or NaN
  % dataType ... 'continuous', 'Gauss', or 'discrete'
  %              NOTE: not yet implemented for discrete data
  % states ... if dataType='discrete' a vector containing the number of state
  %            for each observed variables, else []
  % getCI ... (optional) if 1 calculate confidence intervals of effect, if 0
  %           don't. (default = 1)
  %
  % OUTPUT
  % estiamtes ... a matrix of same dimensions as cell array Zs, each entry
  %               containing the estiamted effect of the corresponging Z
  % CI ... a cell arry of same dimensions as cell arry Zs, each cell having
  %        a confidence interval of the estimated effect (if getCI = 1),
  %        otherwise all cells are empty matrices
  % P_est ... the estimated joint distribution if dataType = 'discrete'

  if ~exist('getCI')
    getCI = 1;
  end

  dims = size(Zs);
  estimates = NaN(dims); % estimated causal effects when Z admissible
  CI = cell(dims); % confidence interval for estimated causal effects

  nobs = size(D,1);
  x = nobs-1;
  y = nobs;

  switch dataType
    case {'continuous','Gauss'}
      % get regression coefficient
      D1 = ones(size(D,2),1); % for intercept
      Dx = D(x,:)';
      Dy = D(y,:)';
      for i1 = 1:dims(1)
	for i2 = 1:dims(2)
	  Z = Zs{i1,i2};
	  if ( ~all(isnan(Z)) || length(Z)==0 )
	    [temp, ci] = regress(Dy, [D1, Dx, D(Z',:)']);
	    estimates(i1,i2) = temp(2);
	    if (getCI)
	      CI{i1,i2} = ci(2,:);
	    end
	  end
	end
      end

      P_est = NaN; % just to have return value

    case 'discrete'

      fprintf('Not yet implemented for discrete data. Return.\n')
      estimates = NaN;
      CI = NaN;
      P_est = NaN;
      return

  end
