function p = indepTest(w,x,Z, samples, DataCov, itest, states)

  % test independence of w and x given Z.
  % itest: 'partialCorr': DataCov is covariance matrix over all variables
  %                       possibly more than in w, x, Z
  %        'gsquare': DataCov is Data matrix over all variables
  % return p-value

%    x
%    w
%    Z

%    threshold_pvalue = 0.1;

  if (strcmp(itest,'partialCorr'))
    indwx = [w,x];
    C = DataCov; % covariance matrix
    C_cond = C(indwx,indwx) - C(indwx,Z) * C(Z,Z)^(-1) * C(Z,indwx);
    
    % test if partial correlation is statistically significantly different
    % from 0 (using Fisher's Z, see Spirtes et al. p.94); if not, independence
    r = C_cond(1,2);
    fisherZ = 0.5* sqrt(samples - length(Z) - 3) * log(abs(1+r) / abs(1-r));
    
    p = 2*(1-normcdf(abs(fisherZ)));
%      indep = p > threshold_pvalue;

%      keyboard

  elseif (strcmp(itest,'gsquare'))

    [pval_g, pval_chi] = gsquare_test(DataCov,states,w,x,Z);
    p = pval_g;
%      indep = pval_g > threshold_pvalue;

  end