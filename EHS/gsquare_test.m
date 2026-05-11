function [pval_g, pval_chi] = gsquare_test(D,states,x,y,Z)

  % D is a sample of discrete variables (variables in rows, observations in
  % columns, i.e. generally more columns than rows)
  % states is a vector indicating the number of states of each discrete variable
  %   in D (in the same order)
  % test: x independent of y given Z, where x and y are single indices and
  %       Z is a (possibly empty) set of indices of variables.

  % get observed counts
  len = length(Z);
  cond_conf = prod(states(Z));
  obs = zeros(states(x),states(y),cond_conf);
  
  cond_states = zeros(cond_conf,len); % in each row one constellation of all
     % conditioning varialbes
  
  % build cond_states
  for i=1:len % all conditioning variables
    z = Z(i);

    rep_state = 1;
    for k=i+1:len
      rep_state = rep_state*states(Z(k));
    end
    rep_block = 1;
    for k=1:(i-1)
      rep_block = rep_block*states(Z(k));
    end

    block = zeros(states(z)*rep_state,1);
    
    for j=1:states(z) %all statets of the conditioning variables
      block(1+rep_state*(j-1):rep_state*j) = j;
    end

    cond_states(:,i) = repmat(block,rep_block,1);
  end
  
  % go through all constellations of cond. vars. and obtain cell counts
  nsamp = size(D,2);
  for i=1:cond_conf
    % get indices where conditioning variables have values cond_states(i,:)
    ind = find( all( D(Z,:) == repmat(cond_states(i,:)',1,nsamp) ,1 ) );
    temp = D([x y],ind); % values of x and y given Z=cond_states(i,:)
    for j=1:states(x)
      for k=1:states(y)
        obs(j,k,i) = sum( all( temp==repmat([j;k],1,size(temp,2)) ) );
      end
    end
  end

  % get expected counts
  exp = zeros(states(x),states(y),cond_conf);

  for k=1:cond_conf
    temp = obs(:,:,k);
    n_k = sum(sum(temp));
    for i=1:states(x)
      for j=1:states(y)
        exp(i,j,k) = sum(temp(i,:))*sum(temp(:,j))/n_k;
      end
    end
  end

  % g-square statistics (see Spirtes-book, p.95)
  G2 = 0;
  df_sub = 0; % degrees of freedom which have to be subtracted because of zero
              % counts in the observations.
  for k=1:cond_conf
    bool = obs(:,:,k)~=0;
    temp = obs(:,:,k);
    obs_temp = temp(bool);
    temp = exp(:,:,k);
    exp_temp = temp(bool);
    G2 = G2 + sum(sum( obs_temp .* log(obs_temp./exp_temp) ));
    df_sub = df_sub + sum(sum(~bool));
  end
  G2 = 2*G2;

  df = (states(x)-1)*(states(y)-1)*prod(states(Z)) - df_sub;
  if (df<=0)
    df = 1;
  end

%    G2
  pval_g = 1-chi2cdf(G2,df);


%    % chi-square statisics
%    Chi2 = 0;
%    df_sub = 0;
%    for k=1:cond_conf
%      Chi2 = Chi2 + sum(sum( ((obs(:,:,k) - exp(:,:,k)).^2)./exp(:,:,k) ));
%      df_sub = df_sub + sum(sum(~bool));
%    end
%  
%    df = (states(x)-1)*(states(y)-1)*prod(states(Z));
%  
%  %    Chi2
%    pval_chi = 1-chi2cdf(Chi2,df);
  pval_chi = NaN;

%  obs
%  exp

%  keyboard
