function VertexMap =compute_vertex_map(source_verts, target_verts, sym_map)
    % Calculate the target position for each vertex from source_verts based
    % on the map provided
    VertexMap.source = source_verts;
    VertexMap.targets = zeros(size(source_verts));
    for i=1:length(VertexMap.source)
        v_map = sym_map(i,:);
        pt_ids = find(v_map);
        bary_wgts = transpose(full(v_map(:, pt_ids)));
        weighted_pts = bary_wgts.*target_verts(pt_ids, :);
        VertexMap.targets(i, :) = sum(weighted_pts, 1);
    end
end

% Want to compute the target position of each vertex
% P_12: row i contains the barycentric coordinates of the vertex i in
% columns (a, b, c, d) where (a, b, c, d) are the vertices of the enclosing
% tetrahedron it is mapped to, and contains zeros in all other columns

% need to convert barycentric coordinates to cartesian coordinates
% need to identify the correct enclosing tetrahedron first
% nevermind that, they are barycentric so I just need to multiply the
% points matching those column ids with the barycentric values and then sum
% the result to get the target location