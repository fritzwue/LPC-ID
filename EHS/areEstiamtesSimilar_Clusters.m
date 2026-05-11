function [val3] = areEstiamtesSimilar_Clusters(estimates, CIs)

  % INPUT
  % estiamtes ... a nk x 1 vector of estimates (for the same quantity)
  % CIs ... a nk x 1 cell array, each cell containing the confidence interval
  %         of the corresponding estimate
  %
  % OUTPUT
  % val ... a measure for how similar the estiamtes are, 0 = not similar at all
  %         1 = very similar

  nk = length(estimates); % number of classes
  
  N = 100; % get 100 samples from each class
  samples = zeros(nk,N);
  
%    figure(3)
%    clf
  
  for c=1:nk
    ci = CIs{c,1};
    l = ci(1);
    u = ci(2);
    samples(c,:) = l +(u-l)*rand(N,1);
%      plot([l,u],[c c]);
%      hold on
  end
%    ylim([0,nk+1])

  % within class median absolute deviation
  stds3 = zeros(nk,1);
  for c=1:nk
    stds3(c,1) = median( abs( samples(c,:)-estimates(c,1)) );
  end

  % overall median absolute deviation
  sigma3 = median( abs( samples(:) - median(samples(:)) ));
  val3 = median(stds3./sigma3);
  % NOTE: this is very robust to confidence intervals that are off, if 10-20% 
  %       of the intervals are off, it still gives a rather high value (> 0.5), 
  %       so std3 is not that large compared to stds3. If half the confidence 
  %       intervals tell one story, and the other half an other one, then val3
  %       becomes small. If one confidence interval is far off, it becomes
  %       small (~0.5), but not too small.

