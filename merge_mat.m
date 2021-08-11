clear x y vrs output;

x = load('test_2.mat');
y = load('test_1.mat');
% Check to see that both files contain the same variables
vrs = fieldnames(x);
%if ~isequal(vrs,fieldnames(y))
%    error('Different variables in these MAT-files')
%end
% Concatenate data
for k = 1:length(vrs)
    try
        x.(vrs{k}) = [x.(vrs{k});y.(vrs{k})];
    catch e
    end 
end
output.data = x;
% Save result in a new file
save('test','-struct','output','-v7.3');

clear x y vrs output;