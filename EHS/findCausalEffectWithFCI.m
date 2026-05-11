function [decision, effect] = findCausalEffectWithFCI(Data,datatype,sig,states,allFCIrules,possDsep)

  % Data = data matrix (observations in cols, vars in rows)
  % datatype = 'continuous' or 'discrete'
  % sig = f.ex. 0.05, significance level for independence test
  % states, if datatype is discrete, the number of states for each variable, otherwise [];

  if ~exist('allFCIrules')
    allFCIrules = 'false';
  end
  if ~exist('possDsep')
    possDsep = 'true';
  end

  nobs = size(Data,1);
  x = nobs-1;
  y = nobs;

  if strcmp(datatype,'Gauss')
    datatype = 'continuous';
  end

  pag = Tetrad_wrapper('databg', 'cfci', Data, nobs, NaN, datatype, sig, allFCIrules, possDsep);
  % pag(i,j) = 0 no edge between i and j
  %          = 1 if i *-- j (tail at j)
  %          = 2 if i *-> j (head at j)
  %          = 3 if i *-o j (circle at j)
  
%    pag = Tetrad_wrapper('graphbg', 'fci', B_skel, nobs, 2)

  if (pag(nobs,nobs-1)==3)
    decision = 3; % cannot make a decision
    effect = NaN; 

  elseif (pag(nobs,nobs-1)==0 || pag(nobs,nobs-1)==2)
    decision = 2; % have a zero effect
    effect = 0;

  elseif (pag(nobs,nobs-1)==1)
    % have non-zero effect of x on y, find admissible set and estimate it
    decision = 1;

%      % step 1+2 was implemented, but in our case acutally not needed
%      % 1. get one MAG from equivalence class
%      mag = getMagFromPag(pag);
%  
%      % sanity check: no entries of mag can be 3
%      if (any(any(mag==3)))
%        fprintf('error in findCausalEffectWithFCI.m: mag has 3s as entries, go to keyboard\n')
%        keyboard
%      end
%      
%      % 2. find admissible set
%      Z = findAdmisSetFromMag(mag, x, y);
  
    % in our case, an admissible set Z is the parent set of y, excluding x.
    % Since all endpoints at y are arrowheads, and in the first step of getting
    % a MAG from the PAG (the Arrowhead Augmentation), we orient circles on 
    % edges o-> as tails, we can easily find the parents of y from the PAG
    tails = pag(y,:)==1 | pag(y,:)==3; % tails or circles at w (w --> y or w o-> y)
    heads = pag(:,y)==2; % heads at y (w *-> y)
    pa_y = find( tails & heads' ); % parents of y
    Z = setdiff(pa_y, x); %Z1
    
    % 3. estimate effect
    Zcell = cell(1); Zcell{1,1} = Z; % need that Z is in a cell array
    effect = calculateEstimatedEffect(Data, Zcell, datatype, states, 0);

  end
    

