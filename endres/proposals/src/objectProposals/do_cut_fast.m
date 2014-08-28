   u_pok = log(u_pok_norm ./ (1-u_pok_norm)) + bias';

   unary = [zeros(numel(u_pok), 1)  -u_pok(:)];
   unary(regions{sind},:) = repmat([Inf 0], numel(regions{sind}), 1);
   %[lab3, energy3] = alphaExpansion(labels, unary, edges_pb_pw, -log(costs_pb_pw)*tradeoff, 2);
   [lab2, energy] = mex_maxflow(unary, -log(pw_pb_norm(1:end))*tradeoff, double(edges_pb_pw(1:end,:)));

   lab2 = 2 - lab2; % flip the labels to be compatible with the previous version.
if(0)

  % figure(1);
  % imagesc(im)
  % axis image;
   figure(3);
   hold off;
   display_sps(bndinfo, u_pok);
   hold on;
   plot(region_data.Xapp(sind).cm(1), region_data.Xapp(sind).cm(2),'gx')
   axis image;

   figure(4)
   display_sps(bndinfo, lab2);
   axis image 

   %figure(5),imagesc(im.*double(repmat(ismember(bndinfo.wseg, find(lab2==2)), [1, 1, 3])));
   %axis image
   %pause(0.1)
end
