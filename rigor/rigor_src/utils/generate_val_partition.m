% @authors:     Fuxin Li
% @contact:     ahumayun@cc.gatech.edu
% @affiliation: Georgia Institute of Technology
% @date:        Fall 2013 - Summer 2014

function partitions = generate_val_partition(D, val, num_partitions)
% Partition val into num_partitions by floodfilling D using a priority
% queue algorithm
    stop_crit = sum(val) / num_partitions;
    num_sp = numel(val);
    used = false(num_sp,1);
    if size(D,1) ~= num_sp
        error('The graph must have the same size as the quality function!');
    end
    partitions = cell(num_partitions,1);
    global_counter = 0;
    conn_comp_flag = false;
    [rows,cols,all_nzvals] = find(D);
    for i=1:num_partitions
        partitions{i} = zeros(num_sp,1);
        cur = find(used==false,1,'first');
        cur_val = val(cur);
        % Create a priority queue implemented with a max-heap. It pops the
        % highest value every time, therefore constant popping will give 
        % always the biggest edge from the current blob to some other superpixel
        pq = pq_create(num_sp);
        partitions{i}(1) = cur;
        used(cur) = true;
        counter = 2;
        global_counter = global_counter + 1;
        did_once_flag = false;
        while cur_val < stop_crit
            if global_counter == num_sp
                break;
            end
%            nzs = cols(rows==cur);
%            nzvals = all_nzvals(rows==cur);
            [nzs,~,nzvals] = find(D(:,cur));
            list_unused = used(nzs) == false;
            nzs = nzs(list_unused);
            nzvals = nzvals(list_unused);
            for j=1:numel(nzs)
                pq_push(pq, int32(nzs(j)), nzvals(j));
            end
            cur = pq_pop(pq);
            % The priority queue has some problems... occasionally popping
            % the same item twice...
            while cur  && used(cur)
                cur = pq_pop(pq);
            end
            % Heap empty, re-initialize
            if (cur == 0)
                cur = find(used==false,1,'first');
            end
            % No unused, break
            if isempty(cur)
                break;
            end
            partitions{i}(counter) = cur;
            used(cur) = true;
            cur_val = cur_val + val(cur);
            counter = counter + 1;
            global_counter = global_counter + 1;
            % Don't break out if there are multiple connected components,
            % unless the flag has been set
            % USELESS
%             if cur_val >= stop_crit
%                 [num_comp,assigns] = graphconncomp(D(partitions{i}(1:counter-1),partitions{i}(1:counter-1)));
%                 % One connected component or already give up, or already did this once, let it go
%                 if num_comp == 1 || conn_comp_flag || did_once_flag
%                     continue;
%                 end
%                 % Find the largest component
%                 num_in_comp = histc(assigns, 1:num_comp);
%                 [a,max_plc] = max(num_in_comp);
%                 cur_part = partitions{i}(1:counter-1);
%                 in_largest_conncomp = cur_part(assigns ==max_plc);
%                 not_in_largest = cur_part(assigns ~= max_plc);
%                 % Largest connected component less than 50%, give up
%                 if numel(in_largest_conncomp) < numel(not_in_largest)
%                     conn_comp_flag = true;
%                 end
%                 % Rip off once those not in the largest connected component
%                 used(not_in_largest) = false;
%                 cur_val = cur_val - sum(val(not_in_largest));
%                 partitions{i}(1:numel(in_largest_conncomp)) = in_largest_conncomp;
%                 counter = numel(in_largest_conncomp) + 1;
%                 % Re-do a priority queue
%                 pq_delete(pq);
%                 pq = pq_create(num_sp);
%                 % Only push in the ones that goes from the connected
%                 % component to somewhere else
%                 [rows, cols] = find(D(in_largest_conncomp,:));
%                 all_conn = unique(cols);
%                 all_conn = all_conn(used(all_conn)==false);
%                 push_val = max(D(in_largest_conncomp,all_conn),[],1);
%                 for j=1:numel(push_val)
%                     pq_push(pq, int32(all_conn(j)), push_val(j));
%                 end
%                 did_once_flag = true;
%             end
        end
        partitions{i} = partitions{i}(1:counter-1);
        pq_delete(pq);
    end
end